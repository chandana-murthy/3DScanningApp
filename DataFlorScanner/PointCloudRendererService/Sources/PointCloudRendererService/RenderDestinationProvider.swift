//
//  RenderDestinationProvider.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 30/04/2021.
//

import Metal
import MetalKit
import ARKit

public protocol RenderDestinationProvider: AnyObject {
    var currentRenderPassDescriptor: MTLRenderPassDescriptor? { get }
    var currentDrawable: CAMetalDrawable? { get }
    var colorPixelFormat: MTLPixelFormat { get set }
    var depthStencilPixelFormat: MTLPixelFormat { get set }
    var sampleCount: Int { get set }
}
