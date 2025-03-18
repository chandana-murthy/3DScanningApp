//
//  Colorizer.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 28.03.22.
//

import UIKit
import ARKit

class Colorizer {
    struct StoredColors {
        var id: UUID
        var color: UIColor
    }
    var savedColors = [StoredColors]()

    init() { }

    func assignColor(to id: UUID, classification: ARMeshClassification, color: UIColor = UIColor.black.withAlphaComponent(0.7)) -> UIColor {
        return savedColors.first(where: { $0.id == id })?.color
        ?? saveColor(uuid: id, classification: classification, color: color)
    }

    func saveColor(uuid: UUID, classification: ARMeshClassification, color: UIColor = UIColor.black.withAlphaComponent(0.7)) -> UIColor {
//        let newColor = classification.color.withAlphaComponent(0.5)
        let newColor = color
        let stored = StoredColors(id: uuid, color: newColor)
        savedColors.append(stored)
        return newColor
    }
}
