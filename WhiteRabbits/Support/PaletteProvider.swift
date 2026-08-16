//
//  PaletteProvider.swift
//  WhiteRabbits
//
//  Reads the system color scheme and hands every child a matching Palette.
//  Settings' "Dark evening" toggle can force dark mode on.
//

import SwiftUI

struct PaletteProvider<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var store: AppStore
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .environment(\.palette, store.forceDarkMode ? .dark : Palette.current(for: colorScheme))
            .preferredColorScheme(store.forceDarkMode ? .dark : nil)
    }
}
