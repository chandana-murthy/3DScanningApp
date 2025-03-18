//
//  MeasurementUtils.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 19.12.22.
//

import Foundation
import ARKit
import SceneKit

class MeasurementUtils {
    static func meterOrCentimeter(value: Float) -> String {
        if value < 1 {
            return String(format: "%.0f", value * 100) + "cm"
        }
        return String(format: "%.2f", value) + "m"
    }

    static func getMarker(rayCastResult: ARRaycastResult, color: UIColor = .yellow) -> SCNNode {
        let sphere = SCNSphere(radius: 0.015)
        sphere.firstMaterial?.diffuse.contents = color

        let markerNode = SCNNode(geometry: sphere)
        markerNode.position = SCNVector3(rayCastResult.worldTransform.columns.3.x, rayCastResult.worldTransform.columns.3.y, rayCastResult.worldTransform.columns.3.z)
        return markerNode
    }

    static func getMarker(hitTestResult: SCNHitTestResult, color: UIColor = .yellow) -> SCNNode {
        let sphere = SCNSphere(radius: 0.015)
        sphere.firstMaterial?.diffuse.contents = color
        sphere.firstMaterial?.isDoubleSided = true

        let markerNode = SCNNode(geometry: sphere)
        markerNode.position = hitTestResult.worldCoordinates
        return markerNode
    }

    static func getLineBetween(_ start: SCNVector3, _ end: SCNVector3, color: UIColor = UIColor.white) -> SCNNode {
        let lineNode = SCNGeometry.cylinderLine(from: start, to: end, color: color)
        return lineNode
    }

    static func getLineBetween(_ startNode: SCNNode, _ endNode: SCNNode, color: UIColor = UIColor.white) -> SCNNode {
        getLineBetween(startNode.position, endNode.position, color: color)
    }

    static func getDistanceBetween(_ start: SCNVector3, _ end: SCNVector3) -> Float {
        return SCNVector3.distanceFrom(vector: start, toVector: end)
    }

    static func getDistanceTextNode(_ start: SCNVector3, _ end: SCNVector3) -> SCNNode {
        let distance = getDistanceBetween(start, end)

        let textGeometry = SCNText(string: meterOrCentimeter(value: distance), extrusionDepth: 5)
        textGeometry.font = UIFont(name: "NeoSans-Standard", size: 12)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.black

        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3Make((start.x + end.x)/2.0,
                                           (start.y + end.y)/2.0,
                                           (start.z + end.z)/2.0
        )
        textNode.scale = SCNVector3Make(0.003, 0.003, 0.003)

        // ------ Background
        let minVec = textNode.boundingBox.min
        let maxVec = textNode.boundingBox.max
        let bound = SCNVector3Make(maxVec.x - minVec.x,
                                   maxVec.y - minVec.y,
                                   maxVec.z - minVec.z)

        let plane = SCNPlane(width: CGFloat(bound.x + 15),
                             height: CGFloat(bound.y + 5))
        plane.cornerRadius = 20
        plane.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.7)
        plane.firstMaterial?.isDoubleSided = true

        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3(CGFloat(minVec.x) + CGFloat(bound.x) / 2,
                                        CGFloat(minVec.y) + CGFloat(bound.y) / 2,
                                        CGFloat(minVec.z - 0.01))
        // ------ Background

        textNode.addChildNode(planeNode)
        return textNode
    }

    static func getVectorFromWorldTransform(_ worldTransform: simd_float4x4) -> SCNVector3 {
        return SCNVector3(worldTransform.columns.3.x, worldTransform.columns.3.y, worldTransform.columns.3.z)
    }

    static func getSessionStateInfo(for frame: ARFrame, trackingState: ARCamera.TrackingState) -> String {
        let message: String
        switch trackingState {
        case .normal where frame.anchors.isEmpty:// No planes detected
            message = Strings.moveDevice
        case .notAvailable:
            message = Strings.trackingUnavailable
        case .limited(.relocalizing):
            message = Strings.resuming
        case .limited(.excessiveMotion):
            message = Strings.moveSlowly
        case .limited(.insufficientFeatures):
            message = Strings.trackingLimited
        case .limited(.initializing):
            message = Strings.initializingSession
        default: // tracking is normal and planes are visible.
            message = ""
        }
        return message
    }
}
