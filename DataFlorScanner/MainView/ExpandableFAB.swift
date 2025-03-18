//
//  ButtonViews.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 04.12.22.
//

import SwiftUI

struct ExpandableButtonItem: Identifiable {
    let id = UUID()
    let imageName: String?
    let buttonLabel: String
    private(set) var action: (() -> Void)?
}

struct ExpandableFAB: View {
    let primaryItem: ExpandableButtonItem
    let secondaryItems: [ExpandableButtonItem]
    @Binding var isOpen: Bool
    private let noop: () -> Void = {}

    var body: some View {
        VStack {
            if self.isOpen {
                ForEach(secondaryItems) { item in
                    Button(action:
                        item.action ?? noop
                    ) {
                        HStack {
                            if let name = item.imageName {
                                Image(name).resizable()
                                    .frame(width: 24, height: 24)
                                    .padding([.top, .leading, .bottom], 12)
                            }
                            Text(item.buttonLabel)
                                .font(.subheadline)
                                .foregroundStyle(Color.white)
                                .padding([.trailing], 8)
                        }
                    }
                    .frame(width: 150)
                    .background(Color.dataFlorGreen)
                    .foregroundStyle(Color.basicColor)
                    .cornerRadius(30)
                }
            }

            Button(action: {
                self.isOpen.toggle()
            }) {
                HStack {
                    if let name = primaryItem.imageName {
                        Image(name).resizable()
                            .frame(width: 24, height: 24)
                            .padding([.top, .bottom], 12)
                            .padding([.leading], 24)
                        //  .rotationEffect(.init(degrees: self.isOpen ? 45 : 0), anchor: .center )
                    }
                    Text(primaryItem.buttonLabel)
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .padding([.trailing], 24)
                }

            }
            .background(Color.dataFlorGreen)
            .foregroundStyle(Color.basicColor)
            .cornerRadius(30)

        }
        .animation(.spring(), value: isOpen)
    }
}
