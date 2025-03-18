//
//  NavigationUtils.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 18.01.23.
//

import SwiftUI

class NavigationUtils: ObservableObject {
    @Published var path: NavigationPath

    init() {
        self.path = NavigationPath()
    }
}
