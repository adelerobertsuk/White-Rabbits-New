//
//  AppStore.swift
//  WhiteRabbits
//
//  One source of truth: the alarm, this month's bunny, and the stamps.
//

import Foundation
import Combine
import WidgetKit

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data: AppData
    @Published private(set) var alarmAuthorizationDenied = false
    @Published private(set) var nextAlarmDate: Date?
    @Published private(set) var isSchedulingAlarm = false
    @Published private(set) var luckyHourAuthorizationDenied = false
    @Published private(set) var offerLuckyShare = false

    private var cancellables = Set<AnyCancellable>()
    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.timeZone = .current
        return formatter
    }()

    init() {
        self.data = Persistence.load()
        Haptics.isEnabled = data.hapticsEnabled
        LuckyHourScheduler.shared.prepare()
        NotificationCenter.default.publisher(for: .didOpenLuckyHour)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.offerLuckyShare = true
            }
            .store(in: &cancellables)
        if data.firstOpenedAt == nil {
            data.firstOpenedAt = Date()
            persist(reloadWidgets: false)
        }
    }

    private func persist(reloadWidgets: Bool = true) {
        Persistence.save(data)
        if reloadWidgets {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func monthKey(_ date: Date = Date()) -> String { monthFormatter.string(from: date) }

    func isFirstOfMonth(_ date: Date = Date()) -> Bool {
        data.previewFirstOfMonth || Calendar.current.component(.day, from: date) == 1
    }

    var firstName: String {
        data.name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func setName(_ name: String) {
        data.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        persist()
        Task { await refreshLuckyHour() }
    }

    func monthName(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: date)
    }

    func currentBunny(_ date: Date = Date()) -> Bunny {
        BunnyData.bunny(forMonth: Calendar.current.component(.month, from: date))
    }

    func monthRecord(_ date: Date = Date()) -> MonthRecord? {
        data.months[monthKey(date)]
    }

    func ritualCompleted(_ date: Date = Date()) -> Bool {
        monthRecord(date)?.completed ?? false
    }

    var intention: String {
        monthRecord()?.intention?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    func setIntention(_ text: String, date: Date = Date()) {
        let key = monthKey(date)
        var record = data.months[key] ?? MonthRecord(
            key: key,
            year: Calendar.current.component(.year, from: date),
            month: Calendar.current.component(.month, from: date)
        )
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        record.intention = trimmed.isEmpty ? nil : trimmed
        data.months[key] = record
        persist()
    }

    /// Marks the month as said, and unlocks this month's charm. This is
    /// the single unlock event — the Year of Luck grid listens for
    /// `.didCompleteRitual` to play its door-reveal animation, whether
    /// the ritual was said from the hero button or the door itself.
    func completeRitual(_ date: Date = Date()) {
        let key = monthKey(date)
        var record = data.months[key] ?? MonthRecord(
            key: key,
            year: Calendar.current.component(.year, from: date),
            month: Calendar.current.component(.month, from: date)
        )
        record.completed = true
        record.charmId = currentBunny(date).id
        if record.saidAt == nil { record.saidAt = date }
        data.months[key] = record
        persist()
        NotificationCenter.default.post(name: .didCompleteRitual, object: nil)
    }

    var unlockedCharmIds: Set<String> {
        Set(data.months.values.compactMap { $0.completed ? $0.charmId : nil })
    }

    var hapticsEnabled: Bool { data.hapticsEnabled }

    func setHapticsEnabled(_ on: Bool) {
        data.hapticsEnabled = on
        Haptics.isEnabled = on
        persist()
    }

    var forceDarkMode: Bool { data.forceDarkMode }

    func setForceDarkMode(_ on: Bool) {
        data.forceDarkMode = on
        persist()
    }

    var previewFirstOfMonth: Bool { data.previewFirstOfMonth }

    func setPreviewFirstOfMonth(_ on: Bool) {
        data.previewFirstOfMonth = on
        persist()
    }

    var alarmHour: Int { data.alarmHour }
    var alarmMinute: Int { data.alarmMinute }
    var alarmEnabled: Bool { data.alarmEnabled }

    var alarmTime: Date {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = data.alarmHour
        components.minute = data.alarmMinute
        components.second = 0
        return Calendar.current.date(from: components) ?? Date()
    }

    func setAlarmTime(_ date: Date) {
        data.alarmHour = Calendar.current.component(.hour, from: date)
        data.alarmMinute = Calendar.current.component(.minute, from: date)
        persist()
        Task { await refreshAlarms() }
    }

    func setAlarmEnabled(_ on: Bool) {
        data.alarmEnabled = on
        persist()
        Task { await refreshAlarms() }
    }

    /// Asks for AlarmKit permission if needed, then queues the next firsts of the month.
    func refreshAlarms() async {
        isSchedulingAlarm = true
        defer { isSchedulingAlarm = false }
        do {
            let result = try await MonthAlarmScheduler.shared.sync(
                enabled: data.alarmEnabled,
                hour: data.alarmHour,
                minute: data.alarmMinute
            )
            alarmAuthorizationDenied = result.denied
            nextAlarmDate = result.nextDate
            if result.denied, data.alarmEnabled {
                data.alarmEnabled = false
                persist()
            }
        } catch {
            nextAlarmDate = nil
        }
    }

    func scheduleTestAlarm() async {
        try? await MonthAlarmScheduler.shared.scheduleTest()
    }

    var luckyHourEnabled: Bool { data.luckyHourEnabled }

    /// 11:11, and a little while after, so there is time to send it on.
    func isLuckyShareWindow(_ date: Date = Date()) -> Bool {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        guard parts.hour == 11 else { return false }
        let minute = parts.minute ?? 0
        return minute >= 11 && minute < 21
    }

    func shouldOfferLuckyShare(at date: Date = Date()) -> Bool {
        luckyHourEnabled && (offerLuckyShare || isLuckyShareWindow(date))
    }

    func setLuckyHourEnabled(_ on: Bool) {
        data.luckyHourEnabled = on
        persist()
        Task { await refreshLuckyHour() }
    }

    func scheduleTestLuckyHour() async {
        try? await LuckyHourScheduler.shared.scheduleTest()
    }

    /// Asks for notification permission if needed, then sets the daily 11:11 tap.
    func refreshLuckyHour() async {
        do {
            let result = try await LuckyHourScheduler.shared.sync(enabled: data.luckyHourEnabled)
            luckyHourAuthorizationDenied = result.denied
            if result.denied, data.luckyHourEnabled {
                data.luckyHourEnabled = false
                persist()
            }
        } catch {
            luckyHourAuthorizationDenied = false
        }
    }

    /// Keeps both the monthly alarm and the optional 11:11 tap in sync.
    func refreshScheduledItems() async {
        await refreshAlarms()
        await refreshLuckyHour()
    }

    /// A quiet count of real visits, so we do not ask for a review on day one.
    func noteOpened() {
        data.openCount += 1
        persist(reloadWidgets: false)
    }

    /// A week of coming back, at least a few visits, and we have not asked yet.
    var isEligibleForReview: Bool {
        guard data.reviewPromptedAt == nil else { return false }
        guard let firstOpenedAt = data.firstOpenedAt else { return false }
        let days = Calendar.current.dateComponents([.day], from: firstOpenedAt, to: Date()).day ?? 0
        return days >= 7 && data.openCount >= 3
    }

    func markReviewPrompted() {
        data.reviewPromptedAt = Date()
        persist(reloadWidgets: false)
    }

    func exportSnapshot() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try? encoder.encode(data)
    }

    func importSnapshot(from fileData: Data) -> Bool {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let imported = try? decoder.decode(AppData.self, from: fileData) else { return false }
        data = imported
        Haptics.isEnabled = data.hapticsEnabled
        if data.firstOpenedAt == nil {
            data.firstOpenedAt = Date()
        }
        persist()
        Task { await refreshScheduledItems() }
        return true
    }

    func resetDevice() {
        data = AppData(name: "")
        Haptics.isEnabled = true
        persist()
        Task { await refreshScheduledItems() }
    }
}
