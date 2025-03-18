//
//  PointsCaptureTabViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 05.04.23.
//

import PointCloudRendererService
import SceneKit
import ModelIO

final class PointsCaptureTabViewModel: ObservableObject {
    unowned var renderingService: RenderingService

    lazy var captureParametersModel: CaptureParametersModel = CaptureParametersModel(renderingService: renderingService)
    lazy var captureViewerModel: CaptureViewerModel = CaptureViewerModel(renderingService: renderingService)
    lazy var toggleStyle: CaptureToggleStyle = CaptureToggleStyle()
    var scene: SCNScene

    @Published var hasCaptureData: Bool?

    init(renderingService: RenderingService) {
        print("PointsCaptureTabViewModel: init")
        self.scene = SCNScene()
        self.renderingService = renderingService
        renderingService.$currentPointCount
            .map { $0 != 0 }
            .assign(to: &$hasCaptureData)
    }

    deinit {
        hasCaptureData = nil
        print("PointsCaptureTabViewModel: deinit")
    }

    var capturing: Bool { renderingService.capturing }

    func pauseCapture() {
        renderingService.capturing = false
    }

    func flushCapture() {
        renderingService.flush = true
    }

    func getCombinedScene(scene1: SCNScene, asset: MDLAsset?) -> SCNScene {
        let finalScene = scene1
        if let asset {
            let scene2 = SCNScene(mdlAsset: asset)
            for node in scene2.rootNode.childNodes {
                finalScene.rootNode.addChildNode(node)
            }
        }
        return finalScene
    }

    func getMeshSceneFromAsset(asset: MDLAsset?) -> SCNScene? {
        if let asset {
            return SCNScene(mdlAsset: asset)
        }
        return nil
    }

    func getPointsViewerModel(measurementNodes: [SCNNode]?, asset: MDLAsset?, orientation: Double?) -> PointsViewerViewModel {
        // Add mesurement nodes
        for node in measurementNodes ?? [] {
            node.renderingOrder = 4
            self.scene.rootNode.addChildNode(node)
        }
        return PointsViewerViewModel(
            renderingService: renderingService,
            scene: scene,
            meshScene: getMeshSceneFromAsset(asset: asset),
            asset: asset,
            orientation: orientation
        )
    }
}
