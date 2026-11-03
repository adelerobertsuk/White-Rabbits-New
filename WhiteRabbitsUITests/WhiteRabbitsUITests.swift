import XCTest

final class WhiteRabbitsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        addUIInterruptionMonitor(withDescription: "system alert") { alert in
            for label in ["Don\u{2019}t Allow", "Don't Allow", "Not Now", "OK"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
        app.launch()
        clearDevice()
    }

    // MARK: helpers

    func tab(_ name: String) { app.tabBars.buttons[name].tap() }

    func scrollTo(_ element: XCUIElement, max: Int = 8) {
        var n = 0
        while (!element.exists || !element.isHittable) && n < max { app.swipeUp(); n += 1 }
    }

    func clearDevice() {
        if app.buttons["Skip"].waitForExistence(timeout: 2) { app.buttons["Skip"].tap() }
        tab("Settings")
        let reset = app.buttons["Clear all White Rabbits data"]
        app.swipeUp(); app.swipeUp()
        // The link can sit under the tab bar; tap its centre by coordinate.
        reset.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.buttons["Clear this device"].tap()
        sleep(1)
        tab("Home")
    }

    func field(_ placeholder: String) -> XCUIElement {
        let tf = app.textFields[placeholder]
        return tf.exists ? tf : app.textViews[placeholder]
    }

    /// SanctuaryToggle is exposed as a switch labelled with its row title.
    func toggle(nextTo title: String) -> XCUIElement {
        let sw = app.switches[title]
        scrollTo(sw)
        return sw
    }

    /// On the 1st, opening Home runs the monthly reveal, completes the ritual and raises the intention prompt.
    func enablePreviewAndSay() {
        tab("Settings")
        toggle(nextTo: "Preview the 1st").tap()
        tab("Home")
        _ = app.buttons["Skip"].waitForExistence(timeout: 8)
    }

    func topField(_ placeholder: String) -> XCUIElement {
        app.swipeDown(); app.swipeDown(); app.swipeDown()
        return field(placeholder)
    }

    func collectionCount() -> String {
        tab("Collection")
        let t = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d+ OF 12")).firstMatch
        _ = t.waitForExistence(timeout: 3)
        return t.label
    }

    func relaunch() { app.terminate(); app.launch() }

    // MARK: F01

    func testF01H1_launch() {
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
        XCTAssertTrue(app.buttons["Share your luck"].waitForExistence(timeout: 3))
        for t in ["Home", "Collection", "Settings"] { XCTAssertTrue(app.tabBars.buttons[t].exists, t) }
    }

    func testF01H2_collectionFresh() {
        XCTAssertEqual(collectionCount(), "0 OF 12")
    }

    func testF01A1_togglesLabelled() {
        tab("Settings")
        let switches = app.switches.allElementsBoundByIndex
        XCTAssertGreaterThanOrEqual(switches.count, 4, "Settings toggles should be exposed as switches")
        let unlabeled = switches.filter { $0.label.isEmpty }
        XCTAssertEqual(unlabeled.count, 0, "toggles without an accessible name: \(unlabeled.count)")
    }

    // MARK: F02

    func testF02H1_previewAutoSaysOnHome() {
        enablePreviewAndSay()
        XCTAssertTrue(app.buttons["Skip"].exists, "intention prompt should follow the reveal")
    }

    func testF02H2_sayUnlocksStamp() {
        enablePreviewAndSay()
        app.buttons["Skip"].tap()
        XCTAssertEqual(collectionCount(), "1 OF 12")
    }

    func testF02E2_cannotSayTwice() {
        enablePreviewAndSay()
        sleep(1)
        if app.buttons["Skip"].exists { app.buttons["Skip"].tap() }
        tab("Collection"); tab("Home")
        XCTAssertFalse(app.buttons["Say White Rabbits"].exists)
    }

    // MARK: F03

    func testF03H1_promptKeep() {
        enablePreviewAndSay()
        XCTAssertTrue(app.staticTexts["What would you like to carry into this month?"].waitForExistence(timeout: 4))
        let input = app.textFields.firstMatch.exists ? app.textFields.firstMatch : app.textViews.firstMatch
        input.tap(); input.typeText("Be brave")
        app.buttons["Keep this"].tap()
        tab("Settings")
        XCTAssertTrue(app.textFields["Be brave"].exists || app.textViews["Be brave"].exists)
    }

    func testF03H2_promptSkipStaysSkipped() {
        enablePreviewAndSay()
        XCTAssertTrue(app.buttons["Skip"].waitForExistence(timeout: 4))
        app.buttons["Skip"].tap()
        relaunch()
        sleep(2)
        XCTAssertFalse(app.buttons["Skip"].exists)
    }

    func testF03E1_emptyKeepDisabled() {
        enablePreviewAndSay()
        XCTAssertTrue(app.buttons["Keep this"].waitForExistence(timeout: 4))
        XCTAssertFalse(app.buttons["Keep this"].isEnabled)
    }

    func testF03E2_promptCap() {
        enablePreviewAndSay()
        XCTAssertTrue(app.buttons["Keep this"].waitForExistence(timeout: 4))
        let input = app.textFields.firstMatch.exists ? app.textFields.firstMatch : app.textViews.firstMatch
        input.tap(); input.typeText(String(repeating: "a", count: 150))
        XCTAssertLessThanOrEqual((input.value as? String ?? "").count, 120)
    }

    func testF03E3_settingsIntentionCap() {
        tab("Settings")
        let f = topField("What are you carrying into this month?")
        f.tap(); f.typeText(String(repeating: "a", count: 150))
        sleep(1) // let the cap finish trimming
        let typed = app.textFields.matching(NSPredicate(format: "value BEGINSWITH 'aaaa'")).firstMatch
        XCTAssertLessThanOrEqual((typed.value as? String ?? "").count, 120, "Settings intention is uncapped, prompt caps at 120")
    }

    func testF03E4_emojiAccents() {
        tab("Settings")
        let f = topField("What are you carrying into this month?")
        f.tap(); f.typeText("Café 🐇 naïve")
        relaunch(); tab("Settings")
        app.swipeDown(); app.swipeDown()
        let saved = app.textFields.matching(NSPredicate(format: "value == %@", "Café 🐇 naïve")).firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 3))
    }

    // MARK: F04

    func testF04H1_namePersists() {
        tab("Settings")
        let n = app.textFields["Adele"]
        n.tap(); n.typeText("Kate")
        relaunch(); tab("Settings")
        XCTAssertEqual(app.textFields["Kate"].exists, true)
    }

    func testF04E1_spacesOnlyName() {
        tab("Settings")
        let n = app.textFields["Adele"]
        n.tap(); n.typeText("   ")
        relaunch(); tab("Settings")
        XCTAssertTrue(app.textFields["Adele"].exists, "spaces-only name should read as empty (placeholder)")
    }

    func testF04E2_longName() {
        tab("Settings")
        let n = app.textFields["Adele"]
        n.tap(); n.typeText(String(repeating: "W", count: 200))
        XCTAssertTrue(app.staticTexts["Settings"].exists)
    }

    // MARK: F05

    func testF05H1_stampSurvivesRelaunch() {
        enablePreviewAndSay()
        sleep(1)
        relaunch()
        if app.buttons["Skip"].waitForExistence(timeout: 3) { app.buttons["Skip"].tap() }
        XCTAssertEqual(collectionCount(), "1 OF 12")
    }

    // MARK: F06

    func testF06H1_alarmPicker() {
        tab("Settings")
        let row = app.staticTexts["White Rabbits alarm"]
        scrollTo(row)
        let time = app.buttons.allElementsBoundByIndex.first {
            abs($0.frame.midY - row.frame.midY) < 30 && $0.frame.width > 60
        }
        time?.tap()
        XCTAssertTrue(app.datePickers.firstMatch.waitForExistence(timeout: 2) || app.pickerWheels.firstMatch.exists)
    }

    func testF06N1_alarmToggleNoCrash() {
        tab("Settings")
        toggle(nextTo: "White Rabbits alarm").tap()
        sleep(3)
        XCTAssertEqual(app.state, .runningForeground)
    }

    // MARK: F07

    func testF07H1_resetClearsStamps() {
        enablePreviewAndSay()
        sleep(1)
        clearDevice()
        XCTAssertEqual(collectionCount(), "0 OF 12")
    }

    func testF07N1_resetCancelKeepsData() {
        enablePreviewAndSay()
        if app.buttons["Skip"].exists { app.buttons["Skip"].tap() }
        tab("Settings")
        let reset = app.buttons["Clear all White Rabbits data"]
        scrollTo(reset); reset.tap()
        XCTAssertTrue(app.alerts.buttons["Cancel"].waitForExistence(timeout: 3), "reset confirmation needs a Cancel button")
        app.alerts.buttons["Cancel"].tap()
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertEqual(collectionCount(), "1 OF 12")
    }

    // MARK: F08

    func testF08H1_toggleStateObservable() {
        tab("Settings")
        let t = toggle(nextTo: "Haptics")
        let before = t.value as? String
        t.tap()
        let after = toggle(nextTo: "Haptics").value as? String
        XCTAssertNotNil(after, "toggle exposes no value to assistive tech")
        XCTAssertNotEqual(before, after)
    }
}
