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
                                    CharmView(bunny: bunny, unlocked: store.unlockedCharmIds.contains(bunny.id))
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
                    .padding(Layout.cardPadding)
                    .cardBackground()

                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle(String(localized: "charms.milestones.title", defaultValue: "Milestones"))

                        ForEach(store.milestones) { milestone in
                            HStack(spacing: 14) {
                                milestoneIcon(milestone)

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
                        }
                    }
                    .padding(Layout.cardPadding)
                    .cardBackground()
                }
                .padding(Layout.screenInset)
            }
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "tab.charms", defaultValue: "Charms"))
                        .kickerStyle()
                }
            }
            .settingsButton()
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(String(format: String(localized: "charms.header.count", defaultValue: "%d of 12"), store.unlockedCharmIds.count))
                .displayTitleStyle()
            Spacer()
            Text(store.unlockedCharmIds.count >= 12
                 ? String(localized: "charms.header.complete", defaultValue: "A complete year")
                 : String(localized: "charms.header.gathering", defaultValue: "Still gathering"))
                .kickerStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .sectionHeaderStyle()
    }

    /// Matches `CharmView`'s own circle-badge-with-glow language, so a
    /// milestone reads as part of the same collection as the seasonal
    /// charms above it, not a plain system-icon afterthought.
    private func milestoneIcon(_ milestone: Milestone) -> some View {
        ZStack {
            Circle()
                .fill(milestone.isUnlocked ? palette.accentGlow : palette.card)
            Circle()
                .strokeBorder(milestone.isUnlocked ? palette.accent.opacity(0.5) : palette.line, lineWidth: milestone.isUnlocked ? 1.5 : 1)
            Image(systemName: milestone.systemImage)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(milestone.isUnlocked ? palette.accent : palette.faint)
        }
        .frame(width: 44, height: 44)
        .shadow(color: milestone.isUnlocked ? palette.accentGlow : .clear, radius: 10)
        .opacity(milestone.isUnlocked ? 1 : 0.55)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: milestone.isUnlocked)
    }
}

#Preview {
    CharmsView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
