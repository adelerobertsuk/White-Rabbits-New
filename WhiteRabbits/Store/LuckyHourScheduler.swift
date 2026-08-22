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

    func sync(enabled: Bool) async throws -> LuckyHourSyncResult {
        let center = UNUserNotificationCenter.current()

        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
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

        // This runs on every launch and foreground, which is normally fine —
        // it just refreshes today's whisper line. But if it runs inside the
        // 11:11 window itself, cancelling an already-due request that the OS
        // hasn't delivered yet (common if the phone was locked right at
        // 11:11) makes the fresh trigger compute "next fire" as tomorrow,
        // silently skipping today. So inside that window, leave an existing
        // pending request alone rather than touch it.
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        if now.hour == 11, let minute = now.minute, minute <= 15 {
            let pending = await center.pendingNotificationRequests()
            if pending.contains(where: { $0.identifier == Self.requestID }) {
                return LuckyHourSyncResult(denied: false)
            }
        }

        center.removePendingNotificationRequests(withIdentifiers: [Self.requestID])
        let content = Self.message()

        var components = DateComponents()
        components.hour = 11
        components.minute = 11
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.requestID, content: content, trigger: trigger)
        try await center.add(request)

        return LuckyHourSyncResult(denied: false)
    }

    func scheduleTest() async throws {
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

        let content = Self.message()
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
