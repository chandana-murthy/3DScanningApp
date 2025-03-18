//
//  LocationMetricsView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 22.12.22.
//

import SwiftUI

struct LocationMetricsView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("language") private var language = LocalizationService.shared.language
    @State var showLocationAlert = false
    var locationString: String?
    var locCoordinateString: String?
    var includeBorder = false

    var body: some View {
        if let coords = locCoordinateString, let loc = locationString, !loc.isEmpty, !coords.isEmpty {
            if sizeClass == .regular {
                iPadLocationView(loc: loc, coords: coords)
            } else {
                iPhoneLocationView(loc: loc, coords: coords)
            }
        }
    }

    func iPadLocationView(loc: String, coords: String) -> some View {
        return HStack {
            Image.location
                .frame(width: 40, height: 40)
                .foregroundStyle(Color.dataFlorGreen)

            VStack(alignment: .leading, spacing: 4) {
                Text(loc).font(Font.sansNeoRegular(size: 14)).animation(.easeIn)
                Text(coords).font(Font.sansNeoRegular(size: 14)).animation(.easeIn)
            }
            .foregroundStyle(Color.white)
            .padding(.trailing, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.3))
                .frame(width: 144, height: 112)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .strokeBorder(includeBorder ? Color.lightGray.opacity(0.7) : .clear, lineWidth: 1)
                .frame(width: 144, height: 112)
        )
        .padding(.top, 64)
    }

    func iPhoneLocationView(loc: String, coords: String) -> some View {
        return Button {
            showLocationAlert = true
        } label: {
            Image.location
                .foregroundStyle(Color.dataFlorGreen)
                .font(.title)
        }
        .padding(.top, 40)
        .alert(Strings.location.localized(language), isPresented: $showLocationAlert) {
            Button(Strings.gotIt.localized(language), role: .none) {}
        } message: {
            Text("\(loc)\n\(coords)")
        }
    }
}
