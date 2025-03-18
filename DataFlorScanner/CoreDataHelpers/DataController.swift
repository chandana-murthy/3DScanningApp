//
//  DataController.swift
//  mapper-basic
//
//  Created by Chandana Murthy on 04.12.22.
//

import Foundation
import CoreData

// Store inside the swiftUI environment when app launches and use it in the entire app
class DataController: ObservableObject {
    let persistentContainer = NSPersistentContainer(name: "scannerModel")

    init() {
        persistentContainer.loadPersistentStores { (_, error) in
            if let error = error {
                print("Core data failed to load: \(error.localizedDescription)")
            }
        }
    }
}
