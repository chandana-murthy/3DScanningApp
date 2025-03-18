import Foundation
import ARKit

public struct PointCloud {
    var points: [simd_float3]
    var colors: [simd_float3]

    public init() {
        self.points = []
        self.colors = []
    }

    public init(pointCount: Int, pointsData: Data, colorsData: Data) {
        assert(pointCount * 12 == pointsData.count)
        assert(pointCount * 12 == pointsData.count)

        self.points = []
        self.colors = []

        if pointCount == 0 {
            return
        }

        for i in 0..<pointCount {
            self.points.append(simd_float3(
                pointsData[i*12..<i*12+4].withUnsafeBytes { $0.load(as: Float.self) },
                pointsData[i*12+4..<i*12+8].withUnsafeBytes { $0.load(as: Float.self) },
                pointsData[i*12+8..<i*12+12].withUnsafeBytes { $0.load(as: Float.self) }
            ))
            self.colors.append(simd_float3(
                colorsData[i*12..<i*12+4].withUnsafeBytes { $0.load(as: Float.self) },
                colorsData[i*12+4..<i*12+8].withUnsafeBytes { $0.load(as: Float.self) },
                colorsData[i*12+8..<i*12+12].withUnsafeBytes { $0.load(as: Float.self) }
            ))
        }
    }

    public func pointsData() -> Data {
        var data = Data(count: self.points.count * 12)

        for i in 0..<self.points.count {
            data.replaceSubrange(i*12..<i*12+4, with: withUnsafeBytes(of: self.points[i].x) { Data($0) })
            data.replaceSubrange(i*12+4..<i*12+8, with: withUnsafeBytes(of: self.points[i].y) { Data($0) })
            data.replaceSubrange(i*12+8..<i*12+12, with: withUnsafeBytes(of: self.points[i].z) { Data($0) })
        }
        return data
    }

    public func colorsData() -> Data {
        var data = Data(count: self.points.count * 12)

        for i in 0..<self.colors.count {
            data.replaceSubrange(i*12..<i*12+4, with: withUnsafeBytes(of: self.colors[i].x) { Data($0) })
            data.replaceSubrange(i*12+4..<i*12+8, with: withUnsafeBytes(of: self.colors[i].y) { Data($0) })
            data.replaceSubrange(i*12+8..<i*12+12, with: withUnsafeBytes(of: self.colors[i].z) { Data($0) })
        }
        return data
    }

    public func export(fileName: String = UUID().uuidString) -> URL {
        do {
            let plyTempPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).appendingPathExtension("ply")
            var file = """
            ply
            format ascii 1.0
            comment author: DataFlor/Uni-goe.
            element vertex \(self.points.count)
            property float x
            property float y
            property float z
            property uchar red
            property uchar green
            property uchar blue
            end_header\n
            """

            for i in 0..<self.points.count {
                var red = Int(self.colors[i].x * 255)
                var green = Int(self.colors[i].y * 255)
                var blue = Int(self.colors[i].z * 255)

                if red < 0 {
                    red = 0
                } else if red > 255 {
                    red = 255
                }

                if green < 0 {
                    green = 0
                } else if green > 255 {
                    green = 255
                }

                if blue < 0 {
                    blue = 0
                } else if blue > 255 {
                    blue = 255
                }

                file.append("\(self.points[i].x) \(self.points[i].y) \(self.points[i].z) \(red) \(green) \(blue)\n")
            }

            do {
                try file.write(to: plyTempPath, atomically: true, encoding: .utf8)
            } catch let error as NSError {
                print("Error: \(error.localizedDescription)")
            }

            return plyTempPath
        }
    }
}
