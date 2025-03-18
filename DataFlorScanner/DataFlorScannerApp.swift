//
//  DataFlorScannerApp.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 04.12.22.
//

import SwiftUI
import ARKit
import Open3DSupport
import NumPySupport
import PythonSupport

@main
struct DataFlorScannerApp: App {
    @AppStorage("appTheme") private var isDarkModeOn = true
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var dataController = DataController()
    @StateObject private var navigationUtils = NavigationUtils()
    @State private var isLidarAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)

    init() {
        // Initialize Python environment
        PythonSupport.initialize()
        Open3DSupport.sitePackagesURL.insertPythonPath()
        NumPySupport.sitePackagesURL.insertPythonPath()
    }

    var body: some Scene {
        WindowGroup {
            if isLidarAvailable {
                NavigationStack(path: $navigationUtils.path) {
                    MainView()
                }
                // inject the navigation path into the environment of the navigationView.
                .environmentObject(navigationUtils)
                // inject datamodel into environment. viewContext lets us work with data in memory
                .environment(\.managedObjectContext, dataController.persistentContainer.viewContext)
                .preferredColorScheme(isDarkModeOn ? .dark : .light)
            } else {
                DeviceUnsupportedView()
            }
        }
    }
}
