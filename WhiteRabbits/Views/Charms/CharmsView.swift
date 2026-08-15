//
//  CharmsView.swift
//  WhiteRabbits
//
//  Tab 4: every monthly charm collected so far, plus a few milestone
//  talismans. Unlocked pieces get a subtle glow.
//

import SwiftUI

struct CharmsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    private let charmColumns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle(String(localized: "charms.seasonal.title", defaultValue: "Seasonal charms"))

                        LazyVGrid(columns: charmColumns, spacing: 20) {
                            ForEach(BunnyData.all) { bunny in
                                VStack(spacing: 8) {
                                    CharmView(bunny: bunny, unlocked: store.unlockedCharmIds.contains(bunny.id), size: 68)
                                    Text(bunny.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(palette.ink)
                                    Text(bunny.season)
                                        .font(.system(size: 10))
                                        .foregroundStyle(palette.faint)
                                }
                            }
                        }
                    }
                    .padding(18)
                    .cardBackground()

                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle(String(localized: "charms.milestones.title", defaultValue: "Milestones"))

                        ForEach(store.milestones) { milestone in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(milestone.isUnlocked ? palette.accentGlow : palette.card)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: milestone.systemImage)
                                        .foregroundStyle(milestone.isUnlocked ? palette.accent : palette.faint)
                                }
                                .shadow(color: milestone.isUnlocked ? palette.accentGlow : .clear, radius: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(milestone.title)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(palette.ink)
                                    Text(milestone.caption)
                                        .font(.system(size: 12))
                                        .foregroundStyle(palette.muted)
                                }
                                Spacer()
                            }
                            .opacity(milestone.isUnlocked ? 1 : 0.55)
                        }
                    }
                    .padding(18)
                    .cardBackground()
                }
                .padding(20)
            }
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "tab.charms", defaultValue: "Charms"))
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(palette.muted)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(format: String(localized: "charms.header.count", defaultValue: "%d of 12"), store.unlockedCharmIds.count))
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(palette.ink)
            Text(store.unlockedCharmIds.count >= 12
                 ? String(localized: "charms.header.complete", defaultValue: "A complete year")
                 : String(localized: "charms.header.gathering", defaultValue: "Still gathering, one month at a time"))
                .font(.system(size: 14))
                .foregroundStyle(palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(palette.muted)
    }
}

#Preview {
    CharmsView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
