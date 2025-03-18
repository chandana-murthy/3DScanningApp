//
//  Enums.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 14.12.22.
//

import Foundation

enum NodeIdentifier: String {
    case camera = "com.dataFlorScanner.nodes.camera"
    case pointCloudRoot = "com.dataFlorScanner.nodes.pointCloudRootRoot"
}

enum CoachingOverlayStatus {
    case activated, deactivated
}

enum AlertType {
    case information
    case error(message: String)
}

enum XError: Error {
    case savingFailed
    case noScanDone
    case alreadySavingFile
}

enum ExportFormat: String {
    case obj = "OBJ" // large file size, but well supported
    case stl = "STL" // un-textured file used in 3D printing
    case usdz = "USDZ" // well supported on iOS device
    case ply = "PLY" // point clouds
//    case fbx = "FBX"
//    case glb = "GLB"
//    case gltf = "GLTF" // share in AR for android devices

    static let allValues = [obj, stl, usdz, ply] // fbx, glb, gltf
}

enum PointsExportFormat: String {
    case ascii = "Ascii"
    case littleEndian = "Binary Little Endian"
    case bigEndian = "Binary Big Endian"
}

enum ScanType: String {
    case pointsScan = "Point Cloud"
    case meshScan = "Mesh"
}

enum Language: String {
    case english = "en"
    case german = "de"
}
