//
//  PreviewControllerRepresentable.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 26.12.22.
//

import UIKit
import SwiftUI
import QuickLook

struct PreviewControllerRepresentable: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {
        uiViewController.reloadData()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: QLPreviewControllerDataSource {
        let parent: PreviewControllerRepresentable

        init(parent: PreviewControllerRepresentable) {
            self.parent = parent
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return parent.url as QLPreviewItem
        }
    }
}
