//
//  PointsViewerAdjustmentsViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 10.01.23.
//  Based on PointCloudKit
//

import SwiftUI
import PointCloudRendererService
import Common
import Combine

class PointsViewerAdjustmentsViewModel {
    public var cancellables = Set<AnyCancellable>()
    let particleBuffer: ParticleBufferWrapper?
    let processorService: ProcessorService?

    init(particleBuffer: ParticleBufferWrapper?, processorService: ProcessorService?) {
        self.particleBuffer = particleBuffer
        self.processorService = processorService
    }

    func normalsEstimation(_ object: Object3D, parameters: ProcessorParameters.NormalsEstimation) -> Future<Object3D, ProcessorServiceError>? {
       return processorService?.normalsEstimation(of: object, with: parameters)
    }

    func poissonSurfaceReconstruction(_ object: Object3D, parameters: ProcessorParameters.SurfaceReconstruction.Poisson) -> Future<Object3D, ProcessorServiceError>? {
        return processorService?.poissonSurfaceReconstruction(of: object, with: parameters)
    }
}
