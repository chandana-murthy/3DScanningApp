//
//  SceneView.swift
//  DataFlor
//
//  Created by Chandana Murthy on 23.06.22.
//

import Foundation
import SwiftUI
import SceneKit
import RealityKit
import ARKit
// import Model3DView

struct SceneUIView: UIViewRepresentable {
    @Binding var offset: Float
    @Binding var message: String
    @Binding var clearMeasureNodes: Bool
    @Binding var makeOrtho: Bool
    @Binding var makePerspective: Bool
    @Binding var undoLast: Bool
    var scene: SCNScene
    var arSceneView = ARSCNView()

    func makeUIView(context: Context) -> ARSCNView {
        // Instantiate the SCNView and setup the scene
        arSceneView.scene = scene

        arSceneView.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: true)
        arSceneView.allowsCameraControl = true
        arSceneView.autoenablesDefaultLighting = true
        arSceneView.layer.isDoubleSided = true
        arSceneView.rendersContinuously = true
        arSceneView.session.delegate = context.coordinator
        arSceneView.delegate = context.coordinator
        context.coordinator.initialiseMeasureNodes()

        // Add gesture recognizer
        let recognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        arSceneView.addGestureRecognizer(recognizer)

        return arSceneView
    }

    func updateUIView(_ view: ARSCNView, context: Context) {
        if clearMeasureNodes {
            context.coordinator.clearAllMeasureNodes()
            DispatchQueue.main.async {
                self.clearMeasureNodes = false
            }
        }
        if makeOrtho {
            context.coordinator.updateProjection(toOrtho: true)
            DispatchQueue.main.async {
                self.makeOrtho = false
            }
        }
        if makePerspective {
            context.coordinator.updateProjection(toOrtho: false)
            DispatchQueue.main.async {
                self.makePerspective = false
            }
        }
        if undoLast {
            context.coordinator.undoLast()
            DispatchQueue.main.async {
                self.undoLast = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(arSceneView, offset: $offset, message: $message)
    }

    func getSnapShot() -> UIImage {
        arSceneView.snapshot()
    }

    class Coordinator: NSObject, ARSessionDelegate, ARSCNViewDelegate {
        @Binding var offset: Float
        @Binding var message: String

        private let arSceneView: ARSCNView
        private var startPoint: SCNVector3?
        private var endPoint: SCNVector3?
        private var textNodes = [SCNNode]()
        private var measureNodes = [SCNNode]()
        private var numberOfTaps = 0

        init(_ view: ARSCNView, offset: Binding<Float>, message: Binding<String>) {
            self.arSceneView = view
            self._message = message
            self._offset = offset
            super.init()
        }

        func initialiseMeasureNodes() {
            self.measureNodes = arSceneView.scene.rootNode.childNodes.filter({
                $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
            })
        }

        func clearAllMeasureNodes() {
            for node in measureNodes {
                node.removeFromParentNode()
            }
            numberOfTaps = 0
            measureNodes.removeAll()
        }

        func undoLast() {
            if measureNodes.isEmpty {
                refreshView()
                return
            }
            if measureNodes.count % 4 == 0 {
                measureNodes[measureNodes.count - 1].removeFromParentNode() // text
                measureNodes[measureNodes.count - 2].removeFromParentNode() // 2nd node
                measureNodes[measureNodes.count - 3].removeFromParentNode() // line
                self.measureNodes = measureNodes.dropLast(3)
                numberOfTaps = 1
            } else if measureNodes.last != nil {
                measureNodes[measureNodes.count - 1].removeFromParentNode() // first marker node
                self.measureNodes.removeLast()
                numberOfTaps = 0
                if measureNodes.isEmpty {
                    refreshView()
                }
            }
        }

        private func addMeasureNode(hitTestResult: SCNHitTestResult, color: UIColor) {
            let node = MeasurementUtils.getMarker(hitTestResult: hitTestResult, color: color)
            let measureCount = measureNodes.count / 2
            node.name = "Measure\(measureCount)" // \(nodeCount)
            addChildToRootNode(node: node)
        }

        private func addLineNode(node: SCNNode) {
            node.name = "Line\(measureNodes.count)"
            addChildToRootNode(node: node)
        }

        private func addTextNode(node: SCNNode) {
            node.name = "Text\(measureNodes.count)"
            textNodes.append(node)
            addChildToRootNode(node: node)
        }

        private func updateSceneNodes(hitTestResult: SCNHitTestResult) {
            let tappedPoint = hitTestResult.worldCoordinates
            if numberOfTaps == 1 {
                startPoint = tappedPoint
            } else if numberOfTaps == 2 {
                numberOfTaps = 0
                endPoint = tappedPoint
                if startPoint == nil {
                    startPoint = measureNodes.last?.worldPosition
                }
                guard let startPoint, let endPoint else {
                    return
                }
                let line = MeasurementUtils.getLineBetween(startPoint, endPoint)
                let distanceText = MeasurementUtils.getDistanceTextNode(startPoint, endPoint)
                addLineNode(node: line)
                addTextNode(node: distanceText)
            }
        }

        private func addChildToRootNode(node: SCNNode) {
            node.position.z += offset
            measureNodes.append(node)
            showMessageHack()
            arSceneView.scene.rootNode.addChildNode(node)
        }

        private func showMessageHack() {
            // This is a hack to refresh the view so that the measurement button appears/disappears
            if measureNodes.count == 1 {
                refreshView()
            }
        }

        private func refreshView() {
            DispatchQueue.main.async {
                self.message = "."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.message = ""
                }
            }
        }

        @objc func handleTap(_ gesture: UIGestureRecognizer) {
            // Raycasting doesn't work here because it doesn't have any existing plane geometry

            let touchPosition = gesture.location(in: arSceneView)
            let hitResults = arSceneView.hitTest(
                touchPosition,
                options: [SCNHitTestOption.categoryBitMask: NodeType.userInteraction.rawValue]
            )

            guard hitResults.count > 0 else {
                if message.isEmpty {
                    message = Strings.noPlaneFound
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.message = ""
                    }
                }
                print("SceneUIView: error in tap gesture")
                return
            }
            var finalResult = hitResults.first! // this is okay as I checked the count just before is one or more.
            for hit in hitResults {
                if let nodeName = hit.node.name, !nodeName.contains(Constants.pointCloudNodeName) {
                    finalResult = hit
                    break
                }
            }

            self.numberOfTaps += 1
            addMeasureNode(hitTestResult: finalResult, color: .yellow)
            updateSceneNodes(hitTestResult: finalResult)
        }

        private func updateOffsetOfLastMeasurement() {
            if offset != 0, measureNodes.count > 3 {
                measureNodes[measureNodes.count - 1].position.z += offset // text Node
                measureNodes[measureNodes.count - 2].position.z += offset // line Node
                measureNodes[measureNodes.count - 3].position.z += offset // 2nd measure node
                measureNodes[measureNodes.count - 4].position.z += offset // 1st measure node
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            if let camera = arSceneView.pointOfView {
                let allTextNodes = arSceneView.scene.rootNode.childNodes.filter({$0.name?.contains(Constants.textNodeName) ?? false})
                for node in allTextNodes {
                    node.orientation = camera.orientation
                }
            }
        }

        func updateProjection(toOrtho: Bool) {
            if toOrtho {
                arSceneView.pointOfView?.camera?.usesOrthographicProjection = true
                arSceneView.pointOfView?.camera?.zNear = 0.1
                arSceneView.pointOfView?.camera?.zFar = 50.0
                arSceneView.pointOfView?.camera?.orthographicScale = 3
            } else {
                // Reset to the default perspective projection
                arSceneView.pointOfView?.camera?.usesOrthographicProjection = false
            }
        }
    }
}
