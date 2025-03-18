//
//  HelperStructs.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 04.04.23.
//

import Foundation
import ModelIO
import SceneKit

struct NodeType: OptionSet {
  let rawValue: Int

  static let `default` = NodeType(rawValue: 1)
  static let userInteraction = NodeType(rawValue: 4)
}

class SaveData: ObservableObject {
    var imageData: Data?
    var locationString: String?
    var coordinateString: String?
    var pointCloud: PointCloud
    var confidence: UInt
    var pointCount: Int
    var scene: SCNScene
    var objURL: URL?
    var plyData: Data?
    var orientation: Double?
    var cameraOrientation: Float3?

    init(imageData: Data? = nil, locationString: String? = nil, coordinateString: String? = nil, pointCloud: PointCloud, pointCount: Int, scene: SCNScene, objURL: URL? = nil, plyData: Data? = nil, orientation: Double? = nil, cameraOrientation: Float3? = nil, confidence: UInt = 0) {
        self.imageData = imageData
        self.locationString = locationString
        self.coordinateString = coordinateString
        self.pointCloud = pointCloud
        self.pointCount = pointCount
        self.scene = scene
        self.objURL = objURL
        self.plyData = plyData
        self.orientation = orientation
        self.cameraOrientation = cameraOrientation
        self.confidence = confidence
    }
}

class ARScnViewStates: ObservableObject {
    @Published var undoLast: Bool? = false
    @Published var deleteAllMarkers: Bool? = false
    @Published var resetMesh: Bool? = false

    func clearAll() {
        deleteAllMarkers = nil
        resetMesh = nil
        undoLast = nil
    }
}

class MeshViewStates: ObservableObject {
    @Published var cameraButtonActive: Bool = true
    @Published var goToViewer: Bool = false
    @Published var undoLast: Bool = false
    @Published var deleteAllMarkers: Bool = false
    @Published var cameraStateChanged: Bool = false
    @Published var isMeshAvailable: Bool = false
}

// This is a model. Keep UIelements out of it
class AssetFile: ObservableObject {
    @Published var path: URL?
    @Published var asset: MDLAsset
    @Published var format: ExportFormat
    @Published var assetImage: Data?
    @Published var usdzUrl: URL?

    init(path: URL? = nil, asset: MDLAsset = MDLAsset(), format: ExportFormat = .obj, assetImage: Data? = nil, usdzUrl: URL? = nil) {
        self.path = path
        self.asset = asset
        self.format = format
        self.assetImage = assetImage
        self.usdzUrl = usdzUrl
    }
}
