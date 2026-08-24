//
//  SettingsButton.swift
//  WhiteRabbits
//
//  The small bunny-mark circle in the top-right corner.
//

import SwiftUI

struct SettingsMarkButton: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    var body: some View {
        Button {
            Haptics.light()
            isPresented = true
        } label: {
            BunnyMarkView(bunny: store.currentBunny(), style: .mark)
                .frame(width: 22, height: 22)
                .frame(width: 40, height: 40)
                .background(Circle().fill(palette.card))
                .overlay(Circle().strokeBorder(palette.line, lineWidth: 1))
                .shadow(color: palette.ink.opacity(0.08), radius: 20, x: 0, y: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "settings.open", defaultValue: "Open settings"))
    }
}

private struct SettingsSheetModifier: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsMarkButton(isPresented: $showSettings)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }
}

extension View {
    /// Adds the settings cog to this screen's toolbar, and wires it up
    /// to open `SettingsView` in a sheet.
    func settingsButton() -> some View {
        modifier(SettingsSheetModifier())
    }
}
