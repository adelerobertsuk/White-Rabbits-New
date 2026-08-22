//
//  StampCardView.swift
//  WhiteRabbits
//
//  Twelve months. A month's own bunny artwork is revealed only once
//  that month's ritual has been said, in the same neutral bone/dark
//  tile as a closed door — no colour, no fill. Only the current month
//  carries a soft luminous edge, the same restrained language as the
//  hero medallion. Every other month waits behind a closed door: a
//  single embossed ✦, nothing more.
//

import SwiftUI

struct StampCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme

    /// Local, short-lived animation state for the one door that can ever
    /// be tapped open: the current month, on the day its ritual is said.
    /// Purely presentational — `store.completeRitual()` is what actually
    /// persists the unlock. Kept as separate beats (press, recede, reveal,
    /// sparkle) rather than one crossfade, and held true for the whole
    /// sequence so a mid-animation store update can't cut it short.
    @State private var isAnimatingReveal = false
    @State private var doorPressed = false
    @State private var doorDismissed = false
    @State private var bunnyRevealed = false
    @State private var showRevealSparkle = false
    @State private var bloomOpacity: Double = 0
    @State private var underLightOpacity: Double = 0
    @State private var bunnyLift: CGFloat = 0
    @State private var bunnyScale: CGFloat = 0.92
    @State private var sparkleBurst: Double = 0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)
    private var current: Bunny { store.currentBunny() }
    private var canRevealCurrent: Bool {
        store.isFirstOfMonth() && !store.ritualCompleted()
    }

    private var currentYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }

    /// Roughly where the current month sits in the 4-column grid, so the
    /// bloom can originate near it rather than from dead centre.
    private var bloomCenter: UnitPoint {
        let index = current.month - 1
        let row = index / 4
        let col = index % 4
        let x = (CGFloat(col) + 0.5) / 4
        let headerFraction: CGFloat = 0.16
        let y = headerFraction + (1 - headerFraction) * (CGFloat(row) + 0.5) / 3
        return UnitPoint(x: x, y: y)
    }

    private var bloomColor: Color {
        // Light: cool pearl, not warm accent (that read as muddy beige).
        // Dark: unchanged approved white.
        colorScheme == .dark ? .white : Color.white
    }

    private var bloomPeakOpacity: Double {
        colorScheme == .dark ? 0.55 : 0.72
    }

    /// Soft cool illumination for the current month in Light Mode only.
    private var lightCurrentGlow: Color {
        Color(red: 0.92, green: 0.94, blue: 0.97)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentYear)
                        .kickerStyle()
                    Text(String(localized: "circle.stampCard.title", defaultValue: "Year of luck"))
                        .font(.system(size: 24, weight: .light))
                        .tracking(-0.96)
                        .foregroundStyle(palette.ink)
                }
                Spacer()
                Text(String(format: String(localized: "circle.stampCard.countShort", defaultValue: "%d OF 12"), store.unlockedCharmIds.count))
                    .kickerStyle()
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(BunnyData.all) { bunny in
                    stampCell(bunny)
                }
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 14)
        .padding(.bottom, 12)
        .cardBackground(dashed: true)
        .overlay {
            RadialGradient(
                colors: [bloomColor.opacity(bloomOpacity), bloomColor.opacity(0)],
                center: bloomCenter,
                startRadius: 0,
                endRadius: 240
            )
            .blendMode(.screen)
            .allowsHitTesting(false)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteRitual)) { _ in
            guard !isAnimatingReveal else { return }
            triggerReveal(for: current, alreadyCompleted: true)
        }
    }

    private func stampCell(_ bunny: Bunny) -> some View {
        let unlocked = store.unlockedCharmIds.contains(bunny.id)
        let isCurrent = bunny.id == current.id
        let tappable = isCurrent && !unlocked && canRevealCurrent

        return VStack(spacing: 5) {
            Group {
                if tappable || (isCurrent && isAnimatingReveal) {
                    revealableDoor(bunny)
                } else if unlocked {
                    monthTile(bunny, isCurrent: isCurrent)
                } else {
                    closedDoor()
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)

            Text(monthAbbrev(bunny.month))
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.12)
                .textCase(.uppercase)
                .foregroundStyle(isCurrent && (unlocked || bunnyRevealed) ? palette.ink : palette.faint)
        }
    }

    /// The one door that can ever be tapped: the current month, closed,
    /// on the day its ritual is said. Door and bunny both stay in the
    /// hierarchy the whole time, each with its own animated opacity, so
    /// the door can finish receding before the bunny starts to appear —
    /// a clean handoff rather than one crossfade.
    @ViewBuilder
    private func revealableDoor(_ bunny: Bunny) -> some View {
        ZStack {
            // Tile plate (illuminated current-month treatment once revealed).
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(palette.line, lineWidth: 0.75)
                }
                .materialEmboss(colorScheme, strength: 0.55)
                .opacity(bunnyRevealed || doorDismissed ? 1 : 0)

            // Light that appears underneath as the door opens.
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            lightCurrentGlow.opacity(0.55),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 48
                    )
                )
                .blendMode(colorScheme == .dark ? .screen : .plusLighter)
                .opacity(underLightOpacity)

            if bunnyRevealed || doorDismissed {
                currentMonthRim()
            }

            BunnyMarkView(bunny: bunny, unlocked: true, style: .charm, monochrome: true)
                .padding(6)
                .scaleEffect(bunnyScale)
                .offset(y: bunnyLift)
                .opacity(bunnyRevealed ? 1 : 0)

            closedDoor()
                .scaleEffect(doorPressed ? 0.94 : 1)
                .offset(y: doorPressed ? 1.5 : 0)
                .opacity(doorDismissed ? 0 : 1)

            if showRevealSparkle {
                constellationBurst
            }
        }
        .compositingGroup()
        .shadow(
            color: bunnyRevealed
                ? (colorScheme == .dark ? palette.accent.opacity(0.55) : lightCurrentGlow.opacity(0.7))
                : .clear,
            radius: bunnyRevealed ? 14 : 0
        )
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isAnimatingReveal else { return }
            triggerReveal(for: bunny, alreadyCompleted: false)
        }
    }

    private var constellationBurst: some View {
        let sizes: [CGFloat] = [5, 7, 6, 8, 5, 9, 6, 7, 5, 8, 6, 7]
        let glyphs = ["✦", "✧", "⋆", "✦", "✧", "⋆", "✦", "✧", "⋆", "✦", "✧", "⋆"]
        return ZStack {
            ForEach(0..<12, id: \.self) { i in
                let angle = Double(i) * (.pi / 6.0)
                let distBase = 22.0 + Double(i % 3) * 10.0
                let dist = distBase + sparkleBurst * (14.0 + Double(i % 4) * 4.0)
                Text(glyphs[i])
                    .font(.system(size: sizes[i], weight: .light))
                    .foregroundStyle(sparkleColor)
                    .offset(x: cos(angle) * dist, y: sin(angle) * dist - Double(bunnyLift) * 0.3)
                    .opacity(max(0.0, 1.0 - sparkleBurst * 0.55))
                    .scaleEffect(0.85 + sparkleBurst * 0.35)
            }
        }
        .allowsHitTesting(false)
    }

    private var sparkleColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.92) : lightCurrentGlow.opacity(0.95)
    }

    @ViewBuilder
    private func currentMonthRim() -> some View {
        if colorScheme == .dark {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                .blur(radius: 1.2)
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            lightCurrentGlow.opacity(0.35),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 52
                    )
                )
                .blendMode(.plusLighter)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.95), lineWidth: 1.25)
                .blur(radius: 0.9)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(lightCurrentGlow.opacity(0.65), lineWidth: 0.75)
        }
    }

    /// press → light haptic → door responds → door recedes → under-light →
    /// bunny appears with one tiny hop → pearl bloom + constellation →
    /// success haptic at the peak → settle into permanent glow.
    private func triggerReveal(for bunny: Bunny, alreadyCompleted: Bool) {
        isAnimatingReveal = true
        bunnyLift = 6
        bunnyScale = 0.88
        sparkleBurst = 0
        underLightOpacity = 0
        bloomOpacity = 0

        Haptics.light()
        withAnimation(.easeOut(duration: 0.12)) {
            doorPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeInOut(duration: 0.26)) {
                doorDismissed = true
            }
            withAnimation(.easeOut(duration: 0.28)) {
                underLightOpacity = colorScheme == .dark ? 0.7 : 0.9
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            if !alreadyCompleted {
                store.completeRitual()
            }
            withAnimation(.easeOut(duration: 0.18)) {
                bunnyRevealed = true
            }
            // One tiny joyful hop — then soft settle.
            withAnimation(.spring(response: 0.34, dampingFraction: 0.52)) {
                bunnyLift = -7
                bunnyScale = 1.06
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            withAnimation(.easeOut(duration: 0.22)) {
                bloomOpacity = bloomPeakOpacity
                sparkleBurst = 1
            }
            withAnimation(.easeOut(duration: 0.12)) {
                showRevealSparkle = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            // Peak of hop + poof.
            Haptics.success()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.62) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                bunnyLift = 0
                bunnyScale = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            withAnimation(.easeInOut(duration: 0.35)) {
                showRevealSparkle = false
                sparkleBurst = 1.35
                underLightOpacity = 0.25
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.15) {
            withAnimation(.easeInOut(duration: 0.45)) {
                bloomOpacity = 0
                underLightOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.45) {
            isAnimatingReveal = false
            doorPressed = false
            doorDismissed = false
            bunnyRevealed = false
            showRevealSparkle = false
            bunnyLift = 0
            bunnyScale = 1
            sparkleBurst = 0
            underLightOpacity = 0
        }
    }

    // MARK: - Months still to come: a quiet door, not a lock

    /// Bone-on-bone (or dark-on-dark), a single embossed ✦. No bunny,
    /// no padlock, no preview — just a tactile, gently raised mark.
    @ViewBuilder
    private func closedDoor() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(palette.card)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(palette.line, lineWidth: 0.75)
            }
            .materialEmboss(colorScheme, strength: 0.55)
            .overlay {
                Text("✦")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(palette.bg)
                    .materialEmboss(colorScheme, strength: 1)
            }
    }

    // MARK: - Months already here: the original artwork

    /// Nothing about a month that's already happened is hidden — it
    /// shows its own bunny and seasonal prop, in the same neutral ink as
    /// every other revealed month: no pastel fills, no coloured
    /// backgrounds. Same bone/dark tile and embossed surface as a closed
    /// door — the only difference is the bunny is visible. The current
    /// month alone carries the same restrained luminous edge as the hero
    /// medallion; every other revealed month is visible but not glowing.
    @ViewBuilder
    private func monthTile(_ bunny: Bunny, isCurrent: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.card)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(palette.line, lineWidth: 0.75)
                }
                .materialEmboss(colorScheme, strength: 0.55)

            if isCurrent {
                currentMonthRim()
            }

            BunnyMarkView(bunny: bunny, unlocked: true, style: .charm, monochrome: true)
                .padding(6)
        }
        .shadow(
            color: isCurrent
                ? (colorScheme == .dark
                    ? palette.accent.opacity(0.7)
                    : lightCurrentGlow.opacity(0.85))
                : .clear,
            radius: isCurrent ? (colorScheme == .dark ? 20 : 16) : 0
        )
        .shadow(
            color: isCurrent
                ? (colorScheme == .dark
                    ? palette.accent.opacity(0.5)
                    : Color.white.opacity(0.95))
                : .clear,
            radius: isCurrent ? (colorScheme == .dark ? 8 : 10) : 0,
            y: isCurrent && colorScheme == .light ? -1 : 0
        )
    }

    private func monthAbbrev(_ month: Int) -> String {
        var components = DateComponents()
        components.year = Calendar.current.component(.year, from: Date())
        components.month = month
        components.day = 1
        let date = Calendar.current.date(from: components) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "LLL"
        return formatter.string(from: date)
    }
}

#Preview {
    StampCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
