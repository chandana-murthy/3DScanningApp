//
//  MainView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 04.12.22.
//

import SwiftUI

@available(iOS 16.0, *)
struct MainView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @State private var isFABOpen = false
    @State private var isRootActive = true
    @EnvironmentObject var navigationUtils: NavigationUtils
    private let HEADER_HEIGHT = 48.0

    var body: some View {
        VStack {
            HeaderView()
                .frame(height: HEADER_HEIGHT)
                .padding(.vertical, 8)
            ZStack {
                ScanListView()
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        expandableFAB

                    }.padding([.bottom, .trailing], 32)
                }
            }
        }
        .navigationDestination(for: String.self, destination: { finalPath in
            if finalPath.contains(Constants.POINTS_NAV_STRING) {
                PointCloudScanView()
            } else if finalPath.contains(Constants.MESH_NAV_STRING) {
                MeshScanView()
            }
        })
        .toolbar(.hidden)
    }

    var expandableFAB: some View {
        //        ExpandableFAB(
        //            primaryItem: primaryItem,
        //            secondaryItems:
        //                [
        //                    pointCloudButtonItem,
        //                    meshButtonItem
        //                ],
        //            isOpen: $isFABOpen)

        Button(action: {
            self.navigationUtils.path.append(Constants.POINTS_NAV_STRING)
            isFABOpen.toggle()
        }) {
            Text("+")
                .padding()
                .padding(.top, 8)
                .foregroundStyle(Color.white)
                .font(.sansNeoBold(size: 52))
                .background(Color.dataFlorGreen)
                .clipShape(Circle())
        }
    }

    var primaryItem: ExpandableButtonItem {
        ExpandableButtonItem(
            imageName: "plus",
            buttonLabel: Strings.addScan.localized(language)
        )
    }

    var pointCloudButtonItem: ExpandableButtonItem {
        ExpandableButtonItem(
            imageName: "points",
            buttonLabel: Strings.pointCloud.localized(language),
            action: {
                self.navigationUtils.path.append(Constants.POINTS_NAV_STRING)
                isFABOpen.toggle()
            })
    }

    var meshButtonItem: ExpandableButtonItem {
        ExpandableButtonItem(
            imageName: "mesh",
            buttonLabel: Strings.mesh.localized(language),
            action: {
                self.navigationUtils.path.append(Constants.MESH_NAV_STRING)
                isFABOpen.toggle()
            })
    }
}
