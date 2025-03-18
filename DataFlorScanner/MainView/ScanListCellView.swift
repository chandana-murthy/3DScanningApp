//
//  ScanListCellView.swift
//  DataFlorScanner
//
//  Created by Chandana Murthy on 04.12.22.
//

import SwiftUI

struct ScanListCellView: View {
    var scanName: String
    var scanDate: Date
    var scanImage: UIImage
    var deleting: Bool
    var scanLocation: String?

    private let TEXT_SIZE = 19.0
    private let SUB_TEXT_SIZE = 16.0
    private let IMAGE_SIZE = 120.0

    var dateCreatedString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.LONG_DATE_FORMAT
        return formatter.string(from: self.scanDate)
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(uiImage: scanImage)
                .resizable()
                .frame(width: IMAGE_SIZE, height: IMAGE_SIZE)
                .frame(alignment: .leading)
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                }
                .overlay {
                    if deleting {
                        withAnimation(.easeIn) {
                            ProgressView()
                        }
                    }
                }

            VStack(alignment: .leading, spacing: 12) {
                Text(scanName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(Font.sansNeoRegular(size: TEXT_SIZE))
                    .padding(.top, 16)

                Text(dateCreatedString)
                    .font(Font.sansNeoLight(size: SUB_TEXT_SIZE))

                if let location = scanLocation {
                    Text(location.replacingOccurrences(of: "\n", with: " "))
                        .font(Font.sansNeoLight(size: SUB_TEXT_SIZE))
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
