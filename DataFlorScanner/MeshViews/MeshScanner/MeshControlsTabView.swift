//
//  MeshControlsTabView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 21.12.22.
//

import SwiftUI

struct MeshControlsTabView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @EnvironmentObject var meshViewStates: MeshViewStates
    @EnvironmentObject var assetFile: AssetFile

    @State var flashlightOn = false
    @State private var showDeleteMarkersAlert = false

    var markersPresent: Bool
    var message: String

    var body: some View {
        VStack(spacing: 0) {
            if !message.isEmpty {
                messageView
                    .transition(.opacity)
            }

            ZStack {
                Rectangle()
                    .fill(.black.opacity(0.3))
                    .frame(height: 102)
                HStack {
                    flashlightButton
                        .padding([.leading, .trailing], 16)
                        .padding(.bottom, 8)

                    if markersPresent {
                        HStack {
                            undoButton
                                .padding(.trailing, 16)

                            deleteMarkersButton
                        }
                        .transition(.opacity)
                    }

                    Spacer()

                    cameraButton
                        .padding(.bottom, 24)

                    Spacer()

                    goToViewerButton
                        .padding(.trailing, 16)
                        .padding(.bottom, 8)
                }
            }
        }
        .alert(Strings.deleteAllMarkersConfirmation.localized(language), isPresented: $showDeleteMarkersAlert) {
            Button(role: .destructive) {
                meshViewStates.deleteAllMarkers = true
            } label: {
                Text(Strings.delete.localized(language))
            }
        }
    }

    var flashlightButton: some View {
        Button {
            flashlightOn = FlashlightService.toggleFlashlight()
        } label: {
            let image = flashlightOn ? Image.flashlightOn : Image.flashlightOff
            image
                .font(.title)
                .foregroundStyle(Color.dataFlorGreen)
        }
    }

    var deleteMarkersButton: some View {
        Button {
            showDeleteMarkersAlert = true
        } label: {
            Image.trash
                .font(.title)
                .foregroundStyle(Color.red)
        }
    }

    var undoButton: some View {
        VStack {
            Button {
                meshViewStates.undoLast = true
            } label: {
                Image.undo
                    .font(.title)
                    .foregroundStyle(Color.dataFlorGreen)
            }

            Text(Strings.undo.localized(language))
                .font(Font.sansNeoRegular(size: 8))
        }
    }

    var cameraButton: some View {
        Button {
            meshViewStates.cameraButtonActive.toggle()
            meshViewStates.cameraStateChanged = true
        } label: {
            let name = meshViewStates.cameraButtonActive ? "stop.circle" : "restart.circle"
            Image(systemName: name)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(meshViewStates.cameraButtonActive ? .red : .white)
        }
    }

    var goToViewerButton: some View {
        NavigationLink {
            MeshViewerMainView()
                .environmentObject(assetFile)
                .onAppear {
                    FlashlightService.turnFlashlightOff()
                    meshViewStates.goToViewer = true
                }
        } label: {
            Image.cubeTransparent
                .font(.title)
                .foregroundStyle(meshViewStates.isMeshAvailable ? Color.dataFlorGreen : Color.disabledColor)
        }
        .disabled(!meshViewStates.isMeshAvailable)
    }

    var messageView: some View {
        Rectangle()
            .fill(.black.opacity(0.3))
            .frame(height: 40)
            .overlay(alignment: .trailing, content: {
                Text(message.localized(language))
                    .font(Font.sansNeoRegular(size: 13))
                    .foregroundStyle(Color.white)
                    .padding([.trailing], 8)
            })
    }
}
