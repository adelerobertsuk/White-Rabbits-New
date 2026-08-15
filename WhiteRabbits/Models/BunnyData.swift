//
//  BunnyData.swift
//  WhiteRabbits
//
//  The twelve seasonal charms. One per month, all year round.
//  Fashion-house marks, not mascots.
//

import Foundation

enum BunnyData {
    static let all: [Bunny] = [
        Bunny(id: "frost", month: 1, name: "Frost", season: "January",
              fillHex: "E8EEF2", strokeHex: "8A97A3", accentHex: "B7C4CE",
              line: "A quiet white beginning. The year is still unwritten."),
        Bunny(id: "darling", month: 2, name: "Darling", season: "February",
              fillHex: "F3E4E4", strokeHex: "B3888C", accentHex: "D4A8AC",
              line: "A small tenderness, kept close."),
        Bunny(id: "equinox", month: 3, name: "Equinox", season: "March",
              fillHex: "E7EDE3", strokeHex: "7E9174", accentHex: "A9B89A",
              line: "Light and dark in equal measure. Begin in balance."),
        Bunny(id: "shower", month: 4, name: "Shower", season: "April",
              fillHex: "E6EEF2", strokeHex: "7E93A1", accentHex: "A7BCC8",
              line: "What falls, feeds. Let the month arrive softly."),
        Bunny(id: "blossom", month: 5, name: "Blossom", season: "May",
              fillHex: "F6E8EA", strokeHex: "C08B93", accentHex: "E0B4BA",
              line: "A brief, perfect opening."),
        Bunny(id: "solstice", month: 6, name: "Solstice", season: "June",
              fillHex: "F4EBD4", strokeHex: "C4A15A", accentHex: "E0C57A",
              line: "The longest light. Stay in it a little longer."),
        Bunny(id: "heat", month: 7, name: "Heat", season: "July",
              fillHex: "F3E4D6", strokeHex: "C08A68", accentHex: "E0B089",
              line: "Warmth as a kind of luck."),
        Bunny(id: "harvest", month: 8, name: "Harvest", season: "August",
              fillHex: "F3E6C8", strokeHex: "C4A36A", accentHex: "E2C888",
              line: "Golden hour, gathered. The year begins to glow."),
        Bunny(id: "goldleaf", month: 9, name: "Goldleaf", season: "September",
              fillHex: "F0E2C4", strokeHex: "B8954E", accentHex: "D4B56A",
              line: "A harvest moon, and the first cool morning."),
        Bunny(id: "shadow", month: 10, name: "Shadow", season: "October",
              fillHex: "EDE4DC", strokeHex: "5C4A5A", accentHex: "C4A36A",
              line: "A Halloween charm. The beautiful dark, worn lightly."),
        Bunny(id: "ember", month: 11, name: "Ember", season: "November",
              fillHex: "F0E0D0", strokeHex: "A07858", accentHex: "C4A07A",
              line: "What remains after the fire. Still warm."),
        Bunny(id: "starlight", month: 12, name: "Starlight", season: "December",
              fillHex: "EEE8DC", strokeHex: "8A7E68", accentHex: "D4C48A",
              line: "A small light, kept for the longest night."),
    ]

    static func bunny(forMonth month: Int) -> Bunny {
        all.first(where: { $0.month == month }) ?? all[0]
    }

    static func bunny(id: String) -> Bunny {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}
