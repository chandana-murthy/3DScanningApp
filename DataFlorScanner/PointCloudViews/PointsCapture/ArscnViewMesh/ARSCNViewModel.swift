//
//  ARSCNViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 26.01.23.
//

import ARKit
import UIKit
import MetalKit
import ModelIO

/// This is used in correspondence with the pointsViewer. The mesh is shown on top of the points to enable rayCasting and measurements.
class ARSCNViewModel: NSObject, ObservableObject {
    @Published var message: String? = Strings.startARSession
    @Published var measureNodes: [SCNNode]? = [SCNNode]()
    @Published var isMeshAvailable = false
    var cameraOrientation: Float3?

    // MARK: - Private
    private var colorizer: Colorizer? = Colorizer()
    private var arSceneView: ARSCNView?
    private var textNodes = [SCNNode]()
    private var noOfTaps = 0
    private var startPoint: SCNVector3!
    private var endPoint: SCNVector3!
    private var isSessionActive: Bool = true
    private var config: ARConfiguration?
    var undoLast: Bool = false {
        didSet {
            if undoLast {
                performOnUndo()
            }
        }
    }
    var deleteAllMarkers: Bool = false {
        didSet {
            if deleteAllMarkers {
                clearAllMeasureNodes()
            }
        }
    }

    override init() {
        print("ARSCNVIewModel init")
    }

    deinit {
        print("ARSCNVIewModel deinit")
    }

    func clearAll() {
        stopArSession()
        textNodes.removeAll()
        measureNodes = nil
        config = nil
        colorizer = nil
        cameraOrientation = nil
    }

    func setARView(_ arscnView: ARSCNView, session: ARSession) {
        arscnView.session = session
        arscnView.delegate = self
        arscnView.scene = SCNScene()
        isSessionActive = true

        // note: This is set as clear to give the points background more priority. nil does not work.
        arscnView.scene.background.contents = UIColor.clear
        self.arSceneView = arscnView

        configureGestureRecognition()
    }
}

// MARK: - Gesture helpers
extension ARSCNViewModel {
    private func configureGestureRecognition() {
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnARView))
        self.arSceneView?.addGestureRecognizer(gestureRecognizer)
    }

    @objc func didTapOnARView(gesture: UITapGestureRecognizer) {
        guard let arScnView = arSceneView else {
            return
        }
        let touchPosition = gesture.location(in: arScnView)

        if let rayCastQuery = arScnView.raycastQuery(from: touchPosition, allowing: .estimatedPlane, alignment: .any),
           let result = arScnView.session.raycast(rayCastQuery).first {
            noOfTaps += 1
            addMeasureNode(raycastResult: result)
            updateSceneNodes(raycastResult: result)
        } else if let hitPoint = arScnView.hitTest(touchPosition, options: [:]).first {
            noOfTaps += 1
            addMeasureNode(hitTestResult: hitPoint)
            updateSceneNodes(hitTestResult: hitPoint)
        } else {
            message = Strings.noPlaneFound
            print("error in tap gesture: ARSCNViewModel")
        }
    }

    private func addChildToRootNode(node: SCNNode) {
        measureNodes?.append(node)
        arSceneView?.scene.rootNode.addChildNode(node)
    }

    private func addMeasureNode(hitTestResult: SCNHitTestResult) {
        let node = MeasurementUtils.getMarker(hitTestResult: hitTestResult, color: .yellow)
        let measureCount = (measureNodes?.count ?? 0)/2
//        let nodeCount = (measureNodes?.count ?? 0) % 2 == 0 ? 1 : 2
        node.name = "Measure\(measureCount)" // \(nodeCount)
        addChildToRootNode(node: node)
    }

    private func updateSceneNodes(hitTestResult: SCNHitTestResult) {
        let tappedPoint = hitTestResult.worldCoordinates
        if noOfTaps == 1 {
            startPoint = tappedPoint
        } else if noOfTaps == 2 {
            noOfTaps = 0
            endPoint = tappedPoint
            let line = MeasurementUtils.getLineBetween(startPoint, endPoint)
            let distanceText = MeasurementUtils.getDistanceTextNode(startPoint, endPoint)
            addLineNode(node: line)
            addTextNode(node: distanceText)
            textNodes.append(distanceText)
        }
    }

    private func addMeasureNode(raycastResult: ARRaycastResult) {
        let node = MeasurementUtils.getMarker(rayCastResult: raycastResult, color: .yellow)
        let measureCount = (measureNodes?.count ?? 0)/2
//        let nodeCount = (measureNodes?.count ?? 0) % 2 == 0 ? 1 : 2
        node.name = "Measure\(measureCount)" // \(nodeCount)
        addChildToRootNode(node: node)
    }

    private func updateSceneNodes(raycastResult: ARRaycastResult) {
        if noOfTaps == 2 {
            noOfTaps = 0
            endPoint = MeasurementUtils.getVectorFromWorldTransform(raycastResult.worldTransform)
            let line = MeasurementUtils.getLineBetween(startPoint, endPoint)
            let distanceText = MeasurementUtils.getDistanceTextNode(startPoint, endPoint)
            distanceText.light?.doubleSided = true
            addLineNode(node: line)
            addTextNode(node: distanceText)
            textNodes.append(distanceText)
        } else {
            message = Strings.measureSecond
            startPoint =  MeasurementUtils.getVectorFromWorldTransform(raycastResult.worldTransform)
        }
    }

    private func addLineNode(node: SCNNode) {
        node.name = "Line\(measureNodes?.count ?? 0)"
        addChildToRootNode(node: node)
    }

    private func addTextNode(node: SCNNode) {
        node.name = "Text\(measureNodes?.count ?? 0)"
        addChildToRootNode(node: node)
    }

    func performOnUndo() {
        guard let measureNodes else {
            return
        }
        if measureNodes.last?.geometry as? SCNText != nil, measureNodes.count > 2 {
            measureNodes[measureNodes.count - 1].removeFromParentNode() // text
            measureNodes[measureNodes.count - 2].removeFromParentNode() // 2nd node
            measureNodes[measureNodes.count - 3].removeFromParentNode() // line
            self.measureNodes = measureNodes.dropLast(3)
            noOfTaps = 1
        } else if measureNodes.last != nil {
            measureNodes[measureNodes.count - 1].removeFromParentNode() // first marker node
            self.measureNodes?.removeLast()
            noOfTaps = 0
        }
        DispatchQueue.main.async { [weak self] in
            self?.undoLast = false
        }
    }

    func clearAllMeasureNodes() {
        guard let measureNodes else {
            return
        }
        for node in measureNodes {
            node.removeFromParentNode()
        }
        self.measureNodes?.removeAll()
        self.noOfTaps = 0
        DispatchQueue.main.async { [weak self] in
            self?.deleteAllMarkers = false
        }
    }
}

// MARK: - Session manipulation helpers
extension ARSCNViewModel {
    private func setupPlaneDetection() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .mesh
        configuration.environmentTexturing = .automatic
        configuration.frameSemantics = .smoothedSceneDepth

        arSceneView?.session.run(configuration)
    }

    private func stopArSession() {
        arSceneView?.session.pause()
        arSceneView?.removeFromSuperview()
        arSceneView = nil
        isSessionActive = false
    }

    func getAsset() -> MDLAsset? {
        guard let frame = arSceneView?.session.currentFrame, let device = MTLCreateSystemDefaultDevice() else {
            print("Couldn't get the current ARFrame/device")
            return nil
        }
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(bufferAllocator: allocator)
        let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        for anchor in meshAnchors {
            let mesh = SCNGeometry.getMeshFromGeometry(anchor: anchor, allocator: allocator)
            asset.add(mesh)
        }
        return asset
    }

    func pauseSession() {
        if isSessionActive {
            self.config = arSceneView?.session.configuration
            isSessionActive = false
        }
    }

    func stopSession() {
        isSessionActive = false
        arSceneView?.session.pause()
    }

    func resumeSession() {
        guard !isSessionActive else {
            return
        }
        if let config = self.config {
            arSceneView?.session.run(config, options: [.removeExistingAnchors, .resetSceneReconstruction])
            self.config = nil
        } else {
            setupPlaneDetection()
        }
        isSessionActive = true
    }

    func areMeshAnchorsAvailable() -> Bool {
        guard let frame = arSceneView?.session.currentFrame else {
            return false
        }
        let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        return !meshAnchors.isEmpty
    }

    func resetMesh() {
        DispatchQueue.main.async { [weak self] in
            self?.isMeshAvailable = false
        }
        if let config = arSceneView?.session.configuration {
            arSceneView?.session.run(config, options: [.resetTracking, .removeExistingAnchors, .resetSceneReconstruction])
            isSessionActive = true
        } else {
            setupPlaneDetection()
        }
    }

    func toggleShowHideMeshButton(show: Bool) {
        if !show {
            arSceneView?.debugOptions.remove(.showWireframe)
        } else {
            arSceneView?.debugOptions.insert(.showWireframe)
        }
    }
}

extension ARSCNViewModel: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        if areMeshAnchorsAvailable() != isMeshAvailable { // Only send an update when the value changes
            DispatchQueue.main.async { [weak self] in
                self?.isMeshAvailable = self?.areMeshAnchorsAvailable() ?? false
            }
            if cameraOrientation == nil, let orientation = arSceneView?.session.currentFrame?.camera.eulerAngles {
                DispatchQueue.main.async { [weak self] in
                    self?.cameraOrientation = orientation
                }
            }
        }
        guard let meshAnchor = anchor as? ARMeshAnchor else {
            return nil
        }
        let geometry = SCNGeometry(arGeometry: meshAnchor.geometry)
        let classification = meshAnchor.geometry.classificationOf(faceWithIndex: 0)

        let linesMaterial = SCNMaterial()
        linesMaterial.fillMode = .lines
        linesMaterial.isDoubleSided = true
        linesMaterial.diffuse.contents = colorizer?.assignColor(to: meshAnchor.identifier, classification: classification, color: .red)

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
        linesMaterial.diffuse.contents = colorizer?.assignColor(to: meshAnchor.identifier, classification: classification, color: .red)

        geometry.materials = [linesMaterial]
        node.geometry = geometry
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let camera = arSceneView?.pointOfView {
            for node in textNodes {
                node.orientation = camera.orientation
            }
        }
    }
}

extension ARSCNViewModel: ARSessionDelegate {
    private func updateSessionInfo(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        message = MeasurementUtils.getSessionStateInfo(for: frame, trackingState: frame.camera.trackingState)
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
        isSessionActive = false
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        message = Strings.sessionResumed
        isSessionActive = true
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
        message = messages.compactMap({ $0 }).joined(separator: ". ")
        isSessionActive = false
    }
}
