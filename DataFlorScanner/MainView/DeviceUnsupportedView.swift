//
//  DeviceUnsupportedView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 29.07.23.
//

import SwiftUI

struct DeviceUnsupportedView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language

    var body: some View {
        ZStack {
            Color.basicColor
                .ignoresSafeArea()

            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.dataFlorGreen)
                    .padding(.bottom, 8)

                Text(Strings.lidarIncapable.localized(language))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .font(.sansNeoStandard(size: 16))
                    .foregroundStyle(Color.inactiveColor)
            }
        }
    }
}
