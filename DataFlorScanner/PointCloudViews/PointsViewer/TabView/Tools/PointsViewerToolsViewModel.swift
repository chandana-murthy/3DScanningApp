//
//  PointsViewerToolsViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 10.01.23.
//  Based on PointCloudKit
//

import SwiftUI
import PointCloudRendererService
import Common
import Combine

class PointsViewerToolsViewModel {
    public var cancellables = Set<AnyCancellable>()
    var particleBuffer: ParticleBufferWrapper?
    var processorService: ProcessorService?

    init(particleBuffer: ParticleBufferWrapper?, processorService: ProcessorService?) {
        self.particleBuffer = particleBuffer
        self.processorService = processorService
    }

    func voxelDownSampling(_ object: Object3D, parameters: ProcessorParameters.VoxelDownSampling) -> Future<Object3D, ProcessorServiceError>? {
        return processorService?.voxelDownsampling(of: object, with: parameters)
    }

    func statisticalOutlierRemoval(_ object: Object3D, parameters: ProcessorParameters.OutlierRemoval.Statistical) -> Future<Object3D, ProcessorServiceError>? {
        return processorService?.statisticalOutlierRemoval(of: object, with: parameters)
    }

    func radiusOutlierRemoval(_ object: Object3D, parameters: ProcessorParameters.OutlierRemoval.Radius) -> Future<Object3D, ProcessorServiceError>? {
        return processorService?.radiusOutlierRemoval(of: object, with: parameters)
    }

    func redraw(object: Object3D) {
        object.particles()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] particles in
                self?.particleBuffer?.buffer.assign(with: particles)
            })
            .store(in: &cancellables)
    }
}
