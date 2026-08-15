//
//  RootTabView.swift
//  WhiteRabbits
//
//  The four tabs: Today, Journal, Circle, Charms.
//

import SwiftUI

enum RootTab { case today, journal, circle, charms }

struct RootTabView: View {
    @State private var selection: RootTab = .today

    var body: some View {
        PaletteProvider {
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
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppStore())
}
