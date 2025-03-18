//
//  MeshScanView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 19.12.22.
//

import SwiftUI

struct MeshScanView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @State var message: String = Strings.startARSession
    @State var errorMessage: String?
    @State var shouldShowUndo = false
    @StateObject var assetFile = AssetFile()
    @StateObject var meshViewStates = MeshViewStates()

    var body: some View {
        ZStack {
            MeshViewControllerRepresentable(
                message: $message,
                errorMessage: $errorMessage,
                shouldShowUndo: $shouldShowUndo
            )

            VStack {

                Spacer()

                MeshControlsTabView(
                    markersPresent: shouldShowUndo,
                    message: message
                )
            }

        }
        .ignoresSafeArea()
        .environmentObject(meshViewStates)
        .environmentObject(assetFile)
    }
}
