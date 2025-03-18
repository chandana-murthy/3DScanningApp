//
//  ObjFileViewerView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 23.01.23.
//

import SwiftUI
import SceneKit

struct ObjFileViewerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ObjFileViewerViewModel
    @State private var offset: Float = 0
    @State private var message: String = ""
    @State private var clearNodes: Bool = false
    @State private var topView: Bool = false

    init(viewModel: ObjFileViewerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
//        SceneUIView(offset: $offset, message: $message, clearMeasureNodes: $clearNodes, makeOrtho: $topView, scene: viewModel.scene)
        Text("This is Obj File Viewer")
    }
}
