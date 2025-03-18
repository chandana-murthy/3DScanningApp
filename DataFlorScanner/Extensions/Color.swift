//
//  Color.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 18.12.22.
//

import SwiftUI

extension Color {
    private static func getColor(r: Double, g: Double, b: Double) -> Color {
        return Color(red: r/255, green: g/255, blue: b/255)
    }

    public static let dataFlorGreen = getColor(r: 95, g: 158, b: 51)
    public static let basicColor = Color("BasicColor")
    public static let appModeColor = Color("AppModeColor")
    public static let lightGray = Color.gray.opacity(0.5)
    public static let disabledColor = getColor(r: 84, g: 95, b: 92)
    public static let inactiveColor = Color("InactiveColor")
}

extension UIColor {
    public static let dataFlorGreenUI = UIColor(red: 95/255, green: 158/255, blue: 51/255, alpha: 1)
}
