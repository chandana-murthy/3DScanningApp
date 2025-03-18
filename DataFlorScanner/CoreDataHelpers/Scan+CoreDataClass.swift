//
//  Scan+CoreDataClass.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 17.12.22.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(Scan)
public class Scan: NSManagedObject {
    @NSManaged public var colors: Data
    @NSManaged public var dateCreated: Date?
    @NSManaged public var image: Data
    @NSManaged public var locationString: String?
    @NSManaged public var locCoordinateString: String?
    @NSManaged public var meshUrl: URL?
    @NSManaged public var name: String
    @NSManaged public var orientation: NSNumber?
    @NSManaged public var plyData: Data?
    @NSManaged public var pointCount: Int
    @NSManaged public var points: Data
    @NSManaged public var pointConfidence: NSNumber?
    @NSManaged public var scanDescription: String
    @NSManaged public var sceneData: Data
    @NSManaged public var cameraOrientation: String?

    public func didFinishScan(pointCloud: PointCloud) {
        self.pointCount = pointCloud.points.count
        self.points = pointCloud.pointsData()
        self.colors = pointCloud.colorsData()
    }

    public var pointCloud: PointCloud {
        return PointCloud(pointCount: self.pointCount, pointsData: self.points, colorsData: self.colors)
    }
}
