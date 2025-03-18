//
//  Image.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 05.01.23.
//

import SwiftUI

extension Image {
    static let location = Image(systemName: "location.circle.fill")
    static let save = Image(systemName: "square.and.arrow.down")
    static let export = Image(systemName: "tray.and.arrow.up")
    static let xMark = Image(systemName: "xmark")
    static let cubeTransparent = Image(systemName: "cube.transparent")
    static let trash = Image(systemName: "trash.fill")
    static let undo = Image(systemName: "arrow.counterclockwise")
    static let flashlightOn = Image(systemName: "flashlight.on.fill")
    static let flashlightOff = Image(systemName: "flashlight.off.fill")
    static let slider = Image(systemName: "slider.horizontal.3")
    static let restart = Image(systemName: "arrow.triangle.2.circlepath")
    static let scissors = Image(systemName: "scissors.circle")
    static let wrench = Image(systemName: "wrench.and.screwdriver")
    static let lightMode = Image(systemName: "sun.min.fill")
    static let darkMode = Image(systemName: "moon.fill")
    static let confidence = Image(systemName: "circlebadge.2")
    static let normals = Image(systemName: "line.diagonal.arrow")
    static let surfaceRecons = Image(systemName: "skew")
    static let objFile = Image(systemName: "square.stack.3d.up")
    static let usdzFile = Image(systemName: "circle.hexagonpath")
    static let voxelDS = Image(systemName: "arrow.down.backward.circle")
    static let statisticalOR = Image(systemName: "aqi.medium")
    static let radiusOR = Image(systemName: "camera.filters")
    static let englishFlag = Image("eng")
    static let germanFlag = Image("ger")
    static let dataFlorLogo = Image("logo")
}

extension UIImage {
    static let cubeTransparent = UIImage(systemName: "cube.transparent")!
    static let points = UIImage(named: "points")!
    static let mesh = UIImage(named: "mesh")!
    static let person = UIImage(systemName: "person.fill")!
}
