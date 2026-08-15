//
//  Palette.swift
//  WhiteRabbits
//
//  The app's design tokens. Every screen pulls its colors from here,
//  never a hardcoded hex value, so light and dark mode always match.
//

import SwiftUI

struct Palette {
    let bg: Color
    let card: Color
    let ink: Color
    let muted: Color
    let faint: Color
    let line: Color
    let accent: Color
    let accentGlow: Color

    static let light = Palette(
        bg: Color(hex: "F6F1EA"),
        card: Color(hex: "FFFCF8").opacity(0.78),
        ink: Color(hex: "2A2622"),
        muted: Color(hex: "7A736B"),
        faint: Color(hex: "B7AEA4"),
        line: Color(hex: "2A2622").opacity(0.1),
        accent: Color(hex: "C4A36A"),
        accentGlow: Color(hex: "C4A36A").opacity(0.3)
    )

    static let dark = Palette(
        bg: Color(hex: "161412"),
        card: Color(hex: "241C1C").opacity(0.78),
        ink: Color(hex: "F3ECE4"),
        muted: Color(hex: "A39A90"),
        faint: Color(hex: "6E675F"),
        line: Color(hex: "F3ECE4").opacity(0.1),
        accent: Color(hex: "D4B57A"),
        accentGlow: Color(hex: "D4B57A").opacity(0.24)
    )

    static func current(for scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = .light
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

/// Reads the system color scheme and hands every child view a matching
/// `Palette` through the environment. Put this once near the root.
struct PaletteProvider<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .environment(\.palette, Palette.current(for: colorScheme))
    }
}

extension Color {
    init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        cleaned = cleaned.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xFF) / 255.0
        let g = Double((value >> 8) & 0xFF) / 255.0
        let b = Double(value & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
