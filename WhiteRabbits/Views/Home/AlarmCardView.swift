//
//  AlarmCardView.swift
//  WhiteRabbits
//
//  One recurring alarm. First of every month. They pick the time.
//

import SwiftUI
import UIKit

struct AlarmCardView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "alarm.kicker", defaultValue: "Charm alarm"))
                        .kickerStyle()
                    ZStack(alignment: .leading) {
                        Text(timeLabel)
                            .font(.system(size: 28, weight: .light))
                            .tracking(-0.8)
                            .foregroundStyle(palette.ink)
                        DatePicker(
                            String(localized: "alarm.time", defaultValue: "Time"),
                            selection: Binding(
                                get: { store.alarmTime },
                                set: { store.setAlarmTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(palette.accent)
                        .scaleEffect(x: 1.6, y: 1.3, anchor: .leading)
                        .opacity(0.02)
                        .frame(width: 128, height: 36, alignment: .leading)
                        .clipped()
                    }
                }
                Spacer()
                SanctuaryToggle(
                    isOn: Binding(
                        get: { store.alarmEnabled },
                        set: { store.setAlarmEnabled($0) }
                    )
                )
            }

            Text(statusLine)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.muted)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Haptics.medium()
                Task { await store.scheduleTestAlarm() }
            } label: {
                Text(String(localized: "settings.tryAlarm.action", defaultValue: "Ring a test"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.ink)
            }
            .buttonStyle(.plain)

            if store.alarmAuthorizationDenied {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                } label: {
                    Text(String(localized: "alarm.openSettings", defaultValue: "Turn on Alarms in Settings"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PillButtonStyle(filled: false))
            }
        }
        .padding(Layout.cardPadding)
        .cardBackground()
    }

    private var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: store.alarmTime)
    }

    private var statusLine: String {
        if store.alarmAuthorizationDenied {
            return String(localized: "alarm.denied", defaultValue: "Alarms are off for White Rabbits. Turn them on in Settings so the first of the month can break through Silent and Focus.")
        }
        if !store.alarmEnabled {
            return String(localized: "alarm.off", defaultValue: "Set it. Forget it. The phone surprises you.")
        }
        if let next = store.nextAlarmDate {
            return String(format: String(localized: "alarm.next", defaultValue: "Next rings %@."), formattedNext(next))
        }
        if store.isSchedulingAlarm {
            return String(localized: "alarm.scheduling", defaultValue: "Setting the alarm.")
        }
        return String(localized: "alarm.on", defaultValue: "The first of every month. Breaks Silent and Focus.")
    }

    private func formattedNext(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("dMMMMhmm")
        return formatter.string(from: date)
    }
}

#Preview {
    AlarmCardView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
        .padding()
}
