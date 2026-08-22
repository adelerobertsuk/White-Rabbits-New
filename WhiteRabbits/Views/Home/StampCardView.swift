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
    /// A soft, temporary light wash across the card at the moment of
    /// reveal — pure lighting, not a permanent UI change.
    @State private var bloomOpacity: Double = 0

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
        colorScheme == .dark ? .white : palette.accent
    }

    private var bloomPeakOpacity: Double {
        colorScheme == .dark ? 0.55 : 0.32
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
            monthTile(bunny, isCurrent: true)
                .opacity(bunnyRevealed ? 1 : 0)

            closedDoor()
                .scaleEffect(doorPressed ? 0.96 : 1)
                .opacity(doorDismissed ? 0 : 1)

            Text("✦")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(palette.accent)
                .opacity(showRevealSparkle ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isAnimatingReveal else { return }
            triggerReveal(for: bunny, alreadyCompleted: false)
        }
    }

    /// The single reveal sequence, however it starts: the primary path is
    /// automatic, the instant the first-of-month ritual is completed
    /// (`.didCompleteRitual`, `alreadyCompleted: true`); the fallback is a
    /// direct tap on the still-closed current door, which completes the
    /// ritual itself partway through. Same choreography either way:
    /// press (light haptic, tiny scale-down) → the door recedes and fades
    /// away cleanly → the existing bunny underneath appears smoothly in
    /// place → a tiny ✦ moment with a success haptic and a soft light
    /// bloom across the card → everything breathes back to settle.
    private func triggerReveal(for bunny: Bunny, alreadyCompleted: Bool) {
        isAnimatingReveal = true

        Haptics.light()
        withAnimation(.easeOut(duration: 0.08)) {
            doorPressed = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.2)) {
                doorDismissed = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            if !alreadyCompleted {
                store.completeRitual()
            }
            withAnimation(.easeOut(duration: 0.22)) {
                bunnyRevealed = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Haptics.success()
            withAnimation(.easeOut(duration: 0.1)) {
                showRevealSparkle = true
            }
            withAnimation(.easeOut(duration: 0.15)) {
                bloomOpacity = bloomPeakOpacity
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) {
            withAnimation(.easeInOut(duration: 0.14)) {
                showRevealSparkle = false
            }
        }

        // The bloom holds at its peak briefly, then breathes back down
        // rather than cutting off — slower and later than the door/bunny
        // mechanics, which settle on their own at 0.85s.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.5)) {
                bloomOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            isAnimatingReveal = false
            doorPressed = false
            doorDismissed = false
            bunnyRevealed = false
            showRevealSparkle = false
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
                // A white rim reads clearly in dark mode but is nearly
                // invisible against the pale bone tile in light mode, so
                // the warm accent edge carries the illumination in light
                // mode while the white rim adds the cool pearlescent
                // catch in dark mode.
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.85) : palette.accent.opacity(0.95), lineWidth: 1.5)
                    .blur(radius: colorScheme == .dark ? 1.2 : 0.6)
            }

            BunnyMarkView(bunny: bunny, unlocked: true, style: .charm, monochrome: true)
                .padding(6)
        }
        .shadow(
            color: isCurrent ? palette.accent.opacity(colorScheme == .dark ? 0.7 : 0.6) : .clear,
            radius: isCurrent ? 20 : 0
        )
        .shadow(
            color: isCurrent ? palette.accent.opacity(colorScheme == .dark ? 0.5 : 0.35) : .clear,
            radius: isCurrent ? 8 : 0
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
