//
//  PinnedIntentionDockView.swift
//  WhiteRabbits
//
//  A small dock at the bottom of Today, showing the intention card
//  that was pinned from Circle. Tapping it opens the full card.
//

import SwiftUI

struct PinnedIntentionDockView: View {
    let record: MonthRecord
    let photo: PlatformImage?
    var onTap: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                thumbnail
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "pinned.label", defaultValue: "Pinned from Circle"))
                        .kickerStyle()
                    Text(record.intention ?? "")
                        .bodyStyle(weight: .medium)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.faint)
            }
            .padding(12)
            .cardBackground(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var thumbnail: some View {
        #if canImport(UIKit)
        if let photo {
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            fallbackThumbnail
        }
        #else
        fallbackThumbnail
        #endif
    }

    private var fallbackThumbnail: some View {
        let bunny = BunnyData.bunny(id: record.charmId ?? "harvest")
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(hex: bunny.fillHex))
            .frame(width: 44, height: 44)
            .overlay(
                BunnyMarkView(bunny: bunny, style: .charm)
                    .padding(6)
            )
    }
}
