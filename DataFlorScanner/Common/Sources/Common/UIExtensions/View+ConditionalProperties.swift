//
//  View+HiddenConditionally.swift
//  PointCloudKit
//
//  Created by Alexandre Camilleri on 30/04/2021.
//

import SwiftUI

extension View {
    public func hiddenConditionally(_ hidden: Bool) -> some View {
        opacity(hidden ? 0 : 1)
    }
}
