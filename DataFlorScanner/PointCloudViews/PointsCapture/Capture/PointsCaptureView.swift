//
//  PointsCaptureView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 27.01.23.
//

import SwiftUI
import ModelIO
import ARKit
import AVFoundation

struct PointsCaptureView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @Environment(\.dismiss) var dismiss
    @StateObject var model: PointsCaptureViewModel
    @StateObject var arScnViewModel = ARSCNViewModel()
    @StateObject private var navigationUtils = NavigationUtils()
    @State private var shouldDismiss = false
    @State private var showCameraPermissionAlert = false

    var body: some View {
        ZStack {
            CaptureRenderingView(model: model.captureRenderingModel)

            ARViewRepresentable(
                arScnViewModel: arScnViewModel,
                session: model.renderingService.session
            )
            .opacity(0.5)

            VStack {
                MetricsView(model: model.metricsModel)

                Spacer()

                PointsCaptureTabView(
                    model: model.captureControlModel,
                    arscnViewModel: arScnViewModel,
                    shouldDismiss: $shouldDismiss
                )
                .padding(.top, 10)
                .padding(.bottom, 16)
                .padding(.horizontal, 20)
                .background(Color.appModeColor.opacity(0.8))
            }
        }
        .alert(Strings.error.localized(language), isPresented: $model.bufferCreationFailed) {
            Button(Strings.okay.localized(language), role: .none) {
                dismiss()
            }
        } message: {
            Text(Strings.unableToStartScan.localized(language))
        }

        .alert(Strings.enableCamera.localized(language), isPresented: $showCameraPermissionAlert) {
            Button(Strings.cancel.localized(language), role: .destructive) { self.dismiss() }
            Button(Strings.settings.localized(language), role: .cancel) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: { _ in })
                }
            }
        } message: {
            Text(Strings.enableCameraMsg.localized(language))
        }

        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(Strings.capture.localized(language))
        .ignoresSafeArea(edges: .bottom)

        .onChange(of: shouldDismiss, perform: { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        })

        .onAppear {
            if model.bufferCreationFailed {
                arScnViewModel.stopSession()
                model.pauseCapture()
            } else { // MARK: Locking and unlocking scanUI
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
//                UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation") // Forcing the rotation to portrait
                AppDelegate.orientationLock = .portrait // And making sure it stays that way
            }
            checkCameraAccess()
        }

        .onDisappear {
            AppDelegate.orientationLock = .all
        }
    }

    func checkCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            print("Denied, request permission from settings")
            showCameraPermissionAlert = true
        case .authorized:
            print("Authorized, proceed")
        default:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    print("Permission granted, proceed")
                } else {
                    showCameraPermissionAlert = true
                }
            }
        }
    }
}
