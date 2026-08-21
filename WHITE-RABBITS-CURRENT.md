# White Rabbits — Current Save Point

**Updated:** 21 August 2026 (Settings pass, 500-line affirmation bank, intention cadence, whole-app language audit, and release-readiness fixes all complete)
**Status:** Shipping priority. Continue toward TestFlight QA and App Store submission.

## Product truth

White Rabbits is a tiny first-of-the-month ritual for good luck, good intentions and a positive start to the month.

- Say **“White Rabbits!”** first thing on the first of the month.
- The app's charm alarm makes sure the user remembers.
- The user can set a **monthly intention**, which lives in Settings and reappears gently on the Home screen exactly three times a month (**1st, 11th, 21st**) — never a streak, journal or productivity mechanic.
- **11:11 is not a wish feature.** It is a small daily moment: **“a little nod from the universe.”**
- Do not label 11:11 as “angel numbers”; keep it open and inclusive.
- Bunny, seasonal stamps and widgets are charm, not productivity mechanics.
- No account, feed, streak pressure or habit-tracker behaviour.
- White Rabbits is **not a journal**.

## Current implementation situation

Cursor's work from the morning of 21 August appears to have saved into the synced project before its allowance stopped.

Evidence checked by GG:

- `Localizable.xcstrings` was modified on 21 August around 12:46.
- Current strings include intention language such as **“Set this month's intention”** / **“My Intention.”**
- Current strings include the 11:11 direction **“A little nod from the universe.”**
- A new `StudioContact.swift` was created on 21 August.

There are still stale internal/localization references to old concepts, including “wish” terminology and older journal/social concepts. **Do not infer product requirements from stale keys. Current Studio/product docs override them.**

## Settings screen — agreed polish pass

The Settings visual design is fundamentally good. **Do not redesign it.** The problem is copy density and hierarchy. Aim to remove roughly 40–50% of explanatory text while preserving behaviour.

Agreed direction:

- Keep **“This is yours, Adele.”**
- Intro: simplify toward **“Everything stays on this device.”**
- `YOUR NAME`: name is enough; remove unnecessary explanation.
- `THIS MONTH`: make intention-setting obvious and warm. Direction: **“Set an intention”** / **“A little note from you, to you.”**
- `CHARM ALARM`: simplify explanation. Direction: **“First of every month.”**
- Test action: prefer **“Test alarm.”**
- Rename **LUCKY MINUTE** to **11:11**.
- 11:11 explanation: **“A little nod from the universe.”**
- Test action: prefer **“Test reminder.”**
- Haptics direction: **“A little tap for luck.”**
- Dark evening direction: **“Softer after dusk.”**
- Preview direction: **“Preview the 1st”** / **“See what happens.”**

### Why White Rabbits card

Current card is too long and still contains old “wish” language. Cut it dramatically. Direction:

> **WHY WHITE RABBITS**
>
> An old British ritual for good luck.
>
> Say “White Rabbits” first thing on the first of the month. Set an intention. Start the month with good vibes.
>
> We just make sure you remember. 🐇

Do not re-explain 11:11 in this card; it has its own setting.

### Bottom utilities

Keep Support/Privacy/Studio/export/import utilities quiet and compact. Support does not need a large explanatory card. Keep destructive “clear all data” action visually isolated.

## Completed — Settings copy/hierarchy pass (21 August 2026)

Status: **done, reviewed on-device by Adele, committed and pushed.** This pass is closed; do not reopen without a new agreed brief.

What shipped, against the agreed direction above:

- Intro simplified to **“Everything stays on this device.”**
- `YOUR NAME`: caption removed, name field alone. (`field()` helper's caption made optional rather than duplicated, so this stays behaviour-neutral.)
- Intention field: label → **“Set an intention,”** caption → **“A little note from you, to you.”** No new section heading added — kept as a pure copy change, per Adele's explicit call to keep the UI as-is rather than add hierarchy.
- Charm Alarm: normal enabled state → **“First of every month.”** The “next rings” variant keeps the specific date (**“First of every month. Next: %@.”**); the off/invite state keeps its functional description (**“First of every month. Pick a time, and we'll remind you.”**); the denied/exceptional state was deliberately left untouched, since it's the one state that genuinely needs the user's attention. Test action renamed **“Test alarm.”**
- Renamed Lucky Minute → **11:11**. The old “Lucky minute” kicker line was removed outright (rather than relabelled to “11:11”) so the screen doesn't show “11:11” twice stacked on top of itself — the large “11:11” numeral is now the only visible label. Status line (on and off) is now exactly **“A little nod from the universe.”** — denied/exceptional state left untouched for the same reason as the alarm. Test action renamed **“Test reminder.”**
- Haptics caption → **“A little tap for luck.”** Dark evening caption → **“Softer after dusk.”** Preview title/caption → **“Preview the 1st”** / **“See what happens.”**
- Why White Rabbits card replaced with the exact agreed copy above; no longer re-explains 11:11.
- Support card: kicker “Support” and “Email AKA Studio” link only — the “Need a hand...” line removed entirely, card container/layout untouched.
- The malformed `\'` JSON escape that was sitting in the old intention-label value in `Localizable.xcstrings` is gone, resolved naturally by that string's rewrite.
- `luckyHour.kicker`, `settings.name.caption`, and `settings.support.body` were removed from the strings catalog as a direct, intended consequence of the copy cuts above — not a broader localization cleanup. The larger population of stale `circle.*`/`journal.*`/`tab.journal` keys from the old concept is untouched and still needs a real pass eventually (see next task, below).

**Implementation lesson worth keeping for next time:** in this codebase, `String(localized: "key", defaultValue: "...")` calls fall back to the Swift-source `defaultValue:` literal at runtime whenever the matching `.xcstrings` entry's `extractionState` is `"extracted_with_value"` (i.e. auto-extracted, state `"new"`, never marked `"translated"`) — Xcode does not compile those entries into the bundled `.strings` resource at all. Only entries with `extractionState: "manual"` / state `"translated"` (e.g. `settings.about.body`) get compiled and would win over a stale source default. **Practical implication: editing `Localizable.xcstrings` alone is not sufficient for most of the strings in this app — the Swift-source `defaultValue:` must be edited too, or the change silently won't show up.** This caused one round of stale copy (Haptics/Dark evening/Preview/11:11) in this pass, caught in visual review and fixed by editing both.

## Completed — Affirmation bank, 11:11 whispers, and intention cadence (21 August 2026)

Status: **done, built/tested, committed and pushed.** This pass is closed; do not reopen without a new agreed brief.

- **500 curated daily lines.** [Affirmations.swift](WhiteRabbits/Models/Affirmations.swift) now holds 500 unique lines (curated by GG from the original 365-line export, removing 33 weaker entries and adding new material for variety). Source of truth for provenance/curation notes: `Reference/affirmations/curation-notes.md` and the original editorial export at `Reference/affirmations/WHITE-RABBITS-AFFIRMATIONS-FOR-GG.txt`.
- **Continuous 500-line rotation.** The old selection logic picked a line by day-of-year (`(day - 1) % count`), which cleanly cycled exactly 365 lines but would have left ~134 of the new 500 permanently unreachable. Selection now uses a continuous day-counter — days since a fixed epoch (1 Jan 2025), mod 500 — so the whole bank rotates through once every ~16.5 months instead of resetting every January 1st. Verified: on 21 Aug 2026 the app correctly showed the line at array index 97, matching the day-counter math exactly.
- **Cleaned 11:11 whisper set.** The 12 `luckyHour.whisper.*` lines (used by the Lock Screen/share card at [LuckyHourShareCardView.swift](WhiteRabbits/Views/Home/LuckyHourShareCardView.swift)) were replaced with GG's cleaned set — kept light and ambiguous, no "angel number"/religious drift. Selection there is still day-of-year mod 12, unchanged and fine at that small scale (cycles many times a year, no dead lines).
- **Intention reminder cadence: 1st / 11th / 21st.** [HomeView.swift](WhiteRabbits/Views/Home/HomeView.swift)'s `shouldShowIntention` changed from "day 1 + every 7th day" (~weekly, 4–5×/month) to exactly three fixed dates a month. Verified exhaustively across all 31 possible day values — fires only on 1, 11, 21. No new UI, no notifications, no streak/journal mechanics added; the intention still lives in Settings and this is purely a display-condition change on the existing Home "gift line."
- Both the Swift `defaultValue:` literals and the `Localizable.xcstrings` catalog were kept in sync for every changed key, per the lesson recorded in the Settings pass above.

## Completed — Whole-app customer-facing language audit (21 August 2026)

Status: **done, approved, committed and pushed.** This pass is closed; do not reopen without a new agreed brief.

Every customer-facing string was audited against product truth — the live surface (Home, Settings, alarm, 11:11, notifications, widget: 70 live catalog keys, the 500-line affirmation bank, the 12 whispers, and a handful of hardcoded strings) came back clean, with no wish/journal/friends-circle/streak/habit-tracker/angel-number language. One change was approved and shipped:

- The 11:11 push notification title changed from `✨11:11✨` to plain **`11:11`**. Scoped narrowly: a new `LuckyMinuteCopy.notificationTitle` constant was added ([LuckyHourShareCardView.swift](WhiteRabbits/Views/Home/LuckyHourShareCardView.swift)) so only `LuckyHourScheduler.swift`'s notification title changed — the shareable 11:11 postcard image still uses the original sparkled `LuckyMinuteCopy.sparkle` text, since that wasn't part of the approved change.

Judgement calls explicitly resolved as "keep, no change":
- Affirmation line "You've got a lucky streak in miniature." stays — idiomatic, not a habit-tracker mechanic.
- AlarmKit secondary button "Say it" stays as-is.
- No pre-permission explainer screen added — out of scope for this pass.
- The ~95 dead/internal catalog keys (`circle.*`, `journal.*`, `tab.*`, `milestone.*`, old `intention.*`, etc.) and the entirely-unreferenced `RitualSheetView.swift` were confirmed genuinely unreachable by any customer — left untouched, not renamed or cleaned up.

## Completed — Release-readiness fixes (21 August 2026)

Status: **done, verified, committed and pushed.** This pass is closed; do not reopen without a new agreed brief.

Following the release-health inspection (read-only report, no changes made in that pass), GG/Adele made four calls and this pass implemented them:

1. **iPhone only.** `TARGETED_DEVICE_FAMILY` changed from `"1,2"` to `1` for both targets (all Debug/Release configs). Verified in a real-device archive: `UIDeviceFamily` is now `[1]` only. iPad was never designed or tested for — this is intentional and not a regression.
2. **Privacy manifest added.** Searched the actual source for every Apple "required-reason API" category (UserDefaults, file-timestamp APIs, disk-space APIs, system-boot-time APIs) — zero matches anywhere in either target, and the project has zero third-party/SPM dependencies. `WhiteRabbits/PrivacyInfo.xcprivacy` and `WhiteRabbitsWidget/PrivacyInfo.xcprivacy` were added declaring `NSPrivacyTracking: false`, empty tracking domains, empty collected-data types, and an empty required-reason API list — an accurate "we don't do any of this" declaration, not a speculative one. Both validated with `plutil -lint` and confirmed present in a real-device archive.
3. **Deployment target — tested, not just assumed.** Tried building/archiving at iOS 26.0: it genuinely fails. `AlarmPresentation.Alert.init(title:secondaryButton:secondaryButtonBehavior:)` in [MonthAlarmScheduler.swift:107](WhiteRabbits/Store/MonthAlarmScheduler.swift:107) — the alarm's "Say it" secondary button — is iOS 26.1+ only. Per instruction, left the deployment target at **26.1** rather than rewriting that functionality to force 26.0 compatibility.
4. **English-only for this release.** Removing `ja`/`ko` from the project's `knownRegions` alone turned out to be insufficient — Xcode's String Catalog compiler ships a `.lproj` for every locale that has *any* translated content inside `Localizable.xcstrings`, regardless of `knownRegions`. Verified this empirically (still shipped `ja.lproj`/`ko.lproj` in a real archive even after the `knownRegions` edit, confirmed not a caching artifact via a full DerivedData wipe). The actual fix: the 104 keys carrying `ja`/`ko` translations were backed up verbatim to [Reference/ja-ko-translations-backup.json](Reference/ja-ko-translations-backup.json) (nothing lost — fully recoverable), then those `ja`/`ko` blocks were surgically stripped from the live catalog. Re-verified in a fresh archive: only `en.lproj` ships now.

**Verification performed:** clean Debug build (simulator), clean Release build (simulator, 0 warnings/0 errors), real-device Release archive with Apple's `-validate-for-store` check — all green on the final settings.

**Remaining genuine release blocker:** none found. The paid Apple Developer Program membership question from the release-health report (needed for actual TestFlight/App Store distribution, distinct from the working "Apple Development" signing already confirmed) still needs a human check in developer.apple.com — that's an account-status fact only Adele can confirm, not something inspectable from this repo.

**Still open from the release-health report, deliberately not touched this pass:** no launch-screen project, no accessibility expansion, no widget deep-link change, no new permission explainer — all explicitly deferred. The live website's "11:11 wishes" wording is being handled separately outside this repo.

## Next outstanding task

None currently agreed. Settings pass, affirmation-bank swap, intention cadence, language audit, and release-readiness fixes are all closed. Next up (per Adele/GG, not yet started): App Store screenshot capture, once GG art-directs the six exact states. Await that brief before starting.

## Next-chat starter

> We are continuing White Rabbits. Read `AKA-CURRENT.md`, then this White Rabbits `CURRENT.md`, then the app's authoritative Studio docs. Cursor is unavailable until 13 September, Claude is temporarily implementing, and GG is holding continuity/product/copy/QA. The Settings copy/hierarchy pass, the 500-line affirmation bank swap, the cleaned 11:11 whispers, the intention-reminder cadence (1st/11th/21st), the whole-app customer-facing language audit, and the release-readiness fixes (iPhone-only, privacy manifest, deployment target confirmed at 26.1, English-only for this release) are all complete and shipped. Next up is App Store screenshot capture, once GG art-directs the six exact states — first tell me what is already complete according to the files, then wait for that brief before making any changes.
