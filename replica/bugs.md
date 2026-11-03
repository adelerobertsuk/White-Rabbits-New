# Bugs

Run: iPhone 17 Pro simulator (iOS 26.5), scheme `WhiteRabbitsUITests`, 21 cases: 17 passed, 4 failed. After fixes: 21 of 21 passed.

## BUG-001 (S3) Settings toggles have no accessible name or value (FIXED)
- Cases: F01-A1, F08-H1
- Steps: open Settings tab. Inspect the Alarm, Haptics, Dark evening and Preview the 1st switches.
- Expected: each switch has a label and an on/off value for VoiceOver.
- Actual: 4 buttons with an empty label and an empty value. Their state cannot be read.
- Evidence: `testF01A1_togglesLabelled` ("toggles without an accessible name: 4"), `testF08H1_toggleStateObservable`.
- Cause: `SanctuaryToggle` in `WhiteRabbits/Views/Shared/CardBackground.swift` is a plain `Button` with a capsule label.

## BUG-002 (S3) Settings intention is not capped at 120 characters (FIXED)
- Case: F03-E3
- Steps: Settings tab, type 150 characters into "My intention".
- Expected: capped at 120, like the monthly prompt (`HomeView.swift` IntentionPromptView).
- Actual: all 150 kept.
- Evidence: `testF03E3_settingsIntentionCap` (150 > 120).
- Cause: `SettingsView.intentionCard` has no length limit.

## To check (not reproduced as bugs)
- **Auto-ritual on the 1st.** With Preview the 1st on, opening Home runs the monthly reveal and completes the ritual with no tap. The "Say White Rabbits" button disappears and the intention prompt opens. Confirm this is intended. F02-H1/H2/E2 now test this flow.
- **F07-N1 (reset, then cancel)** (FIXED): the confirmation was a popover with no Cancel button. It is now an alert with Cancel, covered by `testF07N1_resetCancelKeepsData`.
- **Intention sheet returns on relaunch** if it was neither skipped nor kept after the ritual (the code re-presents it). Probably intended.
- **Not covered by the simulator:** alarm firing, notification delivery, share sheet, haptics, widget, real first of month.
