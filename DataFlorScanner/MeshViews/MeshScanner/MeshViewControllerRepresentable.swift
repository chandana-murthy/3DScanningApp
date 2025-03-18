//
//  MeshViewControllerRepresentable.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 19.12.22.
//

import Foundation
import SwiftUI
import ARKit

struct MeshViewControllerRepresentable: UIViewControllerRepresentable {
    @Binding var message: String
    @Binding var errorMessage: String?
    @Binding var shouldShowUndo: Bool
    @EnvironmentObject var meshViewStates: MeshViewStates
    @EnvironmentObject var assetFile: AssetFile

    func makeUIViewController(context: Context) -> some MeshViewController {
        let viewController = MeshViewController()
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        if meshViewStates.undoLast {
            uiViewController.performOnUndo()
            DispatchQueue.main.async {
                meshViewStates.undoLast = false
            }
        }
        if meshViewStates.deleteAllMarkers {
            uiViewController.clearAllMeasureNodes()
            DispatchQueue.main.async {
                meshViewStates.deleteAllMarkers = false
                context.coordinator.shouldShowUndo(false)
            }
        }
        if meshViewStates.cameraStateChanged {
            uiViewController.changePauseState(paused: !meshViewStates.cameraButtonActive)
            DispatchQueue.main.async {
                meshViewStates.cameraStateChanged = false
            }
        }
        if meshViewStates.goToViewer {
            uiViewController.moveToViewMode()
            DispatchQueue.main.async {
                meshViewStates.goToViewer = false
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, MeshViewControllerDelegate {
        private(set) var parent: MeshViewControllerRepresentable

        init(_ parent: MeshViewControllerRepresentable) {
            self.parent = parent
        }

        func isMeshAvailable(_ isAvailable: Bool) {
            parent.meshViewStates.isMeshAvailable = isAvailable
        }

        func updateMessages(message: String, errorMessage: String?) {
            parent.$message.wrappedValue = message
            parent.$errorMessage.wrappedValue = errorMessage
        }

        func didChangeSessionState(_ isPaused: Bool) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.meshViewStates.cameraButtonActive = !isPaused
            }
        }

        func shouldShowUndo(_ showUndo: Bool) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.$shouldShowUndo.wrappedValue = showUndo
            }
        }

        func assetUpdated(_ asset: AssetFile) {
            DispatchQueue.main.async { [weak self] in
                self?.parent.assetFile.path = asset.path
                self?.parent.assetFile.asset = asset.asset
                self?.parent.assetFile.format = asset.format
                self?.parent.assetFile.assetImage = asset.assetImage
                self?.parent.assetFile.usdzUrl = asset.usdzUrl
            }
        }
    }
}
