//
//  SettingsButton.swift
//  WhiteRabbits
//
//  The small bunny-mark circle in the top-right corner of every tab,
//  matching the web app's global `.icon-btn` "Open settings" button.
//

import SwiftUI

private struct SettingsToolbarButton: View {
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
                .colorMultiply(palette.accent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(palette.accent.opacity(0.35), lineWidth: 1))
                .shadow(color: palette.ink.opacity(0.08), radius: 20, x: 0, y: 16)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsSheetModifier: ViewModifier {
    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    SettingsToolbarButton(isPresented: $showSettings)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
    }
}

extension View {
    /// Adds the bunny-mark settings button to this screen's toolbar, and
    /// wires it up to open `SettingsView` in a sheet.
    func settingsButton() -> some View {
        modifier(SettingsSheetModifier())
    }
}
