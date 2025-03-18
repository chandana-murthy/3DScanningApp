//
//  MeshViewerView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 26.12.22.
//

import SwiftUI
import ModelIO

struct MeshViewerView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @EnvironmentObject var assetFile: AssetFile

    var body: some View {
        TabView {
            if assetFile.path == nil {
                ProgressView(Strings.pleaseWait.localized(language))
            } else {
                ObjFileViewerView(viewModel: ObjFileViewerViewModel(assetFile: assetFile))
                    .tabItem {
                        Image.objFile
                        Text("Obj")
                    }
                    .font(.subheadline)

                UsdzFileViewerView()
                    .tabItem {
                        Image.usdzFile
                        Text("USDZ")
                    }
                    .font(.subheadline)
            }
        }
    }
}
