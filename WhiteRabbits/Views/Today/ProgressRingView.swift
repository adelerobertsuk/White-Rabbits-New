//
//  ProgressRingView.swift
//  WhiteRabbits
//
//  The central ring on Today. It fills smoothly as habits are checked
//  off, and switches to a golden, sparkling "celebratory" look on the
//  1st of the month, before the ritual is said.
//

import SwiftUI

struct ProgressRingView: View {
    var progress: Double
    var isCelebratory: Bool
    var bunny: Bunny
    var doneText: String
    var onTap: () -> Void

    @Environment(\.palette) private var palette
    @State private var sparklePhase: Bool = false

    private var ringSize: CGFloat { 200 }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .stroke(palette.line, lineWidth: 10)

                Circle()
                    .trim(from: 0, to: isCelebratory ? 1 : max(progress, 0.001))
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)
                    .shadow(color: isCelebratory ? palette.accentGlow : .clear, radius: isCelebratory ? 18 : 0)

                if isCelebratory {
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                            .foregroundStyle(palette.accent)
                            .offset(x: cos(Double(i) / 8 * 2 * .pi) * (ringSize / 2 + 6),
                                    y: sin(Double(i) / 8 * 2 * .pi) * (ringSize / 2 + 6))
                            .opacity(sparklePhase ? 0.9 : 0.25)
                    }
                }

                VStack(spacing: 6) {
                    CharmView(bunny: bunny, unlocked: true, size: 56)
                    Text(doneText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(palette.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .frame(width: ringSize, height: ringSize)
        }
        .buttonStyle(.plain)
        .onAppear {
            guard isCelebratory else { return }
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                sparklePhase = true
            }
        }
    }

    private var ringGradient: AngularGradient {
        if isCelebratory {
            return AngularGradient(colors: [palette.accent, Color(hex: bunny.accentHex), palette.accent], center: .center)
        }
        return AngularGradient(colors: [palette.accent, palette.accent.opacity(0.6)], center: .center)
    }
}

#Preview {
    VStack(spacing: 40) {
        ProgressRingView(progress: 0.5, isCelebratory: false, bunny: BunnyData.bunny(forMonth: 8), doneText: "2 kept today", onTap: {})
        ProgressRingView(progress: 1, isCelebratory: true, bunny: BunnyData.bunny(forMonth: 8), doneText: "Begin the month", onTap: {})
    }
    .environment(\.palette, .light)
}
