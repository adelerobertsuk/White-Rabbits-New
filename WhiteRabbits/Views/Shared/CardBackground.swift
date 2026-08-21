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
    var cornerRadius: CGFloat = 20
    var dashed: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(palette.card)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        palette.line,
                        style: StrokeStyle(lineWidth: 1, dash: dashed ? [5, 4] : [])
                    )
            )
            // Matches the web app's `box-shadow: 0 16px 40px rgba(42,38,34,0.08)`.
            .shadow(color: palette.ink.opacity(0.08), radius: 20, x: 0, y: 16)
    }
}

extension View {
    func cardBackground(cornerRadius: CGFloat = 20, dashed: Bool = false) -> some View {
        modifier(CardBackground(cornerRadius: cornerRadius, dashed: dashed))
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

/// Matches the web app's `.primary` / `.ghost` buttons: a 16px rounded
/// rectangle (not a full pill), 50pt tall, semibold 13pt label.
struct PillButtonStyle: ButtonStyle {
    @Environment(\.palette) private var palette
    var filled: Bool = true
    /// Full-size CTAs (like "Enter the circle") are 50pt tall; compact ones
    /// (like the inline "New Entry" button) are sized to their label.
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: compact ? 11 : 12, weight: .semibold))
            .tracking(compact ? 0.8 : 1.0)
            .frame(minHeight: compact ? 0 : 50)
            .padding(.horizontal, compact ? 14 : 18)
            .padding(.vertical, compact ? 8 : 0)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(filled ? palette.ink : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(filled ? Color.clear : palette.line, lineWidth: 1)
            )
            .shadow(color: filled && !compact ? palette.ink.opacity(0.08) : .clear, radius: 20, x: 0, y: 16)
            .foregroundStyle(filled ? palette.bg : palette.ink)
            // Compact pills stay visually small, but always keep a real
            // 44pt tap target so they're comfortable to hit.
            .frame(minHeight: compact ? 44 : 0)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

/// A little switch: a 48x30 capsule track that turns ink-colored when on,
/// with a sliding card-colored knob.
struct SanctuaryToggle: View {
    @Binding var isOn: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        Button {
            Haptics.light()
            isOn.toggle()
        } label: {
            Capsule()
                .fill(isOn ? palette.accent : palette.track)
                .frame(width: 48, height: 30)
                .overlay(
                    Circle()
                        .fill(palette.card)
                        .frame(width: 24, height: 24)
                        .shadow(color: palette.ink.opacity(isOn ? 0.12 : 0.06), radius: 2, y: 1)
                        .padding(3)
                        .offset(x: isOn ? 18 : 0),
                    alignment: .leading
                )
                .animation(.easeOut(duration: 0.2), value: isOn)
        }
        .buttonStyle(.plain)
    }
}
