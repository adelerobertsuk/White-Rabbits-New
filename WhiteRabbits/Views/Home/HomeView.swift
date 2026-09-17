//
//  HomeView.swift
//  WhiteRabbits
//
//  The original Today: ink bunny in a thin ring, White Rabbits,
//  a quiet greeting, then the year of stamps.
//  Alarm and intention live behind the settings cog.
//

import SwiftUI
import StoreKit

struct HomeView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    @State private var didCelebrate = false
    @State private var showMonthlyReveal = false
    @State private var hasStartedMonthlyReveal = false
    @State private var showIntentionPrompt = false

    private var canSayIt: Bool { store.isFirstOfMonth() && !store.ritualCompleted() }
    private var ringProgress: CGFloat {
        CGFloat(store.unlockedCharmIds.count) / 12
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    chrome
                    hero
                }
                .padding(.horizontal, Layout.screenInset)
                .padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .sanctuaryBackground()
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await store.refreshScheduledItems()
                store.noteOpened()
                startMonthlyRevealIfNeeded()
                presentIntentionPromptIfNeeded()
                offerReviewIfReady()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await store.refreshScheduledItems() }
                    store.noteOpened()
                    offerReviewIfReady()
                }
            }
            .overlay {
                if showMonthlyReveal {
                    monthlyReveal
                }
            }
        }
    }

    private var chrome: some View {
        HStack {
            Text(dateKicker)
                .kickerStyle()
            Spacer()
            BunnyMarkView(bunny: store.currentBunny(), style: .mark)
                .frame(width: 22, height: 22)
                .opacity(0.72)
        }
        .padding(.top, 8)
    }

    private var hero: some View {
        VStack(spacing: 0) {
            Button {
                guard canSayIt else { return }
                sayTheWords()
            } label: {
                HeroRingView(progress: ringProgress, enchanted: canSayIt, celebrating: didCelebrate)
            }
            .buttonStyle(.plain)
            .disabled(!canSayIt)
            .padding(.top, 22)
            .padding(.bottom, 22)

            if canSayIt {
                Text(greeting)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.14)
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            Text(giftLine)
                .font(.system(size: 25, weight: .light, design: .serif))
                .tracking(-0.3)
                .lineSpacing(6.8)
                .foregroundStyle(palette.ink.opacity(0.95))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Rectangle().fill(palette.line).frame(width: 42, height: 1)
                    Image(systemName: "sparkle")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(palette.coolPearl)
                    Rectangle().fill(palette.line).frame(width: 42, height: 1)
                }
                Text(luckyMinuteLabel)
                    .font(.system(size: 25, weight: .light, design: .serif))
                    .tracking(2.4)
                    .foregroundStyle(palette.ink)
                LuckyHourShareLink {
                    Text("Share Your Luck")
                }
                .buttonStyle(PillButtonStyle(filled: false, compact: true))
                .accessibilityLabel("Share your luck")
            }
            .padding(.top, 28)

            if canSayIt {
                Button {
                    sayTheWords()
                } label: {
                    Text(String(localized: "ritual.sayIt", defaultValue: "Say White Rabbits"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle())
                .padding(.top, 8)
            }

        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .sheet(isPresented: $showIntentionPrompt) {
            IntentionPromptView()
        }
    }

    private var dateKicker: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return String(format: String(localized: "home.dateKicker", defaultValue: "White Rabbits  ·  %@"), formatter.string(from: Date()))
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let month = store.monthName()
        let name = store.firstName
        if hour < 12 {
            return name.isEmpty
                ? String(format: String(localized: "greeting.morning.unnamed", defaultValue: "Good morning. %@ is yours."), month)
                : String(format: String(localized: "greeting.morning.named", defaultValue: "Good morning, %@. %@ is yours."), name, month)
        }
        if hour < 18 {
            return name.isEmpty
                ? String(format: String(localized: "greeting.afternoon.unnamed", defaultValue: "Good afternoon. %@ is yours."), month)
                : String(format: String(localized: "greeting.afternoon.named", defaultValue: "Good afternoon, %@. %@ is yours."), name, month)
        }
        return name.isEmpty
            ? String(format: String(localized: "greeting.evening.unnamed", defaultValue: "Good evening. %@ is yours."), month)
            : String(format: String(localized: "greeting.evening.named", defaultValue: "Good evening, %@. %@ is yours."), name, month)
    }

    /// A daily treat under the bunny. Your own note surfaces a few times a month.
    private var giftLine: String {
        store.dailyGiftLine()
    }

    private var luckyMinuteLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: store.luckyMinuteDate)
    }

    private var monthlyReveal: some View {
        ZStack {
            palette.bg.opacity(0.92)
                .ignoresSafeArea()
            RadialGradient(
                colors: [palette.card.opacity(0.96), palette.accentGlow.opacity(0.55), .clear],
                center: .center,
                startRadius: 4,
                endRadius: 260
            )
            .ignoresSafeArea()
            .phaseAnimator([false, true]) { content, phase in
                content.opacity(phase ? 0.78 : 0.5).scaleEffect(phase ? 1.04 : 0.96)
            } animation: { _ in
                .easeInOut(duration: 2.4)
            }

            VStack(spacing: 24) {
                BunnyMarkView(bunny: store.currentBunny(), style: .asset)
                    .frame(width: 190, height: 190)
                    .phaseAnimator([false, true]) { content, phase in
                        content.scaleEffect(phase ? 1.04 : 0.98).opacity(phase ? 1 : 0.86)
                    } animation: { _ in
                        .easeInOut(duration: 1.8)
                    }
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(palette.accent)
                    .phaseAnimator([false, true]) { content, phase in
                        content.opacity(phase ? 1 : 0.42).scaleEffect(phase ? 1.12 : 0.9)
                    } animation: { _ in
                        .easeInOut(duration: 1.3)
                    }
                Text("\(store.monthName().uppercased()) IS YOURS.")
                    .font(.system(size: 15, weight: .medium))
                    .tracking(2.1)
                    .foregroundStyle(palette.ink)
            }
        }
        .transition(.opacity)
    }

    private func startMonthlyRevealIfNeeded() {
        guard canSayIt, !hasStartedMonthlyReveal else { return }
        hasStartedMonthlyReveal = true
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.7))
            Haptics.soft()
            withAnimation(.easeInOut(duration: 0.8)) {
                showMonthlyReveal = true
            }
            try? await Task.sleep(for: .seconds(0.8))
            store.completeRitual()
            Haptics.success()
            try? await Task.sleep(for: .seconds(2.0))
            withAnimation(.easeInOut(duration: 0.8)) {
                showMonthlyReveal = false
            }
            presentIntentionPromptIfNeeded()
        }
    }

    private func sayTheWords() {
        Haptics.success()
        store.completeRitual()
        withAnimation(.easeOut(duration: 0.7)) {
            didCelebrate = true
        }
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.9))
            presentIntentionPromptIfNeeded()
        }
        offerReviewIfReady(delay: 2.4)
    }

    private func presentIntentionPromptIfNeeded() {
        guard store.isFirstOfMonth(), store.ritualCompleted(), !store.hasHandledCurrentMonthIntentionPrompt else { return }
        guard !showIntentionPrompt else { return }
        showIntentionPrompt = true
    }

    /// Apple's own stars sheet. Once, after a week of coming back.
    /// Never on top of saying White Rabbits.
    private func offerReviewIfReady(delay: Double = 1.2) {
        guard !canSayIt, store.isEligibleForReview else { return }
        store.markReviewPrompted()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            requestReview()
        }
    }
}

private struct IntentionPromptView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var intention = ""

    var body: some View {
        VStack(spacing: 22) {
            Capsule()
                .fill(palette.line)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            Text("What would you like to carry into this month?")
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            TextField("", text: $intention, axis: .vertical)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(palette.ink)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(palette.card)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(palette.line, lineWidth: 1)
                }
                .padding(.horizontal, 24)
                .onChange(of: intention) { _, value in
                    if value.count > 120 {
                        intention = String(value.prefix(120))
                    }
                }

            HStack(spacing: 14) {
                Button("Skip") {
                    store.markCurrentMonthIntentionPromptHandled()
                    dismiss()
                }
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(palette.muted)

                Button {
                    store.setIntention(intention)
                    store.markCurrentMonthIntentionPromptHandled()
                    dismiss()
                } label: {
                    Text("Keep this")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(compact: true))
                .disabled(intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(intention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .sanctuaryBackground()
        .onAppear { intention = store.intention }
    }
}

/// The original 248pt ring. Most days he sits still.
/// On the 1st he breathes. When you say the words, he comes alive once.
private struct HeroRingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    var progress: CGFloat
    var enchanted: Bool
    var celebrating: Bool

    private let ringSize: CGFloat = 248
    private let bunnyPadding: CGFloat = 50
    private let medallionPadding: CGFloat = 26
    private let trackPadding: CGFloat = 10
    private let sparkleRadius: CGFloat = 108

    @State private var tilt: Double = 0
    @State private var lift: CGFloat = 0
    @State private var breathe = false
    @State private var orbitStarted = Date()
    @State private var orbitCelebration = false
    @State private var sparkleOut = false
    /// A brief, subtle brightening of the ring's own glow at the moment
    /// a month is revealed — not a redesign, just a transient pulse.
    @State private var pulseGlow = false

    private var tubeCore: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.95)
            : palette.ink.opacity(0.22)
    }

    private var tubePearl: Color {
        colorScheme == .dark
            ? Color(red: 0.94, green: 0.95, blue: 0.98)
            : palette.accent.opacity(0.55)
    }

    private var tubeWarm: Color {
        palette.accent.opacity(colorScheme == .dark ? 0.55 : 0.35)
    }

    var body: some View {
        ZStack {
            if colorScheme == .dark {
                // Recessed channel — dormant tube, fine and architectural.
                Circle()
                    .stroke(Color.black.opacity(0.65), lineWidth: 5.2)
                    .blur(radius: 0.55)
                    .padding(trackPadding)

                Circle()
                    .stroke(Color.white.opacity(0.07), lineWidth: 3.6)
                    .padding(trackPadding)
            } else {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [palette.pearl, palette.card, palette.pearlGlow],
                            center: .center,
                            startRadius: 8,
                            endRadius: ringSize / 2
                        )
                    )
                    .padding(18)
                    .overlay {
                        Circle()
                            .stroke(palette.pearlGlow, lineWidth: 1)
                            .padding(18)
                    }
                    .shadow(color: palette.pearlGlow.opacity(0.8), radius: 18, y: 8)

                // Quiet pearl outline around the bunny.
                Circle()
                    .stroke(palette.coolPearl.opacity(0.45), lineWidth: 1.75)
                    .padding(11)


            }

            // Inner lip of the channel (catches a little ambient light).
            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.14)
                        : palette.line,
                    lineWidth: 1.15
                )
                .blur(radius: colorScheme == .dark ? 0.8 : 0)
                .padding(trackPadding)
                .opacity(colorScheme == .dark ? 1 : 0)

            if colorScheme == .dark {
                // Soft outer bloom of the lit segment (the tube glowing through the surface).
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        tubePearl.opacity(0.55),
                        style: StrokeStyle(lineWidth: 7.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 5.5)
                    .padding(trackPadding)
                    .opacity(pulseGlow ? 1 : 0.85)

                // Warm secondary halo — restrained, not neon.
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        tubeWarm,
                        style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .blur(radius: 3.2)
                    .padding(trackPadding)
            }

            // Bright core of the embedded LED strip.
            Circle()
                .trim(from: 0, to: colorScheme == .dark ? progress : 1)
                .stroke(
                    colorScheme == .dark
                        ? AnyShapeStyle(
                            AngularGradient(
                                colors: [
                                    tubeCore.opacity(0.55),
                                    tubePearl,
                                    tubeCore,
                                    tubeWarm.opacity(0.85),
                                    tubePearl,
                                    tubeCore.opacity(0.55)
                                ],
                                center: .center,
                                angle: .degrees(-90)
                            )
                        )
                        : AnyShapeStyle(palette.pearl),
                    style: StrokeStyle(lineWidth: colorScheme == .dark ? 2.35 : 2.2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(trackPadding)
                .shadow(
                    color: colorScheme == .dark
                        ? tubePearl.opacity(pulseGlow ? 0.95 : 0.7)
                        : palette.pearl.opacity(0.65),
                    radius: pulseGlow ? 12 : 7
                )
                .shadow(
                    color: colorScheme == .dark
                        ? Color.white.opacity(pulseGlow ? 0.55 : 0.28)
                        : .clear,
                    radius: pulseGlow ? 16 : 9
                )
                .opacity(colorScheme == .dark ? 1 : 0)
                .animation(.easeOut(duration: 0.8), value: progress)

            // Medallion: calm off-white in light mode (matches widget); lit porcelain in dark.
            Group {
                if colorScheme == .dark {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    palette.card,
                                    palette.card
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: ringSize / 2
                            )
                        )
                        .padding(medallionPadding)
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                .padding(medallionPadding)
                                .blur(radius: 1.2)
                                .opacity(0.7)
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(palette.line, lineWidth: 0.75)
                                .padding(medallionPadding)
                        }
                        .shadow(color: palette.ink.opacity(0.05), radius: 14, y: 8)
                } else {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.28), palette.card, palette.card],
                                center: .topLeading,
                                startRadius: 0,
                                endRadius: ringSize / 2
                            )
                        )
                        .padding(medallionPadding)
                        .overlay {
                            Circle()
                                .strokeBorder(palette.ultraviolet.opacity(0.42), lineWidth: 0.9)
                                .padding(medallionPadding)
                        }
                        .shadow(color: palette.ultravioletGlow, radius: 18, y: 5)
                        .shadow(color: Color.white.opacity(0.42), radius: 4)
                }
            }

            BunnyMarkView(bunny: store.currentBunny(), style: .asset)
                .padding(bunnyPadding)
                .offset(y: lift)
                .rotationEffect(.degrees(tilt), anchor: .bottom)
                .scaleEffect(breathe ? 1.03 : 1)

            if enchanted || orbitCelebration {
                TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { context in
                    let elapsed = context.date.timeIntervalSince(orbitStarted)
                    let turn = reduceMotion ? 0 : elapsed / (orbitCelebration ? 2.0 : 8.0) * 360
                    ZStack {
                        Circle()
                            .stroke(palette.pearl.opacity(0.95), lineWidth: 2.5)
                            .padding(11)
                            .shadow(color: palette.pearl, radius: 7)

                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [.clear, .clear, palette.warmPearl.opacity(0.7), Color.white, .clear],
                                    center: .center
                                ),
                                lineWidth: 4.5
                            )
                            .rotationEffect(.degrees(turn))
                            .padding(11)
                            .shadow(color: palette.warmPearl.opacity(0.9), radius: 10)
                            .shadow(color: Color.white, radius: 4)

                        ZStack {
                            ForEach(0..<6, id: \.self) { i in
                                Image(systemName: "sparkle")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(palette.accent)
                                    .shadow(color: Color.white, radius: 4)
                                    .offset(
                                        x: cos(Double(i) * .pi / 3) * sparkleRadius,
                                        y: sin(Double(i) * .pi / 3) * sparkleRadius
                                    )
                            }
                        }
                        .rotationEffect(.degrees(turn))
                    }
                    .opacity(orbitCelebration ? 1 : 0.9)
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }

        }
        .frame(width: ringSize, height: ringSize)
        .shadow(
            color: colorScheme == .dark
                ? Color.white.opacity(pulseGlow ? 0.28 : 0.14)
                : palette.accentGlow.opacity(pulseGlow ? 0.35 : 0.22),
            radius: colorScheme == .dark ? (pulseGlow ? 28 : 20) : (pulseGlow ? 18 : 14),
            y: colorScheme == .dark ? 12 : 10
        )
        .shadow(
            color: colorScheme == .dark
                ? palette.accent.opacity(pulseGlow ? 0.35 : 0.18)
                : .clear,
            radius: colorScheme == .dark ? (pulseGlow ? 22 : 14) : 0,
            y: colorScheme == .dark ? 8 : 0
        )
        .task(id: orbitCelebration) {
            guard orbitCelebration else { return }
            // Three gentle beats build to the end of the first full orbit.
            for beat in 0..<3 {
                do {
                    try await Task.sleep(for: .milliseconds(650))
                } catch {
                    return
                }
                guard !Task.isCancelled, scenePhase == .active else { return }
                if beat == 2 {
                    Haptics.medium()
                } else {
                    Haptics.soft()
                }
            }
        }
        .onAppear { settleIntoTheDay() }
        .onChange(of: enchanted) { _, on in
            if on { settleIntoTheDay() }
        }
        .onChange(of: celebrating) { _, on in
            if on { comeAlive() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteRitual)) { _ in
            orbitStarted = Date()
            orbitCelebration = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                orbitCelebration = false
            }
            withAnimation(.easeOut(duration: 0.25)) {
                pulseGlow = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    pulseGlow = false
                }
            }
        }
    }

    private func settleIntoTheDay() {
        tilt = 0
        lift = 0
        sparkleOut = false
        guard enchanted else {
            breathe = false
            return
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            breathe = true
        }
        orbitStarted = Date()
    }

    private func comeAlive() {
        breathe = false
        withAnimation(.spring(response: 0.32, dampingFraction: 0.42)) {
            tilt = -8
            lift = -8
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5).delay(0.16)) {
            tilt = 6
            lift = 2
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.36)) {
            tilt = 0
            lift = 0
        }
        withAnimation(.easeOut(duration: 0.9).delay(0.2)) {
            sparkleOut = true
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
