import Foundation
import Combine

public typealias UInt3 = SIMD3<UInt>

// Loosely close to Open3D return type but in Swift
// Open3D and other types http://www.open3d.org/docs/release/python_api/open3d.geometry.TriangleMesh.html
public struct Object3D {
    public var vertices = [Float3]()
    public var vertexConfidence = [UInt]()
    public var vertexColors = [Float3]()
    public var vertexNormals = [Float3]()
    public var triangles = [UInt3]()

    public init() {}

    public init(
        vertices: [Float3] = [],
        vertexConfidence: [UInt] = [],
        vertexColors: [Float3] = [],
        vertexNormals: [Float3] = [],
        triangles: [UInt3] = []
    ) {
        self.vertices = vertices
        self.vertexConfidence = vertexConfidence
        self.vertexColors = vertexColors
        self.vertexNormals = vertexNormals
        self.triangles = triangles
    }

    public var hasVertices: Bool { !vertices.isEmpty }
    public var hasVertexConfidence: Bool { !vertexConfidence.isEmpty }
    public var hasVertexColors: Bool { !vertexColors.isEmpty }
    public var hasVertexNormals: Bool { !vertexNormals.isEmpty }
    public var hasTriangles: Bool { !triangles.isEmpty }

    public var hash: Int { vertices.hashValue & vertexNormals.hashValue & triangles.hashValue }
}

extension Object3D {
    public func particles() -> Future<[ParticleUniforms], Never> {
        Future { promise in
            DispatchQueue.global(qos: .userInteractive).async {
                /* * */ let start = DispatchTime.now()
                let particles = zip(vertices, zip(vertexColors, vertexConfidence)).map { point, arg -> ParticleUniforms in
                    let (color, confidence) = arg
                    return ParticleUniforms(position: point, color: color, confidence: Float(confidence))
                }
                /* * */ let end = DispatchTime.now()
                /* * */ let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                /* * */ print(" <*> Object3D -> particles : \(Double(nanoTime) / 1_000_000) ms")
                promise(.success(particles))
            }
        }
    }
}
