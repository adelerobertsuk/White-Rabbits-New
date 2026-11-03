# White Rabbits test plan (iOS, XCUITest)

Target: `WhiteRabbitsUITests`, iPhone 17 Pro simulator. Source of flows: AppStore, HomeView, SettingsView, WhiteRabbitsApp.
Each test starts from a cleared device (Settings > Clear all White Rabbits data).

## Flows
F01 Launch and tabs (Home, Collection, Settings)
F02 Say White Rabbits (Preview the 1st) and unlock the month's stamp
F03 Monthly intention (prompt sheet, Settings field)
F04 Name (Settings)
F05 Persistence across relaunch
F06 Alarm and lucky minute settings
F07 Reset device
F08 Toggles (haptics, dark evening, preview)

## Cases
| ID | Case | Expect |
| --- | --- | --- |
| F01-H1 | Cold launch | Home tab selected, kicker "White Rabbits", "Share your luck" visible, 3 tabs |
| F01-H2 | Open Collection on fresh data | "0 OF 12" |
| F01-A1 | Every Settings toggle has an accessible name | toggles are labelled |
| F02-H1 | Turn on Preview the 1st, return Home | monthly reveal runs, intention prompt appears (ritual auto-completes) |
| F02-H2 | After the reveal, Skip the prompt | Collection shows "1 OF 12" |
| F02-E2 | Say it, then Home | button gone (cannot say twice) |
| F03-H1 | After saying, prompt sheet: type, Keep this | sheet closes, Settings intention holds text |
| F03-H2 | Prompt: Skip | sheet closes, prompt not shown again on relaunch |
| F03-E1 | Prompt: empty text | Keep this disabled |
| F03-E2 | Prompt: 150 chars | capped at 120 |
| F03-E3 | Settings intention: 150 chars | capped at 120 like the prompt |
| F03-E4 | Intention with emoji and accents | stored intact |
| F04-H1 | Enter name | persists after relaunch |
| F04-E1 | Name with spaces only | stored as empty |
| F04-E2 | 200 char name | does not crash, layout holds |
| F05-H1 | Say it, relaunch | Collection still "1 OF 12" |
| F06-H1 | Open alarm time picker | wheel appears |
| F06-N1 | Switch alarm on with permission denied | toggle returns to off, no crash |
| F07-H1 | Reset, confirm | Collection back to "0 OF 12" |
| F07-N1 | Reset, cancel | data kept |
| F08-H1 | Toggle Haptics, Dark evening | value change is observable to assistive tech |

Not automated (manual or device only): real AlarmKit alarm firing, notification delivery at the lucky minute, share sheet contents, haptics, widget, real first-of-month date behaviour, App Store review prompt.
