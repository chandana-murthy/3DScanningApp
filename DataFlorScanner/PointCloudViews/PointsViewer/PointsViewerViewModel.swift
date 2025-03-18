//
//  PointsViewerViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 19.01.23.
//  Based on PointCloudKit
//

import Foundation
import SceneKit
import PointCloudRendererService
import Combine
import Common
import ModelIO

final class PointsViewerViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    var meshNodes = [SCNNode]()
    var pointCloud: PointCloud?
    private let fileManager = FileManager.default
    private var helper: PointCloudKitHelper? = PointCloudKitHelper()
    private var meshScene: SCNScene?
    private var customModelPath: URL?
    private let date = Date().formatted(date: .numeric, time: .omitted)
    private var asset: MDLAsset?

    // Injected
    unowned var renderingService: RenderingService
    lazy var pointsViewerTabModel = PointsViewerTabViewModel(particleBuffer: renderingService.particleBufferWrapper, scene: scene)

    @Published var object = Object3D()
    @Published var objUrl: URL?
    @Published var plyData: Data?

    let scene: SCNScene
    let cameraNode = SCNNode()
    var pointCloudNode: SCNNode?
    let orientation: Double?

    deinit {
        helper = nil
        asset = nil
        meshScene = nil
        customModelPath = nil
        objUrl = nil
        plyData = nil
        print("PointsViewerViewModel deinit")
    }

    init(renderingService: RenderingService, scene: SCNScene, meshScene: SCNScene? = nil, asset: MDLAsset?, orientation: Double?) {
        self.renderingService = renderingService
        self.asset = asset
        self.orientation = orientation
        self.scene = scene
        self.meshScene = meshScene

        $object.sink { [weak self] object in
            guard let self = self else { return }

            self.updateScene(using: renderingService.particleBufferWrapper,
                             particleCount: object.vertices.count)
        }
        .store(in: &cancellables)

        // Initialize Scene
        cameraNode.camera = SCNCamera()
        cameraNode.name = NodeIdentifier.camera.rawValue
        cameraNode.position.z += 5
        scene.rootNode.addChildNode(cameraNode)

        let ambientLightNode = SCNNode()
        let light = SCNLight()
        light.type = .ambient
        ambientLightNode.light = light
        scene.rootNode.addChildNode(ambientLightNode)

        scene.background.contents = UIColor.clear
    }

    func generateFirstObjectFromParticleBuffer() {
        guard let bufferWrapper = renderingService.particleBufferWrapper else {
            return
        }
        Self.convert(bufferWrapper,
                     particleCount: renderingService.currentPointCount)
        .receive(on: DispatchQueue.main)
        .sink(receiveValue: { [weak self] object in
            self?.object = object
            self?.objUrl = self?.getObjFileUrl()
            self?.plyData = self?.getPlyData()
        })
        .store(in: &cancellables)
    }

    private func updateScene(using particleBuffer: ParticleBufferWrapper?, particleCount: Int, pointSize: CGFloat = 10) {
        guard let bufferWrapper = particleBuffer else {
            return
        }
        helper?.pointCloudNode(from: bufferWrapper, particleCount: particleCount, pointSize: pointSize)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pointCloudRootNode in
                guard let self = self else { return }
                // update SOURCE pointCount
                self.renderingService.currentPointCount = particleCount

                self.pointCloudNode?.removeFromParentNode()
                self.pointCloudNode = pointCloudRootNode

                // Add new pointCloudNode
                self.scene.rootNode.insertChildNode(pointCloudRootNode, at: 0)
                // Adjust camera
                self.cameraNode.look(at: pointCloudRootNode.position)

                self.addMeshAndMeasureNodes()

            }
            .store(in: &cancellables)
        plyData = getPlyData()
    }

    private func addMeshAndMeasureNodes() {
        // Add mesh nodes
        if let meshScene = self.meshScene, !meshScene.rootNode.childNodes.isEmpty {
            var count = 1
            for node in meshScene.rootNode.childNodes {
                node.name = Constants.meshNodeName + String(count)
                node.categoryBitMask = NodeType.userInteraction.rawValue
                node.opacity = 0.1
                node.renderingOrder = 5
                if let geometry = node.geometry {
                    for material in geometry.materials {
                        material.transparencyMode = .rgbZero
                        material.isDoubleSided = true
                        material.transparency = 1
                    }
                }
                self.scene.rootNode.addChildNode(node)
                count += 1
            }
        }
    }

    private func getParticlesAndColors() -> ([Float3], [Float3]) {
        guard let wrapper = renderingService.particleBufferWrapper else {
            return ([], [])
        }
        let pointCount = renderingService.currentPointCount
        let particles = wrapper.buffer.getMemoryRepresentationCopy(for: pointCount)
        let points = particles.map(\.position)
        let colors = particles.map(\.color)
        return (points, colors)
    }

    func getPointCloud() -> PointCloud {
        if let pointCloud {
            return pointCloud
        }
        var cloud = PointCloud()
        let (points, colors) = getParticlesAndColors()
        cloud.points = points
        cloud.colors = colors
        self.pointCloud = cloud
        return cloud
    }

    // MARK: - PointCloudKit -> PointCloudKit
    private class func convert(_ particleBuffer: ParticleBufferWrapper, particleCount: Int) -> Future<Object3D, Never> {
        Future { promise in
            DispatchQueue.global(qos: .userInitiated).async {
                let particles = particleBuffer.buffer.getMemoryRepresentationCopy(for: particleCount)
                let object = Object3D(vertices: particles.map(\.position),
                                      vertexConfidence: particles.map({ particle in UInt(particle.confidence) }),
                                      vertexColors: particles.map(\.color))
                promise(.success(object))
            }
        }
    }

    func areMeasurementsAvailable() -> Bool {
        return self.scene.rootNode.childNodes.contains(where: {
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
    }

    func deleteAllMeasureNodes() {
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
        for node in nodes {
            node.removeFromParentNode()
        }
    }
}

// MARK: - Export
extension PointsViewerViewModel {
    func getObjFileUrl() -> URL? {
        if let url = objUrl {
            return url
        }
        guard let asset = asset else {
            return nil
        }
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let docName = "model_\(UUID().uuidString.prefix(5))_\(date).obj"
        customModelPath = documentsPath.appendingPathComponent(docName)
        guard let path = customModelPath else {
            return nil
        }
        do {
            try asset.export(to: path)
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            return fileURLs.first(where: {$0.absoluteString.contains(docName)})
        } catch let error {
            print("PointsViewerViewModel: \(error.localizedDescription)")
            return nil
        }
    }

    func getPlyData() -> Data? {
        var comment: [String]?
        if let orientation {
            comment = ["initialOrientation: \(orientation)"]
        }
        return PolygonFileFormat.generateAsciiData(using: object, comments: comment)
    }

    func pointConfidence() -> UInt {
        object.vertexConfidence.first ?? 0
    }
}
