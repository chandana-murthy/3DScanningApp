//
//  SavedPointsViewerViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 08.03.23.
//

import SceneKit
import Common

final class SavedPointsViewerViewModel: ObservableObject {
//    @Published var object: Object3D
    let tabViewModel: PointsViewerTabViewModel
    var scene: SCNScene
    var initialMeasureCount: Int = 0
    private var scan: Scan

    init(scan: Scan, scene: SCNScene) {
        self.scan = scan
        self.scene = scene
        self.tabViewModel = PointsViewerTabViewModel(particleBuffer: nil, scene: scene)

//        self.object = Object3D(
//            vertices: scan.pointCloud.points,
//            vertexConfidence: Array(repeating: scan.pointConfidence as? UInt ?? 0, count: scan.pointCount),
//            vertexColors: scan.pointCloud.colors
//        )
        setInitialPointView()
        setInitialMeshConfig()
        saveInitialMeasureCount()
    }

    func sceneNodeAvailable() -> Bool {
        return getPointCloudNode() != nil
    }

    private func setInitialPointView() {
        let node = getPointCloudNode()
        node?.isHidden = false
        for ele in node?.geometry?.elements ?? [] {
            ele.pointSize = 10
            ele.minimumPointScreenSpaceRadius = 1.0
            ele.maximumPointScreenSpaceRadius = 8
        }
        for mat in node?.geometry?.materials ?? [] {
            mat.transparent.intensity = 0
        }
    }

    private func setInitialMeshConfig() {
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.meshNodeName) ?? false
        })
        for node in nodes {
            node.renderingOrder = 5
            guard let geometry = node.geometry else {
                return
            }
            for material in geometry.materials {
                material.transparencyMode = .rgbZero
                material.isDoubleSided = true
                material.transparency = 1
            }
        }
    }

    /// Initial measurements in this view are saved so that when new ones are added later, we can show user an alert before exiting the view
    private func saveInitialMeasureCount() {
        initialMeasureCount = getMeasureCount()
    }

    func getMeasureCount() -> Int {
        self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false
        }).count
    }

    private func getPointCloudNode() -> SCNNode? {
        return self.scene.rootNode.childNodes.first(where: {
            $0.name?.contains(Constants.pointCloudNodeName) ?? false
        })
    }

    func areMeasurementsAvailable() -> Bool {
        !self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false
        }).isEmpty
    }

    func getDataOfScene(offset: Float) -> Data {
        changeMeasurementPosition(position: 0 - offset)
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: scene.rootNode, requiringSecureCoding: false)
            return data
        } catch let error {
            print(error.localizedDescription)
            return scan.sceneData
        }
    }

    /// Reset the measurement positions to 0 
    func changeMeasurementPosition(position: Float) {
        if position == 0 {
            return
        }
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
        for node in nodes {
            node.position.z += position
        }
    }

    func deleteAllMeasureNodes() {
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
        for node in nodes {
            node.removeFromParentNode()
        }
    }

    func newMeasurementsAdded() -> Bool {
        var currentCount = getMeasureCount()
        if currentCount % 2 != 0 { // there are an odd number of measurements, remove last
            self.scene.rootNode.childNodes.last?.removeFromParentNode()
            currentCount -= 1
        }
        return initialMeasureCount != currentCount
    }
}
