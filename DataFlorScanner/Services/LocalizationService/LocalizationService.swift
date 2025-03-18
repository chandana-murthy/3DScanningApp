//
//  LocalizationService.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 05.03.23.
//

import Foundation

class LocalizationService {
    static let shared = LocalizationService()
    static let changedLanguage = Notification.Name("changedLanguage")

    private init() {}

    var language: Language {
        get {
            guard let lang = UserDefaults.standard.string(forKey: "language") else {
                return .english
            }
            return Language(rawValue: lang) ?? .english
        } set {
            if newValue != language {
                UserDefaults.standard.setValue(newValue.rawValue, forKey: "language")
                NotificationCenter.default.post(name: LocalizationService.changedLanguage, object: nil)
            }
        }
    }

    func localizedString(_ string: String) -> String {
        return string.localized(language)
    }
}
