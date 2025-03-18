//
//  EmptySectionView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 18.12.22.
//

import SwiftUI

struct EmptySectionView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @EnvironmentObject var navigationUtils: NavigationUtils
    var scanType: ScanType
    var newScanString: String
    var noScanString: String

    init(scanType: ScanType) {
        self.scanType = scanType
        newScanString = scanType == .meshScan ? Strings.newMeshScan : Strings.newScan
        noScanString = scanType == .meshScan ? Strings.noMeshScan : Strings.noScansAvailable
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(noScanString.localized(language))
                .font(Font.sansNeoRegular(size: 16))
                .frame(maxWidth: .infinity, alignment: .center)

            Button {
                scanType == .meshScan ? moveToNewMeshView() : moveToNewPointsView()
            } label: {
                Text("+ \(newScanString.localized(language))")
            }
            .foregroundStyle(Color.blue)
            .font(.sansNeoRegular(size: 16))

            Spacer()
        }
    }

    func moveToNewPointsView() {
        self.navigationUtils.path.append(Constants.POINTS_NAV_STRING)
    }

    func moveToNewMeshView() {
        self.navigationUtils.path.append(Constants.MESH_NAV_STRING)
    }
}
