//
//  PointsViewerView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 11.01.23.
//

import SwiftUI
import PointCloudRendererService
import SceneKit
import ModelIO

struct PointsViewerView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @EnvironmentObject var navigationUtils: NavigationUtils
    @Environment(\.dismiss) var dismiss
    @StateObject var model: PointsViewerViewModel

    @State var sceneView: SceneUIView
    @State private var showSaveScanView = false
    @State private var isSaved = false
    @State private var showSaveAlert = false
    @State private var showDeleteAlert = false
    @State private var measurePosition: Float = 0
    @State private var showProgress = false

    @Binding var offset: Float
    @Binding var message: String
    @Binding var clearNodes: Bool
    @Binding var shouldDismiss: Bool
    @Binding var makeOrthographic: Bool
    @Binding var makePerspective: Bool
    @Binding var isOrtho: Bool
    @Binding var undoLast: Bool

    var cameraOrientation: Float3?
    var locationString: String?
    var locCoordinateString: String?

    public var body: some View {
        VStack {
            scanView

            tabView
        }

        .navigationBarTitle(Strings.viewer.localized(language), displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                closeButton
            }
        }
        .sheet(isPresented: $showSaveScanView, onDismiss: {
            if isSaved { moveToRoot() }
        }) {
            savePointsView
        }

        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            // This converts the initial particle buffer into the first Object3D, triggering initial render.
            model.generateFirstObjectFromParticleBuffer()
        }
        .onDisappear {
            model.cancellables.forEach { cancellable in cancellable.cancel() }
        }
        .alert(Strings.alert.localized(language), isPresented: $showSaveAlert) {
            Button(Strings.yes.localized(language), role: .none) {
                moveToRoot()
            }
            cancelButton
        } message: {
            Text(Strings.scanNotSavedAlert.localized(language))
        }

        .alert(Strings.alert.localized(language), isPresented: $showDeleteAlert) {
            Button(Strings.yes.localized(language), role: .none) {
                clearNodes = true
                measurePosition = 0
                model.deleteAllMeasureNodes()
            }
            cancelButton
        } message: {
            Text(Strings.deleteAllMarkersConfirmation.localized(language))
        }
    }

    var scanView: some View {
        return SceneDisplayView(
            locationString: locationString,
            locCoordinateString: locCoordinateString,
            scene: model.scene,
            sceneView: sceneView,
            message: $message,
            showDeleteAlert: $showDeleteAlert,
            undoLast: $undoLast,
            showProgress: $showProgress
        )
    }

    var tabView: some View {
        PointsViewerTabView(
            model: model.pointsViewerTabModel,
            object: $model.object,
            showSaveView: $showSaveScanView,
            offset: $offset,
            message: $message,
            measurePosition: $measurePosition,
            makeOrthographic: $makeOrthographic,
            makePerspective: $makePerspective,
            isOrtho: $isOrtho,
            objUrl: model.objUrl,
            plyData: model.plyData
        )
        .padding(.bottom, 16)
        .background(Color.appModeColor.opacity(0.8))
    }

    var cancelButton: some View {
        Button(Strings.cancel.localized(language), role: .cancel) { }
    }

    var closeButton: some View {
        Button {
            if !isSaved {
                showSaveAlert = true
            } else {
                moveToRoot()
            }
        } label: {
            Image.xMark
                .foregroundStyle(Color.red)
                .font(.headline)
        }
    }

    var deleteMeasurementsButton: some View {
        return HStack {
            Spacer()

            Button {
                withAnimation {
                    showDeleteAlert = true
                }
            } label: {
                VStack {
                    Image.trash
                        .font(.title3)
                        .padding(.bottom, 4)
                    Text(Strings.measurements.localized(language))
                        .font(.sansNeoRegular(size: 11))
                }
            }
            .foregroundStyle(Color.red)
        }
    }

    var savePointsView: some View {
        return SavePointsScanView(
            isSaved: $isSaved,
            saveData: SaveData(
                imageData: sceneView.getSnapShot().jpegData(compressionQuality: 1),
                locationString: locationString,
                coordinateString: locCoordinateString,
                pointCloud: model.getPointCloud(),
                pointCount: model.renderingService.currentPointCount,
                scene: model.scene,
                objURL: model.objUrl,
                plyData: model.plyData,
                orientation: model.orientation,
                cameraOrientation: cameraOrientation,
                confidence: model.pointConfidence()
            ),
            offset: offset
        )
    }

    func moveToRoot() {
        shouldDismiss = true
        navigationUtils.path = NavigationPath()
    }
}
