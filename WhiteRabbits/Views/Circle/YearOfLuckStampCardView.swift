//
//  YearOfLuckStampCardView.swift
//  WhiteRabbits
//
//  A quiet teaser for the Year of luck: this month's charm, plus a link
//  to the full 12-month grid over on the Charms tab, instead of
//  duplicating that whole grid here too.
//

import SwiftUI

struct YearOfLuckStampCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.tabSelection) private var tabSelection

    private var currentBunny: Bunny { store.currentBunny() }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentYear)
                        .kickerStyle()
                    Text(String(localized: "circle.stampCard.title", defaultValue: "Year of luck"))
                        .displayTitleStyle()
                }
                Spacer()
                Text(String(format: String(localized: "circle.stampCard.countShort", defaultValue: "%d OF 12"), store.unlockedCharmIds.count))
                    .kickerStyle()
            }

            HStack(spacing: 14) {
                CharmView(bunny: currentBunny, unlocked: store.unlockedCharmIds.contains(currentBunny.id), size: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "circle.stampCard.thisMonth", defaultValue: "This month's charm"))
                        .bodyStyle(weight: .medium)
                    Text(currentBunny.season)
                        .bodyStyle(muted: true)
                }
                Spacer()
            }

            Button {
                Haptics.light()
                tabSelection.wrappedValue = .charms
            } label: {
                HStack(spacing: 4) {
                    Text(String(localized: "circle.stampCard.seeAll", defaultValue: "See all in Charms"))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .bodyStyle(weight: .medium)
                .foregroundStyle(palette.ink)
            }
            .buttonStyle(.plain)
        }
        .padding(Layout.cardPadding)
        .cardBackground()
    }
}

#Preview {
    YearOfLuckStampCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
