//
//  UsdzFileViewerView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 25.01.23.
//

import SwiftUI

struct UsdzFileViewerView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @EnvironmentObject var assetFile: AssetFile

    var body: some View {
        if let path = assetFile.usdzUrl {
            PreviewControllerRepresentable(url: path)
        } else {
            ProgressView {
                Text(Strings.pleaseWait.localized(language))
            }
            .font(.title2)
            .padding()
            .background(.black.opacity(0.3))
        }
    }
}
