//
//  Comparable.swift
//  DataFlor
//
//  Created by Chandana Murthy on 30.03.22.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
