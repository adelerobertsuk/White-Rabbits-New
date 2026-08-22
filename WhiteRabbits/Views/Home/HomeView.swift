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
    @State private var showSettings = false

    private var canSayIt: Bool { store.isFirstOfMonth() && !store.ritualCompleted() }
    private var ringProgress: CGFloat {
        CGFloat(store.unlockedCharmIds.count) / 12
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 4) {
                    chrome
                    hero
                    StampCardView()
                }
                .padding(.horizontal, Layout.screenInset)
                .padding(.bottom, 8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .sanctuaryBackground()
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .presentationDragIndicator(.visible)
                    .presentationBackground {
                        SanctuaryBackground()
                    }
            }
            .task {
                await store.refreshScheduledItems()
                store.noteOpened()
                offerReviewIfReady()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await store.refreshScheduledItems() }
                    store.noteOpened()
                    offerReviewIfReady()
                }
            }
            .onChange(of: showSettings) { _, open in
                if !open { offerReviewIfReady() }
            }
        }
    }

    private var chrome: some View {
        HStack {
            Text(dateKicker)
                .kickerStyle()
            Spacer()
            SettingsMarkButton(isPresented: $showSettings)
        }
        .padding(.top, 2)
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
            .padding(.bottom, 10)

            wordmark

            if canSayIt {
                Text(greeting)
                    .font(.system(size: 14, weight: .regular))
                    .tracking(0.14)
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            Text(giftLine)
                .font(.system(size: 16, weight: .light))
                .tracking(-0.4)
                .lineSpacing(4)
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 6)

            if canSayIt {
                Button {
                    sayTheWords()
                } label: {
                    Text(String(localized: "ritual.sayIt", defaultValue: "Say White Rabbits"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle())
                .padding(.top, 6)
            }

            luckyShare
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    /// Ink on the 1st. The rest of the year it sits in the paper, like a letterpress stamp.
    private var wordmark: some View {
        let lit = store.isFirstOfMonth()
        return Text("White Rabbits")
            .font(.system(size: 34, weight: .light))
            .tracking(-1.9)
            .lineSpacing(-1.6)
            .multilineTextAlignment(.center)
            .foregroundStyle(palette.ink.opacity(lit ? 1 : 0.28))
            .shadow(color: lit ? .clear : palette.bg.opacity(0.95), radius: 0, y: 0.8)
            .shadow(color: lit ? .clear : palette.ink.opacity(0.1), radius: 0, y: -0.5)
            .animation(.easeOut(duration: 0.7), value: lit)
            .accessibilityHidden(!lit)
    }

    private var dateKicker: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return String(format: String(localized: "home.dateKicker", defaultValue: "Today  ·  %@"), formatter.string(from: Date()))
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
        if canSayIt {
            return String(localized: "greeting.ritual", defaultValue: "White Rabbits, White Rabbits!")
        }
        if shouldShowIntention {
            return store.intention
        }
        return Affirmations.line()
    }

    private var luckyShare: some View {
        TimelineView(.periodic(from: .now, by: 20)) { context in
            if store.shouldOfferLuckyShare(at: context.date) {
                LuckyHourShareLink {
                    Text(String(localized: "luckyHour.share.action", defaultValue: "Share today's luck"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(filled: false))
                .tint(palette.ink)
                .padding(.top, 8)
            }
        }
    }

    /// Past-you, three times a month: the 1st, 11th and 21st.
    private var shouldShowIntention: Bool {
        guard !store.intention.isEmpty else { return false }
        let day = Calendar.current.component(.day, from: Date())
        return day == 1 || day == 11 || day == 21
    }

    private func sayTheWords() {
        Haptics.success()
        store.completeRitual()
        withAnimation(.easeOut(duration: 0.7)) {
            didCelebrate = true
        }
        offerReviewIfReady(delay: 2.4)
    }

    /// Apple's own stars sheet. Once, after a week of coming back.
    /// Never on top of saying White Rabbits.
    private func offerReviewIfReady(delay: Double = 1.2) {
        guard !canSayIt, !showSettings, store.isEligibleForReview else { return }
        store.markReviewPrompted()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(delay))
            requestReview()
        }
    }
}

/// Hero ring. Most days he sits still.
/// On the 1st he breathes. When you say the words, he comes alive once.
private struct HeroRingView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.colorScheme) private var colorScheme
    var progress: CGFloat
    var enchanted: Bool
    var celebrating: Bool

    private let ringSize: CGFloat = 210
    private let bunnyPadding: CGFloat = 42
    private let medallionPadding: CGFloat = 22
    private let trackPadding: CGFloat = 8
    private let sparkleRadius: CGFloat = 90

    @State private var tilt: Double = 0
    @State private var lift: CGFloat = 0
    @State private var breathe = false
    @State private var sparkleTurn: Double = 0
    @State private var sparkleOut = false
    /// A brief, subtle brightening of the ring's own glow at the moment
    /// a month is revealed — not a redesign, just a transient pulse.
    @State private var pulseGlow = false

    private var tubeCore: Color {
        colorScheme == .dark
            ? Color.white.opacity(0.95)
            : Color.white
    }

    private var tubePearl: Color {
        colorScheme == .dark
            ? Color(red: 0.94, green: 0.95, blue: 0.98)
            : Color(red: 0.92, green: 0.94, blue: 0.97)
    }

    private var tubeWarm: Color {
        palette.accent.opacity(colorScheme == .dark ? 0.55 : 0.4)
    }

    var body: some View {
        ZStack {
            // Recessed channel — dormant tube, fine and architectural.
            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.black.opacity(0.65)
                        : palette.ink.opacity(0.06),
                    lineWidth: 5.2
                )
                .blur(radius: 0.55)
                .padding(trackPadding)

            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.07)
                        : palette.ink.opacity(0.045),
                    lineWidth: 3.6
                )
                .padding(trackPadding)

            // Inner lip of the channel (catches a little ambient light).
            Circle()
                .stroke(
                    colorScheme == .dark
                        ? Color.white.opacity(0.14)
                        : Color.white.opacity(0.55),
                    lineWidth: 1.15
                )
                .blur(radius: colorScheme == .dark ? 0.8 : 0.5)
                .padding(trackPadding)

            // Soft outer bloom of the lit segment (the tube glowing through the surface).
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    tubePearl.opacity(colorScheme == .dark ? 0.55 : 0.7),
                    style: StrokeStyle(lineWidth: 7.5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .blur(radius: colorScheme == .dark ? 5.5 : 4.5)
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

            // Bright core of the embedded LED strip.
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
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
                    ),
                    style: StrokeStyle(lineWidth: 2.35, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .padding(trackPadding)
                .shadow(
                    color: tubePearl.opacity(pulseGlow ? 0.95 : 0.7),
                    radius: pulseGlow ? 12 : 7
                )
                .shadow(
                    color: colorScheme == .dark
                        ? Color.white.opacity(pulseGlow ? 0.55 : 0.28)
                        : Color.white.opacity(pulseGlow ? 0.9 : 0.55),
                    radius: pulseGlow ? 16 : 9
                )
                .animation(.easeOut(duration: 0.8), value: progress)

            // A shallow porcelain/frosted-glass medallion: a soft radial
            // fill so it reads as lit from within, a delicate luminous
            // rim (cool pearl in light; white catch in dark), the original
            // fine edge, and a shallow shadow. Progress arc and bunny stay.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.96),
                            colorScheme == .dark
                                ? palette.card
                                : Color(red: 0.96, green: 0.97, blue: 0.99).opacity(0.9),
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
                        .stroke(
                            colorScheme == .dark ? Color.white.opacity(0.5) : Color.white.opacity(0.95),
                            lineWidth: colorScheme == .dark ? 1 : 1.25
                        )
                        .padding(medallionPadding)
                        .blur(radius: colorScheme == .dark ? 1.2 : 1.4)
                        .opacity(colorScheme == .dark ? 0.7 : 0.85)
                }
                .overlay {
                    Circle()
                        .strokeBorder(palette.line, lineWidth: 0.75)
                        .padding(medallionPadding)
                }
                .shadow(
                    color: colorScheme == .dark
                        ? palette.ink.opacity(0.05)
                        : Color(red: 0.55, green: 0.58, blue: 0.64).opacity(0.12),
                    radius: colorScheme == .dark ? 14 : 16,
                    y: colorScheme == .dark ? 8 : 6
                )

            BunnyMarkView(bunny: store.currentBunny(), style: .asset)
                .padding(bunnyPadding)
                .offset(y: lift)
                .rotationEffect(.degrees(tilt), anchor: .bottom)
                .scaleEffect(breathe ? 1.03 : 1)

            if enchanted || celebrating {
                ForEach(0..<6, id: \.self) { i in
                    Image(systemName: "sparkle")
                        .font(.system(size: 8, weight: .light))
                        .foregroundStyle(palette.accent)
                        .offset(
                            x: cos(Double(i) * .pi / 3 + sparkleTurn) * sparkleRadius,
                            y: sin(Double(i) * .pi / 3 + sparkleTurn) * sparkleRadius
                        )
                        .opacity(sparkleOut ? 0 : (enchanted ? 0.55 : 1))
                        .scaleEffect(sparkleOut ? 1.4 : 1)
                }
            }
        }
        .frame(width: ringSize, height: ringSize)
        .shadow(
            color: colorScheme == .dark
                ? Color.white.opacity(pulseGlow ? 0.28 : 0.14)
                : Color(red: 0.92, green: 0.94, blue: 0.97).opacity(pulseGlow ? 0.95 : 0.7),
            radius: pulseGlow ? 28 : (colorScheme == .dark ? 20 : 22),
            y: colorScheme == .dark ? 12 : 10
        )
        .shadow(
            color: colorScheme == .dark
                ? palette.accent.opacity(pulseGlow ? 0.35 : 0.18)
                : Color.white.opacity(pulseGlow ? 0.9 : 0.65),
            radius: colorScheme == .dark ? (pulseGlow ? 22 : 14) : (pulseGlow ? 18 : 12),
            y: colorScheme == .dark ? 8 : -2
        )
        .onAppear { settleIntoTheDay() }
        .onChange(of: enchanted) { _, on in
            if on { settleIntoTheDay() }
        }
        .onChange(of: celebrating) { _, on in
            if on { comeAlive() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didCompleteRitual)) { _ in
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
        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) {
            sparkleTurn = .pi * 2
        }
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
