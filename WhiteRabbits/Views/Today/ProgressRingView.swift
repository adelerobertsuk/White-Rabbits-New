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
    var onTap: () -> Void

    @Environment(\.palette) private var palette
    @State private var sparklePhase: Bool = false

    private var ringSize: CGFloat { 248 }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // The web app always casts a soft accent-colored shadow behind
                // this whole ring group (`filter: drop-shadow(...)`), which is
                // what makes the ring read as a "double ring": a crisp track
                // plus its own soft glowing halo just outside it. Gating that
                // shadow to celebratory-only (as this used to) made every
                // ordinary day look like a single flat ring, so it's on here
                // all the time, just brighter and bigger on the 1st.
                Circle()
                    .stroke(palette.track, lineWidth: 10)

                Circle()
                    .trim(from: 0, to: isCelebratory ? 1 : max(progress, 0.001))
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.6), value: progress)

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

                BunnyMarkView(bunny: bunny, style: .mark)
                    .frame(width: ringSize * 0.62, height: ringSize * 0.62)
            }
            .frame(width: ringSize, height: ringSize)
            .background(
                Circle()
                    .fill(palette.card)
                    .padding(6)
            )
            .shadow(color: palette.accentGlow, radius: isCelebratory ? 24 : 14, x: 0, y: isCelebratory ? 4 : 10)
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
        ProgressRingView(progress: 0.5, isCelebratory: false, bunny: BunnyData.bunny(forMonth: 8), onTap: {})
        ProgressRingView(progress: 1, isCelebratory: true, bunny: BunnyData.bunny(forMonth: 8), onTap: {})
    }
    .environment(\.palette, .light)
}
