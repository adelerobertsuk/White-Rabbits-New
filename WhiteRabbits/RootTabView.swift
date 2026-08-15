//
//  RootTabView.swift
//  WhiteRabbits
//
//  The four tabs: Today, Journal, Circle, Charms.
//

import SwiftUI

struct RootTabView: View {
    var body: some View {
        PaletteProvider {
            TabView {
                TodayView()
                    .tabItem {
                        Label(String(localized: "tab.today", defaultValue: "Today"), systemImage: "hare.fill")
                    }

                JournalView()
                    .tabItem {
                        Label(String(localized: "tab.journal", defaultValue: "Journal"), systemImage: "book.closed.fill")
                    }

                CircleView()
                    .tabItem {
                        Label(String(localized: "tab.circle", defaultValue: "Circle"), systemImage: "person.2.fill")
                    }

                CharmsView()
                    .tabItem {
                        Label(String(localized: "tab.charms", defaultValue: "Charms"), systemImage: "seal.fill")
                    }
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppStore())
}
