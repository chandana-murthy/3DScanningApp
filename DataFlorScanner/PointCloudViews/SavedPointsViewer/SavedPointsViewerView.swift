//
//  SavedPointsViewerView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 04.12.22.
//

import SwiftUI
import PointCloudRendererService
import SceneKit
import ARKit
import MetalKit
import Common

struct SavedPointsViewerView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @Environment(\.managedObjectContext) var managedContext
    @Environment(\.dismiss) var dismiss
    @StateObject var model: SavedPointsViewerViewModel

    @State private var isDisplayingShareSheet = false
    @State private var showFileCorruptError = false
    @State private var shouldSaveScan = false
    @State private var showProgress = false
    @State private var showAlert = false
    @State private var showDeleteAlert = false
    @State private var showCloseAlert = false
    @State private var offset: Float = 0
    @State private var message: String = ""
    @State private var clearNodes = false
    @State private var saved = false
    @State private var makeOrthographic = false
    @State private var makePerspective = false
    @State private var measurePosition: Float = 0
    @State private var isOrtho = false
    @State private var undoLast = false
    @Binding var deletePointsScan: Bool
    var scan: Scan

    var dateCreatedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.LONG_DATE_FORMAT
        if let dateCreated = self.scan.dateCreated {
            return formatter.string(from: dateCreated)
        }
        return ""
    }

    var body: some View {
        VStack(spacing: 8) {
            headerView
                .padding([.top, .leading], 24)
                .padding(.trailing, 22)

            Divider()
                .overlay(Color.dataFlorGreen)

            scanView

            tabView
        }

        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                deleteButton
            }
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }

        .alert(Strings.deleteConfirmation.localized(language), isPresented: $showAlert) {
            Button(role: .destructive) {
                self.dismiss()
                deletePointsScan = true
            } label: {
                Text(Strings.delete.localized(language))
            }
        }

        .alert(Strings.alert.localized(language), isPresented: $showDeleteAlert) {
            cancelButton
            Button(Strings.delete.localized(language), role: .destructive) {
                model.deleteAllMeasureNodes()
                measurePosition = 0
                clearNodes = true
            }
        } message: {
            Text(Strings.deleteAllMarkersConfirmation.localized(language))
        }

        .alert(Strings.alert.localized(language), isPresented: $showCloseAlert) {
            cancelButton
            Button(Strings.yes.localized(language), role: .destructive) {
                dismiss()
            }
        } message: {
            Text(Strings.changesNotSavedAlert.localized(language))
        }

        .alert(Strings.error.localized(language), isPresented: $showFileCorruptError) {
            okayButton
        } message: {
            Text(Strings.fileCorrupted.localized(language))
        }

        .alert(Strings.saveChangesAsk.localized(language), isPresented: $shouldSaveScan) {
            cancelButton
            Button(Strings.save.localized(language), role: .none) {
                saveScan()
            }
        } message: {
            Text(Strings.sureYouWantToSaveChanges.localized(language))
        }

        .alert(Strings.scanSaved.localized(language), isPresented: $saved) {
            okayButton
        }
        .navigationTitle(Strings.viewer.localized(language))
        .navigationBarBackButtonHidden(true)
    }

    var scanView: some View {
        if !model.sceneNodeAvailable() {
            return AnyView(PointCloudVisualizationHostView(pointCloud: scan.pointCloud))
        }
        return AnyView(SceneDisplayView(
            locationString: scan.locationString,
            locCoordinateString: scan.locCoordinateString,
            scene: model.scene,
            sceneView: sceneView,
            message: $message,
            showDeleteAlert: $showDeleteAlert,
            undoLast: $undoLast,
            showProgress: $showProgress
        ))
    }

    var sceneView: SceneUIView {
        SceneUIView(offset: $offset, message: $message, clearMeasureNodes: $clearNodes, makeOrtho: $makeOrthographic, makePerspective: $makePerspective, undoLast: $undoLast, scene: model.scene)
    }

    var cancelButton: some View {
        Button(Strings.cancel.localized(language), role: .cancel) { }
    }
    var okayButton: some View {
        Button(Strings.okay.localized(language), role: .none) { }
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(self.scan.name)
                    .font(.sansNeoBold(size: 24))

                Spacer()

            }
            HStack {
                if !scan.scanDescription.isEmpty {
                    Text(self.scan.scanDescription)

                    Spacer()
                }

                Text("\(Strings.createdOn.localized(language)) \(self.dateCreatedString)")
            }
            .font(.sansNeoRegular(size: 16))
        }
    }

    var tabView: some View {
        return SavedPointsViewerTabView(
            model: model.tabViewModel,
            measurePosition: $measurePosition,
            offset: $offset,
            showFileCorruptError: $showFileCorruptError,
            saveScan: $shouldSaveScan,
            makeOrthographic: $makeOrthographic,
            makePerspective: $makePerspective,
            isOrtho: $isOrtho,
            plyData: scan.plyData,
            meshUrl: scan.meshUrl,
            scanName: scan.name
        )
        .padding(.bottom, 16)
        .padding(.top, 8)
        .padding(.horizontal, 20)
        .background(Color.appModeColor.opacity(0.8))
    }

    var deleteButton: some View {
        Button {
            showAlert = true
        } label: {
            Image.trash
                .foregroundStyle(Color.red)
        }
        .font(.subheadline)
    }

    var backButton: some View {
        Button {
            if model.newMeasurementsAdded() {
                showCloseAlert = true
            } else {
                dismiss()
            }
        } label: {
            HStack {
                Image(systemName: "chevron.backward")
                Text(Strings.back.localized(language))
            }
        }
    }

    var deleteMeasurementsButton: some View {
        HStack {
            Spacer()

            Button {
                withAnimation {
                    showDeleteAlert = true
                }
            } label: {
                VStack {
                    Image.trash
                        .font(.title2)
                        .padding(.bottom, 4)

                    Text(Strings.measurements.localized(language))
                        .font(.sansNeoRegular(size: 11))
                }
            }
            .foregroundStyle(Color.red)
            .hiddenConditionally(!model.areMeasurementsAvailable())
        }
    }

    var locationView: some View {
        VStack {
            HStack {
                Spacer()

                LocationMetricsView(
                    locationString: scan.locationString,
                    locCoordinateString: scan.locCoordinateString,
                    includeBorder: true
                )
                .padding(.trailing, 16)
            }
        }
    }

    func deviceAvailable() -> Bool {
        if MTLCreateSystemDefaultDevice() != nil {
            return true
        }
        return false
    }

    func saveScan() {
        showProgress = true
        managedContext.performAndWait {
            do {
                scan.sceneData = model.getDataOfScene(offset: offset)
                model.changeMeasurementPosition(position: offset)
                try managedContext.save()
            } catch let error {
                print("SavedPointsViewerView: \(error.localizedDescription)")
            }
        }
        showProgress = false
        model.initialMeasureCount = model.getMeasureCount()
        saved = true
    }
}
