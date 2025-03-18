//
//  SaveMeshScanView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 28.12.22.
//

import SwiftUI
import ModelIO

struct SaveMeshScanView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @Environment(\.managedObjectContext) var managedObjectContext
    @Environment(\.dismiss) var dismiss

    @State var showingModal = false
    @State private var name: String = ""
    @State private var description: String = ""
    @State private var doneButtonTapped = false
    @State private var isValid = false
    @Binding var isSaved: Bool

    var imageData: Data?
    var locationString: String?
    var coordinateString: String?
    var usdzUrl: URL?

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

                if let data = imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(height: 240)
                        .scaledToFit()
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
                    .padding(.horizontal, 24)

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
                .padding(.horizontal, 24)

                Text(Strings.enterDescription.localized(language))
                    .foregroundStyle(Color.red)
                    .font(Font.sansNeoLight(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 24)
                    .padding(.vertical, 4)
                    .hidden(shouldHide: !(description.isEmpty && doneButtonTapped))

                Spacer()
            }
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

    private func checkForText() {
        if name.isEmpty || description.isEmpty {
            isValid = false
        } else {
            isValid = true
            self.save()
        }
    }

    private func save() {
        let scan = MeshScan(context: self.managedObjectContext)
        scan.name = name
        scan.scanDescription = description
        scan.dateCreated = dateCreated
        scan.locCoordinateString = coordinateString
        scan.locationString = locationString
        scan.image = imageData ?? Data()
        if let usdUrl = usdzUrl {
            scan.usdzUrl = usdUrl
        } else {
            print("USDZ URL is missing. Something is wrong")
            scan.usdzUrl = URL(fileURLWithPath: "")
        }
        do {
            try self.managedObjectContext.save()
        } catch let error {
            print("CoreData save failed: \(error.localizedDescription)")
        }
        self.isSaved = true
        self.dismiss()
        self.showingModal = false
    }
}
