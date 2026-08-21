//
//  LuckyHourCardView.swift
//  WhiteRabbits
//
//  One optional ritual. Every day, exactly 11:11, local to this phone.
//

import SwiftUI
import UIKit

struct LuckyHourCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "luckyHour.kicker", defaultValue: "Lucky minute"))
                        .kickerStyle()
                    Text("11:11")
                        .font(.system(size: 28, weight: .light))
                        .tracking(-0.8)
                        .foregroundStyle(palette.ink)
                }
                Spacer()
                SanctuaryToggle(
                    isOn: Binding(
                        get: { store.luckyHourEnabled },
                        set: { store.setLuckyHourEnabled($0) }
                    )
                )
            }

            Text(statusLine)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.muted)
                .fixedSize(horizontal: false, vertical: true)

            if store.luckyHourEnabled {
                HStack(spacing: 18) {
                    Button {
                        Haptics.medium()
                        Task { await store.scheduleTestLuckyHour() }
                    } label: {
                        Text(String(localized: "luckyHour.try.action", defaultValue: "Send a test"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(palette.ink)
                    }
                    .buttonStyle(.plain)

                    LuckyHourShareLink {
                        Text(String(localized: "luckyHour.share.action", defaultValue: "Share today's luck"))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(palette.ink)
                    }
                    .buttonStyle(.plain)
                    .tint(palette.ink)
                }
            }

            if store.luckyHourAuthorizationDenied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Text(String(localized: "luckyHour.openSettings", defaultValue: "Turn on Notifications in Settings"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(filled: false))
            }
        }
        .padding(Layout.cardPadding)
        .cardBackground()
    }

    private var statusLine: String {
        if store.luckyHourAuthorizationDenied {
            return String(localized: "luckyHour.denied", defaultValue: "Notifications are off for White Rabbits. Turn them on in Settings so 11:11 can find you.")
        }
        if store.luckyHourEnabled {
            return String(localized: "luckyHour.on", defaultValue: "Every day, exactly 11:11, on this phone. A little nod from the universe.")
        }
        return String(localized: "luckyHour.off", defaultValue: "A little daily nod. Turn it on, and the bunny will tap you when the numbers line up.")
    }
}

#Preview {
    LuckyHourCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
