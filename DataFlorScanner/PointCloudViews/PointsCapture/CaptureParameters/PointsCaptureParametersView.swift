//
//  PointsCaptureParametersView.swift
//  DataFlorScanner
//  Based on PointCloudKit CaptureParametersView
//
//  Created by Chandana Murthy on 01.02.23.
//

import SwiftUI

struct PointsCaptureParametersView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @StateObject var model: CaptureParametersModel

    @State private var showSubParameter: Bool = false
    @State private var showConfidence: Bool = false
    @State private var flashlightActive: Bool = false

    var body: some View {
        if showSubParameter {

            if showConfidence {
                ConfidenceCaptureSubParameterView(confidenceThreshold: $model.renderingService.confidenceThreshold)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .transition(.moveAndFade)
            }

            Divider()
        }

        parameters

        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .transition(.moveAndFade)
    }

    var parameters: some View {
        HStack(alignment: .center, spacing: 20) {
            flashlightButton
                .padding(.trailing, 28)

            confidenceButton
                .padding(.trailing, 28)

            pointSizeSlider
                .padding(.trailing, 28)

            backgroundVisibilitySlider

            Spacer()
        }
    }

    // MARK: - Flashlight
    var flashlightButton: some View {
        return Button(action: {
            flashlightActive = FlashlightService.toggleFlashlight()
        }, label: {
            let image = flashlightActive ? Image.flashlightOn : Image.flashlightOff
            VStack {
                image
                    .font(.title)
                    .foregroundStyle(Color.dataFlorGreen)
                Text("\(Strings.flashlight.localized(language))")
                    .font(.sansNeoRegular(size: 12))
                    .foregroundStyle(Color.basicColor)
                    .padding(.top, 1.2)
            }
        })
    }

    // MARK: - Confidence
    var confidenceButton: some View {
        let confidenceDisabled = showSubParameter && !showConfidence
        return Button(action: {
            withAnimation {
                showSubParameter.toggle()
                showConfidence.toggle()
            }
        }, label: {
            VStack {
                Image.confidence
                    .font(.title)
                    .foregroundStyle(!confidenceDisabled ? Color.dataFlorGreen : Color.disabledColor)
                Text("\(Strings.confidence.localized(language))")
                    .font(.sansNeoRegular(size: 12))
                    .foregroundStyle(Color.basicColor)
                    .padding(.top, 13)
            }
        })
        .disabled(confidenceDisabled)
    }

    // MARK: - Slider for Point Size
    var pointSizeSlider: some View {
        let pointSize = Binding(
            get: {
                Double(self.model.getPointSize())
            }, set: {
                self.model.setPointSize(size: Float($0))
            }
        )
        return VStack {
            Slider(value: pointSize, in: 15...40)
                .tint(.dataFlorGreen)
                .frame(width: 200)
            Text("\(Strings.pointSize.localized(language))")
                .font(.sansNeoRegular(size: 12))
        }
    }

    // MARK: - Slider for Background Visibility Radius
    var backgroundVisibilitySlider: some View {
        let backgroundRadius = Binding(
            get: {
                Double(self.model.getBackgroundRadius())
            }, set: {
                self.model.setBackgroundVisibilityRadius(radius: Float($0))
            }
        )
        return VStack {
            Slider(value: backgroundRadius, in: 0...1.5)
                .tint(.dataFlorGreen)
                .frame(width: 200)
            Text(Strings.bgVisibility.localized(language))
                .font(.sansNeoRegular(size: 12))
        }
    }
}
