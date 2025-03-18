//
//  MeasurementPolygonFileFormat.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 26.04.23.
//

import Foundation
import UniformTypeIdentifiers
import SceneKit

public struct MeasurementPolygonFileFormat {

    public struct HeaderLine {
        let key: String
        let value: String?

        static let start = HeaderLine(key: Keyword.start)
        static let end = HeaderLine(key: Keyword.end)

        private init(key: Keyword, value: String? = nil) {
            self.key = key.rawValue
            self.value = value
        }

        init(format: Format, version: String) {
            key = Keyword.format.rawValue
            value = "\(format) \(version)"
        }

        init(comment: String) {
            key = Keyword.comment.rawValue
            value = "\(comment)"
        }

        init(element: Element, count: Int) {
            key = "\(Keyword.element)"
            value = "\(element) \(count)"
        }

        init(property: Property, type: PropertyType) {
            key = "\(Keyword.property)"
            value = "\(type) \(property.rawValue)"
        }

        /// Property list initializer
        /// ```
        ///     element face 10
        ///     property list uchar int vertex_index
        /// ```
        init(property: Property, types: [PropertyType]) {
            key = "\(Keyword.property) \(Keyword.list)"
            value = "\(types.map(\.rawValue).joined(separator: " ")) \(property.rawValue)"
        }

    }

    enum Keyword: String {
        case start = "ply", end = "end_header"
        case format, comment, element, property
        case list
    }

    enum Element: String {
        case vertex
        case face
    }

    enum Format: String {
        case ascii
        //        case bin
    }

    enum Property: String {
        case positionX = "x", positionY = "y", positionZ = "z"
        case redComponent = "red", greenComponent = "green", blueComponent = "blue"
        case normalX = "nx", normalY = "ny", normalZ = "nz"
        case confidence
        case vertexIndex = "vertex_index"
    }

    enum PropertyType: String {
        case float, uchar, int
    }

    /// Generates a `Data` instance representing a PolygonFileFormat.
    /// - Returns: The `Data` representation of the PolygonFileFormat instance.
    ///
    /// Example file (remove {comments} from final file):
    ///
    /// ply
    /// format ascii 1.0                          { ascii/binary, format version number }
    /// comment made by Greg Turk    { comments keyword specified, like all lines }
    /// comment this file is a cube
    /// element node 8                          { define "node" element, 8 of them in file }
    /// property float x                           { vertex contains float "x" coordinate }
    /// property float y                           { y coordinate is also a vertex property }
    /// property float z                           { z coordinate, too }
    /// element measurement 6            { there are 6 "measurement" elements in the file. two vertices form a measurement }
    /// property list uchar int vertex_index     { "vertex_indices" is a list of ints }
    /// end_header                                { delimits the end of the header }
    /// 0 0 0                                           { start of vertex list }
    /// 0 0 1
    /// 0 1 1
    /// 0 1 0
    /// 1 0 0
    /// 1 0 1
    /// 1 1 1
    /// 1 1 0
    /// 4 0                                    { start of Measurement list }
    /// 4 7
    /// 1 0
    /// 6 2
    /// 2 6
    /// 3 7
    ///
    public static func generateAsciiData(using measureNodes: [SCNNode], comments: [String]? = nil) -> Data? {
        var header = [HeaderLine]()

        header.append(.start)
        header.append(.init(format: .ascii, version: "1.0"))
        // Add comments
        comments?.forEach({ (comment) in
            header.append(.init(comment: comment))
        })
        // Define Vertice property
        header.append(.init(element: .vertex, count: measureNodes.count))
        header.append(.init(property: .positionX, type: .float))
        header.append(.init(property: .positionY, type: .float))
        header.append(.init(property: .positionZ, type: .float))

        header.append(.init(element: .face, count: measureNodes.count/2))
        header.append(.init(property: .vertexIndex, types: [.uchar, .int]))

        header.append(.end)

        var lines = [AsciiRepresentable]()

        lines.append(contentsOf: header)
        for node in measureNodes {
            lines.append(node)
        }
        lines.append(measureNodes)

        let asciiData = lines
            .joinedAsciiRepresentation()
            .data(using: .ascii)

        return asciiData
    }
}

private protocol AsciiRepresentable {
    var ascii: String { get }
}

extension SCNNode: AsciiRepresentable {
    fileprivate func position() -> String {
        return "\(position.x) \(position.y) \(position.z)"
    }
    fileprivate var ascii: String {
        return self.position()
    }
}

extension [SCNNode]: AsciiRepresentable {
    fileprivate var ascii: String {
        var string = ""
        for i in 0..<self.count {
            for j in i+1..<self.count where self[i].name == self[j].name { // measure nodes of the same measurement have the same name
                string.append("3 \(i) \(j) \(i)\n") // 3 indicated that it is a triangle
            }
        }
        return string
    }
}

extension Float {
    fileprivate var rgb: UInt {
        UInt(self * 255)
    }
}

extension MeasurementPolygonFileFormat.HeaderLine: AsciiRepresentable {
    fileprivate var ascii: String { "\(key) \(value ?? "")" }
}

extension Sequence where Iterator.Element == AsciiRepresentable {
    fileprivate func joinedAsciiRepresentation(separator: String = "\n") -> String {
        map { $0.ascii }
            .joined(separator: separator)
    }
}
