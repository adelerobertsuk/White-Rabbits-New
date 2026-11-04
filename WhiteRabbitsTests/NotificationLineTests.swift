import XCTest
@testable import WhiteRabbits

@MainActor
final class NotificationLineTests: XCTestCase {
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: y, month: m, day: d))!
    }

    /// Far-future dates, so no saved month record on the test device can interfere.
    func testNotificationBodiesMatchInAppLineAcrossDates() {
        let store = AppStore()
        for start in [date(2031, 2, 26), date(2031, 5, 29), date(2031, 12, 29), date(2032, 2, 25)] {
            let entries = store.upcomingLuckyHourEntries(from: start, days: 7)
            XCTAssertEqual(entries.count, 7)
            for entry in entries {
                let day = Calendar.current.startOfDay(for: entry.fireDate)
                XCTAssertEqual(entry.body, store.dailyGiftLine(for: day), "\(day)")
                if Calendar.current.component(.day, from: day) == 1 {
                    XCTAssertEqual(entry.body, "White Rabbits, White Rabbits!", "\(day)")
                } else {
                    XCTAssertEqual(entry.body, Affirmations.line(for: day), "\(day)")
                }
            }
        }
    }

    func testFirstOfMonthIsGreetingEverywhere() {
        let store = AppStore()
        let first = date(2031, 3, 1)
        XCTAssertEqual(store.dailyGiftLine(for: first), "White Rabbits, White Rabbits!")
        XCTAssertEqual(Affirmations.dailyLine(for: first), "White Rabbits, White Rabbits!")
    }

    func testSharedRuleIntentionOnlyOnThe7th14thAnd21st() {
        let mine = "Be gentle with myself"
        for day in [7, 14, 21] {
            XCTAssertEqual(Affirmations.dailyLine(for: date(2031, 3, day), greetingDue: false, intention: mine), mine)
        }
        let other = date(2031, 3, 8)
        XCTAssertEqual(Affirmations.dailyLine(for: other, greetingDue: false, intention: mine), Affirmations.line(for: other))
        XCTAssertEqual(Affirmations.dailyLine(for: date(2031, 3, 7), greetingDue: false, intention: ""), Affirmations.line(for: date(2031, 3, 7)))
        // A completed ritual hands the 1st back to the affirmation.
        let first = date(2031, 3, 1)
        XCTAssertEqual(Affirmations.dailyLine(for: first, greetingDue: false, intention: ""), Affirmations.line(for: first))
    }

    func testReviewedBankHas500UniqueAffirmations() {
        let bank = Affirmations.all
        XCTAssertEqual(bank.count, 500)
        XCTAssertEqual(Set(bank).count, 500)

        let front = [
            "Your kindness is never a small thing.",
            "There’s still time for something extraordinary.",
            "A beautiful life has many shapes.",
            "Your best chapters aren’t behind you.",
            "The love you give matters.",
            "Life has more colours than this moment.",
            "Your dreams matter even before they happen.",
            "The little things count as living.",
            "The world is better with you in it.",
            "Beautiful things happen in imperfect lives.",
            "Your joy can be quiet and still be beautiful.",
            "Big dreams belong to ordinary people, too.",
            "Your little corner of the world matters.",
            "There’s more than one road to happiness.",
            "Your life doesn’t need an audience to matter.",
            "A hopeful heart is a beautiful thing.",
            "Your heart has room for new joys.",
            "There’s joy in being wonderfully human.",
        ]
        XCTAssertEqual(Array(bank.prefix(18)), front)

        let luck = bank.firstIndex(of: "Good luck looks lovely on you.")
        let wishes = bank.firstIndex(of: "Some of your wishes are already memories.")
        XCTAssertEqual(luck, 255)
        XCTAssertEqual(wishes, 410)

        for favourite in [
            "The stars are quietly rooting for you.",
            "Good things are finding their way to you.",
            "Resilience lives in ordinary days.",
        ] {
            XCTAssertTrue(bank.contains(favourite), favourite)
        }
        XCTAssertFalse(bank.contains("Good things are drawn to your care."))
        XCTAssertFalse(bank.contains("Something lovely is on its way."))

        for line in bank {
            let words = line.split(whereSeparator: \.isWhitespace)
            XCTAssertLessThanOrEqual(words.count, 12, line)
            XCTAssertFalse(words.isEmpty, line)
        }

        func opening(_ line: String) -> [String] {
            Array(line.split(whereSeparator: \.isWhitespace).prefix(2)).map { $0.lowercased() }
        }
        for index in bank.indices {
            let start = opening(bank[index])
            let end = min(bank.count, index + 4)
            for later in (index + 1)..<end {
                XCTAssertNotEqual(start, opening(bank[later]), "\(bank[index]) / \(bank[later])")
            }
        }
    }
}
