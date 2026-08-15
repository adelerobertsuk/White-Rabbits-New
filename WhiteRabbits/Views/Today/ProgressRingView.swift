//
//  ProgressRingView.swift
//  WhiteRabbits
//
//  The central ring on Today. A faint outer track sits just outside a
//  thicker inner progress ring, so the hero reads as a double ring.
//  The bunny in the middle is the plain brand silhouette (.mark),
//  sized to leave air inside the inner ring.
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
    /// Gap between the outer track and the inner progress ring.
    private var innerInset: CGFloat { 14 }
    private var innerLine: CGFloat { 8 }
    private var bunnySize: CGFloat { ringSize * 0.46 }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .stroke(palette.track, lineWidth: 1.5)

                Circle()
                    .stroke(palette.track, lineWidth: innerLine)
                    .padding(innerInset)

                Circle()
                    .trim(from: 0, to: isCelebratory ? 1 : max(progress, 0.001))
                    .stroke(
                        ringGradient,
                        style: StrokeStyle(lineWidth: innerLine, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(innerInset)
                    .animation(.easeInOut(duration: 0.6), value: progress)

                if isCelebratory {
                    ForEach(0..<8, id: \.self) { i in
                        Image(systemName: "sparkle")
                            .font(.system(size: 10))
                            .foregroundStyle(palette.accent)
                            .offset(
                                x: cos(Double(i) / 8 * 2 * .pi) * (ringSize / 2 + 6),
                                y: sin(Double(i) / 8 * 2 * .pi) * (ringSize / 2 + 6)
                            )
                            .opacity(sparklePhase ? 0.9 : 0.25)
                    }
                }

                BunnyMarkView(bunny: bunny, style: .mark)
                    .frame(width: bunnySize, height: bunnySize)
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
