// swiftlint:disable file_length

import Foundation
import Metal
import MetalKit
import ARKit
import Combine
import Common

public enum ConfidenceThreshold: Int32, CaseIterable {
    case /*low = 0,*/ medium = 1, high
}

public enum SamplingRate: Float, CaseIterable {
    case slow = 0.5, regular = 1, fast = 1.5
}

public final class RenderingService: ObservableObject {
    // MARK: - Settings and Constants
    private let orientation = UIInterfaceOrientation.portrait
    // Camera's threshold values for detecting when the camera moves so that we can accumulate the points
    lazy var cameraRotationThreshold = Self.updateCameraRotationThreshold()
    lazy var cameraTranslationThreshold = Self.updateCameraTranslationThreshold()
    // The max number of command buffers in flight
    private let maxInFlightBuffers = 1
    lazy var rotateToARCamera = Self.makeRotateToARCameraMatrix(orientation: orientation)

    private class func updateCameraRotationThreshold(with rate: SamplingRate = .regular) -> Float {
        let degree = (2 / rate.rawValue)
        return cos(degree * .degreesToRadian)
    }

    private class func updateCameraTranslationThreshold(with rate: SamplingRate = .regular) -> Float {
        let meter = (0.02 / rate.rawValue)
        return pow(meter, 2) // (meter-squared)
    }

    // MARK: - Engine

    // Metal objects and textures
    let library: MTLLibrary
    private let depthStencilState: MTLDepthStencilState
    private let commandQueue: MTLCommandQueue
    lazy var unprojectPipelineState = makeUnprojectionPipelineState()!
    lazy var rgbPipelineState = makeRGBPipelineState()!
    lazy var particlePipelineState = makeParticlePipelineState()!
    // texture cache for captured image
    lazy var textureCache = makeTextureCache()
    private var capturedImageTextureY: CVMetalTexture?
    private var capturedImageTextureCbCr: CVMetalTexture?
    private var depthTexture: CVMetalTexture?
    private var confidenceTexture: CVMetalTexture?

    // Multi-buffer rendering pipeline
    private let inFlightSemaphore: DispatchSemaphore
    private var currentBufferIndex = 0

    // The current viewport size
    private var viewportSize = CGSize()
    // The grid of sample points
    lazy var gridPointsBuffer = MetalBuffer<Float2>(device: device,
                                                    array: makeGridPoints(),
                                                    index: Index.Buffer.gridPoints.rawValue, options: [])

    // Number of sample points on the grid <=> How many point are sampled per frame
    let numGridPoints: Int = 2_000 // Apple's Default 500

    // MARK: - Buffers
    // MARK: RGB buffer
    private lazy var rgbUniforms: RGBUniforms = {
        var uniforms = RGBUniforms()
        uniforms.radius = rgbRadius
        uniforms.viewToCamera.copy(from: viewToCamera)
        uniforms.viewRatio = Float(viewportSize.height / viewportSize.width)
        return uniforms
    }()
    private var rgbUniformsBuffers = [MetalBuffer<RGBUniforms>]()

    // MARK: Point Cloud buffer
    lazy var pointCloudUniforms: PointCloudUniforms = {
        return getNewUniforms()
    }()

    var pointCloudUniformsBuffers = [MetalBuffer<PointCloudUniforms>]()

    // Maximum number of points we store in the point cloud
    // 4096 * 128 // Apples's default was 500k
    public var maxPoints = 15_000_000 {
        didSet {
            pointCloudUniforms.maxPoints = Int32(maxPoints) // apply the change for the shader
        }
    }

    // Particle's size in pixels
    public var particleSize: Float = 32 {
        didSet {
            pointCloudUniforms.particleSize = particleSize // apply the change for the shader
        }
    } // Apple's Default 10

    public var rgbRadius: Float = 0.2 {
        didSet {
            // apply the change for the shader
            rgbUniforms.radius = rgbRadius
        }
    }
    // MARK: Particles buffer
    private(set) public var particlesBuffer: MetalBuffer<ParticleUniforms>?
    private var currentPointIndex = 0
    private var relaxedStencilState: MTLDepthStencilState?
    // MARK: - Sampling

    // Camera data
    private var sampleFrame: ARFrame { session.currentFrame! }
    lazy var cameraResolution = Float2(Float(sampleFrame.camera.imageResolution.width), Float(sampleFrame.camera.imageResolution.height))
    lazy var viewToCamera = sampleFrame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
    private lazy var lastCameraTransform = sampleFrame.camera.transform

    // MARK: - Public Interfaces
    public let session = ARSession()
    public var renderDestination: RenderDestinationProvider?
    public let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    public var bufferCreationFailed = false
    @Published public var currentPointCount: Int = 0
    // Used by the outside world to access the captured particles without creating too many memory problems
    @Published public var particleBufferWrapper: ParticleBufferWrapper?

    @Published public var running: Bool = false {
        didSet {
            switch running {
            case true:
                session.run(defaultARSessionConfiguration, options: [.resetSceneReconstruction, .removeExistingAnchors, .resetTracking])
            case false:
                session.pause()
            }
        }
    }

    // A.k.a. accumulate
    @Published public var capturing: Bool = false

    @Published public var flush: Bool = false {
        didSet {
            if flush == true {
                running = true
                particlesBuffer = .init(device: device, count: maxPoints, index: Index.Buffer.particleUniforms.rawValue,
                                     options: [MTLResourceOptions.storageModeShared])
                if let buffer = particlesBuffer {
                    particleBufferWrapper = ParticleBufferWrapper(buffer: buffer)
                }
                pointCloudUniforms = getNewUniforms()
                currentPointCount = 0
                currentPointIndex = 0
                flush = false
            }
        }
    }

    public func clearAll() {
        particlesBuffer = nil
        particleBufferWrapper = nil
        currentPointCount = 0
        currentPointIndex = 0
    }

    public var confidenceThreshold: ConfidenceThreshold = .medium {
        didSet {
            // apply the change for the shader
            pointCloudUniforms.confidenceThreshold = confidenceThreshold
        }
    }

    public var horizontalSamplingRate: SamplingRate = .regular {
        didSet {
            cameraRotationThreshold = Self.updateCameraRotationThreshold(with: horizontalSamplingRate)
        }
    }

    public var verticalSamplingRate: SamplingRate = .regular {
        didSet {
            cameraTranslationThreshold = Self.updateCameraTranslationThreshold(with: verticalSamplingRate)
        }
    }
    deinit {
        print("deinited")
        relaxedStencilState = nil
        currentPointCount = 0
        rgbUniformsBuffers = []
        pointCloudUniformsBuffers = []
        particleBufferWrapper = nil
        particlesBuffer = nil
    }

    // MARK: - Public

    /// Using an `MTLDevice`, process the RGBD live data sampled by the `ARSession` object and renders a point cloud at `renderDestination`.
    /// - Parameters:
    ///   - session: The input providing RGBD samples from the user capture.
    ///   - device: The Metal device used for processing information and generating a render (The phone GPU)
    ///   - renderDestination: Where the render is being draw for the user to see
    public init(renderDestination: RenderDestinationProvider? = nil, particleUniforms: [ParticleUniforms]? = nil) {
        print("---Rendering service inited")
        self.currentPointCount = 0
        self.renderDestination = renderDestination

        if MemoryLayout<Float2>.stride * maxPoints >= 234000000 {
            bufferCreationFailed = true
        }
        // Create the library of metal functions
        // swiftlint:disable:next force_try
        library = try! device.makeDefaultLibrary(bundle: Bundle.module)
        commandQueue = device.makeCommandQueue()!

        // initialize our buffers
        for _ in 0 ..< maxInFlightBuffers {
            rgbUniformsBuffers.append(.init(device: device, count: 1, index: 0))
            pointCloudUniformsBuffers.append(.init(device: device, count: 1,
                                                   index: Index.Buffer.pointCloudUniforms.rawValue))
        }
        particlesBuffer = .init(device: device, count: maxPoints, index: Index.Buffer.particleUniforms.rawValue,
                                options: [MTLResourceOptions.storageModeShared]) // not sure it need to be explicit
        if let particleUniforms {
            particlesBuffer?.assign(with: particleUniforms)
        }

        // rbg does not need to read/write depth
        let relaxedStateDescriptor = MTLDepthStencilDescriptor()
        relaxedStencilState = device.makeDepthStencilState(descriptor: relaxedStateDescriptor)!

        // setup depth test for point cloud
        let depthStateDescriptor = MTLDepthStencilDescriptor()
        depthStateDescriptor.depthCompareFunction = .lessEqual
        depthStateDescriptor.isDepthWriteEnabled = true
        depthStencilState = device.makeDepthStencilState(descriptor: depthStateDescriptor)!

        inFlightSemaphore = DispatchSemaphore(value: maxInFlightBuffers)
        // Starts
        particleBufferWrapper = ParticleBufferWrapper(buffer: particlesBuffer!)
        running = true
    }

    // MARK: - AK Kit Session

    var defaultARSessionConfiguration: ARConfiguration = {
        let configuration = ARWorldTrackingConfiguration()
        configuration.frameSemantics = .sceneDepth
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .mesh
        configuration.environmentTexturing = .automatic
        return configuration
    }()

    func getNewUniforms() -> PointCloudUniforms {
        var uniforms = PointCloudUniforms()
        uniforms.maxPoints = Int32(maxPoints)
        uniforms.confidenceThreshold = confidenceThreshold
        uniforms.particleSize = particleSize
        uniforms.cameraResolution = cameraResolution
        return uniforms
    }
}

// MARK: - drawRectResized
extension RenderingService {
    public func resizeDrawRect(to size: CGSize) {
        viewportSize = size
    }

    private func updateCapturedImageTextures(frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else {
            return
        }

        capturedImageTextureY = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = makeTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
    }

    private func updateDepthTextures(frame: ARFrame) -> Bool {
        guard let depthMap = frame.sceneDepth?.depthMap,
              let confidenceMap = frame.sceneDepth?.confidenceMap else {
            return false
        }

        depthTexture = makeTexture(fromPixelBuffer: depthMap, pixelFormat: .r32Float, planeIndex: 0)
        confidenceTexture = makeTexture(fromPixelBuffer: confidenceMap, pixelFormat: .r8Uint, planeIndex: 0)

        return true
    }

    private func update(frame: ARFrame) {
        // frame dependent info
        let camera = frame.camera
        let cameraIntrinsicsInversed = camera.intrinsics.inverse
        let viewMatrix = camera.viewMatrix(for: orientation)
        let viewMatrixInversed = viewMatrix.inverse
        let projectionMatrix = camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.001, zFar: 0)
        pointCloudUniforms.viewProjectionMatrix = projectionMatrix * viewMatrix
        pointCloudUniforms.localToWorld = viewMatrixInversed * rotateToARCamera
        pointCloudUniforms.cameraIntrinsicsInversed = cameraIntrinsicsInversed
    }
}

// MARK: - draw
extension RenderingService {
    public func draw() {
        guard let renderDestination = renderDestination,
              let currentFrame = session.currentFrame,
              let renderDescriptor = renderDestination.currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderDescriptor) else {
            return
        }

        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)
        commandBuffer.addCompletedHandler { [weak self] _ in
            if let self = self {
                self.inFlightSemaphore.signal()
            }
        }

        // update frame data
        update(frame: currentFrame)
        updateCapturedImageTextures(frame: currentFrame)

        // handle buffer rotating
        currentBufferIndex = (currentBufferIndex + 1) % maxInFlightBuffers
        pointCloudUniformsBuffers[currentBufferIndex][0] = pointCloudUniforms

        if shouldAccumulate(frame: currentFrame), updateDepthTextures(frame: currentFrame) {
            accumulatePoints(frame: currentFrame, commandBuffer: commandBuffer, renderEncoder: renderEncoder)
        }

        // check and render rgb camera image
        if rgbUniforms.radius > 0 {
            var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr]
            commandBuffer.addCompletedHandler { _ in
                retainingTextures.removeAll()
            }
            rgbUniformsBuffers[currentBufferIndex][0] = rgbUniforms

            renderEncoder.setDepthStencilState(relaxedStencilState)
            renderEncoder.setRenderPipelineState(rgbPipelineState)
            renderEncoder.setVertexBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentBuffer(rgbUniformsBuffers[currentBufferIndex])
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureY!),
                                             index: Index.Texture.yComponent.rawValue)
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr!),
                                             index: Index.Texture.cbcr.rawValue)
            renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        }

        // render particles
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setRenderPipelineState(particlePipelineState)
        renderEncoder.setVertexBuffer(pointCloudUniformsBuffers[currentBufferIndex])
        if let buffer = particlesBuffer {
            renderEncoder.setVertexBuffer(buffer)
        }
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: currentPointCount)
        renderEncoder.endEncoding()

        commandBuffer.present(renderDestination.currentDrawable!)
        commandBuffer.commit()
    }

    private func shouldAccumulate(frame: ARFrame) -> Bool {
        let cameraTransform = frame.camera.transform
        return capturing && (currentPointCount == 0
            || dot(cameraTransform.columns.2, lastCameraTransform.columns.2) <= cameraRotationThreshold
            || distance_squared(cameraTransform.columns.3, lastCameraTransform.columns.3) >= cameraTranslationThreshold)
    }

    private func accumulatePoints(frame: ARFrame, commandBuffer: MTLCommandBuffer, renderEncoder: MTLRenderCommandEncoder) {
        pointCloudUniforms.pointCloudCurrentIndex = Int32(currentPointIndex)

        var retainingTextures = [capturedImageTextureY, capturedImageTextureCbCr, depthTexture, confidenceTexture]
        commandBuffer.addCompletedHandler { _ in
            retainingTextures.removeAll()
        }

        renderEncoder.setDepthStencilState(relaxedStencilState)
        renderEncoder.setRenderPipelineState(unprojectPipelineState)
        renderEncoder.setVertexBuffer(pointCloudUniformsBuffers[currentBufferIndex])
        if let buffer = particlesBuffer {
            renderEncoder.setVertexBuffer(buffer)
        }
        renderEncoder.setVertexBuffer(gridPointsBuffer)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureY!),
                                       index: Index.Texture.yComponent.rawValue)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(capturedImageTextureCbCr!),
                                       index: Index.Texture.cbcr.rawValue)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(depthTexture!),
                                       index: Index.Texture.depth.rawValue)
        renderEncoder.setVertexTexture(CVMetalTextureGetTexture(confidenceTexture!),
                                       index: Index.Texture.confidence.rawValue)
        renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: gridPointsBuffer.count)

        currentPointIndex = (currentPointIndex + gridPointsBuffer.count) % maxPoints
        currentPointCount = min(currentPointCount + gridPointsBuffer.count, maxPoints)
        lastCameraTransform = frame.camera.transform
    }
}
