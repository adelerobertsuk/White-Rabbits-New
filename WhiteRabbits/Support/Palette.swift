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
    let track: Color
    let accent: Color
    let accentGlow: Color

    static let light = Palette(
        bg: Color(hex: "F6F1EA"),
        card: Color(hex: "FFFCF8").opacity(0.78),
        ink: Color(hex: "2A2622"),
        muted: Color(hex: "7A736B"),
        faint: Color(hex: "B7AEA4"),
        line: Color(hex: "2A2622").opacity(0.1),
        track: Color(hex: "2A2622").opacity(0.08),
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
        track: Color(hex: "F3ECE4").opacity(0.1),
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
///
/// Settings' "Dark evening" toggle can force dark mode on regardless of
/// the system setting, matching the web app's manual theme override.
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

/// The app's spacing and radius scale, so every screen reaches for the
/// same handful of numbers instead of inventing a new one each time.
enum Layout {
    /// The gap from a screen's edge to its content.
    static let screenInset: CGFloat = 18
    /// The gap between a card's border and what's inside it.
    static let cardPadding: CGFloat = 16
    /// Vertical gap between stacked cards on a screen.
    static let stackSpacing: CGFloat = 16
    /// Corner radius for cards (the app's primary "surface").
    static let cardRadius: CGFloat = 20
    /// Corner radius for buttons and other small controls.
    static let controlRadius: CGFloat = 16
    /// Corner radius for a large photo living inside a card, e.g. a
    /// journal entry's hero image.
    static let mediaRadiusLarge: CGFloat = 16
    /// Corner radius for a small thumbnail, e.g. a list row's photo.
    static let mediaRadiusSmall: CGFloat = 12
}

/// The uppercase micro-label used for things like "AUGUST INTENTION" or
/// "TODAY · AUGUST 2026": the smallest, quietest text in the hierarchy.
private struct KickerText: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .semibold))
            .textCase(.uppercase)
            .tracking(2.2)
            .foregroundStyle(palette.muted)
    }
}

/// The uppercase label for a card or list section, e.g. "SUGGESTIONS",
/// "FRIENDS": one step louder than a kicker.
private struct SectionHeaderText: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .semibold))
            .textCase(.uppercase)
            .tracking(1.56)
            .foregroundStyle(palette.muted)
    }
}

/// A screen's own title, e.g. "Charms", "Quiet settings."
private struct DisplayTitleText: ViewModifier {
    @Environment(\.palette) private var palette
    var weight: Font.Weight = .light
    func body(content: Content) -> some View {
        content
            .font(.system(size: 28, weight: weight))
            .tracking(-1.0)
            .foregroundStyle(palette.ink)
    }
}

/// Everyday UI copy: list rows, greetings, captions on cards.
private struct BodyText: ViewModifier {
    @Environment(\.palette) private var palette
    var weight: Font.Weight = .regular
    var muted: Bool = false
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: weight))
            .foregroundStyle(muted ? palette.muted : palette.ink)
    }
}

/// The smallest supporting line under a field or row.
private struct CaptionText: ViewModifier {
    @Environment(\.palette) private var palette
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(palette.muted)
    }
}

/// Longer editorial lines: journal pages, intention sentences, quotes.
private struct ReadingText: ViewModifier {
    @Environment(\.palette) private var palette
    var muted: Bool = false
    func body(content: Content) -> some View {
        content
            .font(.system(size: 14, weight: .regular, design: .serif))
            .lineSpacing(3)
            .foregroundStyle(muted ? palette.muted : palette.ink)
    }
}

extension View {
    func kickerStyle() -> some View { modifier(KickerText()) }
    func sectionHeaderStyle() -> some View { modifier(SectionHeaderText()) }
    func displayTitleStyle(weight: Font.Weight = .light) -> some View { modifier(DisplayTitleText(weight: weight)) }
    func bodyStyle(weight: Font.Weight = .regular, muted: Bool = false) -> some View { modifier(BodyText(weight: weight, muted: muted)) }
    func captionStyle() -> some View { modifier(CaptionText()) }
    func readingStyle(muted: Bool = false) -> some View { modifier(ReadingText(muted: muted)) }
}

/// The soft glow that sits behind every screen: a warm radial highlight
/// fading into the base background, matching the web app's
/// `radial-gradient(120% 70% at 50% -8%, accent-glow, transparent 52%)`.
struct SanctuaryBackground: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            palette.bg
            GeometryReader { geo in
                EllipticalGradient(
                    gradient: Gradient(colors: [palette.accentGlow, palette.accentGlow.opacity(0)]),
                    center: .center,
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.52
                )
                .frame(width: geo.size.width * 1.2, height: geo.size.height * 0.7)
                .position(x: geo.size.width * 0.5, y: geo.size.height * -0.08)
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    /// Applies the app's warm sanctuary backdrop behind a screen's content.
    func sanctuaryBackground() -> some View {
        background(SanctuaryBackground())
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
