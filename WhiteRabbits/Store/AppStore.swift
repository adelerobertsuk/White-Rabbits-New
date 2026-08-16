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

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.timeZone = .current
        return formatter
    }()

    init() {
        self.data = Persistence.load()
        Haptics.isEnabled = data.hapticsEnabled
    }

    private func persist() {
        Persistence.save(data)
        WidgetCenter.shared.reloadAllTimelines()
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

    /// Marks the month as said, and unlocks this month's charm.
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
        persist()
        Task { await refreshAlarms() }
        return true
    }

    func resetDevice() {
        data = AppData(name: "")
        Haptics.isEnabled = true
        persist()
        Task { await refreshAlarms() }
    }
}
