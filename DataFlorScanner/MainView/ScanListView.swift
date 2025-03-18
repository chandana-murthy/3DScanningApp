//
//  ScanListView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 18.12.22.
//

import SwiftUI
import SceneKit

struct ScanListView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @EnvironmentObject var navigationUtils: NavigationUtils
    @Environment(\.managedObjectContext) private var managedContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Scan.dateCreated, ascending: false)]) var pointsScans: FetchedResults<Scan>

    // make a new fetch request with sorting based on creation date, and put it into the property ,pointsScans'.
    // You can use pointsScans as a regular swift array
    @FetchRequest( sortDescriptors: [NSSortDescriptor(keyPath: \MeshScan.dateCreated, ascending: false)]) var meshScans: FetchedResults<MeshScan>
    @State private var selectedMeshScan: MeshScan?
    @State private var selectedPointsScan: Scan?
    @State private var deleteMeshScan = false
    @State private var deletePointsScan = false
    @State private var moveToAddPoints = false
    @State private var showDeleteAlert = false

    var body: some View {
        List {
            pointsSection

//            meshSection
        }
//        .refreshable { // uncomment this to allow pull to refresh if needed
//            managedContext.refreshAllObjects()
//        }

        .listStyle(InsetGroupedListStyle()) // for collapsible sections use SidebarListStyle()

        .onChange(of: deleteMeshScan) { valueChanged in
            if valueChanged {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.deleteScan(type: .meshScan)
                    deleteMeshScan = false
                    selectedMeshScan = nil
                }
            }
        }
        .onChange(of: deletePointsScan) { valueChanged in
            if valueChanged {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    self.deleteScan(type: .pointsScan)
                    deletePointsScan = false
                    selectedPointsScan = nil
                }
            }
        }
    }

    var pointsSection: some View {
        Section(header: Text(Strings.scans.localized(language))
            .font(.sansNeoRegular(size: 14))
        ) {
            if self.pointsScans.isEmpty {
                EmptySectionView(scanType: ScanType.pointsScan)
            } else {
                pointsScanRows
            }
        }
    }

    var meshSection: some View {
        Section(header: Text(Strings.meshScans.localized(language))
            .font(.sansNeoRegular(size: 14))
        ) {
            if self.meshScans.isEmpty {
                EmptySectionView(scanType: ScanType.meshScan)
            } else {
                meshScanRows
            }
        }
    }

    var pointsScanRows: some View {
        return ForEach(self.pointsScans, id: \.self) { pointsScan in
            NavigationLink(
                destination: getSavedViewer(pointsScan: pointsScan)
                    .onAppear {
                        self.selectedPointsScan = pointsScan
                    }
            ) {
                getScanCellView(pointsScan: pointsScan)
            }
        }
        .onDelete(perform: delete)
    }

    var meshScanRows: some View {
        ForEach(self.meshScans, id: \.self) { meshScan in
            NavigationLink(
                destination: SavedMeshViewerView(scan: meshScan, deleteMesh: $deleteMeshScan)
                    .onAppear {
                        self.selectedMeshScan = meshScan
                    }
            ) {
                ScanListCellView(
                    scanName: meshScan.name,
                    scanDate: meshScan.dateCreated,
                    scanImage: UIImage(data: meshScan.image) ?? UIImage.mesh,
                    deleting: deleteMeshScan && selectedMeshScan == meshScan,
                    scanLocation: meshScan.locationString)
            }
        }
    }

    func getScanCellView(pointsScan: Scan) -> some View {
        ScanListCellView(
            scanName: pointsScan.name,
            scanDate: pointsScan.dateCreated ?? Date(),
            scanImage: UIImage(data: pointsScan.image) ?? UIImage.cubeTransparent,
            deleting: deletePointsScan && selectedPointsScan == pointsScan,
            scanLocation: pointsScan.locationString)
    }

    func getSavedViewer(pointsScan: Scan) -> SavedPointsViewerView {
        return SavedPointsViewerView(
            model: SavedPointsViewerViewModel(scan: pointsScan, scene: getScene(scan: pointsScan)),
            deletePointsScan: $deletePointsScan,
            scan: pointsScan
        )
    }

    func getScene(scan: Scan) -> SCNScene {
        let scene = SCNScene()
        if let node = getSceneNode(scan: scan) {
            for childNode in node.childNodes {
                scene.rootNode.addChildNode(childNode)
            }
        }
        return scene
    }

    func getSceneNode(scan: Scan) -> SCNNode? {
        do {
            guard let asset = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: scan.sceneData as Data) else {
                return nil
            }
            return asset
        } catch {
            return nil
        }
    }

    func deleteScan(type: ScanType) {
        let scan = (type == .meshScan) ? selectedMeshScan : selectedPointsScan
        guard let scan else {
            print("Failed to delete")
            return
        }
        deleteMeshScan = false
        managedContext.delete(scan)
        try? managedContext.save()
    }

    func delete(at offsets: IndexSet) {
        for offset in offsets {
            let scan = pointsScans[offset]

            managedContext.delete(scan)
        }

        try? managedContext.save()
    }

    func delete(scan: Scan) {
        managedContext.delete(scan)
        try? managedContext.save()
    }
}
