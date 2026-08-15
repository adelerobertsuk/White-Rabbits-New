//
//  CardBackground.swift
//  WhiteRabbits
//
//  The one editorial card style used everywhere: soft glass, a whisper
//  of a border, and a gentle shadow. Corner radius always 16-24px.
//

import SwiftUI

struct CardBackground: ViewModifier {
    @Environment(\.palette) private var palette
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.card)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(palette.line, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 22) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius))
    }

    /// A small helper so the same code compiles on iOS and macOS: this
    /// title style only exists on iOS, so it's a no-op elsewhere.
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

struct PillButtonStyle: ButtonStyle {
    @Environment(\.palette) private var palette
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(filled ? palette.ink : Color.clear)
            )
            .overlay(
                Capsule().strokeBorder(filled ? Color.clear : palette.line, lineWidth: 1)
            )
            .foregroundStyle(filled ? palette.bg : palette.ink)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
