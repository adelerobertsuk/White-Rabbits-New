//
//  AudioPillView.swift
//  WhiteRabbits
//
//  A small floating pill, tucked in the corner of Circle, for the
//  soft lofi soundscape. Tap to turn it on or off.
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
            if manager.isPlaying {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    barPhase.toggle()
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: manager.isPlaying ? "waveform" : "waveform.slash")
                    .font(.system(size: 13, weight: .medium))
                Text(manager.isPlaying
                     ? String(localized: "audio.playing", defaultValue: "Soft lofi")
                     : String(localized: "audio.paused", defaultValue: "Ambient sound"))
                    .font(.system(size: 13, weight: .medium))
                if manager.isPlaying {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { i in
                            Capsule()
                                .fill(palette.accent)
                                .frame(width: 2.5, height: barPhase ? CGFloat(6 + i * 3) : 4)
                                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(Double(i) * 0.12), value: barPhase)
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(palette.ink)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(palette.line, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .onAppear {
            if manager.isPlaying { barPhase = true }
        }
    }
}

#Preview {
    AudioPillView(manager: AmbientAudioManager())
        .environment(\.palette, .light)
        .padding()
}
