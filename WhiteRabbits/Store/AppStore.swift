//
//  AppStore.swift
//  WhiteRabbits
//
//  The single source of truth for the whole app. Every screen reads
//  from here, and every change goes through a method on this class so
//  saving to disk always stays in sync with what's on screen.
//

import Foundation
import Combine
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data: AppData

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.timeZone = .current
        return formatter
    }()

    init() {
        self.data = Persistence.load()
    }

    private func persist() {
        Persistence.save(data)
    }

    // MARK: - Keys & dates

    func dayKey(_ date: Date = Date()) -> String { dayFormatter.string(from: date) }
    func monthKey(_ date: Date = Date()) -> String { monthFormatter.string(from: date) }

    func isFirstOfMonth(_ date: Date = Date()) -> Bool {
        Calendar.current.component(.day, from: date) == 1
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

    // MARK: - Month ritual

    func monthRecord(_ date: Date = Date()) -> MonthRecord? {
        data.months[monthKey(date)]
    }

    func ritualCompleted(_ date: Date = Date()) -> Bool {
        monthRecord(date)?.completed ?? false
    }

    /// Called when the "Say White Rabbits" ritual finishes. Marks the
    /// month as complete and earns this month's charm.
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

    func setIntention(_ text: String, photo: PlatformImage?, date: Date = Date()) {
        let key = monthKey(date)
        var record = data.months[key] ?? MonthRecord(
            key: key,
            year: Calendar.current.component(.year, from: date),
            month: Calendar.current.component(.month, from: date)
        )
        record.completed = true
        record.charmId = currentBunny(date).id
        if record.saidAt == nil { record.saidAt = date }
        record.intention = text.trimmingCharacters(in: .whitespacesAndNewlines)
        #if canImport(UIKit)
        if let photo, let fileName = Persistence.savePhoto(photo) {
            record.photoFileName = fileName
        }
        #endif
        data.months[key] = record
        persist()
    }

    func intentionPhoto(_ date: Date = Date()) -> PlatformImage? {
        #if canImport(UIKit)
        return Persistence.loadPhoto(monthRecord(date)?.photoFileName)
        #else
        return nil
        #endif
    }

    // MARK: - Greeting

    /// Exactly the copy from the spec: the first-of-month magic words,
    /// or a warm time-of-day greeting with the month's name.
    func greeting(_ date: Date = Date()) -> String {
        if isFirstOfMonth(date) && !ritualCompleted(date) {
            return NSLocalizedString("greeting.ritual", value: "White Rabbits, White Rabbits!", comment: "Shown only on the 1st of the month")
        }
        let hour = Calendar.current.component(.hour, from: date)
        let month = monthName(date)

        if firstName.isEmpty {
            let key: String
            let fallback: String
            if hour < 12 { key = "greeting.morning.unnamed"; fallback = "Good morning. %1$@ is yours." }
            else if hour < 18 { key = "greeting.afternoon.unnamed"; fallback = "Good afternoon. %1$@ is yours." }
            else { key = "greeting.evening.unnamed"; fallback = "Good evening. %1$@ is yours." }
            let format = NSLocalizedString(key, value: fallback, comment: "")
            return String(format: format, month)
        }

        let key: String
        let fallback: String
        if hour < 12 { key = "greeting.morning.named"; fallback = "Good morning, %1$@. %2$@ is yours." }
        else if hour < 18 { key = "greeting.afternoon.named"; fallback = "Good afternoon, %1$@. %2$@ is yours." }
        else { key = "greeting.evening.named"; fallback = "Good evening, %1$@. %2$@ is yours." }
        let format = NSLocalizedString(key, value: fallback, comment: "")
        return String(format: format, firstName, month)
    }

    // MARK: - Habits & today's ring

    func todayChecks(_ date: Date = Date()) -> Set<String> {
        Set(data.checks[dayKey(date)] ?? [])
    }

    func isHabitDone(_ habitId: String, date: Date = Date()) -> Bool {
        todayChecks(date).contains(habitId)
    }

    func toggleHabit(_ habitId: String, date: Date = Date()) {
        let key = dayKey(date)
        var set = todayChecks(date)
        if set.contains(habitId) { set.remove(habitId) } else { set.insert(habitId) }
        data.checks[key] = Array(set)
        persist()
    }

    var progress: Double {
        let total = data.habits.count
        guard total > 0 else { return 0 }
        let done = data.habits.filter { isHabitDone($0.id) }.count
        return Double(done) / Double(total)
    }

    var doneCount: Int { data.habits.filter { isHabitDone($0.id) }.count }
    var totalCount: Int { data.habits.count }

    // MARK: - Suggestions (max 3, adaptive)

    func suggestions(_ date: Date = Date()) -> [Suggestion] {
        var items: [Suggestion] = []

        if isFirstOfMonth(date) && !ritualCompleted(date) {
            items.append(Suggestion(id: "ritual", title: String(localized: "suggestion.beginMonth", defaultValue: "Begin the month"), systemImage: "sparkles", action: .openRitual))
        }

        if journalEntry(date) == nil {
            items.append(Suggestion(id: "journal", title: String(localized: "suggestion.writeToday", defaultValue: "Write a few lines today"), systemImage: "square.and.pencil", action: .openJournal))
        }

        for habit in data.habits where !isHabitDone(habit.id, date: date) {
            if items.count >= 3 { break }
            items.append(Suggestion(id: habit.id, title: habit.name, systemImage: "circle.dashed", action: .toggleHabit(habit.id)))
        }

        if items.isEmpty, monthRecord(date)?.intention == nil {
            items.append(Suggestion(id: "intention", title: String(localized: "suggestion.setIntention", defaultValue: "Set this month's intention"), systemImage: "leaf", action: .openIntention))
        }

        return Array(items.prefix(3))
    }

    func toggleSuggestionsCollapsed() {
        data.suggestionsCollapsed.toggle()
        persist()
    }

    // MARK: - Journal

    func journalEntry(_ date: Date = Date()) -> JournalEntry? {
        data.journal[dayKey(date)]
    }

    /// This is the fix for the calendar sync bug: entries are read live
    /// from `data.journal` every time this is called, so the moment an
    /// entry is saved the calendar dot appears immediately.
    func hasEntry(on date: Date) -> Bool {
        journalEntry(date)?.hasContent ?? false
    }

    func saveJournalEntry(date: Date = Date(), text: String, mood: String, photo: PlatformImage?, removePhoto: Bool = false) {
        let key = dayKey(date)
        var entry = data.journal[key] ?? JournalEntry(id: key, date: date)
        entry.text = text
        entry.mood = mood
        entry.updated = Date()

        #if canImport(UIKit)
        if removePhoto {
            Persistence.deletePhoto(entry.photoFileName)
            entry.photoFileName = nil
        } else if let photo, let fileName = Persistence.savePhoto(photo) {
            Persistence.deletePhoto(entry.photoFileName)
            entry.photoFileName = fileName
        }
        #endif

        if entry.hasContent {
            data.journal[key] = entry
            if !text.isEmpty {
                markHabitDoneIfWriting(date: date)
            }
        } else {
            data.journal.removeValue(forKey: key)
        }
        persist()
    }

    private func markHabitDoneIfWriting(date: Date) {
        guard let habit = data.habits.first(where: { $0.name.localizedCaseInsensitiveContains("write") }) else { return }
        var set = todayChecks(date)
        set.insert(habit.id)
        data.checks[dayKey(date)] = Array(set)
    }

    func deleteJournalEntry(date: Date) {
        let key = dayKey(date)
        #if canImport(UIKit)
        Persistence.deletePhoto(data.journal[key]?.photoFileName)
        #endif
        data.journal.removeValue(forKey: key)
        persist()
    }

    func entryPhoto(_ entry: JournalEntry) -> PlatformImage? {
        #if canImport(UIKit)
        return Persistence.loadPhoto(entry.photoFileName)
        #else
        return nil
        #endif
    }

    /// All entries in the month containing `date`, most recent first.
    func entries(inMonthContaining date: Date) -> [JournalEntry] {
        let prefix = monthKey(date)
        return data.journal.values
            .filter { $0.id.hasPrefix(prefix) && $0.hasContent }
            .sorted { $0.id > $1.id }
    }

    /// Every month that has at least one entry, most recent first.
    func allMonthsWithEntries() -> [String] {
        let prefixes = Set(data.journal.values.filter { $0.hasContent }.map { String($0.id.prefix(7)) })
        return prefixes.sorted(by: >)
    }

    // MARK: - Pinned intention (Today <- Circle)

    func pinIntention(monthKey: String) {
        data.pinnedIntentionMonthKey = monthKey
        persist()
    }

    func unpinIntention() {
        data.pinnedIntentionMonthKey = nil
        persist()
    }

    var isCurrentMonthPinned: Bool {
        data.pinnedIntentionMonthKey == monthKey()
    }

    var pinnedRecord: MonthRecord? {
        guard let key = data.pinnedIntentionMonthKey else { return nil }
        return data.months[key]
    }

    // MARK: - Circle

    var circleJoined: Bool { data.circleJoined }

    func joinCircle() {
        data.circleJoined = true
        persist()
    }

    func leaveCircle() {
        data.circleJoined = false
        persist()
    }

    func myCard(_ date: Date = Date()) -> SanctuaryCard? {
        guard let intention = monthRecord(date)?.intention, !intention.isEmpty else { return nil }
        let bunny = currentBunny(date)
        return SanctuaryCard(
            id: "me",
            name: firstName.isEmpty ? String(localized: "circle.aFriend", defaultValue: "A friend") : firstName,
            intention: intention,
            month: Calendar.current.component(.month, from: date),
            year: Calendar.current.component(.year, from: date),
            charmId: monthRecord(date)?.charmId ?? bunny.id,
            kind: .me
        )
    }

    func fellows(_ date: Date = Date()) -> [SanctuaryCard] {
        FellowsData.cards(for: date)
    }

    var friends: [SanctuaryCard] { data.friends }

    func addFriend(name: String, intention: String, date: Date = Date()) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedIntention = intention.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedIntention.isEmpty else { return }
        let bunny = currentBunny(date)
        let card = SanctuaryCard(
            id: UUID().uuidString,
            name: trimmedName,
            intention: trimmedIntention,
            month: Calendar.current.component(.month, from: date),
            year: Calendar.current.component(.year, from: date),
            charmId: bunny.id,
            kind: .friend
        )
        data.friends.insert(card, at: 0)
        persist()
    }

    func removeFriend(_ id: String) {
        data.friends.removeAll { $0.id == id }
        persist()
    }

    private func sparkKey(_ cardId: String, date: Date) -> String { "\(cardId):\(monthKey(date))" }

    func hasSparked(_ cardId: String, date: Date = Date()) -> Bool {
        data.sparksGiven.contains(sparkKey(cardId, date: date))
    }

    func sendSpark(_ cardId: String, date: Date = Date()) {
        data.sparksGiven.insert(sparkKey(cardId, date: date))
        persist()
    }

    // MARK: - Profile photo

    func profileImage() -> PlatformImage? {
        #if canImport(UIKit)
        return Persistence.loadPhoto(data.profilePhotoFileName)
        #else
        return nil
        #endif
    }

    func setProfilePhoto(_ image: PlatformImage) {
        #if canImport(UIKit)
        if let fileName = Persistence.savePhoto(image) {
            Persistence.deletePhoto(data.profilePhotoFileName)
            data.profilePhotoFileName = fileName
            persist()
        }
        #endif
    }

    // MARK: - Charms & milestones

    var unlockedCharmIds: Set<String> {
        Set(data.months.values.compactMap { $0.completed ? $0.charmId : nil })
    }

    var milestones: [Milestone] {
        let hasEntry = !data.journal.values.filter { $0.hasContent }.isEmpty
        let hasSpark = !data.sparksGiven.isEmpty
        let hasCharm = !unlockedCharmIds.isEmpty
        let fullYear = unlockedCharmIds.count >= 12
        return [
            Milestone(id: "first-entry", title: String(localized: "milestone.firstEntry.title", defaultValue: "First page"), caption: String(localized: "milestone.firstEntry.caption", defaultValue: "You wrote your first journal entry"), systemImage: "book.closed.fill", isUnlocked: hasEntry),
            Milestone(id: "first-charm", title: String(localized: "milestone.firstCharm.title", defaultValue: "First charm"), caption: String(localized: "milestone.firstCharm.caption", defaultValue: "You earned your first monthly charm"), systemImage: "seal.fill", isUnlocked: hasCharm),
            Milestone(id: "first-spark", title: String(localized: "milestone.firstSpark.title", defaultValue: "First spark"), caption: String(localized: "milestone.firstSpark.caption", defaultValue: "You sent someone a little encouragement"), systemImage: "sparkle", isUnlocked: hasSpark),
            Milestone(id: "full-year", title: String(localized: "milestone.fullYear.title", defaultValue: "A full year"), caption: String(localized: "milestone.fullYear.caption", defaultValue: "All twelve charms, collected"), systemImage: "crown.fill", isUnlocked: fullYear),
        ]
    }
}

#if canImport(UIKit)
typealias PlatformImage = UIImage
#else
typealias PlatformImage = NSImage
#endif
