//
//  FellowsData.swift
//  WhiteRabbits
//
//  A handful of gentle reference cards so the Circle tab never feels
//  empty before real friends join. Purely local, never uploaded.
//

import Foundation

enum FellowsData {
    static let names: [(name: String, intention: String)] = [
        ("Mira", "Keep the mornings slow"),
        ("Jonah", "Make one true thing"),
        ("Sylvie", "Leave room for luck"),
        ("Kenji", "Protect the quiet hours"),
        ("Noor", "Begin with softness"),
    ]

    /// Four rotating reference cards for the current month, so the
    /// list looks a little different as the months turn.
    static func cards(for date: Date = Date()) -> [SanctuaryCard] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let bunny = BunnyData.bunny(forMonth: month)
        let start = (month - 1) % names.count
        return (0..<4).map { offset in
            let entry = names[(start + offset) % names.count]
            return SanctuaryCard(
                id: "fellow-\(entry.name.lowercased())",
                name: entry.name,
                intention: entry.intention,
                month: month,
                year: year,
                charmId: bunny.id,
                kind: .fellow
            )
        }
    }
}
