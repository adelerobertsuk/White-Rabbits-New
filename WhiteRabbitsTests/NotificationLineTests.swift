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

    func testReviewedBankHas401UniqueAffirmations() {
        XCTAssertEqual(Affirmations.all.count, 401)
        XCTAssertEqual(Set(Affirmations.all).count, 401)
        XCTAssertTrue(Affirmations.all.contains("Good things are finding their way to you."))
        XCTAssertFalse(Affirmations.all.contains("Good things are drawn to your care."))
    }
}
