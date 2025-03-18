//
//  PointsViewerTabViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 10.01.23.
//

import SwiftUI
import Common
import PointCloudRendererService
import Combine
import SceneKit

final class PointsViewerTabViewModel: ObservableObject {
    public var cancellables = Set<AnyCancellable>()
    private var nodeOpacity: Float = 1
    private var minValue: Float?
    var customModelPath: URL?
    var exportService: ExportService? = ExportService()
    let scene: SCNScene

    var particleBuffer: ParticleBufferWrapper?
    var processorService: ProcessorService? = ProcessorService()
    lazy var cleanersModel = PointsViewerToolsViewModel(particleBuffer: particleBuffer, processorService: processorService)
    lazy var reconstructionModel = PointsViewerAdjustmentsViewModel(particleBuffer: particleBuffer, processorService: processorService)

    init(particleBuffer: ParticleBufferWrapper?, scene: SCNScene) {
        self.particleBuffer = particleBuffer
        self.scene = scene
    }

    deinit {
        exportService = nil
        particleBuffer = nil
        processorService = nil
        print("deiniting: PointsViewerTabViewModel")
    }

    func areMeasurementsAvailable() -> Bool {
        return self.scene.rootNode.childNodes.contains(where: {
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
    }

    func areMeasureSpheresAvailable() -> Bool {
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false
        })
        return nodes.count >= 2
    }

    func getOnlyMeasureSpheres() -> [SCNNode] {
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false
        })
        return nodes
    }
}

// MARK: - Adjustment functions
extension PointsViewerTabViewModel {
    func setPointNodeOpacity(opacity: Float) {
        let node = self.scene.rootNode.childNodes.first(where: {
            $0.name?.contains(Constants.pointCloudNodeName) ?? false
        })

        guard let geometry = node?.geometry else {
            return
        }

        for material in geometry.materials {
            material.transparencyMode = .rgbZero
            // point cloud
            material.transparent.intensity = CGFloat(1 - opacity)
        }
    }

    func arePointsShown() -> Bool {
        let node = self.scene.rootNode.childNodes.first(where: {
            $0.name?.contains(Constants.pointCloudNodeName) ?? false
        })
        return !(node?.isHidden ?? false)
    }

    func showPoints(show: Bool) {
        let node = self.scene.rootNode.childNodes.first(where: {
            $0.name?.contains(Constants.pointCloudNodeName) ?? false
        })
        if node?.isHidden != !show {
            node?.isHidden = !show
        }
    }

    func showMesh(show: Bool) {
        let transparency: CGFloat = show ? 0 : 1
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.meshNodeName) ?? false
        })
        for node in nodes {
            guard let geometry = node.geometry else {
                return
            }
            for material in geometry.materials {
                material.transparencyMode = .rgbZero
                material.isDoubleSided = true
                material.transparency = transparency
            }
        }
    }

    func changePointSize(size: Float) {
        guard let pointNode = self.scene.rootNode.childNodes.first(where: {
            $0.name?.contains(Constants.pointCloudNodeName) ?? false
        }) else {
            print("No elements found")
            return
        }
        pointNode.geometry?.elements.first?.pointSize = CGFloat(size)
    }

    func changeMeasurementPosition(position: Float) {
        let nodes = self.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
        for node in nodes {
            node.position.z += position
        }
    }

    func minimumValue() -> Float? {
        if minValue == nil {
            minValue = self.scene.rootNode.childNodes.filter({
                $0.name?.contains(Constants.measureNodeName) ?? false
            }).first?.position.z
        }
        return minValue
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
