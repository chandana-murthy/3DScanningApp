//
//  MeshViewerMainView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 25.01.23.
//

import SwiftUI
import ModelIO

struct MeshViewerMainView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var assetFile: AssetFile
    @EnvironmentObject var navigationUtils: NavigationUtils

    @State private var openSaveSheet = false
    @State private var isSaved = false
    @State private var customModelPath: URL?
    @State private var isShareSheetPresented = false

    var body: some View {
        VStack {
            headerView
                .padding([.horizontal, .top], 24)
                .font(.title)

            ZStack {
                MeshViewerView()

                locationView
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isShareSheetPresented) {
            let modelPath = customModelPath ?? assetFile.path?.appendingPathComponent("scene.usdz")
            ActivityViewRepresentable(activityItems: [modelPath as Any], applicationActivities: nil)
        }

        .sheet(isPresented: $openSaveSheet, onDismiss: {
            if isSaved {
                navigationUtils.path = NavigationPath()
            }
        }) {
            SaveMeshScanView(
                isSaved: $isSaved,
                imageData: assetFile.assetImage,
                locationString: locationManager.locationString,
                coordinateString: locationManager.coordinateString,
                usdzUrl: assetFile.usdzUrl
            )
        }
    }

    var locationView: some View {
        VStack {
            HStack {
                Spacer()

                LocationMetricsView(
                    locationString: locationManager.locationString,
                    locCoordinateString: locationManager.coordinateString
                )
                .padding(.trailing, 24)
            }
            Spacer()
        }
    }

    var headerView: some View {
        HStack {
            closeButton

            Spacer()

            downloadOptionsMenu
                .disabled(assetFile.path == nil)
        }
    }

    var closeButton: some View {
        Button {
            isSaved
            ? navigationUtils.path = NavigationPath()
            : (openSaveSheet = true)
        } label: {
            Image.xMark
                .foregroundStyle(Color.red)
        }
    }

    var downloadOptionsMenu: some View {
        Menu {
            ForEach(ExportFormat.allValues, id: \.self) { format in
                Button(format.rawValue) {
                    assetFile.format = format
                    exportAsset()
                }
            }
        } label: {
            Image.export
        }
    }

    func exportAsset() {
        guard let path = assetFile.path else {
            print("MeshViewerView: This should not have been called, since menu is disabled till path is available")
            return
        }
        let date = Date().formatted(date: .numeric, time: .omitted)
        if assetFile.format == .usdz {
            customModelPath = assetFile.usdzUrl
        } else {
            customModelPath = path.appendingPathComponent("model_\(date).\(assetFile.format.rawValue.lowercased())")
            print("CAN export format \(assetFile.format.rawValue): \(MDLAsset.canExportFileExtension("dae"))")
            do {
                try assetFile.asset.export(to: customModelPath!)
            } catch let error {
                print("MeshViewerView: \(error.localizedDescription)")
            }
        }
        isShareSheetPresented.toggle()
    }
}
