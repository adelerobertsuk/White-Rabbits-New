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

@MainActor
final class LuckyHourScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LuckyHourScheduler()
    static let requestID = "white-rabbits.lucky-hour"
    static let testRequestID = "white-rabbits.lucky-hour.test"

    private override init() {
        super.init()
    }

    /// Call once at launch so 11:11 can still appear if the app is open.
    func prepare() {
        UNUserNotificationCenter.current().delegate = self
    }

    func sync(enabled: Bool) async throws -> LuckyHourSyncResult {
        let center = UNUserNotificationCenter.current()

        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
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

        // Reliability fix: do not cancel and re-add the daily trigger on
        // every launch/foreground. That churn was racing the real 11:11
        // delivery (especially if the phone was locked at fire time) and
        // could push the next fire to tomorrow. If a correct pending
        // request already exists, leave it alone.
        let pending = await center.pendingNotificationRequests()
        if let existing = pending.first(where: { $0.identifier == Self.requestID }),
           isDaily1111Trigger(existing.trigger) {
            return LuckyHourSyncResult(denied: false, pendingScheduled: true)
        }

        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
        let content = Self.message()

        var components = DateComponents()
        components.hour = 11
        components.minute = 11
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger)
        try await center.add(request)

        let verified = await center.pendingNotificationRequests()
            .contains(where: { $0.identifier == Self.requestID })
        return LuckyHourSyncResult(denied: false, pendingScheduled: verified)
    }

    /// Fires in a few seconds so a physical device can be tested without
    /// waiting for tomorrow's real 11:11. Does not touch the production
    /// daily request.
    func scheduleTest() async throws -> LuckyHourTestResult {
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
        let content = Self.message()
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
        return pending.contains { $0.identifier == Self.requestID && isDaily1111Trigger($0.trigger) }
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

    private func isDaily1111Trigger(_ trigger: UNNotificationTrigger?) -> Bool {
        guard let calendar = trigger as? UNCalendarNotificationTrigger, calendar.repeats else {
            return false
        }
        return calendar.dateComponents.hour == 11 && calendar.dateComponents.minute == 11
    }

    private static func isLuckyHour(_ request: UNNotificationRequest) -> Bool {
        if request.identifier == requestID || request.identifier.hasPrefix(requestID) {
            return true
        }
        return request.content.userInfo["kind"] as? String == "luckyHour"
    }

    private static func message() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = LuckyMinuteCopy.notificationTitle
        content.body = LuckyMinuteCopy.whisper()
        content.sound = .default
        content.userInfo = ["kind": "luckyHour"]
        return content
    }
}

extension Notification.Name {
    static let didOpenLuckyHour = Notification.Name("white-rabbits.didOpenLuckyHour")
    static let didCompleteRitual = Notification.Name("white-rabbits.didCompleteRitual")
}
