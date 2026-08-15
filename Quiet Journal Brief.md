# White Rabbit: The Quiet Journal Brief

Saved 15 Aug 2026 for tomorrow. Do not start this until Adele opens a new chat and asks to begin.

## Role

Senior UI/UX Engineer & Minimalist Designer

## Task

Refactor the existing White Rabbit prototype back into a pristine, ultra-minimalist, private journal. Strip away all community sharing, social network features, and backend complexity that caused previous design clutter.

## Core constraints

### The layout

A strict, clean, native-feeling 3-tab layout with generous whitespace, crisp typography, and zero heavy containers, excessive padding, or clunky buttons.

### The core mechanic (one entry a day)

The journal feature must be strictly limited to one entry per calendar day, stored locally on the device (using local storage). Once a daily entry is logged, it can be viewed or edited, but no additional new entries can be created until the next day.

### Design aesthetic

Quiet, distraction-free, analog feel. Focus entirely on local styling, serene typography, and a peaceful user experience.

## Punch list for the next chat

This is the same app in `Studio/White Rabbits New/`. Stay on branch `swiftui-ios-app`. Do not start a new product or folder.

What to strip
- Circle tab and all social / sanctuary sharing
- Supabase, `CircleSyncService`, `SupabaseConfig`, join/leave circle
- Share button and share-card render on journal pages
- Shared Sanctuary toggle in Settings
- Friends, sparks, fellows, remote members

What to keep and quieten
- Today, Journal, Charms as the 3 tabs (confirm with Adele if she wants a different third tab)
- On-device JSON store and photos (`Persistence.swift`)
- One page per calendar day (the store already keys entries by `yyyy-MM-dd`)
- First-of-month ritual, charms, habits, settings, export/import

UI bar
- World class only. Reuse the existing Palette, type styles, and radii. No one-off hex. No em dashes in copy.
- Once today's page exists, the invite must become view / edit, never a second new page.
