//
//  Utilities.swift
//  DataFlor
//
//  Created by Chandana Murthy on 08.03.22.
//

import Foundation
import ARKit

@available(iOS 13.0, *)
extension ARPlaneAnchor.Classification {
    var description: String {
        switch self {
        case .wall:
            return "Wall"
        case .floor:
            return "Floor"
        case .ceiling:
            return "Ceiling"
        case .table:
            return "Table"
        case .seat:
            return "Seat"
        case .window:
            return "Window"
        case .door:
            return "Door"
        case .none(.unknown):
            return "Unknown"
        default:
            return ""
        }
    }
}
