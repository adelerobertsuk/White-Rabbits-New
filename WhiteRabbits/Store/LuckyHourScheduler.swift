//
//  LuckyHourScheduler.swift
//  WhiteRabbits
//
//  A quiet daily tap at 11:11, local to this phone. Not an alarm.
//  The first of the month still uses AlarmKit. This is a wish.
//

import Foundation
import UserNotifications

struct LuckyHourSyncResult {
    var denied: Bool
}

@MainActor
final class LuckyHourScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LuckyHourScheduler()
    static let requestID = "white-rabbits.lucky-hour"

    private override init() {
        super.init()
    }

    /// Call once at launch so 11:11 can still appear if the app is open.
    func prepare() {
        UNUserNotificationCenter.current().delegate = self
    }

    func sync(enabled: Bool, firstName: String) async throws -> LuckyHourSyncResult {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])

        guard enabled else {
            return LuckyHourSyncResult(denied: false)
        }

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            return LuckyHourSyncResult(denied: true)
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else {
                return LuckyHourSyncResult(denied: true)
            }
        default:
            break
        }

        let content = Self.message(firstName: firstName)

        var components = DateComponents()
        components.hour = 11
        components.minute = 11
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger)
        try await center.add(request)

        return LuckyHourSyncResult(denied: false)
    }

    func scheduleTest(firstName: String) async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .denied:
            return
        case .notDetermined:
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return }
        default:
            break
        }

        let content = Self.message(firstName: firstName)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.requestID + ".test",
            content: content,
            trigger: trigger
        )
        try await center.add(request)
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

    private static func isLuckyHour(_ request: UNNotificationRequest) -> Bool {
        if request.identifier == requestID || request.identifier.hasPrefix(requestID) {
            return true
        }
        return request.content.userInfo["kind"] as? String == "luckyHour"
    }

    private static func message(firstName: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "luckyHour.notification.title", defaultValue: "✨11:11✨")
        let name = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        content.body = name.isEmpty
            ? String(localized: "luckyHour.notification.body", defaultValue: "Make a wish.")
            : String(format: String(localized: "luckyHour.notification.body.named", defaultValue: "Make a wish, %@."), name)
        content.sound = .default
        content.userInfo = ["kind": "luckyHour"]
        return content
    }
}

extension Notification.Name {
    static let didOpenLuckyHour = Notification.Name("white-rabbits.didOpenLuckyHour")
}
