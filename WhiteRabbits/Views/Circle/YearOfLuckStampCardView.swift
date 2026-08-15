//
//  YearOfLuckStampCardView.swift
//  WhiteRabbits
//
//  The 12-month stamp card, living here in Circle as a quiet
//  reference. It never pops up uninvited after journaling.
//

import SwiftUI

struct YearOfLuckStampCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "circle.stampCard.title", defaultValue: "Year of luck"))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(palette.ink)
                    Text(String(format: String(localized: "circle.stampCard.count", defaultValue: "%d of 12 collected"), store.unlockedCharmIds.count))
                        .font(.system(size: 13))
                        .foregroundStyle(palette.muted)
                }
                Spacer()
            }

            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(BunnyData.all) { bunny in
                    VStack(spacing: 6) {
                        CharmView(bunny: bunny, unlocked: store.unlockedCharmIds.contains(bunny.id), size: 48)
                        Text(String(bunny.season.prefix(3)))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(palette.faint)
                    }
                }
            }
        }
        .padding(18)
        .cardBackground()
    }
}

#Preview {
    YearOfLuckStampCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
