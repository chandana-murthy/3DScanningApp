//
//  UniformTypeIdentifier.swift
//  DataFlorScanner
//  Based on PointCloudKit
//
//  Created by Chandana Murthy on 11.01.23.
//

import Foundation
import UniformTypeIdentifiers

extension UTType {
    public static let polygon = UTType.init(filenameExtension: "ply")!
    public static let obj = UTType.init(filenameExtension: "obj")!
}
