//
//  AudioPillView.swift
//  WhiteRabbits
//
//  A small, quiet circle in the corner of Circle for the ambient lofi
//  soundscape, styled exactly like the bunny-mark settings button so
//  it reads as one calm family of icon buttons, not a separate loud
//  control. Tap to turn it on or off; while playing, three small bars
//  breathe in place of a fourth static one.
//

import SwiftUI

struct AudioPillView: View {
    @ObservedObject var manager: AmbientAudioManager
    @Environment(\.palette) private var palette
    @State private var barPhase = false

    var body: some View {
        Button {
            Haptics.light()
            manager.toggle()
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                barPhase = manager.isPlaying
            }
        } label: {
            Group {
                if manager.isPlaying {
                    HStack(spacing: 2.5) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(palette.accent)
                                .frame(width: 2, height: barPhase ? CGFloat(5 + i * 3) : 4)
                        }
                    }
                } else {
                    Image(systemName: "moon.zzz")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(palette.muted)
                }
            }
            .frame(width: 40, height: 40)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay(Circle().strokeBorder(palette.line, lineWidth: 1))
            .shadow(color: palette.ink.opacity(0.08), radius: 20, x: 0, y: 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(manager.isPlaying
            ? String(localized: "audio.playing", defaultValue: "Soft lofi")
            : String(localized: "audio.paused", defaultValue: "Ambient sound"))
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: barPhase)
        .onAppear {
            barPhase = manager.isPlaying
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        AudioPillView(manager: AmbientAudioManager())
    }
    .environment(\.palette, .light)
    .padding()
}
