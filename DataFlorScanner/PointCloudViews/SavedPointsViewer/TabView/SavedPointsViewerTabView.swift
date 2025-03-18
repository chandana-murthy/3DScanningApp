//
//  SavedPointsViewerTabView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 16.03.23.
//

import SwiftUI

struct SavedPointsViewerTabView: View {
    @Environment(\.managedObjectContext) private var managedContext
    @AppStorage("language") private var language = LocalizationService.shared.language
    @StateObject var model: PointsViewerTabViewModel
    @State private var showViewTools = false
    @State private var processing = false
    @State private var showExportTypeSelection = false
    @State private var exportPLY = false
    @State private var customModelPath: URL?
    @State private var isShareSheetPresented = false
    @State private var showPoints = true
    @State private var showMesh = false
    @State private var pointOpacity: Float = 1
    @State private var pointSize: Float = 0.007
    @Binding var measurePosition: Float
    @Binding var offset: Float
    @Binding var showFileCorruptError: Bool
    @Binding var saveScan: Bool
    @Binding var makeOrthographic: Bool
    @Binding var makePerspective: Bool
    @Binding var isOrtho: Bool
    let date = Date().formatted(date: .numeric, time: .omitted)
    let fileManager = FileManager.default
    let plyData: Data?
    let meshUrl: URL?
    let scanName: String

    var body: some View {
        VStack {
            if showViewTools {
                PointsViewerSettingsView(model: model, processing: $processing, offset: $offset, showPoints: $showPoints, showMesh: $showMesh, pointOpacity: $pointOpacity, pointSize: $pointSize, measurePosition: $measurePosition)
                    .transition(.moveAndFade)
            }

            Divider()
                .overlay(Color.basicColor.opacity(0.1))

            HStack(spacing: 16) {
                settingsButton

                orthoButton

                Spacer()

                saveButton

                downloadButton
                    .disabled(processing)

            }
            .padding(.top, 4)
        }

        .sheet(isPresented: $exportPLY) {
            getPlyShareView()
        }

        .sheet(isPresented: $isShareSheetPresented) {
            let modelPath = customModelPath ?? URL(fileURLWithPath: "")
            ActivityViewRepresentable(activityItems: [modelPath as Any], applicationActivities: nil)
        }
    }

    var settingsButton: some View {
        Button {
            withAnimation {
                showViewTools.toggle()
            }
        } label: {
            VStack {
                Image.slider
                    .font(.title)
                    .scaleEffect(showViewTools ? 0.9 : 1)
                    .padding(.bottom, 1)

                Text(Strings.settings.localized(language))
                    .font(.sansNeoRegular(size: 12))
            }
            .foregroundStyle(showViewTools ? Color.dataFlorGreen : Color.inactiveColor)
        }
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
                    .font(.title2)
                    .padding(.bottom, 1)
                Text(isOrtho ? Strings.perspective : Strings.orthographic)
                    .font(.sansNeoRegular(size: 12))
            }
            .tint(Color.inactiveColor)
        }
    }

    var saveButton: some View {
        Button(action: {
            saveScan = true
        }, label: {
            VStack {
                Image.save
                    .font(.largeTitle)
                    .foregroundStyle(processing ? Color.disabledColor : Color.dataFlorGreen)
                    .padding(.bottom, 1)

                Text(Strings.save.localized(language))
                    .font(.sansNeoRegular(size: 12))
                    .foregroundStyle(processing ? Color.disabledColor : Color.dataFlorGreen)
            }
        })
    }

    var downloadButton: some View {
        Button(action: {
            withAnimation {
                showExportTypeSelection = true
            }
        }, label: {
            VStack {
                Image.export
                    .font(.title)
                    .foregroundStyle(processing ? Color.disabledColor : .blue)
                    .padding(.bottom, 2)

                Text(Strings.export.localized(language))
                    .font(.sansNeoRegular(size: 12))
                    .foregroundStyle(processing ? Color.disabledColor : .blue)
            }
        })
        .actionSheet(isPresented: $showExportTypeSelection) {
            exportActionSheet
        }
    }

    var exportPlyButton: ActionSheet.Button {
        ActionSheet.Button.default(
            Text("PLY (Polygon File Format)")
        ) {
            if getPlyFileUrl().0 == nil {
                showFileCorruptError = true
            } else {
                exportPLY = true
            }
        }
    }

    var exportObjButton: ActionSheet.Button {
        ActionSheet.Button.default(
            Text("OBJ (Wavefront Object)")
        ) {
            if meshUrl == nil {
                showFileCorruptError = true
            } else {
                exportAsset()
            }
        }
    }

    var exportActionSheet: ActionSheet {
        var exportButtons = [ActionSheet.Button]()
        exportButtons.append(exportPlyButton)
        exportButtons.append(exportObjButton)
        exportButtons.append(.cancel())

        return ActionSheet(
            title: Text(Strings.exportType.localized(language)),
            message: Text(Strings.supportedExports.localized(language)),
            buttons: exportButtons
        )
    }

    func exportAsset() {
        guard let url = meshUrl else {
            showFileCorruptError = true
            return
        }
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        do {
            customModelPath = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil).first(where: {$0.absoluteString.contains(url.absoluteString)})
            isShareSheetPresented = true
        } catch let error {
            print("SavedPointsViewerView: \(error.localizedDescription)")
            showFileCorruptError = true
        }
    }

    func getPlyShareView() -> ActivityViewRepresentable {
        if let file = getPlyFileUrl().0 {
            return ActivityViewRepresentable(activityItems: [file as Any, getPlyFileUrl().1 as Any], applicationActivities: nil)
        }
        fatalError("Flow should not come here")
    }

    func getPlyFileUrl() -> (URL?, URL?) {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let scanName = scanName.replacingOccurrences(of: " ", with: "_")
        let docName = "\(scanName)_\(UUID().uuidString.prefix(5))_\(date)"
        let path = documentsPath.appendingPathComponent("\(docName).ply")

        do {
            try plyData?.write(to: path)
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            let file = fileURLs.first(where: {$0.absoluteString.contains("\(docName).ply")})
            let measureFile = getMeasurementPlyFileUrl(docName: docName)
            return (file, measureFile)
        } catch let error {
            print("SavedPointsViewerView: \(error.localizedDescription)")
            return (nil, nil)
        }
    }

    func getMeasurementPlyFileUrl(docName: String) -> URL? {
        if !model.areMeasureSpheresAvailable() {
            return nil
        }

        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let measurementPLYData = MeasurementPolygonFileFormat.generateAsciiData(using: model.getOnlyMeasureSpheres())
        let measureScanName = "\(docName)_measurements"
        let measurePath = documentsPath.appendingPathComponent("\(measureScanName).ply")
        do {
            try measurementPLYData?.write(to: measurePath)
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            let measureFile = fileURLs.first(where: {$0.absoluteString.contains("\(measureScanName).ply")})
            return measureFile
        } catch let error {
            print("SavedPointsViewerView: #getMeasurementPlyFileUrl \(error.localizedDescription)")
            return nil
        }
    }
}
