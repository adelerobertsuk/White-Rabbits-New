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
                .background(palette.bg)

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
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(palette.muted)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headerCopy)
                .font(.system(size: 15))
                .foregroundStyle(palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headerCopy: String {
        store.firstName.isEmpty
            ? String(localized: "circle.header.unnamed", defaultValue: "This is inspiration only. Cheer and reset, never compare.")
            : String(format: String(localized: "circle.header.named", defaultValue: "%@, this is inspiration only. Cheer and reset, never compare."), store.firstName)
    }

    private var onboardingCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "hare.fill")
                .font(.system(size: 22))
                .foregroundStyle(palette.accent)

            Text(String(localized: "circle.onboarding.title", defaultValue: "Opt in, whenever you like"))
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(palette.ink)

            Text(String(localized: "circle.onboarding.body", defaultValue: "A gentle circle for monthly resets. No scores, no streaks, no comparison."))
                .font(.system(size: 14))
                .foregroundStyle(palette.muted)

            VStack(alignment: .leading, spacing: 8) {
                Label(String(localized: "circle.onboarding.shared", defaultValue: "Shared: your name, this month's intention, and your seasonal stamp"), systemImage: "checkmark.circle")
                Label(String(localized: "circle.onboarding.private", defaultValue: "Never shared: journal notes, photographs, and habits"), systemImage: "lock")
            }
            .font(.system(size: 13))
            .foregroundStyle(palette.muted)

            Button {
                Haptics.medium()
                store.joinCircle()
            } label: {
                Text(String(localized: "circle.onboarding.join", defaultValue: "Enter the circle"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PillButtonStyle())
        }
        .padding(18)
        .cardBackground()
    }
}

#Preview {
    CircleView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
