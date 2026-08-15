//
//  JournalView.swift
//  WhiteRabbits
//
//  Tab 2: the archive, laid out exactly like the reference build. The
//  "Write / Photo / Voice" invite for today sits on top, then this
//  month's calendar (always the current month, no paging), then every
//  page written so far.
//

import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    @State private var selectedDate: Date?
    @State private var selectedEntry: JournalEntry?
    private let currentMonth = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    JournalInviteCardView(date: selectedDate ?? Date())

                    Text(monthTitle)
                        .sectionHeaderStyle()
                        .padding(.top, 12)

                    CalendarStripView(
                        displayedMonth: .constant(currentMonth),
                        selectedDate: $selectedDate,
                        hasEntry: { store.hasEntry(on: $0) },
                        allowsNavigation: false
                    )

                    if selectedDate != nil {
                        HStack {
                            Text(filterLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(palette.muted)
                            Spacer()
                            Button(String(localized: "journal.showAll", defaultValue: "Show all")) {
                                Haptics.light()
                                selectedDate = nil
                            }
                            .font(.system(size: 13, weight: .medium))
                        }
                    }

                    if filteredEntries.isEmpty {
                        emptyState
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(filteredEntries.enumerated()), id: \.element.id) { index, entry in
                                entryRow(entry)
                                if index < filteredEntries.count - 1 {
                                    Rectangle()
                                        .fill(palette.line)
                                        .frame(height: 1)
                                }
                            }
                        }
                    }
                }
                .padding(Layout.screenInset)
                .padding(.bottom, 100)
            }
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(store.todayKicker(String(localized: "tab.journal", defaultValue: "Journal")))
                        .kickerStyle()
                }
            }
            .settingsButton()
        }
        .sheet(item: $selectedEntry) { entry in
            JournalEntryDetailView(entry: entry)
        }
    }

    private func entryRow(_ entry: JournalEntry) -> some View {
        Button {
            selectedEntry = entry
        } label: {
            HStack(spacing: 12) {
                #if canImport(UIKit)
                if let image = store.entryPhoto(entry) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: Layout.mediaRadiusSmall, style: .continuous))
                }
                #endif
                VStack(alignment: .leading, spacing: 3) {
                    Text(dayLabel(for: entry.date))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.muted)
                    Text(entry.text.isEmpty ? String(localized: "journal.detail.photoOnly", defaultValue: "A photograph for this day.") : entry.text)
                        .font(.system(size: 15))
                        .foregroundStyle(palette.ink)
                        .lineLimit(2)
                }
                Spacer()
                if !entry.mood.isEmpty {
                    Text(entry.mood)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(palette.accentGlow))
                        .foregroundStyle(palette.ink)
                }
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "book.closed")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(palette.faint)
            Text(String(localized: "journal.empty", defaultValue: "This month will gather here, one page at a time."))
                .font(.system(size: 14))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var filteredEntries: [JournalEntry] {
        let entries = store.entries(inMonthContaining: currentMonth)
        guard let selectedDate else { return entries }
        let key = store.dayKey(selectedDate)
        return entries.filter { $0.id == key }
    }

    private var monthTitle: String {
        store.monthName(currentMonth)
    }

    private var filterLabel: String {
        guard let selectedDate else { return "" }
        return dayLabel(for: selectedDate)
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEdMMMM")
        return formatter.string(from: date)
    }
}

#Preview {
    JournalView()
        .environmentObject(AppStore())
        .environment(\.palette, .light)
}
