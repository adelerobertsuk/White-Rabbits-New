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

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .tint(Palette.light.accent)
        }
    }
}
