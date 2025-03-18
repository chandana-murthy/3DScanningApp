//
//  MeshScan+CoreDataClass.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 05.01.23.
//

import Foundation
import SwiftUI
import ModelIO
import CoreData

@objc(MeshScan)
public class MeshScan: NSManagedObject {
    @NSManaged public var name: String
    @NSManaged public var scanDescription: String
    @NSManaged public var dateCreated: Date
    @NSManaged public var locationString: String?
    @NSManaged public var locCoordinateString: String?
    @NSManaged public var usdzUrl: URL
    @NSManaged public var image: Data
}
