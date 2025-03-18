//
//  PointCloudScanView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 19.12.22.
//

import SwiftUI
import ARKit
import PointCloudRendererService
import Metal.MTLDevice

final class RendererModel: ObservableObject {
    @Published var renderingService: RenderingService
    private var device: MTLDevice?

    init() {
        self.renderingService = RenderingService()
    }

    deinit {
        self.renderingService.session.pause()
        self.renderingService.clearAll()
        self.device = nil
        print("Deinit of renderModel")
    }
}

struct PointCloudScanView: View {
    @StateObject private var model: RendererModel = RendererModel()

    var body: some View {
        PointsCaptureView(model: PointsCaptureViewModel(
            renderingService: model.renderingService
        ))
    }
}
