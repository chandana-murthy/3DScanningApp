//
//  PointsViewerTabView+Export.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 27.03.23.
//

import Foundation
import SwiftUI
import Common

extension PointsViewerTabView {
    var saveButton: some View {
        Button(action: {
            showSaveView = true
            processing = true
        }, label: {
            VStack {
                Image.save
                    .font(.largeTitle)
                    .foregroundStyle(processing ? Color.disabledColor : Color.dataFlorGreen)
                    .padding(.bottom, 0.4)

                Text(Strings.save.localized(language))
                    .font(.sansNeoRegular(size: 12))
                    .foregroundStyle(processing ? Color.disabledColor : Color.dataFlorGreen)
            }
        })
    }

    var exportButton: some View {
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

    var exportActionSheet: ActionSheet {
        var exportButtons = [ActionSheet.Button]()

        exportButtons.append(exportPlyButton)
        if self.objUrl != nil {
            exportButtons.append(exportObjButton)
        }
        exportButtons.append(.cancel())

        return ActionSheet(
            title: Text(Strings.exportType.localized(language)),
            message: Text(Strings.supportedExports.localized(language)),
            buttons: exportButtons
        )
    }

    func exportAsset() {
        isShareSheetPresented.toggle()
    }

    var exportPlyButton: ActionSheet.Button {
        ActionSheet.Button.default(
            Text("PLY (Polygon File Format)")
        ) {
            processing = true
            exportPLY = true
        }
    }

    var exportObjButton: ActionSheet.Button {
        ActionSheet.Button.default(
            Text("OBJ (Wavefront Object)")
        ) {
            exportAsset()
        }
    }

    func getPlyShareView() -> ActivityViewRepresentable {
        guard let file = getPlyFileUrl() else {
            fatalError("PointsViewerTabView: \(#function): failed to export PLY")
        }
        DispatchQueue.main.async {
            processing = false
        }
        return ActivityViewRepresentable(activityItems: [file as Any], applicationActivities: nil)
    }

    func getPlyFileUrl() -> URL? {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let plyName = "model_\(UUID().uuidString.prefix(5))_\(date).ply"
        let path = documentsPath.appendingPathComponent(plyName)

        do {
            try self.plyData?.write(to: path)
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            let file = fileURLs.first(where: {$0.absoluteString.contains(plyName)})
            return file
        } catch let error {
            print("PointsViewerTabView: \(error.localizedDescription)")
            return nil
        }
    }

}
