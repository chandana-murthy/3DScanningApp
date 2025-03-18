//
//  SavedMeshViewerView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 28.12.22.
//

import SwiftUI
import ARKit

struct SavedMeshViewerView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @Environment(\.dismiss) var dismiss
    var scan: MeshScan
    @State private var isShareSheetPresented = false
    @State private var showAlert = false
    @Binding var deleteMesh: Bool

    var dateCreatedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.LONG_DATE_FORMAT
        return formatter.string(from: scan.dateCreated)
    }

    var body: some View {
        VStack(spacing: 8) {
            headerView
                .padding([.top, .leading, .trailing], 24)

            Divider()
                .overlay(Color.dataFlorGreen)

            ZStack {
                usdzView
                    .frame(width: UIScreen.main.bounds.width)

                locationView

            }
            Spacer()

        }

        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                deleteButton
                    .font(.caption)
            }
        }

        .alert(Strings.deleteConfirmation.localized(language),
               isPresented: $showAlert) {
            Button(role: .destructive) {
                self.dismiss()
                deleteMesh = true
            } label: {
                Text(Strings.delete.localized(language))
            }
        }
    }

    var headerView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(scan.name)
                    .font(.sansNeoBold(size: 24))

                Spacer()

//                downloadButton
            }
            HStack {
                Text(self.scan.scanDescription)

                Spacer()

                Text("\(Strings.createdOn.localized(language)) \(self.dateCreatedString)")
            }
            .font(.sansNeoRegular(size: 16))
        }
    }

    var usdzView: some View {
        PreviewControllerRepresentable(url: scan.usdzUrl)
    }

    var locationView: some View {
        VStack {
            HStack {
                Spacer()

                LocationMetricsView(
                    locationString: scan.locationString,
                    locCoordinateString: scan.locCoordinateString
                )
                .padding(.trailing, 16)
            }
            Spacer()
        }
    }

    var deleteButton: some View {
        Button {
            showAlert = true
        } label: {
            Image.trash
                .foregroundStyle(Color.red)
        }
    }

    func exportAsset(format: ExportFormat) {
//        let fileExtension = format.rawValue.lowercased()
//        let date = scan.dateCreated.formatted(date: .numeric, time: .omitted)
//        var customModelPath: URL
//        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        if format == .usdz {
//            customModelPath = scan.usdzUrl
            // need to figure out a way to export here without having the scene.
//        } else {
//            customModelPath = documentsPath.appendingPathComponent("model_\(date).\(fileExtension)")
//            do {
//                let asset = MDLAsset(url: scan.assetUrl)
//                try asset.export(to: customModelPath)
//            } catch let error {
//                print("MeshViewerView: \(error.localizedDescription)")
//            }
            // How to export here?
//        }
//        isShareSheetPresented.toggle()
    }
}
