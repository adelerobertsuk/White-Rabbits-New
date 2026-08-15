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
                Group {
                    if store.circleJoined {
                        joinedContent
                    } else {
                        unjoinedContent
                    }
                }
                .sanctuaryBackground()

                HStack {
                    Spacer()
                    AudioPillView(manager: audio)
                }
                .padding(.horizontal, Layout.screenInset)
                .padding(.top, 6)
            }
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "tab.circle", defaultValue: "Circle"))
                        .kickerStyle()
                }
            }
            .settingsButton()
        }
        .task {
            await store.ensureCircleSession()
        }
    }

    private var joinedContent: some View {
        ScrollView {
            VStack(spacing: Layout.stackSpacing) {
                MyIntentionCardView()
                FriendsSparksView()
                YearOfLuckStampCardView()

                Button(role: .destructive) {
                    store.leaveCircle()
                } label: {
                    Text(String(localized: "circle.leave", defaultValue: "Step out of the circle"))
                        .bodyStyle(muted: true)
                }
                .padding(.top, 4)
            }
            .padding(Layout.screenInset)
            .padding(.top, 36)
            .padding(.bottom, 20)
        }
    }

    private var unjoinedContent: some View {
        VStack {
            Spacer(minLength: 56)
            onboardingCard
                .padding(.horizontal, Layout.screenInset)
            Spacer(minLength: 40)
        }
    }

    private var onboardingCard: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(palette.card)
                    .frame(width: 72, height: 72)
                    .shadow(color: palette.ink.opacity(0.08), radius: 6, x: 0, y: 3)
                BunnyMarkView(bunny: store.currentBunny(), style: .mark)
                    .frame(width: 36, height: 36)
            }
            .overlay(
                Circle()
                    .strokeBorder(palette.accent.opacity(0.35), lineWidth: 1)
            )

            VStack(spacing: 8) {
                Text(String(localized: "circle.onboarding.title", defaultValue: "Opt in, whenever you like"))
                    .kickerStyle()

                Text(String(localized: "circle.onboarding.heading", defaultValue: "Shared Sanctuary"))
                    .displayTitleStyle()
                    .multilineTextAlignment(.center)

                Text(String(localized: "circle.onboarding.body", defaultValue: "A gentle circle for monthly resets. No scores, no streaks, no comparison."))
                    .readingStyle(muted: true)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 0) {
                onboardingRow(
                    title: String(localized: "circle.onboarding.shared.title", defaultValue: "Shared, if you join"),
                    body: String(localized: "circle.onboarding.shared", defaultValue: "Your name, this month's intention, and your seasonal stamp.")
                )
                Rectangle()
                    .fill(palette.line)
                    .frame(height: 1)
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
        .padding(24)
        .frame(maxWidth: .infinity)
        .cardBackground()
    }

    private func onboardingRow(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .kickerStyle()
            Text(body)
                .readingStyle(muted: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }
}

#Preview {
    CircleView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
