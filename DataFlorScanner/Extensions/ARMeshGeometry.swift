//
//  ARMeshGeometry.swift
//  DataFlor
//
//  Created by Chandana Murthy on 09.03.22.
//

import Foundation
import ARKit

extension ARMeshGeometry {
    func vertex(at index: UInt32) -> (Float, Float, Float) {
        assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
        let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
        let vertex = vertexPointer.assumingMemoryBound(to: (Float, Float, Float).self).pointee
        return vertex
    }

    /// To get the mesh's classification, the sample app parses the classification's raw data and instantiates an
    /// `ARMeshClassification` object. For efficiency, ARKit stores classifications in a Metal buffer in `ARMeshGeometry`.
    func classificationOf(faceWithIndex index: Int) -> ARMeshClassification {
        guard let classification = classification else { return .none }
        assert(classification.format == MTLVertexFormat.uchar, "Expected one unsigned char (one byte) per classification")
        let classificationPointer = classification.buffer.contents().advanced(by: classification.offset + (classification.stride * index))
        let classificationValue = Int(classificationPointer.assumingMemoryBound(to: CUnsignedChar.self).pointee)
        return ARMeshClassification(rawValue: classificationValue) ?? .none
    }

    func vertexIndicesOf(faceWithIndex faceIndex: Int) -> [UInt32] {
        assert(faces.bytesPerIndex == MemoryLayout<UInt32>.size, "Expected one UInt32 (four bytes) per vertex index")
        let vertexCountPerFace = faces.indexCountPerPrimitive
        let vertexIndicesPointer = faces.buffer.contents()
        var vertexIndices = [UInt32]()
        vertexIndices.reserveCapacity(vertexCountPerFace)
        for vertexOffset in 0..<vertexCountPerFace {
            let vertexIndexPointer = vertexIndicesPointer.advanced(by: (faceIndex * vertexCountPerFace + vertexOffset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(vertexIndexPointer.assumingMemoryBound(to: UInt32.self).pointee)
        }
        return vertexIndices
    }

    func normal(at index: UInt32) -> SIMD3<Float> {
        assert(normals.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per normal.")
        let normalPointer = normals.buffer.contents().advanced(by: normals.offset + (normals.stride * Int(index)))
        let normal = normalPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
        return normal
    }

    func textureVertexIndicesOf(faceWithIndex index: Int) -> [Int] {
        let indicesPerFace = faces.indexCountPerPrimitive
        let facesPointer = faces.buffer.contents()
        var vertexIndices = [Int]()
        for offset in 0..<indicesPerFace {
            let vertexIndexAddress = facesPointer.advanced(by: (index * indicesPerFace + offset) * MemoryLayout<UInt32>.size)
            vertexIndices.append(Int(vertexIndexAddress.assumingMemoryBound(to: UInt32.self).pointee))
        }
        return vertexIndices
    }

    func verticesOf(faceWithIndex index: Int) -> [(Float, Float, Float)] {
        let vertexIndices = vertexIndicesOf(faceWithIndex: index)
        let vertices = vertexIndices.map { vertex(at: $0) }
        return vertices
    }

    func centerOf(faceWithIndex index: Int) -> (Float, Float, Float) {
        let vertices = verticesOf(faceWithIndex: index)
        let sum = vertices.reduce((0, 0, 0)) { ($0.0 + $1.0, $0.1 + $1.1, $0.2 + $1.2) }
        let geometricCenter = (sum.0 / 3, sum.1 / 3, sum.2 / 3)
        return geometricCenter
    }
}

extension ARMeshClassification {
    var description: String {
        switch self {
        case .ceiling: return "Ceiling"
        case .door: return "Door"
        case .floor: return "Floor"
        case .seat: return "Seat"
        case .table: return "Table"
        case .wall: return "Wall"
        case .window: return "Window"
        case .none: return "None"
        @unknown default: return "Unknown"
        }
    }

    var color: UIColor {
        switch self {
        case .ceiling: return .dataFlorGreenUI
        case .door: return .brown
        case .floor: return .red
        case .seat: return .yellow
        case .table: return .orange
        case .wall: return .magenta
        case .window: return .blue
        case .none: return .lightGray
        @unknown default: return .white
        }
    }
}
