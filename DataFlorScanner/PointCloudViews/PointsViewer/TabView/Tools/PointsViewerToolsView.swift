//
//  PointsViewerToolsView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 10.01.23.
//  Based on PointCloudKit
//

import SwiftUI
import PointCloudRendererService
import Common
import Combine

struct PointsViewerToolsView: View {
    let model: PointsViewerToolsViewModel

    @AppStorage(ProcessorParameters.storageKey) private var processorParameters = ProcessorParameters()
    @AppStorage("language") private var language = LocalizationService.shared.language

    @Binding var object: Object3D
    @Binding var processing: Bool

    @State var undoAvailable = false
    @State var lastObject: Object3D?
    @State var showError: Bool = false
    @State var error: Error?

    private let buttonSize = Font.title2
    private var processorsEnabled: Bool {
        !processing
    }

    var body: some View {
        HStack(spacing: 16) {
            voxelDSButton

            statisticalORButton

//            radiusORButton

            undoButton
                .padding(.leading, 8)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .transition(.moveAndFade)

        .alert(isPresented: $showError) {
            Alert(title: Text(Strings.error.localized(language)),
                  message: Text(error?.localizedDescription.localized(language) ?? Strings.unknown.localized(language)),
                  dismissButton: .default(Text(Strings.okay.localized(language))))
        }
    }

    var voxelDSButton: some View {
        Button {
            processing = true
            model.voxelDownSampling(object, parameters: processorParameters.voxelDownSampling)?
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: processingCompleted,
                      receiveValue: receivedFromProcessing)
                .store(in: &model.cancellables)
        } label: {
            VStack {
                Image.voxelDS
                    .font(.system(size: 25))
                Text("Voxel Down Sampling")
                    .font(.sansNeoStandard(size: 14))
            }
            .foregroundStyle(
                processorsEnabled ? Color.dataFlorGreen : .gray
            )
        }
        .disabled(!processorsEnabled)
    }

    var statisticalORButton: some View {
        Button {
            processing = true
            model.statisticalOutlierRemoval(object, parameters: processorParameters.outlierRemoval.statistical)?
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: processingCompleted,
                      receiveValue: receivedFromProcessing)
                .store(in: &model.cancellables)
        } label: {
            VStack {
                Image.statisticalOR
                    .font(buttonSize)
                Text("Statistical O.R.")
                    .font(.sansNeoStandard(size: 14))
            }
            .foregroundStyle(
                processorsEnabled ? Color.dataFlorGreen : Color.gray
            )
        }
        .disabled(!processorsEnabled)
    }

    var radiusORButton: some View {
        Button {
            processing = true
            model.radiusOutlierRemoval(object, parameters: processorParameters.outlierRemoval.radius)?
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: processingCompleted,
                      receiveValue: receivedFromProcessing)
                .store(in: &model.cancellables)
        } label: {
            VStack {
                Image.radiusOR
                    .font(buttonSize)
                    .padding(.bottom, 0.5)
                Text("Radius O.R")
                    .font(.sansNeoStandard(size: 14))
            }
            .foregroundStyle(
                processorsEnabled ? Color.dataFlorGreen : Color.gray
            )
        }
        .disabled(!processorsEnabled)
    }

    var undoButton: some View {
        Button(action: {
            undo()
        }, label: {
            VStack {
                Image.undo
                    .font(buttonSize)
                Text(Strings.undo.localized(language))
                    .font(.sansNeoStandard(size: 14))
            }
            .foregroundStyle(
                (undoAvailable && processorsEnabled) ? Color.dataFlorGreen : .gray
            )
        })
        .hiddenConditionally(!undoAvailable)
        .disabled(!processorsEnabled)
    }

    private func redraw() {
        model.redraw(object: object)
    }

    private func update(with object: Object3D) {
        lastObject = self.object
        self.object = object
        undoAvailable = true

        redraw()
    }

    func undo() {
        guard let lastObject = lastObject else { return }
        object = lastObject
        self.lastObject = nil
        undoAvailable = false

        redraw()
    }
}

extension PointsViewerToolsView {
    private func receivedFromProcessing(object: Object3D) {
        update(with: object)
    }

    private func processingCompleted(with result: Subscribers.Completion<ProcessorServiceError>) {
        processing = false
        switch result {
        case let .failure(error):
            self.error = error
            showError = true
        default:
            return
        }
    }
}
