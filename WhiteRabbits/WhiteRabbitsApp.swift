//
//  WhiteRabbitsApp.swift
//  WhiteRabbits
//
//  App entry point. One shared AppStore lives here and is handed down
//  to every screen, so the whole app always reads from the same
//  on-device data.
//

import SwiftUI

@main
struct WhiteRabbitsApp: App {
    @StateObject private var store = AppStore()

    init() {
        LuckyHourScheduler.shared.prepare()
    }

    var body: some Scene {
        WindowGroup {
            PaletteProvider {
                TabView {
                    HomeView()
                        .tabItem {
                            Label {
                                Text("Home")
                            } icon: {
                                Image(systemName: "house")
                                    .font(.system(size: 15, weight: .light))
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                    CollectionView()
                        .tabItem {
                            Label {
                                Text("Collection")
                            } icon: {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 15, weight: .light))
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                    SettingsView()
                        .tabItem {
                            Label {
                                Text("Settings")
                            } icon: {
                                Image(systemName: "moon")
                                    .font(.system(size: 15, weight: .light))
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                }
                .tint(Palette.light.accent)
                .toolbarBackground(.visible, for: .tabBar)
                .toolbarBackground(Palette.light.card.opacity(0.94), for: .tabBar)
            }
            .environmentObject(store)
        }
    }
}

struct CollectionView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                StampCardView()
                    .padding(.horizontal, Layout.screenInset + 2)
                    .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .sanctuaryBackground()
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
