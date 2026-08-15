//
//  CircleView.swift
//  WhiteRabbits
//
//  Tab 3: the shared sanctuary. Inspiration only, never a scoreboard.
//

import SwiftUI

struct CircleView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @StateObject private var audio = AmbientAudioManager()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 18) {
                        header
                            .padding(.top, 8)

                        if store.circleJoined {
                            MyIntentionCardView()
                            FriendsSparksView()
                            YearOfLuckStampCardView()

                            Button(role: .destructive) {
                                store.leaveCircle()
                            } label: {
                                Text(String(localized: "circle.leave", defaultValue: "Step out of the circle"))
                                    .font(.system(size: 13))
                            }
                            .padding(.top, 4)
                        } else {
                            onboardingCard
                        }
                    }
                    .padding(20)
                    .padding(.top, 44)
                    .padding(.bottom, 24)
                }
                .sanctuaryBackground()

                HStack {
                    Spacer()
                    AudioPillView(manager: audio)
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
            }
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "tab.circle", defaultValue: "Circle"))
                        .font(.system(size: 10, weight: .medium))
                        .textCase(.uppercase)
                        .tracking(2.2)
                        .foregroundStyle(palette.muted)
                }
            }
            .settingsButton()
        }
        .task {
            await store.ensureCircleSession()
        }
    }

    private var header: some View {
        VStack(alignment: store.circleJoined ? .leading : .center, spacing: 4) {
            Text(headerCopy)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(store.circleJoined ? .leading : .center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: store.circleJoined ? .leading : .center)
    }

    private var headerCopy: String {
        store.firstName.isEmpty
            ? String(localized: "circle.header.unnamed", defaultValue: "This is inspiration only. Cheer a reset. Never weigh it.")
            : String(format: String(localized: "circle.header.named", defaultValue: "%@, this is inspiration only. Cheer a reset. Never weigh it."), store.firstName)
    }

    private var onboardingCard: some View {
        VStack(spacing: 16) {
            BunnyMarkView(bunny: store.currentBunny(), style: .mark)
                .frame(width: 44, height: 44)
                .padding(14)
                .background(Circle().fill(palette.card))

            VStack(spacing: 8) {
                Text(String(localized: "circle.onboarding.title", defaultValue: "Opt in, whenever you like"))
                    .font(.system(size: 10, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(2.2)
                    .foregroundStyle(palette.muted)

                Text(String(localized: "circle.onboarding.heading", defaultValue: "Shared Sanctuary"))
                    .font(.system(size: 32, weight: .light))
                    .tracking(-1.28)
                    .foregroundStyle(palette.ink)

                Text(String(localized: "circle.onboarding.body", defaultValue: "A gentle circle for monthly resets. No scores, no streaks, no comparison."))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                onboardingRow(
                    title: String(localized: "circle.onboarding.shared.title", defaultValue: "Shared, if you join"),
                    body: String(localized: "circle.onboarding.shared", defaultValue: "Your name, this month's intention, and your seasonal stamp.")
                )
                onboardingRow(
                    title: String(localized: "circle.onboarding.private.title", defaultValue: "Never shared"),
                    body: String(localized: "circle.onboarding.private", defaultValue: "Journal notes, photographs, voice transcripts, and habits stay on this phone.")
                )
            }

            Button {
                Haptics.medium()
                store.joinCircle()
            } label: {
                Text(String(localized: "circle.onboarding.join", defaultValue: "Enter the circle"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle())
        }
        .padding(20)
        .cardBackground()
    }

    private func onboardingRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1.44)
                .foregroundStyle(palette.ink)
            Text(body)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(palette.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(palette.line, lineWidth: 1)
        )
    }
}

#Preview {
    CircleView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
