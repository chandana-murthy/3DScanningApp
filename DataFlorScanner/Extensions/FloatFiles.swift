//
//  float4x4.swift
//  DataFlor
//
//  Created by Chandana Murthy on 14.03.22.
//

import Foundation
import ARKit

typealias Float2 = SIMD2<Float>
typealias Float3 = SIMD3<Float>
typealias Float4 = SIMD4<Float>

extension float4x4 {
    init(translation vector: Float3) {
        self.init(Float4(1, 0, 0, 0),
                  Float4(0, 1, 0, 0),
                  Float4(0, 0, 1, 0),
                  Float4(vector.x, vector.y, vector.z, 1))
    }

    var position: Float3 {
        return Float3(columns.3.x, columns.3.y, columns.3.z)
    }
}

extension Float {
    static let degreesToRadian = Float.pi / 180

    func metersToInches() -> Float {
        return self * 39.3701
    }
}

extension matrix_float3x3 {
    mutating func copy(from affine: CGAffineTransform) {
        columns.0 = Float3(Float(affine.a), Float(affine.c), Float(affine.tx))
        columns.1 = Float3(Float(affine.b), Float(affine.d), Float(affine.ty))
        columns.2 = Float3(0, 0, 1)
    }
}
