//
//  HeaderView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 18.12.22.
//

import SwiftUI

struct HeaderView: View {
    @AppStorage("language") private var language = LocalizationService.shared.language
    @AppStorage("appTheme") private var isDarkModeOn = true
    @State private var showLangChangeAlert = false

    var body: some View {
        HStack {
            VStack {
                Button {
                    showLangChangeAlert = true
                } label: {
                    let image = language == .english ? Image.germanFlag : Image.englishFlag
                    image
                }

                Text("Language")
                    .foregroundStyle(Color.basicColor)
                    .font(Font.sansNeoRegular(size: 12))
            }
            .padding([.leading], 24)

            Spacer()

            Image.dataFlorLogo
                .resizable()
                .frame(width: 30, height: 40)
            Text("3D Scanning App") // Text("DATAflor")
                .foregroundStyle(Color.dataFlorGreen)
                .font(Font.sansNeoRegular(size: 30))

            Spacer()

            VStack {
                Button {
                    isDarkModeOn.toggle()
                } label: {
                    let darkModeImage = isDarkModeOn ? Image.lightMode : Image.darkMode
                    darkModeImage
                        .foregroundStyle(Color.basicColor)
                }

                Text("Theme")
                    .foregroundStyle(Color.basicColor)
                    .font(Font.sansNeoRegular(size: 12))
                    .padding(.top, 4)
            }
            .padding([.trailing], 28)

        }
        .alert(
            Strings.appLangChangeConfirmation.localized(language),
            isPresented: $showLangChangeAlert
        ) {
            Button(Strings.yes.localized(language), role: .none) {
                language = language == .english ? .german : .english
            }
            Button(Strings.cancel.localized(language), role: .cancel) { }
        } message: {
            Text(langText())
        }
    }

    func langText() -> String {
        let text = language == .english ? Strings.changeLangToDeutsch : Strings.changeLangToEnglish
        return text.localized(language)
    }
}
