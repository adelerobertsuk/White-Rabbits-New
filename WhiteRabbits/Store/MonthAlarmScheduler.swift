//
//  MonthAlarmScheduler.swift
//  WhiteRabbits
//
//  AlarmKit only repeats weekly, so the first of the month is a queue
//  of one-shot alarms. Set it once, then the next year is already waiting.
//

import Foundation
import SwiftUI
import UserNotifications

import AlarmKit
import AppIntents
import ActivityKit

struct WhiteRabbitsAlarmMetadata: AlarmMetadata {}

struct OpenWhiteRabbitsIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Say White Rabbits"
    static var openAppWhenRun = true
    static var isDiscoverable = false

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct MonthAlarmSyncResult {
    var denied: Bool
    var nextDate: Date?
}

@MainActor
final class MonthAlarmScheduler {
    static let shared = MonthAlarmScheduler()

    static let testAlarmID = UUID(uuidString: "B8A1B1E5-0001-4000-8000-000000000001")!
    static let notificationPrefix = "white-rabbits.month"
    static let testNotificationID = "white-rabbits.month.test"

    private let manager = AlarmManager.shared

    private init() {}

    func sync(enabled: Bool, hour: Int, minute: Int) async throws -> MonthAlarmSyncResult {
        let center = UNUserNotificationCenter.current()
        await removeNotificationRequests(from: center)

        guard enabled else {
            return MonthAlarmSyncResult(denied: false, nextDate: nil)
        }

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            return MonthAlarmSyncResult(denied: true, nextDate: nil)
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                return MonthAlarmSyncResult(denied: true, nextDate: nil)
            }
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }

        let upcoming = Self.upcomingFirsts(count: 12, hour: hour, minute: minute)
        for date in upcoming {
            let content = UNMutableNotificationContent()
            content.title = "White Rabbits"
            content.body = "The first of the month is here."
            content.sound = .default
            content.userInfo = ["kind": "monthlyCharm"]
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.notificationID(for: date),
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }

        return MonthAlarmSyncResult(denied: false, nextDate: upcoming.first)
    }

    func scheduleTest() async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        }
        center.removePendingNotificationRequests(withIdentifiers: [Self.testNotificationID])
        let content = UNMutableNotificationContent()
        content.title = "White Rabbits"
        content.body = "Your monthly charm is waiting."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        try await center.add(UNNotificationRequest(
            identifier: Self.testNotificationID,
            content: content,
            trigger: trigger
        ))
    }

    private func cancelMonthlyAlarms() {
        let alarms = (try? manager.alarms) ?? []
        for alarm in alarms where alarm.id != Self.testAlarmID {
            try? manager.cancel(id: alarm.id)
        }
    }

    private func removeNotificationRequests(from center: UNUserNotificationCenter) async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending
            .filter { $0.identifier.hasPrefix("\(Self.notificationPrefix).") }
            .map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func notificationID(for date: Date) -> String {
        let day = Calendar.current.startOfDay(for: date).timeIntervalSince1970
        return "\(notificationPrefix).\(Int(day))"
    }

    private func scheduleFixed(date: Date, id: UUID) async throws {
        let bunny = BunnyData.bunny(forMonth: Calendar.current.component(.month, from: date))
        let alert = AlarmPresentation.Alert(
            title: "White Rabbits",
            secondaryButton: AlarmButton(
                text: "Say it",
                textColor: .white,
                systemImageName: "sparkle"
            ),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<WhiteRabbitsAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: WhiteRabbitsAlarmMetadata(),
            tintColor: Color(hex: bunny.accentHex)
        )
        let configuration = AlarmManager.AlarmConfiguration.alarm(
            schedule: .fixed(date),
            attributes: attributes,
            secondaryIntent: OpenWhiteRabbitsIntent(),
            sound: .default
        )
        _ = try await manager.schedule(id: id, configuration: configuration)
    }

    static func upcomingFirsts(count: Int, hour: Int, minute: Int, from now: Date = Date()) -> [Date] {
        let calendar = Calendar.current
        var year = calendar.component(.year, from: now)
        var month = calendar.component(.month, from: now)
        var dates: [Date] = []

        while dates.count < count {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = 1
            components.hour = hour
            components.minute = minute
            components.second = 0
            if let date = calendar.date(from: components), date > now {
                dates.append(date)
            }
            month += 1
            if month > 12 {
                month = 1
                year += 1
            }
        }
        return dates
    }
}
