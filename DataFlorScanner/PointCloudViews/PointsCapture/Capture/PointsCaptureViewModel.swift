//
//  PointsCaptureViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 03.04.23.
//

import SwiftUI
import Common
import PointCloudRendererService

final class PointsCaptureViewModel: ObservableObject {
    unowned var renderingService: RenderingService

    let metricsModel: MetricsModel
    let captureControlModel: PointsCaptureTabViewModel
    let captureRenderingModel: CaptureRenderingModel

    init(renderingService: RenderingService) {
        print("PointsCaptureViewModel: INIT")
        self.renderingService = renderingService
        captureControlModel = PointsCaptureTabViewModel(renderingService: renderingService)
        captureRenderingModel = CaptureRenderingModel(renderingService: renderingService)
        metricsModel = MetricsModel()

        renderingService.$currentPointCount.assign(to: &metricsModel.$currentPointCount)
        renderingService.$capturing.assign(to: &metricsModel.$activity)
    }

    var bufferCreationFailed: Bool {
        get {
            renderingService.bufferCreationFailed
        }
        set {
            renderingService.bufferCreationFailed = newValue
        }
    }

    deinit {
//        renderingService = nil
        print("PointsCaptureViewModel: DEINIT")
    }

    func pauseCapture() {
        renderingService.capturing = false
    }
}
