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
import Supabase
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var data: AppData

    // MARK: - Circle sync (Supabase)

    /// Real members synced from Supabase, this month's intention and photo
    /// included. Empty until `ensureCircleSession()`/`refreshCircle()` succeeds.
    @Published private(set) var circleMembers: [SanctuaryCard] = []
    @Published private(set) var isSyncingCircle = false
    @Published private(set) var circleSyncError: String?
    private var sentSparkUserIDs: Set<UUID> = []

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
        Haptics.isEnabled = data.hapticsEnabled
    }

    private func persist() {
        Persistence.save(data)
    }

    // MARK: - Keys & dates

    func dayKey(_ date: Date = Date()) -> String { dayFormatter.string(from: date) }
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
        guard data.circleJoined else { return }
        let name = firstName
        Task { try? await CircleSyncService.updateDisplayName(name.isEmpty ? "A friend" : name) }
    }

    func monthName(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMM")
        return formatter.string(from: date)
    }

    func currentBunny(_ date: Date = Date()) -> Bunny {
        BunnyData.bunny(forMonth: Calendar.current.component(.month, from: date))
    }

    /// "August light" style kicker for the daily inspiration line.
    func monthLightKicker(_ date: Date = Date()) -> String {
        String(format: String(localized: "today.inspiration.kicker", defaultValue: "%@ light"), monthName(date))
    }

    /// A small "Today · August 2026" style header line, reused across tabs.
    func todayKicker(_ tab: String = "", date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        let monthYear = formatter.string(from: date)
        let label = tab.isEmpty ? String(localized: "tab.today", defaultValue: "Today") : tab
        return "\(label) · \(monthYear)"
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        record.intention = trimmed
        #if canImport(UIKit)
        if let photo, let fileName = Persistence.savePhoto(photo) {
            record.photoFileName = fileName
        }
        #endif
        data.months[key] = record
        persist()
        syncIntentionIfJoined(monthKey: key, text: trimmed, charmID: record.charmId, photo: photo, date: date)
    }

    /// Pushes my own intention (and photo, if provided) up to Supabase so the
    /// rest of the circle can see it. Silent no-op unless "Enter the circle"
    /// has been tapped. Never touches journal, habits, or check-ins.
    private func syncIntentionIfJoined(monthKey: String, text: String, charmID: String?, photo: PlatformImage?, date: Date) {
        guard data.circleJoined else { return }
        #if canImport(UIKit)
        let jpegData = photo?.jpegData(compressionQuality: 0.85)
        #else
        let jpegData: Data? = nil
        #endif
        Task {
            do {
                try await CircleSyncService.setIntention(
                    monthKey: monthKey,
                    text: text,
                    charmID: charmID,
                    photoData: jpegData
                )
                circleSyncError = nil
                await refreshCircle(date)
            } catch {
                circleSyncError = error.localizedDescription
            }
        }
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

    /// Signs this device in anonymously (only ever once) and starts syncing
    /// name, monthly intention, charm, and sparks with everyone else who's
    /// joined. Journal, habits, and check-ins are never part of this.
    func joinCircle() {
        data.circleJoined = true
        persist()
        let name = firstName
        Task {
            isSyncingCircle = true
            defer { isSyncingCircle = false }
            do {
                try await CircleSyncService.joinCircle(displayName: name.isEmpty ? "A friend" : name)
                circleSyncError = nil
                await refreshCircle()
            } catch {
                circleSyncError = error.localizedDescription
            }
        }
    }

    func leaveCircle() {
        data.circleJoined = false
        circleMembers = []
        sentSparkUserIDs = []
        persist()
    }

    /// Called when Circle appears. Restores a previous anonymous session
    /// (e.g. after relaunching the app) before fetching everyone's cards.
    /// If no session can be restored (fresh install, known limitation) it
    /// quietly rejoins so the tab still works.
    func ensureCircleSession() async {
        guard data.circleJoined else { return }
        if CircleSyncService.currentUserID == nil {
            _ = try? await supabase.auth.session
        }
        if CircleSyncService.currentUserID == nil {
            let name = firstName
            _ = try? await CircleSyncService.joinCircle(displayName: name.isEmpty ? "A friend" : name)
        }
        await refreshCircle()
    }

    /// Fetches every member's card and my own sent sparks for the given
    /// month. Failures are stored in `circleSyncError` rather than thrown,
    /// so the tab always keeps showing whatever it last had.
    func refreshCircle(_ date: Date = Date()) async {
        guard data.circleJoined, CircleSyncService.currentUserID != nil else { return }
        isSyncingCircle = true
        defer { isSyncingCircle = false }
        do {
            let key = monthKey(date)
            let myID = CircleSyncService.currentUserID
            async let membersTask = CircleSyncService.fetchMembers()
            async let intentionsTask = CircleSyncService.fetchIntentions(monthKey: key)
            async let sparksTask = CircleSyncService.fetchSparksSentByMe(monthKey: key)
            let members = try await membersTask
            let intentions = try await intentionsTask
            let sparks = try await sparksTask

            let intentionByUser = Dictionary(uniqueKeysWithValues: intentions.map { ($0.user_id, $0) })
            circleMembers = members.compactMap { member -> SanctuaryCard? in
                guard member.user_id != myID else { return nil }
                guard let intention = intentionByUser[member.user_id],
                      !intention.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return nil }
                return SanctuaryCard(
                    id: member.user_id.uuidString,
                    name: member.display_name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? String(localized: "circle.aFriend", defaultValue: "A friend")
                        : member.display_name,
                    intention: intention.text,
                    month: Calendar.current.component(.month, from: date),
                    year: Calendar.current.component(.year, from: date),
                    charmId: intention.charm_id ?? currentBunny(date).id,
                    kind: .circleMember,
                    remoteUserID: member.user_id,
                    photoURL: intention.photo_path.flatMap { CircleSyncService.photoURL(for: $0) }
                )
            }
            sentSparkUserIDs = sparks
            circleSyncError = nil
        } catch {
            circleSyncError = error.localizedDescription
        }
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

    /// Sparking a real, synced circle member (as opposed to a manually
    /// typed-in "friend"), sent through Supabase so it shows up on their phone.
    func hasSparked(remoteUserID id: UUID) -> Bool {
        sentSparkUserIDs.contains(id)
    }

    func sendSpark(remoteUserID id: UUID, date: Date = Date()) {
        guard !sentSparkUserIDs.contains(id) else { return }
        sentSparkUserIDs.insert(id)
        Task {
            do {
                try await CircleSyncService.sendSpark(to: id, monthKey: monthKey(date))
                circleSyncError = nil
            } catch {
                sentSparkUserIDs.remove(id)
                circleSyncError = error.localizedDescription
            }
        }
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
            // The only "photo" the circle can see is this month's intention
            // photo, so the profile picture doubles as that upload.
            let date = Date()
            let key = monthKey(date)
            let record = data.months[key]
            syncIntentionIfJoined(
                monthKey: key,
                text: record?.intention ?? "",
                charmID: record?.charmId ?? currentBunny(date).id,
                photo: image,
                date: date
            )
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

    // MARK: - Settings

    var hapticsEnabled: Bool { data.hapticsEnabled }

    func setHapticsEnabled(_ on: Bool) {
        data.hapticsEnabled = on
        Haptics.isEnabled = on
        persist()
    }

    /// "Dark evening": a manual override so Adele can preview dark mode
    /// without waiting for the system to switch.
    var forceDarkMode: Bool { data.forceDarkMode }

    func setForceDarkMode(_ on: Bool) {
        data.forceDarkMode = on
        persist()
    }

    /// Lets Adele preview the first-of-the-month ritual on any day.
    var previewFirstOfMonth: Bool { data.previewFirstOfMonth }

    func setPreviewFirstOfMonth(_ on: Bool) {
        data.previewFirstOfMonth = on
        persist()
    }

    /// Everything on this phone, as one JSON file, for the "Export Data" row.
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
        return true
    }

    /// "Clear this device": wipes every saved page, stamp, and setting.
    func resetDevice() {
        #if canImport(UIKit)
        Persistence.deleteAllPhotos()
        #endif
        data = AppData(name: "", habits: Habit.defaults)
        Haptics.isEnabled = true
        persist()
    }
}

#if canImport(UIKit)
typealias PlatformImage = UIImage
#else
typealias PlatformImage = NSImage
#endif
