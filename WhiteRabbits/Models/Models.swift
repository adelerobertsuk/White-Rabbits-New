//
//  Models.swift
//  WhiteRabbits
//
//  The plain data types the app saves to this phone.
//

import Foundation

/// One of the twelve seasonal charms, one per month.
struct Bunny: Identifiable, Hashable, Sendable {
    let id: String
    let month: Int
    let name: String
    let season: String
    let fillHex: String
    let strokeHex: String
    let accentHex: String
    let line: String
}

/// Whether they said the words this month, and which charm they earned.
struct MonthRecord: Codable, Hashable {
    var key: String
    var year: Int
    var month: Int
    var completed: Bool = false
    var charmId: String?
    var saidAt: Date?
    var intention: String?
}

/// Everything that gets saved to disk, in one place.
struct AppData: Codable {
    var name: String = "Adele"
    var months: [String: MonthRecord] = [:]
    var hapticsEnabled: Bool = true
    var forceDarkMode: Bool = false
    var previewFirstOfMonth: Bool = false
    var alarmHour: Int = 6
    var alarmMinute: Int = 30
    var alarmEnabled: Bool = false
    var luckyHourEnabled: Bool = false
    var firstOpenedAt: Date?
    var openCount: Int = 0
    var reviewPromptedAt: Date?

    init() {}

    init(name: String) {
        self.init()
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case name, months, hapticsEnabled, forceDarkMode, previewFirstOfMonth
        case alarmHour, alarmMinute, alarmEnabled, luckyHourEnabled
        case firstOpenedAt, openCount, reviewPromptedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Adele"
        months = try container.decodeIfPresent([String: MonthRecord].self, forKey: .months) ?? [:]
        hapticsEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticsEnabled) ?? true
        forceDarkMode = try container.decodeIfPresent(Bool.self, forKey: .forceDarkMode) ?? false
        previewFirstOfMonth = try container.decodeIfPresent(Bool.self, forKey: .previewFirstOfMonth) ?? false
        alarmHour = try container.decodeIfPresent(Int.self, forKey: .alarmHour) ?? 6
        alarmMinute = try container.decodeIfPresent(Int.self, forKey: .alarmMinute) ?? 30
        alarmEnabled = try container.decodeIfPresent(Bool.self, forKey: .alarmEnabled) ?? false
        luckyHourEnabled = try container.decodeIfPresent(Bool.self, forKey: .luckyHourEnabled) ?? false
        firstOpenedAt = try container.decodeIfPresent(Date.self, forKey: .firstOpenedAt)
        openCount = try container.decodeIfPresent(Int.self, forKey: .openCount) ?? 0
        reviewPromptedAt = try container.decodeIfPresent(Date.self, forKey: .reviewPromptedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(months, forKey: .months)
        try container.encode(hapticsEnabled, forKey: .hapticsEnabled)
        try container.encode(forceDarkMode, forKey: .forceDarkMode)
        try container.encode(previewFirstOfMonth, forKey: .previewFirstOfMonth)
        try container.encode(alarmHour, forKey: .alarmHour)
        try container.encode(alarmMinute, forKey: .alarmMinute)
        try container.encode(alarmEnabled, forKey: .alarmEnabled)
        try container.encode(luckyHourEnabled, forKey: .luckyHourEnabled)
        try container.encodeIfPresent(firstOpenedAt, forKey: .firstOpenedAt)
        try container.encode(openCount, forKey: .openCount)
        try container.encodeIfPresent(reviewPromptedAt, forKey: .reviewPromptedAt)
    }
}
