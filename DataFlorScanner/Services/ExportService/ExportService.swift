import Foundation
import Common
import SceneKit

final class ExportService: ObservableObject {

    @Published var exportProgress = 1.0
    @Published var info = "Exporting..."
    @Published var exporting = false

    func generateSCNFile(from scene: SCNScene) -> SCNFile {
        let file = SCNFile(scene: scene)
        info = "Exporting SCN..."
        file.$writeToDiskProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$exportProgress)
        file.$writtingToDisk
            .receive(on: DispatchQueue.main)
            .assign(to: &$exporting)
        return file
    }

    func generatePLYFile(from object: Object3D, fileName: String = "") -> PLYFile {
        let file = PLYFile(object: object, fileName: fileName)
        info = "Exporting PLY..."
        file.$writeToDiskProgress
            .receive(on: DispatchQueue.main)
            .assign(to: &$exportProgress)
        file.$writtingToDisk
            .receive(on: DispatchQueue.main)
            .assign(to: &$exporting)
        return file
    }
}
