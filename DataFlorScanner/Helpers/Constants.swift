//
//  Constants.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 08.01.23.
//  Note: Changing these will break the app without further changes
//

import Foundation

class Constants {
    // MARK: - Strings
    static let USDZ_URL = "usdzUrl"
    static let LONG_DATE_FORMAT = "E, d MMM y"

    // MARK: - Navigation Strings
    static let POINTS_NAV_STRING = "PointsView"
    static let MESH_NAV_STRING = "MeshView"
    static let SAVED_POINTS_NAV_STRING = "PointsSavedView"

    // MARK: - Node Name
    static let pointCloudNodeName = "pointCloudRootRoot"
    static let measureNodeName = "Measure"
    static let lineNodeName = "Line"
    static let textNodeName = "Text"
    static let meshNodeName = "Meshnode"

    // MARK: - Dimensions
    static let SLIDER_MIN_WIDTH: CGFloat = 180
    static let SLIDER_MAX_WIDTH: CGFloat = 320
}
