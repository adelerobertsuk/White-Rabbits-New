# White Rabbits — Current Save Point

**Updated:** 21 August 2026 (Settings copy/hierarchy pass complete)
**Status:** Shipping priority. Continue toward TestFlight QA and App Store submission.

## Product truth

White Rabbits is a tiny first-of-the-month ritual for good luck, good intentions and a positive start to the month.

- Say **“White Rabbits!”** first thing on the first of the month.
- The app's charm alarm makes sure the user remembers.
- The user can set a **monthly intention**.
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

## Next outstanding task

**Whole-app customer-facing language audit.** Settings is now done, but the wider string catalog still carries a large population of stale copy from earlier product concepts — `circle.*`, `journal.*`, `tab.journal`, `milestone.*`, `today.journal.*`, and similar — left over from the old journal/friends-circle/streak direction. `CURRENT.md`'s standing instruction not to infer product requirements from stale keys still applies. This audit was explicitly deferred, not started, in this session — needs its own agreed brief/scope before any Claude session touches it, per the working method above (one app, one contained task per session).

## Next-chat starter

> We are continuing White Rabbits. Read `AKA-CURRENT.md`, then this White Rabbits `CURRENT.md`, then the app's authoritative Studio docs. Cursor is unavailable until 13 September, Claude is temporarily implementing, and GG is holding continuity/product/copy/QA. The Settings copy/hierarchy pass is complete and shipped. The next agreed task is a whole-app customer-facing language audit (stale journal/circle/streak-era strings) — this needs a contained brief before work starts. First tell me what is already complete according to the files and what remains before making any new changes.
