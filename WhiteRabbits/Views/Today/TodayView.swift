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
    @State private var showNewEntry = false
    @State private var showEntryDetail = false
    @State private var showPinnedCard = false

    private var isCelebratory: Bool {
        store.isFirstOfMonth() && !store.ritualCompleted()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
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

                    YearOfLuckStampCardView()

                    inspirationBlock

                    SuggestionsCardView(
                        suggestions: store.suggestions(),
                        isCollapsed: Binding(
                            get: { store.data.suggestionsCollapsed },
                            set: { _ in store.toggleSuggestionsCollapsed() }
                        ),
                        onTapSuggestion: handle
                    )

                    habitsCard

                    journalCard

                    if let record = store.pinnedRecord, let intention = record.intention, !intention.isEmpty {
                        PinnedIntentionDockView(
                            record: record,
                            photo: store.intentionPhoto(),
                            onTap: { showPinnedCard = true }
                        )
                    }
                }
                .padding(20)
                .padding(.bottom, 12)
            }
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(store.todayKicker())
                        .font(.system(size: 12, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1.4)
                        .foregroundStyle(palette.muted)
                }
            }
        }
        .sheet(isPresented: $showRitual) { RitualSheetView() }
        .sheet(isPresented: $showNewEntry) { NewEntrySheet(date: Date()) }
        .sheet(isPresented: $showEntryDetail) {
            if let entry = store.journalEntry() {
                JournalEntryDetailView(entry: entry)
            }
        }
        .sheet(isPresented: $showPinnedCard) { IntentionEditorView() }
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
                .tracking(1.6)
                .foregroundStyle(palette.faint)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    private var inspirationBlock: some View {
        let inspiration = InspirationData.today()
        return VStack(spacing: 6) {
            Text(store.monthLightKicker())
                .font(.system(size: 11, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundStyle(palette.faint)
            Text(inspiration.line)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.center)
            Text(inspiration.prompt)
                .font(.system(size: 13))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
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

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "today.habits.title", defaultValue: "Today"))
                .font(.system(size: 13, weight: .semibold))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(palette.muted)

            ForEach(store.data.habits) { habit in
                Button {
                    Haptics.light()
                    store.toggleHabit(habit.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: store.isHabitDone(habit.id) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(store.isHabitDone(habit.id) ? palette.accent : palette.faint)
                        Text(habit.name)
                            .font(.system(size: 15))
                            .foregroundStyle(palette.ink)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .cardBackground()
    }

    private var journalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "today.journal.title", defaultValue: "Journal"))
                    .font(.system(size: 13, weight: .semibold))
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .foregroundStyle(palette.muted)
                Spacer()
                Button {
                    Haptics.light()
                    showNewEntry = true
                } label: {
                    Text(String(localized: "today.journal.newEntry", defaultValue: "New Entry"))
                        .font(.system(size: 13, weight: .medium))
                }
                .buttonStyle(PillButtonStyle(filled: false))
            }

            if let entry = store.journalEntry(), entry.hasContent {
                Button { showEntryDetail = true } label: {
                    HStack(spacing: 10) {
                        #if canImport(UIKit)
                        if let image = store.entryPhoto(entry) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        #endif
                        Text(entry.text.isEmpty ? String(localized: "today.journal.photoOnly", defaultValue: "A photograph for today.") : entry.text)
                            .font(.system(size: 14))
                            .foregroundStyle(palette.muted)
                            .lineLimit(2)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text(String(localized: "today.journal.empty", defaultValue: "Whenever it feels right, write a few lines or add a photo."))
                    .font(.system(size: 14))
                    .foregroundStyle(palette.muted)
            }
        }
        .padding(18)
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
