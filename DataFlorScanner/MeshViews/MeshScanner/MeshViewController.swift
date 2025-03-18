//
//  MeshViewController.swift
//  DataFlor
//
//  Created by Chandana Murthy on 07.03.22.
//

import Foundation
import ARKit
import CoreLocation
import MetalKit

protocol MeshViewControllerDelegate: AnyObject {
    func updateMessages(message: String, errorMessage: String?)
    func didChangeSessionState(_ isPaused: Bool)
    func shouldShowUndo(_ showUndo: Bool)
    func assetUpdated(_ asset: AssetFile)
    func isMeshAvailable(_ isAvailable: Bool)
}

class MeshViewController: UIViewController {
    private var arSceneView: ARSCNView!
    private let colorizer = Colorizer()
    private var noOfTaps = 0
    private var startPoint: SCNVector3!
    private var endPoint: SCNVector3!
    private var isSessionActive = false
    weak var delegate: MeshViewControllerDelegate?
    private var measureNodes = [SCNNode]() {
        didSet {
            let enableUndo = measureNodes.count > 0
            delegate?.shouldShowUndo(enableUndo)
        }
    }
    private var textNodes = [SCNNode]()
    private var message: String = Strings.startARSession {
        didSet {
            delegate?.updateMessages(message: message, errorMessage: errorMessage)
        }
    }
    private var errorMessage: String? {
        didSet {
            delegate?.updateMessages(message: message, errorMessage: errorMessage)
        }
    }
    private var isPaused = false {
        didSet {
            delegate?.didChangeSessionState(isPaused)
        }
    }
    private var asset: AssetFile? {
        didSet {
            if let asset = asset {
                delegate?.assetUpdated(asset)
            }
        }
    }
    private var isMeshAvailable: Bool = false {
        didSet {
            if isMeshAvailable {
                delegate?.isMeshAvailable(true)
            }
        }
    }

    override func loadView() {
        let sceneView = ARSCNView(frame: .zero)
        self.view = sceneView
        self.arSceneView = sceneView
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupCoachingOverlay()
        arSceneView.delegate = self

        arSceneView.scene = SCNScene()
        arSceneView.scene.isPaused = false
        arSceneView.session.delegate = self

        configureGestureRecognition()
        setupPlaneDetection()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arSceneView.session.pause()
    }
}

extension MeshViewController: ARCoachingOverlayViewDelegate {
    // MARK: - Gesture helpers
    private func configureGestureRecognition() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnScene))
        self.arSceneView.addGestureRecognizer(gestureRecognizer)
    }

    // MARK: - Coaching overlay
    func setupCoachingOverlay() {
        let coachingOverlay = ARCoachingOverlayView(frame: arSceneView.frame)
        coachingOverlay.delegate = self
        coachingOverlay.session = self.arSceneView.session
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.goal = .tracking
        self.view.addSubview(coachingOverlay)
    }

    func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
        if isPaused, let config = arSceneView.session.configuration {
            arSceneView.session.run(config)
        }
        isPaused = false
    }

    func coachingOverlayViewWillActivate(_ coachingOverlayView: ARCoachingOverlayView) {
        isPaused = true
    }
}

// MARK: - setup
extension MeshViewController {
    private func setupPlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .mesh
        configuration.environmentTexturing = .automatic
        configuration.frameSemantics = .smoothedSceneDepth

        arSceneView.session.run(configuration)
        isSessionActive = true
        isPaused = false
    }

    func changePauseState(paused: Bool) {
        if paused {
            arSceneView.session.pause()
        } else {
            if let config = arSceneView.session.configuration {
                arSceneView.session.run(config)
            } else {
                setupPlaneDetection()
            }
        }
    }
}

// MARK: - Tap helpers
extension MeshViewController {
    @objc func didTapOnScene(gesture: UITapGestureRecognizer) {
        let touchPosition = gesture.location(in: arSceneView)
        guard
            let rayCastQuery = arSceneView.raycastQuery(from: touchPosition, allowing: .existingPlaneGeometry, alignment: .any),
            let castResult = arSceneView.session.raycast(rayCastQuery).first else {
            print("MeshViewController: error in tap gesture")
            return
        }
        print("tapped")
        noOfTaps += 1
        addMeasureNode(raycastResult: castResult)
        updateSceneNodes(raycastResult: castResult)
    }

    private func addMeasureNode(raycastResult: ARRaycastResult) {
        let node = MeasurementUtils.getMarker(rayCastResult: raycastResult)
        addChildToRootNode(node: node)
    }

    private func addChildToRootNode(node: SCNNode) {
        measureNodes.append(node)
        arSceneView.scene.rootNode.addChildNode(node)
    }

    private func updateSceneNodes(raycastResult: ARRaycastResult) {
        if noOfTaps == 2 {
            noOfTaps = 0
            endPoint = MeasurementUtils.getVectorFromWorldTransform(raycastResult.worldTransform)
            let line = MeasurementUtils.getLineBetween(startPoint, endPoint)
            let distanceText = MeasurementUtils.getDistanceTextNode(startPoint, endPoint)
            addChildToRootNode(node: line)
            addChildToRootNode(node: distanceText)
            textNodes.append(distanceText)
        } else {
            message = Strings.measureSecond
            startPoint =  MeasurementUtils.getVectorFromWorldTransform(raycastResult.worldTransform)
        }
    }

    func performOnUndo() {
        if measureNodes.last?.geometry as? SCNText != nil, measureNodes.count > 2 {
            measureNodes[measureNodes.count - 1].removeFromParentNode() // text
            measureNodes[measureNodes.count - 2].removeFromParentNode() // 2nd node
            measureNodes[measureNodes.count - 3].removeFromParentNode() // line
            measureNodes = measureNodes.dropLast(3)
            noOfTaps = 1
        } else if measureNodes.last != nil {
            measureNodes[measureNodes.count - 1].removeFromParentNode() // first marker node
            measureNodes.removeLast()
            noOfTaps = 0
        }
    }

    func clearAllMeasureNodes() {
        for node in measureNodes {
            node.removeFromParentNode()
        }
        measureNodes.removeAll()
    }

    func moveToViewMode() {
        isSessionActive = false
        isPaused = true
        guard let frame = arSceneView.session.currentFrame, let device = MTLCreateSystemDefaultDevice() else {
            print("Couldn't get the current ARFrame/device")
            return
        }
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(bufferAllocator: allocator)
        let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        for anchor in meshAnchors {
            let mesh = SCNGeometry.getMeshFromGeometry(anchor: anchor, allocator: allocator)
            asset.add(mesh)
        }

        let snapShot = arSceneView.snapshot()
        // Setting the path to export the file to
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let usdzPath = documentsPath.appendingPathComponent("scene-\(UUID().uuidString.prefix(8)).usdz")
        arSceneView.scene.write(to: usdzPath, options: nil, delegate: nil, progressHandler: nil)

        self.asset = AssetFile(path: documentsPath, asset: asset, format: ExportFormat.usdz, assetImage: snapShot.jpegData(compressionQuality: 1.0), usdzUrl: usdzPath)
    }
}

// MARK: - ARSCN Delegate: Renderer
extension MeshViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        let classification = meshAnchor.geometry.classificationOf(faceWithIndex: 0)

        let linesMaterial = SCNMaterial()
        linesMaterial.fillMode = .lines
        linesMaterial.isDoubleSided = true
        linesMaterial.diffuse.contents = colorizer.assignColor(to: meshAnchor.identifier, classification: classification)

        let fillMaterial = SCNMaterial()
        fillMaterial.fillMode = .fill
        fillMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.8)

        geometry.materials = [linesMaterial]
        let node = SCNNode()
        node.geometry = geometry
        return node

    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return
        }
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        let classification = meshAnchor.geometry.classificationOf(faceWithIndex: 0)

        let linesMaterial = SCNMaterial()
        linesMaterial.fillMode = .lines
        linesMaterial.isDoubleSided = true
        linesMaterial.diffuse.contents = colorizer.assignColor(to: meshAnchor.identifier, classification: classification)

        let fillMaterial = SCNMaterial()
        fillMaterial.fillMode = .fill
        fillMaterial.diffuse.contents = UIColor.black.withAlphaComponent(0.8)

        geometry.materials = [linesMaterial]
        node.geometry = geometry
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let camera = arSceneView.pointOfView {
            for node in textNodes {
                node.orientation = camera.orientation
            }
        }
    }
}

// MARK: - ARSessionDelegate
extension MeshViewController: ARSessionDelegate {
    // MARK: - Session helpers
    private func updateSessionInfo(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        message = MeasurementUtils.getSessionStateInfo(for: frame, trackingState: frame.camera.trackingState)
        // If anchors, available, update the property only once.
        if !frame.anchors.isEmpty && !frame.anchors.filter({$0 as? ARMeshAnchor != nil}).isEmpty && !isMeshAvailable {
            isMeshAvailable = true
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfo(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfo(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateSessionInfo(for: frame, trackingState: frame.camera.trackingState)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        guard let frame = session.currentFrame else { return }
        updateSessionInfo(for: frame, trackingState: camera.trackingState)
    }

    // MARK: Observers
    func sessionWasInterrupted(_ session: ARSession) {
        message = Strings.sessionInterrupted
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        message = Strings.sessionResumed
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        message = "Session failed: \(error.localizedDescription)"
        guard error is ARError else { return }

        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]

        // Remove optional error messages.
        errorMessage = messages.compactMap({ $0 }).joined(separator: ". ")
    }
}
