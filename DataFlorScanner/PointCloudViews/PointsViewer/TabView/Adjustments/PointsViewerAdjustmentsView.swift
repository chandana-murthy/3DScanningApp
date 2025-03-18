//
//  PointsViewerAdjustmentsView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 10.01.23.
//

import SwiftUI
import PointCloudRendererService
import Common
import Combine

struct PointsViewerAdjustmentsView: View {
    let model: PointsViewerAdjustmentsViewModel
    @AppStorage(ProcessorParameters.storageKey) private var processorParameters = ProcessorParameters()
    @AppStorage("language") private var language = LocalizationService.shared.language

    @Binding var object: Object3D
    @Binding var processing: Bool

    @State var undoAvailable = false
    @State var showError: Bool = false
    @State var error: Error?
    @State var lastObject: Object3D?
    private var processorsEnabled: Bool {
        !processing
    }

    var body: some View {
        HStack(spacing: 16) {
            normalsButton

            surfaceReconstructionButton

            undoButton
            Spacer()
        }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .transition(.moveAndFade)
            .alert(isPresented: $showError) {
                Alert(title: Text(Strings.error.localized(language)),
                      message: Text(error?.localizedDescription.localized(language) ?? Strings.unknown.localized(language)),
                      dismissButton: .default(Text(Strings.okay.localized(language))))
            }
    }

    var normalsButton: some View {
        Button {
            processing = true
            model.normalsEstimation(object, parameters: processorParameters.normalsEstimation)?
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: processingCompleted,
                      receiveValue: receivedFromProcessing)
                .store(in: &model.cancellables)
        } label: {
            VStack {
                Image.normals
                    .font(.title)
                Text(Strings.normalEstimation.localized(language))
                    .font(.sansNeoStandard(size: 14))
            }
            .foregroundStyle(
                processorsEnabled ? Color.dataFlorGreen : .gray
            )
        }
        .disabled(!processorsEnabled)
    }

    var surfaceReconstructionButton: some View {
        Button {
            processing = true
            model.poissonSurfaceReconstruction(object, parameters: processorParameters.surfaceReconstruction.poisson)?
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: processingCompleted,
                      receiveValue: receivedFromProcessing)
                .store(in: &model.cancellables)
        } label: {
            VStack {
                Image.surfaceRecons
                    .font(.title2)
                Text(Strings.surfaceReconstruction.localized(language))
                    .font(.sansNeoStandard(size: 14))
            }
            .foregroundStyle(
                (processorsEnabled) ? Color.dataFlorGreen : .gray
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
                    .font(.title2)
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
        object.particles()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { particles in
                model.particleBuffer?.buffer.assign(with: particles)
            })
            .store(in: &model.cancellables)
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

// MARK: - Completion helper for processing functions
extension PointsViewerAdjustmentsView {
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
