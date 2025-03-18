//
//  PointsCaptureTabView.swift
//  DataFlorScanner
//  Based on PointCloudKit CaptureControlView with additional elements
//
//  Created by Chandana Murthy on 15.02.23.
//

import SwiftUI
import ModelIO
import SceneKit

struct PointsCaptureTabView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @Environment(\.dismiss) var dismiss
    @StateObject var model: PointsCaptureTabViewModel
    @StateObject var locationManager: LocationManager = LocationManager()
    @ObservedObject var arscnViewModel: ARSCNViewModel
    @Binding var shouldDismiss: Bool
    @State private var navigateToCaptureViewer: Bool = false
    @State private var showParameters: Bool = false
    @State private var showParameterControls: Bool = false
    @State private var showDeleteMarkersAlert = false
    @State private var clearNodes: Bool = false
    @State private var offset: Float = 0
    @State private var message: String = ""
    @State private var makeOrtho = false
    @State private var undoLast = false
    @State private var makePersp = false
    @State private var isOrtho = false
    @State private var orientation: Double?
    @State private var locationString: String?
    @State private var locCoordinateString: String?
    @State private var isScanning = false

    @State private var finalAsset: MDLAsset?
    @State private var measureNodes: [SCNNode]?
    @State private var camOrientation: Float3?

    var body: some View {
        VStack(spacing: 0) {
            if showParameters {
                PointsCaptureParametersView(model: model.captureParametersModel)

                Divider()
                    .padding(.bottom, 10)
            }

            controls
        }
        .navigationDestination(isPresented: $navigateToCaptureViewer) {
            if let asset = self.finalAsset {
                pointsViewerView(asset: asset)
            }
        }
        .alert(Strings.deleteAllMarkersConfirmation.localized(language), isPresented: $showDeleteMarkersAlert) {
            Button(role: .destructive) {
                arscnViewModel.deleteAllMarkers = true
            } label: {
                Text(Strings.delete.localized(language))
            }
        }
        .onChange(of: arscnViewModel.isMeshAvailable) { isMeshAvailable in
            if isMeshAvailable && orientation == nil {
                orientation = locationManager.lastHeading
                setLocation()
            }
        }
        .onChange(of: shouldDismiss, perform: { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        })
        .onDisappear {
            arscnViewModel.clearAll()
            model.hasCaptureData = nil
        }
    }

    var sceneView: SceneUIView {
        SceneUIView(offset: $offset, message: $message, clearMeasureNodes: $clearNodes, makeOrtho: $makeOrtho, makePerspective: $makePersp, undoLast: $undoLast, scene: model.scene)
    }

    var captureButton: some View {
        Button {
            if model.capturing {
                model.pauseCapture()
            } else {
                model.renderingService.capturing = true
            }
            isScanning = model.renderingService.capturing
        } label: {
            Image(systemName: model.renderingService.capturing ? "stop.circle" : "restart.circle")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(isScanning ? Color.basicColor : Color.dataFlorGreen)
        }
    }

    var controls: some View {
        HStack {
            HStack(spacing: 20) {
                settingsButton

                restartScanningButton
            }

            Spacer()

            captureButton

            Spacer()

            HStack(spacing: 20) {
                if !(arscnViewModel.measureNodes?.isEmpty ?? true) {
                    measureOperationsView
                        .transition(.opacity)
                }

                moveToViewModeButton
                    .padding(.leading, 8)
            }
        }

        // Toggle(isOn: $model.renderingService.capturing, label: { Text("") })
        // .toggleStyle(model.toggleStyle)
        .onChange(of: model.renderingService.capturing) { capturing in
            // if capturing {
            //   arscnViewModel.resumeSession()
            // } else {
            //   arscnViewModel.pauseSession()
            // }
            isScanning = capturing
        }
    }

    var measureOperationsView: some View {
        HStack(spacing: 20) {
            deleteMarkersButton

            undoButton
        }
    }

    var settingsButton: some View {
        Button(action: {
            withAnimation {
                showParameters.toggle()
            }
        }, label: {
            VStack {
                Image.slider
                    .font(.title2)
                    .scaleEffect(showParameters ? 0.9 : 1)
                    .padding(.bottom, 1.3)

                Text(Strings.settings.localized(language))
                    .font(.sansNeoLight(size: 12))
            }
            .foregroundStyle(showParameters ? Color.dataFlorGreen : Color.inactiveColor)
        })
    }

    var restartScanningButton: some View {
        let flushAllowed = model.hasCaptureData ?? false && arscnViewModel.isMeshAvailable
        return Button(action: {
            model.flushCapture()
        }, label: {
            VStack {
                Image.restart
                    .font(.title2)
                    .padding(.bottom, 1)

                Text(Strings.restart.localized(language))
                    .font(.sansNeoLight(size: 12))
            }
        })
        .foregroundStyle(flushAllowed ? .red : Color.disabledColor)
        .disabled(!flushAllowed)
    }

    var deleteMarkersButton: some View {
        Button {
            showDeleteMarkersAlert = true
        } label: {
            VStack {
                Image.trash
                    .font(.title2)
                    .padding(.bottom, 1)

                Text(Strings.measurements.localized(language))
                    .font(Font.sansNeoLight(size: 12))
            }
        }
        .foregroundStyle(Color.red)
    }

    var undoButton: some View {
        Button {
            arscnViewModel.undoLast = true
        } label: {
            VStack {
                Image.undo
                    .font(.title2)
                    .padding(.bottom, 1)

                Text(Strings.undo.localized(language))
                    .font(Font.sansNeoLight(size: 12))
            }
        }
        .foregroundStyle(Color.inactiveColor)
    }

    var moveToViewModeButton: some View {
        let canNavigateAhead =  model.hasCaptureData ?? false && arscnViewModel.isMeshAvailable

        return Button {
            FlashlightService.turnFlashlightOff()
            self.finalAsset = arscnViewModel.getAsset()
            self.camOrientation = arscnViewModel.cameraOrientation
            self.measureNodes = arscnViewModel.measureNodes
            model.pauseCapture()
            navigateToCaptureViewer = true
        } label: {
            VStack {
                Image.cubeTransparent
                    .font(.title)
                    .padding(.bottom, 0.2)

                Text(Strings.view.localized(language))
                    .font(.sansNeoRegular(size: 12))
            }

        }
        .foregroundStyle(canNavigateAhead ? Color.dataFlorGreen : Color.disabledColor)
        .disabled(!canNavigateAhead)
    }

    func pointsViewerView(asset: MDLAsset) -> PointsViewerView {
        PointsViewerView(
            model: model.getPointsViewerModel(measurementNodes: self.measureNodes, asset: asset, orientation: orientation),
            sceneView: sceneView,
            offset: $offset,
            message: $message,
            clearNodes: $clearNodes,
            shouldDismiss: $shouldDismiss,
            makeOrthographic: $makeOrtho,
            makePerspective: $makePersp,
            isOrtho: $isOrtho,
            undoLast: $undoLast,
            cameraOrientation: self.camOrientation,
            locationString: locationString,
            locCoordinateString: locCoordinateString
        )
    }

    func setLocation() {
        if locationString != nil && locCoordinateString != nil {
            return
        }
        locationString = locationManager.locationString
        locCoordinateString = locationManager.coordinateString
        locationManager.stopUpdatingLocation()
    }
}
