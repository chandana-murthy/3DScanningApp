//
//  ObjFileViewerViewModel.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 25.01.23.
//

import Foundation
import SceneKit.ModelIO

class ObjFileViewerViewModel: ObservableObject {
    @Published var scene: SCNScene
    var cameraNode = SCNNode()
    var asset: AssetFile

    // Initialize Scene
    init(assetFile: AssetFile) {
        self.asset = assetFile
        scene = SCNScene(mdlAsset: assetFile.asset)

        cameraNode.camera = SCNCamera()
        cameraNode.name = NodeIdentifier.camera.rawValue
        cameraNode.position.z += 5

        // directional light with stronger intensity and in the right position with euler angles and offsets for shadows
        // Create ambient light
        let ambientLightNode = SCNNode()
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor.white // 0.6 alpha
        ambientLightNode.light = ambientLight

        let directionalLightNode = SCNNode()
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.color = UIColor(white: 0.8, alpha: 0.9)
        directionalLightNode.light = directionalLight
        directionalLightNode.eulerAngles = SCNVector3(x: 0, y: 20, z: 50)
        //    directionalLight.eulerAngles = SCNVector3(-Float(M_PI_4), -Float(M_PI_2), 0)

        // spotlight
        cameraNode.addChildNode(directionalLightNode)
        cameraNode.addChildNode(ambientLightNode)

        scene.rootNode.addChildNode(cameraNode)
        scene.background.contents = UIColor.black

    }

    func writeToFile() {
        if let url = asset.usdzUrl {
            scene.write(to: url, delegate: nil)
        }
    }
}
