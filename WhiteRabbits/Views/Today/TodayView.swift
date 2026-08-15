//
//  TodayView.swift
//  WhiteRabbits
//
//  Tab 1: the daily anchor. Ring, greeting, suggestions, journal, and
//  (if pinned from Circle) this month's intention docked at the base.
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    @State private var showRitual = false
    @State private var showPinnedCard = false
    @State private var showNewEntry = false

    private var isCelebratory: Bool {
        store.isFirstOfMonth() && !store.ritualCompleted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Layout.stackSpacing) {
                    ProgressRingView(
                        progress: store.progress,
                        isCelebratory: isCelebratory,
                        bunny: store.currentBunny(),
                        onTap: {
                            if isCelebratory {
                                Haptics.medium()
                                showRitual = true
                            }
                        }
                    )
                    .padding(.top, 12)

                    header

                    if let record = store.monthRecord(), let intention = record.intention, !intention.isEmpty {
                        IntentionCardView(record: record)
                    }

                    SuggestionsCardView(
                        suggestions: store.suggestions(),
                        isCollapsed: Binding(
                            get: { store.data.suggestionsCollapsed },
                            set: { _ in store.toggleSuggestionsCollapsed() }
                        ),
                        onTapSuggestion: handle
                    )

                    if !doneHabitsToday.isEmpty {
                        habitsCard
                    }

                    inspirationBlock

                    JournalInviteCardView()

                    if let record = store.pinnedRecord, let intention = record.intention, !intention.isEmpty {
                        PinnedIntentionDockView(
                            record: record,
                            photo: store.intentionPhoto(),
                            onTap: { showPinnedCard = true }
                        )
                    }
                }
                .padding(Layout.screenInset)
                // Generous bottom padding to clear the floating bottom navigation bar completely
                .padding(.bottom, 100)
            }
            .scrollBounceBehavior(.basedOnSize)
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(store.todayKicker())
                        .kickerStyle()
                }
            }
            .settingsButton()
        }
        .sheet(isPresented: $showRitual) { RitualSheetView() }
        .sheet(isPresented: $showPinnedCard) { IntentionEditorView() }
        .sheet(isPresented: $showNewEntry) { NewEntrySheet(date: Date()) }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 10) {
            Text("White Rabbits")
                .font(.system(size: 38, weight: .light))
                .tracking(-2.1)
                .foregroundStyle(palette.ink)
            Text(store.greeting())
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
            Text(doneText)
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .tracking(0.9)
                .foregroundStyle(palette.faint)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Layout.screenInset)
    }

    private var inspirationBlock: some View {
        let inspiration = InspirationData.today()
        return VStack(spacing: 6) {
            Text(store.monthLightKicker())
                .kickerStyle()
            Text(inspiration.line)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
            Text(inspiration.prompt)
                .bodyStyle(muted: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Layout.cardPadding)
        .cardBackground()
    }

    private var doneText: String {
        if isCelebratory { return String(localized: "today.beginMonth", defaultValue: "Begin the month") }
        let total = store.totalCount
        guard total > 0 else { return String(localized: "today.addHabit", defaultValue: "Add a habit to begin") }
        let done = store.doneCount
        if done == 0 { return String(localized: "today.gentleBeginning", defaultValue: "A gentle beginning") }
        if done == total { return String(localized: "today.complete", defaultValue: "Today is complete") }
        return String(format: String(localized: "today.keptCount", defaultValue: "%d kept today"), done)
    }

    /// Only the habits actually kept today. The "Today" card below stays
    /// off the page until at least one of these exists, so it reads as a
    /// quiet little log of what's been carried out from Suggestions, not
    /// a second, always-present checklist duplicating them.
    private var doneHabitsToday: [Habit] {
        store.data.habits.filter { store.isHabitDone($0.id) }
    }

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "today.habits.title", defaultValue: "Today"))
                .sectionHeaderStyle()

            ForEach(doneHabitsToday) { habit in
                Button {
                    Haptics.light()
                    store.toggleHabit(habit.id)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: store.isHabitDone(habit.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                            .foregroundStyle(store.isHabitDone(habit.id) ? palette.accent : palette.faint)
                        Text(habit.name)
                            .bodyStyle()
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Layout.cardPadding)
        .cardBackground()
    }

    private func handle(_ suggestion: Suggestion) {
        switch suggestion.action {
        case .toggleHabit(let id):
            store.toggleHabit(id)
        case .openJournal:
            showNewEntry = true
        case .openRitual:
            showRitual = true
        case .openIntention:
            showPinnedCard = true
        }
    }
}

#Preview {
    TodayView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
