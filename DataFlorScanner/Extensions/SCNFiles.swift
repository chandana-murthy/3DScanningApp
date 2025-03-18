//
//  SCNFiles.swift
//  DataFlor
//
//  Created by Chandana Murthy on 14.03.22.
//

import Foundation
import ARKit
import RealityKit

extension SCNNode {
    func centerAlign() {
        let (min, max) = boundingBox
        let extents = SIMD3<Float>(max) - SIMD3<Float>(min)
        simdPivot = float4x4(translation: ((extents / 2) + SIMD3<Float>(min)))
    }

    func cleanup() {
        for child in childNodes {
            child.cleanup()
        }
        self.geometry = nil
    }
}

extension SCNVector3 {
    static func distanceFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> Float {
        let x0 = vector1.x
        let x1 = vector2.x
        let y0 = vector1.y
        let y1 = vector2.y
        let z0 = vector1.z
        let z1 = vector2.z

        return sqrtf(powf(x1-x0, 2) + powf(y1-y0, 2) + powf(z1-z0, 2))
    }
}
