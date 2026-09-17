//
//  LuckyHourCardView.swift
//  WhiteRabbits
//
//  One optional ritual. Every day, at the user's chosen lucky minute.
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("YOUR LUCKY MINUTE")
                        .kickerStyle()
                    DatePicker(
                        "Lucky minute",
                        selection: Binding(
                            get: { store.luckyMinuteDate },
                            set: { store.setLuckyMinute($0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .font(.system(size: 28, weight: .light))
                    .tint(palette.ink)
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
                        Text(String(localized: "luckyHour.try.action", defaultValue: "Test reminder"))
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
            return String(localized: "luckyHour.denied", defaultValue: "Notifications are off for White Rabbits. Turn them on in Settings so your lucky minute can find you.")
        }
        if store.luckyHourEnabled {
            return String(localized: "luckyHour.on", defaultValue: "A little nod from the universe.")
        }
        return String(localized: "luckyHour.off", defaultValue: "A little nod from the universe.")
    }
}

#Preview {
    LuckyHourCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
