//
//  SavePointsScanView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 11.01.23.
//

import SwiftUI

struct SavePointsScanView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss

    @State var showingModal = false
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var doneButtonTapped = false
    @State private var isValid = false
    @State private var saveFailed = false
    @Binding var isSaved: Bool
    @StateObject var saveData: SaveData
    var offset: Float = 0
    let emptyData = Data()

    var dateCreated = Date()
    var dateCreatedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.LONG_DATE_FORMAT
        return formatter.string(from: dateCreated)
    }

    var body: some View {
        ScrollView {
            VStack {
                headerView
                    .font(.sansNeoRegular(size: 18))
                    .padding()

                if let data = saveData.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 240)
                        .cornerRadius(25)
                        .padding(.horizontal, 40)
                }

                Text(name.isEmpty ? Strings.newScan.localized(language) : name)
                    .font(Font.sansNeoBold(size: 15))
                    .padding()
                    .lineLimit(5)

                Text(dateCreatedString)
                    .font(Font.sansNeoRegular(size: 12))
                    .foregroundStyle(Color.gray)
                    .padding(.bottom)

                TextField(Strings.name.localized(language), text: self.$name)
                    .font(Font.sansNeoLight(size: 14))
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 10.0)
                            .strokeBorder(Color.lightGray, style: StrokeStyle(lineWidth: 1.0))
                    )
                    .padding(.horizontal, 16)

                Text(Strings.enterName.localized(language))
                    .foregroundStyle(Color.red)
                    .font(Font.sansNeoLight(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .padding(.vertical, 4)
                    .hidden(shouldHide: !(name.isEmpty && doneButtonTapped))

                TextField(Strings.description.localized(language),
                          text: self.$description,
                          axis: .vertical)
                .lineLimit(5)
                .font(Font.sansNeoLight(size: 14))
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10.0)
                        .strokeBorder(Color.lightGray, style: StrokeStyle(lineWidth: 1.0))
                )
                .padding(.horizontal, 16)

                Text(Strings.optional.localized(language))
                    .foregroundStyle(Color.lightGray)
                    .font(Font.sansNeoLight(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .padding(.vertical, 4)

                Spacer()
            }
        }
        .alert(Strings.error.localized(language), isPresented: $saveFailed) {
            Button(Strings.okay.localized(language), role: .none) { }
        } message: {
            Text(Strings.saveFailed.localized(language))
        }
    }

    var headerView: some View {
        HStack {
            deleteButton

            Spacer()

            saveButton
        }
    }

    var deleteButton: some View {
        Button(action: {
            self.showingModal = false
            self.isSaved = true
            self.dismiss()
        }) {
            Text(Strings.delete.localized(language))
                .foregroundStyle(Color.red)
        }
    }

    var saveButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                doneButtonTapped = true
            }
            checkForText()
        }) {
            Text(Strings.save.localized(language))
        }
    }

    func getDataOfScene() -> Data {
        changeMeasurementPosition(position: 0 - offset)
        removeExtraMeasures()
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: saveData.scene.rootNode, requiringSecureCoding: false)
            return data
        } catch let error {
            print(error.localizedDescription)
            return emptyData
        }
    }

    func removeExtraMeasures() {
        let nodes = self.saveData.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
        if nodes.count % 4 != 0 {
            nodes.last?.removeFromParentNode()
        }
    }

    func changeMeasurementPosition(position: Float) {
        if position == 0 {
            return
        }
        let nodes = self.saveData.scene.rootNode.childNodes.filter({
            $0.name?.contains(Constants.measureNodeName) ?? false || $0.name?.contains(Constants.textNodeName) ?? false || $0.name?.contains(Constants.lineNodeName) ?? false
        })
        for node in nodes {
            node.position.z += position
        }
    }

    private func checkForText() {
        if name.isEmpty {
            isValid = false
        } else {
            isValid = true
            self.save()
        }
    }

    private func save() {
        let scan = Scan(context: managedObjectContext)
        scan.name = name
        scan.scanDescription = description
        scan.dateCreated = dateCreated
        scan.locCoordinateString = saveData.coordinateString
        scan.locationString = saveData.locationString
        scan.image = saveData.imageData ?? emptyData
        scan.didFinishScan(pointCloud: saveData.pointCloud)
        scan.sceneData = getDataOfScene()
        scan.meshUrl = saveData.objURL
        scan.plyData = saveData.plyData
        scan.orientation = saveData.orientation as? NSNumber
        scan.pointConfidence = saveData.confidence as NSNumber
        /// This is saved as a comma separated string which can easily be split on the other side of coreData. Just separate with comma and add into array & then Float3
        if let orn = saveData.cameraOrientation {
            scan.cameraOrientation = "\(orn.x), \(orn.y), \(orn.z)"
        }

        do {
            try self.managedObjectContext.save()
        } catch let error {
            print("CoreData save failed: \(error.localizedDescription)")
            saveFailed = true
            return
        }
        self.isSaved = true
        self.dismiss()
        self.showingModal = false
    }
}
