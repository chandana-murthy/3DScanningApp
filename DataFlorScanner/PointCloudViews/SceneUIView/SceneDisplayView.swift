//
//  SceneDisplayView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 02.08.23.
//

import SwiftUI
import SceneKit

struct SceneDisplayView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("language") private var language = LocalizationService.shared.language
    var locationString: String?
    var locCoordinateString: String?
    var scene: SCNScene
    @State var sceneView: SceneUIView
    @Binding var message: String
    @Binding var showDeleteAlert: Bool
    @Binding var undoLast: Bool
    @Binding var showProgress: Bool

    var body: some View {
        ZStack {
            sceneView

            VStack {
                locationView

                measureOperationsView

                Spacer()

                if showProgress {
                    progressView
                }

                messageView(message: message.localized(language), color: .red)
                    .hiddenConditionally(message.isEmpty)
                    .padding(.bottom, -8)
            }
        }
    }

    var locationView: some View {
        VStack {
            HStack {
                Spacer()

                LocationMetricsView(
                    locationString: locationString,
                    locCoordinateString: locCoordinateString,
                    includeBorder: true
                )
                .padding(.trailing, 16)
            }
        }
    }

    var measureOperationsView: some View {
        if sizeClass == .regular {
            return AnyView(iPadMeasureView)
        } else {
            return AnyView(iPhoneMeasureView)
        }
    }

    var iPadMeasureView: some View {
        HStack {
            Spacer()

            VStack(spacing: 12) {
                Text(Strings.measurements.localized(language))
                    .font(.sansNeoRegular(size: 10))
                    .foregroundStyle(Color.basicColor)

                HStack(spacing: 32) {
                    deleteMeasurementsButton

                    undoButton
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 144, height: 96)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.lightGray.opacity(0.7), lineWidth: 1)
                    .frame(width: 144, height: 96)
            )
            .hiddenConditionally(!areMeasurementsAvailable())
        }
        .padding([.top, .trailing], 48)
    }

    var iPhoneMeasureView: some View {
        HStack {
            Spacer()

            VStack(spacing: 12) {
                Text("Measures") // no need to localise. Need the same word in all languages
                    .font(.sansNeoRegular(size: 10))
                    .foregroundStyle(Color.basicColor)

                    deleteMeasurementsButton

                    undoButton
            }
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 80, height: 184)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.lightGray.opacity(0.7), lineWidth: 1)
                    .frame(width: 80, height: 184)
            )
            .hiddenConditionally(!areMeasurementsAvailable())
        }
        .padding([.top, .trailing], 48)
    }

    var deleteMeasurementsButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            VStack {
                Image.trash
                    .font(.title2)
                    .padding(.bottom, 2)

                Text(Strings.delete.localized(language))
                    .font(.sansNeoRegular(size: 10))
            }
        }
        .foregroundStyle(Color.red)
    }

    var undoButton: some View {
        Button {
            undoLast = true
        } label: {
            VStack {
                Image.undo
                    .font(.title2)
                    .padding(.bottom, 2)

                Text(Strings.undo.localized(language))
                    .font(.sansNeoRegular(size: 10))
            }
        }
        .foregroundStyle(Color.inactiveColor)
    }

    var progressView: some View {
        ProgressView {
            Text(Strings.pleaseWait.localized(language))
                .font(Font.sansNeoRegular(size: 20))
        }
    }

    func messageView(message: String, color: Color) -> some View {
        return Rectangle()
            .fill(Color.appModeColor.opacity(0.3))
            .frame(height: 28)
            .overlay(alignment: .trailing, content: {
                Text(message.localized(language))
                    .font(Font.sansNeoRegular(size: 13))
                    .foregroundStyle(color)
                    .padding([.trailing], 8)
            })
    }

    func areMeasurementsAvailable() -> Bool {
        !scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false
        }).isEmpty
    }
}
