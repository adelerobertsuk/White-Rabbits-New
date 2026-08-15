//
//  CharmView.swift
//  WhiteRabbits
//
//  Draws one seasonal charm badge. Unlocked charms are full color with
//  a soft glow; locked ones are a faint outline waiting its turn.
//
//  Adele: to use your own artwork later, drop images named
//  "charm-<id>" (e.g. "charm-harvest") into Assets.xcassets and swap
//  the `Image(systemName:)` below for `Image("charm-\(bunny.id)")`.
//

import SwiftUI

struct CharmView: View {
    let bunny: Bunny
    var unlocked: Bool
    var size: CGFloat = 64

    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Circle()
                .fill(unlocked ? Color(hex: bunny.fillHex) : palette.card)
            Circle()
                .strokeBorder(unlocked ? Color(hex: bunny.strokeHex) : palette.line, lineWidth: unlocked ? 1.5 : 1)
            Image(systemName: "hare.fill")
                .font(.system(size: size * 0.42, weight: .medium))
                .foregroundStyle(unlocked ? Color(hex: bunny.strokeHex) : palette.faint)
        }
        .frame(width: size, height: size)
        .shadow(color: unlocked ? Color(hex: bunny.accentHex).opacity(0.55) : .clear, radius: unlocked ? size * 0.22 : 0)
        .opacity(unlocked ? 1 : 0.55)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: unlocked)
    }
}

#Preview {
    HStack(spacing: 16) {
        CharmView(bunny: BunnyData.bunny(id: "harvest"), unlocked: true)
        CharmView(bunny: BunnyData.bunny(id: "frost"), unlocked: false)
    }
    .padding()
    .environment(\.palette, .light)
}
