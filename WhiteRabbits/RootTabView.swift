//
//  RootTabView.swift
//  WhiteRabbits
//
//  The four tabs: Today, Journal, Circle, Charms.
//

import SwiftUI

enum RootTab { case today, journal, circle, charms }

/// Lets a screen inside one tab switch the app to another tab, e.g.
/// Circle's "Year of luck" teaser linking straight to the Charms tab.
private struct TabSelectionKey: EnvironmentKey {
    static let defaultValue: Binding<RootTab> = .constant(.today)
}

extension EnvironmentValues {
    var tabSelection: Binding<RootTab> {
        get { self[TabSelectionKey.self] }
        set { self[TabSelectionKey.self] = newValue }
    }
}

struct RootTabView: View {
    @State private var selection: RootTab = .today

    var body: some View {
        PaletteProvider {
            TintedTabs(selection: $selection)
        }
    }
}

/// Reads the live `Palette` (which already accounts for system dark mode
/// and the "Dark evening" override) to tint the tab bar correctly in both
/// appearances, and gives the bar itself a soft material instead of the
/// plain system default.
private struct TintedTabs: View {
    @Binding var selection: RootTab
    @Environment(\.palette) private var palette

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tag(RootTab.today)
                .tabItem {
                    Label { Text(String(localized: "tab.today", defaultValue: "Today")) } icon: { TabIcons.today }
                }

            JournalView()
                .tag(RootTab.journal)
                .tabItem {
                    Label { Text(String(localized: "tab.journal", defaultValue: "Journal")) } icon: { TabIcons.journal }
                }

            CircleView()
                .tag(RootTab.circle)
                .tabItem {
                    Label { Text(String(localized: "tab.circle", defaultValue: "Circle")) } icon: { TabIcons.circle }
                }

            CharmsView()
                .tag(RootTab.charms)
                .tabItem {
                    Label { Text(String(localized: "tab.charms", defaultValue: "Charms")) } icon: { TabIcons.charms }
                }
        }
        .tint(palette.accent)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environment(\.tabSelection, $selection)
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppStore())
}
