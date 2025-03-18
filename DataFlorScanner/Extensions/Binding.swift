//
//  Binding.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 03.05.23.
//

import SwiftUI

extension Binding {
    func didSet(_ closure: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: {
                self.wrappedValue = $0
                closure($0)
            }
        )
    }
}
