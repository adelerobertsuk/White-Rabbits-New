//
//  MonthAlarmScheduler.swift
//  WhiteRabbits
//
//  AlarmKit only repeats weekly, so the first of the month is a queue
//  of one-shot alarms. Set it once, then the next year is already waiting.
//

import Foundation
import SwiftUI
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

    private let manager = AlarmManager.shared

    private init() {}

    func sync(enabled: Bool, hour: Int, minute: Int) async throws -> MonthAlarmSyncResult {
        cancelMonthlyAlarms()

        guard enabled else {
            return MonthAlarmSyncResult(denied: false, nextDate: nil)
        }

        switch manager.authorizationState {
        case .denied:
            return MonthAlarmSyncResult(denied: true, nextDate: nil)
        case .notDetermined:
            let state = try await manager.requestAuthorization()
            guard state == .authorized else {
                return MonthAlarmSyncResult(denied: state == .denied, nextDate: nil)
            }
        case .authorized:
            break
        @unknown default:
            break
        }

        let upcoming = Self.upcomingFirsts(count: 12, hour: hour, minute: minute)
        var scheduled: [Date] = []

        for date in upcoming {
            if scheduled.count >= 12 { break }
            do {
                try await scheduleFixed(date: date, id: UUID())
                scheduled.append(date)
            } catch let error as AlarmManager.AlarmError {
                if case .maximumLimitReached = error { break }
                throw error
            }
        }

        return MonthAlarmSyncResult(denied: false, nextDate: scheduled.first)
    }

    func scheduleTest() async throws {
        switch manager.authorizationState {
        case .denied:
            return
        case .notDetermined:
            let state = try await manager.requestAuthorization()
            guard state == .authorized else { return }
        case .authorized:
            break
        @unknown default:
            break
        }

        try? manager.cancel(id: Self.testAlarmID)
        let fireDate = Date().addingTimeInterval(15)
        try await scheduleFixed(date: fireDate, id: Self.testAlarmID)
    }

    private func cancelMonthlyAlarms() {
        let alarms = (try? manager.alarms) ?? []
        for alarm in alarms where alarm.id != Self.testAlarmID {
            try? manager.cancel(id: alarm.id)
        }
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
