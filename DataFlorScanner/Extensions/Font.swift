//
//  Font.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 28.12.22.
//

import SwiftUI

extension Font {
    static func sansNeoRegular(size: CGFloat) -> Font {
        Font.custom("NeoSansStd-Regular", size: size)
    }
    static func sansNeoStandard(size: CGFloat) -> Font {
        Font.custom("NeoSansStd-Standard", size: size)
    }
    static func sansNeoLight(size: CGFloat) -> Font {
        Font.custom("NeoSansStd-Light", size: size)
    }
    static func sansNeoBold(size: CGFloat) -> Font {
        Font.custom("NeoSansStd-Bold", size: size)
    }
}
