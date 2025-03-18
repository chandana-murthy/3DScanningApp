//
//  PointsViewerTabView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 09.01.23.
//

import SwiftUI
import PointCloudRendererService
import Common
import ModelIO
import Combine

struct PointsViewerTabView: View {
    @AppStorage("language") var language = LocalizationService.shared.language
    @StateObject var model: PointsViewerTabViewModel
    @Binding var object: Object3D
    @Binding var showSaveView: Bool
    @Binding var offset: Float
    @Binding var message: String
    @Binding var measurePosition: Float
    @Binding var makeOrthographic: Bool
    @Binding var makePerspective: Bool
    @Binding var isOrtho: Bool

    @State private var showCleanTools = false
    @State private var showReconstructionTools = false
    @State private var showViewTools = false
    @State var exportPLY = false
    @State var isShareSheetPresented = false
    @State var showExportTypeSelection = false
    @State var processing = false
    @State private var showPoints = true
    @State private var showMesh = false
    @State private var pointOpacity: Float = 1
    @State private var pointSize: Float = 0.007
    let date = Date().formatted(date: .numeric, time: .omitted)

    private let buttonSize = Font.largeTitle
    let objUrl: URL?
    let plyData: Data?

    var controlsSectionView: some View {
        HStack(spacing: 24) {
            // Adjust
            settingsButton

            // Voxel sampling, outlier removal
            cleaningToolsButton

            // normals, and surface construction
            reconstructionToolsButton

            orthoButton

            Spacer()

            saveButton

            exportButton
                .disabled(processing)
        }
    }

    var body: some View {
        VStack {
            if model.exportService?.exporting ?? false {
                exportingView
            }

            if processing {
                processingView
            }

            // normals and surface construction
            if showReconstructionTools {
                PointsViewerAdjustmentsView(
                    model: model.reconstructionModel,
                    object: $object,
                    processing: $processing)
            }

            // Voxel sampling, outlier removal
            if showCleanTools {
                PointsViewerToolsView(
                    model: model.cleanersModel,
                    object: $object,
                    processing: $processing)
            }

            if showViewTools {
                toolsView
                    .disabled(processing)
            }

            Divider()
            controlsSectionView
                .padding(.top, 8)
                .padding(.bottom, 16)
                .padding(.horizontal, 24)
        }

        .onChange(of: showSaveView, perform: { showSaveView in
            if !showSaveView {
                processing = false
            }
        })
        .sheet(isPresented: $isShareSheetPresented) {
            let modelPath = model.customModelPath ?? URL(string: "")
            ActivityViewRepresentable(activityItems: [modelPath as Any], applicationActivities: nil)
        }
        .sheet(isPresented: $exportPLY, content: {
            getPlyShareView()
        })
        .fileExporter(
            isPresented: $exportPLY,
            document: model.exportService?.generatePLYFile(from: object),
            contentType: .polygon,
            onCompletion: { _ in }
        )
        .onDisappear {
            model.cancellables.forEach { cancellable in
                cancellable.cancel()
            }
        }
    }

    private func redraw() {
        processing = true
        object.particles()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { particles in
                model.particleBuffer?.buffer.assign(with: particles)
                processing = false
            })
            .store(in: &model.cancellables)
    }
}

// MARK: - Others
extension PointsViewerTabView {
    var toolsView: some View {
        PointsViewerSettingsView(model: model, processing: $processing, offset: $offset, showPoints: $showPoints, showMesh: $showMesh, pointOpacity: $pointOpacity, pointSize: $pointSize, measurePosition: $measurePosition)
            .padding(.top, 10)
            .transition(.moveAndFade)
    }
}

// MARK: - Parameters Buttons
extension PointsViewerTabView {
    var settingsButton: some View {
        Button {
            withAnimation {
                showViewTools.toggle()
                showCleanTools = false
                showReconstructionTools = false
            }
        } label: {
            VStack {
                Image.slider
                    .font(buttonSize)
                    .scaleEffect(showViewTools ? 0.9 : 1)
                    .padding(.bottom, 0.5)

                Text(Strings.settings.localized(language))
                    .font(.sansNeoRegular(size: 12))
            }
        }
        .foregroundStyle(showViewTools ? Color.dataFlorGreen : Color.inactiveColor)
    }

    var cleaningToolsButton: some View {
        Button {
            withAnimation {
                showCleanTools.toggle()
                showReconstructionTools = false
                showViewTools = false
            }
        } label: {
            VStack {
                Image.scissors
                    .font(buttonSize)
                    .scaleEffect(showCleanTools ? 0.9 : 1)
                    .padding(.bottom, 0.5)

                Text(Strings.tools.localized(language))
                    .font(.sansNeoRegular(size: 12))
            }
        }
        .foregroundStyle(showCleanTools ? Color.dataFlorGreen : Color.inactiveColor)
    }

    var reconstructionToolsButton: some View {
        Button {
            withAnimation {
                showReconstructionTools.toggle()
                showCleanTools = false
                showViewTools = false
            }
        } label: {
            VStack {
                Image.wrench
                    .font(.title)
                    .scaleEffect(showReconstructionTools ? 0.9 : 1)
                    .padding(.bottom, 0.5)

                Text(Strings.adjustments.localized(language))
                    .font(.sansNeoRegular(size: 12))
            }
        }
        .foregroundStyle(showReconstructionTools ? Color.dataFlorGreen : Color.inactiveColor)
    }

    var orthoButton: some View {
        Button {
            if isOrtho {
                makePerspective = true
            } else {
                makeOrthographic = true
            }
            isOrtho.toggle()
        } label: {
            VStack {
                Image(systemName: isOrtho ? "pyramid" : "cube")
                    .font(.title)
                    .padding(.bottom, 1)
                Text(isOrtho ? Strings.perspective : Strings.orthographic)
                    .font(.sansNeoRegular(size: 12))
            }
            .tint(Color.inactiveColor)
        }
    }
}

// MARK: - Processing info views
extension PointsViewerTabView {
    var processingView: some View {
        ProgressView(Strings.processing.localized(language))
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .cornerRadius(16, corners: [.topLeft, .topRight])
            .foregroundStyle(Color.dataFlorGreen)
    }

    var exportingView: some View {
        ProgressView("\(model.exportService?.info ?? "")",
                     value: model.exportService?.exportProgress)
        .padding(20)
        .cornerRadius(16, corners: [.topLeft, .topRight])
        .foregroundStyle(Color.dataFlorGreen)
    }
}
