//
//  PointsViewerSettingsView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 20.04.23.
//

import SwiftUI
import SceneKit
import Common

struct PointsViewerSettingsView: View {
    @AppStorage("language") var language = LocalizationService.shared.language
    @ObservedObject var model: PointsViewerTabViewModel
    @Binding var processing: Bool
    @Binding var offset: Float
    @Binding var showPoints: Bool
    @Binding var showMesh: Bool
    @Binding var pointOpacity: Float
    @Binding var pointSize: Float
    @Binding var measurePosition: Float
    let FONT_SIZE: CGFloat = 14
    let SWITCH_LENGTH: CGFloat = 64

    var body: some View {
        VStack {
            pointVisibilitySwitch
                .padding(.vertical, 6)

            Divider()
                .overlay(Color.basicColor.opacity(0.1))

            meshVisibilitySwitch
                .padding(.vertical, 6)

            Divider()
                .overlay(Color.basicColor.opacity(0.1))

            pointOpacitySlider
                .padding(.vertical, 6)

            Divider()
                .overlay(Color.basicColor.opacity(0.1))

            pointSizeSlider
                .padding(.vertical, 6)

            Divider()
                .overlay(Color.basicColor.opacity(0.1))

            measurePositionSlider
                .padding(.vertical, 6)
        }
        .padding(.horizontal, 32)
    }

    var pointVisibilitySwitch: some View {
        return HStack {
            Text(Strings.showPoints.localized(language))
                .font(.sansNeoRegular(size: FONT_SIZE))
                .foregroundStyle(Color.basicColor)

            Spacer()

            Toggle("", isOn: $showPoints)
                .onChange(of: showPoints, perform: { show in
                    model.showPoints(show: show)
                })
                .toggleStyle(SwitchToggleStyle(tint: processing ? .disabledColor : .dataFlorGreen))
                .frame(width: SWITCH_LENGTH, alignment: .center)
        }
    }

    var meshVisibilitySwitch: some View {
        return HStack {
            Text(Strings.showMesh.localized(language))
                .font(.sansNeoRegular(size: FONT_SIZE))
                .foregroundStyle(Color.basicColor)

            Spacer()

            Toggle("", isOn: $showMesh)
                .onChange(of: showMesh, perform: { show in
                    model.showMesh(show: show)
                })
                .toggleStyle(SwitchToggleStyle(tint: processing ? .disabledColor : .dataFlorGreen))
                .frame(width: SWITCH_LENGTH)
        }
    }

    var pointOpacitySlider: some View {
        return HStack {

            Text("\(Strings.pointVisibility.localized(language))")
                .font(.sansNeoRegular(size: FONT_SIZE))
                .foregroundStyle(Color.basicColor)

            Spacer()

            Slider(value: $pointOpacity, in: 0...1)
                .onChange(of: pointOpacity, perform: { opacity in
                    model.setPointNodeOpacity(opacity: opacity)
                })
                .tint(processing ? .disabledColor : .dataFlorGreen)
                .frame(minWidth: Constants.SLIDER_MIN_WIDTH)
                .frame(maxWidth: Constants.SLIDER_MAX_WIDTH)
        }
    }

    var pointSizeSlider: some View {
        return HStack {
            Text("\(Strings.pointSize.localized(language))")
                .font(.sansNeoRegular(size: FONT_SIZE))
                .foregroundStyle(Color.basicColor)

            Spacer()

            Slider(value: $pointSize, in: 0...0.01)
                .onChange(of: pointSize, perform: { size in
                    model.changePointSize(size: size)
                })
                .tint(processing ? .disabledColor : .dataFlorGreen)
                .frame(minWidth: Constants.SLIDER_MIN_WIDTH)
                .frame(maxWidth: Constants.SLIDER_MAX_WIDTH)
        }
    }

    var measurePositionSlider: some View {
        HStack {
            Text("\(Strings.measurementPosition.localized(language))")
                .font(.sansNeoRegular(size: FONT_SIZE))
                .foregroundStyle(model.areMeasurementsAvailable() ? Color.basicColor : .gray)

            Spacer()

            Slider(value: $measurePosition, in: 0...0.5)
                .onChange(of: measurePosition, perform: { newValue in
                    let delta = newValue - offset
                    model.changeMeasurementPosition(position: delta)
                    offset = measurePosition
                })
                .tint(processing ? .disabledColor : .dataFlorGreen)
                .frame(minWidth: Constants.SLIDER_MIN_WIDTH)
                .frame(maxWidth: Constants.SLIDER_MAX_WIDTH)
        }
        .disabled(!model.areMeasurementsAvailable())
    }
}
