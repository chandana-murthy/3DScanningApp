//
//  AnyTransition.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 30/04/2021.
//

import SwiftUI

extension AnyTransition {
    public static var moveAndFade: AnyTransition {
        AnyTransition.move(edge: .bottom)
            .combined(with: .opacity)
    }
}
