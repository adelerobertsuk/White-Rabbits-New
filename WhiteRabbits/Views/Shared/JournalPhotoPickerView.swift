//
//  JournalPhotoPickerView.swift
//  WhiteRabbits
//
//  The one photo picker for a journal page, whether writing a new one or
//  editing a kept one: a big dashed-border tile that fills with the chosen
//  photo and grows a small "remove" button once one is picked.
//

import SwiftUI
import PhotosUI

struct JournalPhotoPickerView: View {
    @Binding var photoItem: PhotosPickerItem?
    @Binding var photo: PlatformImage?
    @Binding var removePhoto: Bool
    var height: CGFloat = 170

    @Environment(\.palette) private var palette

    var body: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                    .fill(palette.card)
                #if canImport(UIKit)
                if let photo {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                } else {
                    emptyLabel
                }
                #else
                emptyLabel
                #endif
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                    .strokeBorder(palette.line, style: StrokeStyle(lineWidth: 1, dash: photo == nil ? [5, 5] : []))
            )
        }
        .buttonStyle(.plain)
        .overlay(alignment: .topTrailing) {
            if photo != nil {
                Button {
                    Haptics.light()
                    photo = nil
                    removePhoto = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(palette.ink)
                        .background(Circle().fill(palette.bg))
                }
                .padding(8)
            }
        }
    }

    private var emptyLabel: some View {
        VStack(spacing: 6) {
            Image(systemName: "camera")
                .font(.system(size: 18))
            Text(String(localized: "journal.new.addPhotograph", defaultValue: "Add a photograph"))
                .font(.system(size: 14))
        }
        .foregroundStyle(palette.muted)
    }
}
