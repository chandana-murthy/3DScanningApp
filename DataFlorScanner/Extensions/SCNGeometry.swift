//
//  SCNGeometry.swift
//  DataFlor
//
//  Created by Chandana Murthy on 28.03.22.
//

import Foundation
import SceneKit
import ARKit
import MetalKit

extension SCNGeometry {
    convenience init(arGeometry: ARMeshGeometry) {
        let verticesSource = SCNGeometrySource(arGeometry.vertices, semantic: .vertex)
        let normalsSource = SCNGeometrySource(arGeometry.normals, semantic: .normal)
        let faces = SCNGeometryElement(arGeometry.faces)
        self.init(sources: [verticesSource, normalsSource], elements: [faces])
    }

    convenience init(geometry: ARMeshGeometry, camera: ARCamera, modelMatrix: simd_float4x4, needTexture: Bool = false) { // swiftlint:disable:this function_body_length
        func convertType(type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
            switch type {
            case .line:
                return .line
            case .triangle:
                return .triangles
            @unknown default:
                return .line
            }
        }

        func calcTextureCoordinates(vertices: ARGeometrySource, camera: ARCamera, modelMatrix: simd_float4x4) -> SCNGeometrySource? {
            func getVertex(at index: UInt32) -> SIMD3<Float> {
                    assert(vertices.format == MTLVertexFormat.float3, "Expected three floats (twelve bytes) per vertex.")
                    let vertexPointer = vertices.buffer.contents().advanced(by: vertices.offset + (vertices.stride * Int(index)))
                    let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
                    return vertex
            }

            func buildCoordinates() -> [CGPoint]? {
                let size = camera.imageResolution
                let textureCoordinates = (0..<vertices.count).map { i -> CGPoint in
                    let vertex = getVertex(at: UInt32(i))
                    let vertex4 = vector_float4(vertex.x, vertex.y, vertex.z, 1)
                    let world_vertex4 = simd_mul(modelMatrix, vertex4)
                    let world_vector3 = simd_float3(x: world_vertex4.x, y: world_vertex4.y, z: world_vertex4.z)
                    let pt = camera.projectPoint(world_vector3,
                        orientation: .portrait,
                        viewportSize: CGSize(
                            width: CGFloat(size.height),
                            height: CGFloat(size.width)))
                    let v = 1.0 - Float(pt.x) / Float(size.height)
                    let u = Float(pt.y) / Float(size.width)
                    return CGPoint(x: CGFloat(u), y: CGFloat(v))
                }
                return textureCoordinates
            }

            guard let texcoords = buildCoordinates() else {return nil}
            let result = SCNGeometrySource(textureCoordinates: texcoords)
            return result
        }

        let vertices = geometry.vertices
        let normals = geometry.normals
        let faces = geometry.faces
        let verticesSource = SCNGeometrySource(buffer: vertices.buffer, vertexFormat: vertices.format, semantic: .vertex, vertexCount: vertices.count, dataOffset: vertices.offset, dataStride: vertices.stride)
        let normalsSource = SCNGeometrySource(buffer: normals.buffer, vertexFormat: normals.format, semantic: .normal, vertexCount: normals.count, dataOffset: normals.offset, dataStride: normals.stride)
        let data = Data(bytes: faces.buffer.contents(), count: faces.buffer.length)
        let facesElement = SCNGeometryElement(data: data, primitiveType: convertType(type: faces.primitiveType), primitiveCount: faces.count, bytesPerIndex: faces.bytesPerIndex)
        var sources = [verticesSource, normalsSource]
        if needTexture {
            let textureCoordinates = calcTextureCoordinates(vertices: vertices, camera: camera, modelMatrix: modelMatrix)!
            sources.append(textureCoordinates)
        }
        self.init(sources: sources, elements: [facesElement])
    }

    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]

        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)

        return SCNGeometry(sources: [source], elements: [element])
    }

    class func cylinderLine(from: SCNVector3, to: SCNVector3, width: CGFloat = 0.0005, color: UIColor = .white) -> SCNNode {
        let x1 = from.x; let x2 = to.x
        let y1 = from.y; let y2 = to.y
        let z1 = from.z; let z2 = to.z

        let subExpr01 = Float((x2-x1) * (x2-x1))
        let subExpr02 = Float((y2-y1) * (y2-y1))
        let subExpr03 = Float((z2-z1) * (z2-z1))

        let distance = sqrtf(subExpr01 + subExpr02 + subExpr03)

        let cylinder = SCNCylinder(radius: width, height: CGFloat(distance))
        cylinder.radialSegmentCount = 5
        cylinder.firstMaterial?.diffuse.contents = color
        cylinder.firstMaterial?.isDoubleSided = true

        let lineNode = SCNNode(geometry: cylinder)

        lineNode.position = SCNVector3((x1+x2)/2,
                                       (y1+y2)/2,
                                       (z1+z2)/2)

        lineNode.eulerAngles = SCNVector3(x: .pi / 2,
                                          y: acos((to.z-from.z)/distance),
                                          z: atan2((to.y-from.y), (to.x-from.x)))
        return lineNode
    }

    class func getMeshFromGeometry(anchor: ARMeshAnchor, allocator: MTKMeshBufferAllocator) -> MDLMesh {
        let geometry = anchor.geometry
        let vertices = geometry.vertices
        let faces = geometry.faces
        let verticesPointer = vertices.buffer.contents()
        let facesPointer = faces.buffer.contents()
        //        let size = camera.imageResolution

        // Converting each vertex of the geometry from the local space of their ARMeshAnchor to world space
        for vertexIndex in 0..<vertices.count {
            // Extracting the current vertex with an extension method provided by Apple in ARMeshGeometry.swift
            let vertex = geometry.vertex(at: UInt32(vertexIndex))

            // Building a transform matrix with only the vertex position
            // and apply the mesh anchors transform to convert into world space
            var vertexLocalTransform = matrix_identity_float4x4
            vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y: vertex.1, z: vertex.2, w: 1)
            let vertexWorldPosition = (anchor.transform * vertexLocalTransform).position

            // Writing the world space vertex back into it's position in the vertex buffer
            let vertexOffset = vertices.offset + vertices.stride * vertexIndex
            let componentStride = vertices.stride / 3
            verticesPointer.storeBytes(of: vertexWorldPosition.x, toByteOffset: vertexOffset, as: Float.self)
            verticesPointer.storeBytes(of: vertexWorldPosition.y, toByteOffset: vertexOffset + componentStride, as: Float.self)
            verticesPointer.storeBytes(of: vertexWorldPosition.z, toByteOffset: vertexOffset + (2 * componentStride), as: Float.self)
        }

        // Initializing MDLMeshBuffers with the content of the vertex and face MTLBuffers
        let byteCountVertices = vertices.count * vertices.stride
        let byteCountFaces = faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex
        let vertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: verticesPointer, count: byteCountVertices, deallocator: .none), type: .vertex)
        let indexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: facesPointer, count: byteCountFaces, deallocator: .none), type: .index)

        // Creating a MDLSubMesh with the index buffer and a generic material
        let indexCount = faces.count * faces.indexCountPerPrimitive
        let material = MDLMaterial(name: "mat1", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
        let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: indexCount, indexType: .uInt32, geometryType: .triangles, material: material)

        // Creating a MDLVertexDescriptor to describe the memory layout of the mesh
        let vertexFormat = MTKModelIOVertexFormatFromMetal(vertices.format)
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: vertexFormat, offset: 0, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: anchor.geometry.vertices.stride)

        // Finally creating the MDLMesh and adding it to the MDLAsset
        let mesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: anchor.geometry.vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
        return mesh
    }
}

extension  SCNGeometrySource {
    convenience init(_ source: ARGeometrySource, semantic: Semantic) {
           self.init(buffer: source.buffer, vertexFormat: source.format, semantic: semantic, vertexCount: source.count, dataOffset: source.offset, dataStride: source.stride)
    }

    convenience init(textureCoordinates texcoord: [vector_float2]) {
        let stride = MemoryLayout<vector_float2>.stride
        let bytePerComponent = MemoryLayout<Float>.stride
        let data = Data(bytes: texcoord, count: stride * texcoord.count)
        self.init(data: data, semantic: SCNGeometrySource.Semantic.texcoord, vectorCount: texcoord.count, usesFloatComponents: true, componentsPerVector: 2, bytesPerComponent: bytePerComponent, dataOffset: 0, dataStride: stride)
    }
}

extension SCNGeometryElement {
    convenience init(_ source: ARGeometryElement) {
        let pointer = source.buffer.contents()
        let byteCount = source.count * source.indexCountPerPrimitive * source.bytesPerIndex
        let data = Data(bytesNoCopy: pointer, count: byteCount, deallocator: .none)
        self.init(data: data, primitiveType: .of(source.primitiveType), primitiveCount: source.count, bytesPerIndex: source.bytesPerIndex)
    }
}
extension SCNGeometryPrimitiveType {
    static func of(_ type: ARGeometryPrimitiveType) -> SCNGeometryPrimitiveType {
        switch type {
        case .line:
            return .line
        case .triangle:
            return .triangles
        @unknown default:
            return .line
        }
    }
}
