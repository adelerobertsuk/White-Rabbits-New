//
//  Models.swift
//  WhiteRabbits
//
//  All the plain data types the app saves to disk.
//  Nothing here talks to the network. Everything stays on this phone.
//

import Foundation

/// One of the twelve seasonal charms, one per month.
struct Bunny: Identifiable, Hashable {
    let id: String
    let month: Int
    let name: String
    let season: String
    let fillHex: String
    let strokeHex: String
    let accentHex: String
    let line: String
}

/// A single day's page in the journal.
struct JournalEntry: Identifiable, Codable, Hashable {
    var id: String              // day key, e.g. "2026-08-15"
    var date: Date
    var text: String = ""
    var mood: String = ""
    var photoFileName: String?
    var updated: Date = Date()

    var hasContent: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoFileName != nil || !mood.isEmpty
    }
}

/// The "ritual" record for one calendar month: did they say the words,
/// which charm did they earn, and what intention did they set.
struct MonthRecord: Codable, Hashable {
    var key: String              // month key, e.g. "2026-08"
    var year: Int
    var month: Int
    var completed: Bool = false
    var charmId: String?
    var saidAt: Date?
    var intention: String?
    var photoFileName: String?
}

/// A small daily promise, e.g. "Morning light".
struct Habit: Identifiable, Codable, Hashable {
    var id: String
    var name: String

    static let defaults: [Habit] = [
        Habit(id: "light", name: "Morning light"),
        Habit(id: "water", name: "A glass of water"),
        Habit(id: "write", name: "Write a few lines"),
        Habit(id: "outside", name: "Step outside"),
    ]
}

/// A card shown in the Circle tab: your own, a friend's, a reference
/// "fellow" that ships with the app, or a real member synced from Supabase.
struct SanctuaryCard: Identifiable, Codable, Hashable {
    enum Kind: String, Codable {
        case me, friend, fellow, circleMember
    }

    var id: String
    var name: String
    var intention: String
    var month: Int
    var year: Int
    var charmId: String
    var kind: Kind
    /// Set only for `.circleMember` cards, so sparks can be sent through Supabase.
    var remoteUserID: UUID? = nil
    /// Set only for `.circleMember` cards with an uploaded intention photo.
    var photoURL: URL? = nil
}

/// A little glowing badge in the Charms tab, e.g. "First entry".
struct Milestone: Identifiable {
    var id: String
    var title: String
    var caption: String
    var systemImage: String
    var isUnlocked: Bool
}

/// A single adaptive line in the "Suggestions" card on Today.
struct Suggestion: Identifiable {
    var id: String
    var title: String
    var systemImage: String
    var action: SuggestionAction
}

enum SuggestionAction {
    case toggleHabit(String)
    case openJournal
    case openRitual
    case openIntention
}

/// Everything that gets saved to disk, in one place.
struct AppData: Codable {
    var name: String = "Adele"
    var habits: [Habit] = Habit.defaults
    var checks: [String: [String]] = [:]                 // dayKey -> habit ids done that day
    var journal: [String: JournalEntry] = [:]             // dayKey -> entry
    var months: [String: MonthRecord] = [:]               // monthKey -> record
    var pinnedIntentionMonthKey: String?                  // if set, Today shows the dock
    var circleJoined: Bool = false
    var friends: [SanctuaryCard] = []
    var sparksGiven: Set<String> = []                     // "fellowId:monthKey"
    var suggestionsCollapsed: Bool = false
    var profilePhotoFileName: String?
    var hapticsEnabled: Bool = true
    var forceDarkMode: Bool = false
    var previewFirstOfMonth: Bool = false
}
