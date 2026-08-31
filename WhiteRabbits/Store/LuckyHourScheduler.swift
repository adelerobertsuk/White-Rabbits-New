//
//  LuckyHourScheduler.swift
//  WhiteRabbits
//
//  A quiet daily tap at 11:11, local to this phone. Not an alarm.
//  The first of the month still uses AlarmKit. This is the optional 11:11 nod.
//

import Foundation
import UserNotifications

struct LuckyHourSyncResult {
    var denied: Bool
    /// True when a daily 11:11 request is sitting in the pending queue.
    var pendingScheduled: Bool = false
}

struct LuckyHourTestResult {
    var denied: Bool
    var scheduled: Bool
}

struct LuckyHourScheduleEntry {
    let fireDate: Date
    let body: String
}

@MainActor
final class LuckyHourScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LuckyHourScheduler()
    static let requestIDPrefix = "white-rabbits.lucky-hour"
    /// Legacy repeating request id; removed whenever we roll the queue forward.
    static let legacyRequestID = "white-rabbits.lucky-hour"
    static let testRequestID = "white-rabbits.lucky-hour.test"

    private override init() {
        super.init()
    }

    /// Call once at launch so 11:11 can still appear if the app is open.
    func prepare() {
        UNUserNotificationCenter.current().delegate = self
    }

    func sync(enabled: Bool, upcoming: [LuckyHourScheduleEntry]) async throws -> LuckyHourSyncResult {
        let center = UNUserNotificationCenter.current()

        guard enabled else {
            await removeAllLuckyHourRequests(from: center)
            return LuckyHourSyncResult(denied: false, pendingScheduled: false)
        }

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            return LuckyHourSyncResult(denied: true, pendingScheduled: false)
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                return LuckyHourSyncResult(denied: true, pendingScheduled: false)
            }
        default:
            break
        }

        // Reliability fix: do not cancel and re-add on every launch/foreground.
        // That churn was racing the real 11:11 delivery. If the pending queue
        // already matches the next week of Home lines, leave it alone.
        let pending = await center.pendingNotificationRequests()
        let luckyPending = pending.filter { isLuckyHourProductionRequest($0) }
        if schedulesMatch(pending: luckyPending, upcoming: upcoming) {
            return LuckyHourSyncResult(denied: false, pendingScheduled: !upcoming.isEmpty)
        }

        await removeAllLuckyHourRequests(from: center, pending: pending)
        let calendar = Calendar.current
        for entry in upcoming {
            let content = Self.message(body: entry.body)
            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: entry.fireDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.requestID(for: entry.fireDate),
                content: content,
                trigger: trigger
            )
            try await center.add(request)
        }

        let verified = await center.pendingNotificationRequests()
            .contains(where: { isLuckyHourProductionRequest($0) })
        return LuckyHourSyncResult(denied: false, pendingScheduled: verified)
    }

    /// Fires in a few seconds so a physical device can be tested without
    /// waiting for tomorrow's real 11:11. Does not touch the production
    /// daily request.
    func scheduleTest(body: String) async throws -> LuckyHourTestResult {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            return LuckyHourTestResult(denied: true, scheduled: false)
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                return LuckyHourTestResult(denied: true, scheduled: false)
            }
        default:
            break
        }

        center.removePendingNotificationRequests(withIdentifiers: [Self.testRequestID])
        let content = Self.message(body: body)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.testRequestID,
            content: content,
            trigger: trigger
        )
        try await center.add(request)
        return LuckyHourTestResult(denied: false, scheduled: true)
    }

    /// Whether the daily 11:11 request is currently pending (for Settings diagnostics).
    func hasPendingDailyRequest() async -> Bool {
        let pending = await UNUserNotificationCenter.current().pendingNotificationRequests()
        return pending.contains(where: isLuckyHourProductionRequest)
    }

    static func requestID(for fireDate: Date) -> String {
        let day = Calendar.current.startOfDay(for: fireDate).timeIntervalSince1970
        return "\(requestIDPrefix).\(Int(day))"
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard Self.isLuckyHour(response.notification.request) else { return }
        await MainActor.run {
            NotificationCenter.default.post(name: .didOpenLuckyHour, object: nil)
        }
    }

    private func is1111Trigger(_ trigger: UNNotificationTrigger?, on fireDate: Date) -> Bool {
        guard let calendarTrigger = trigger as? UNCalendarNotificationTrigger else { return false }
        let calendar = Calendar.current
        guard let nextFire = calendarTrigger.nextTriggerDate() else { return false }
        return calendar.isDate(nextFire, equalTo: fireDate, toGranularity: .minute)
            && calendar.component(.hour, from: nextFire) == 11
            && calendar.component(.minute, from: nextFire) == 11
    }

    private func isLuckyHourProductionRequest(_ request: UNNotificationRequest) -> Bool {
        request.identifier == Self.legacyRequestID
            || request.identifier.hasPrefix("\(Self.requestIDPrefix).")
    }

    private func removeAllLuckyHourRequests(
        from center: UNUserNotificationCenter,
        pending: [UNNotificationRequest]? = nil
    ) async {
        let requests: [UNNotificationRequest]
        if let pending {
            requests = pending
        } else {
            requests = await center.pendingNotificationRequests()
        }
        let ids = requests
            .filter(isLuckyHourProductionRequest)
            .map(\.identifier)
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func schedulesMatch(
        pending: [UNNotificationRequest],
        upcoming: [LuckyHourScheduleEntry]
    ) -> Bool {
        guard pending.count == upcoming.count else { return false }
        for entry in upcoming {
            let id = Self.requestID(for: entry.fireDate)
            guard let existing = pending.first(where: { $0.identifier == id }),
                  existing.content.body == entry.body,
                  is1111Trigger(existing.trigger, on: entry.fireDate) else {
                return false
            }
        }
        return true
    }

    private static func isLuckyHour(_ request: UNNotificationRequest) -> Bool {
        if request.identifier == legacyRequestID
            || request.identifier.hasPrefix("\(requestIDPrefix).")
            || request.identifier == testRequestID {
            return true
        }
        return request.content.userInfo["kind"] as? String == "luckyHour"
    }

    private static func message(body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = LuckyMinuteCopy.notificationTitle
        content.body = body
        content.sound = .default
        content.userInfo = ["kind": "luckyHour"]
        return content
    }
}

extension Notification.Name {
    static let didOpenLuckyHour = Notification.Name("white-rabbits.didOpenLuckyHour")
    static let didCompleteRitual = Notification.Name("white-rabbits.didCompleteRitual")
}
