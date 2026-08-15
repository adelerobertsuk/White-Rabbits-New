//
//  JournalView.swift
//  WhiteRabbits
//
//  Tab 2: the archive. A calendar that always matches what's actually
//  saved, and a list underneath that a tapped day filters instantly.
//

import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.palette) private var palette

    @State private var displayedMonth = Date()
    @State private var selectedDate: Date?
    @State private var showNewEntry = false
    @State private var selectedEntry: JournalEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    CalendarStripView(
                        displayedMonth: $displayedMonth,
                        selectedDate: $selectedDate,
                        hasEntry: { store.hasEntry(on: $0) }
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
                        Text(String(localized: "journal.empty", defaultValue: "This month will gather here, one page at a time."))
                            .font(.system(size: 14))
                            .foregroundStyle(palette.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filteredEntries) { entry in
                                entryRow(entry)
                            }
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
            .sanctuaryBackground()
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "tab.journal", defaultValue: "Journal"))
                        .font(.system(size: 13, weight: .semibold))
                        .textCase(.uppercase)
                        .tracking(1)
                        .foregroundStyle(palette.muted)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Haptics.light()
                        showNewEntry = true
                    } label: {
                        Text(String(localized: "today.journal.newEntry", defaultValue: "New Entry"))
                            .font(.system(size: 14, weight: .medium))
                    }
                }
            }
        }
        .sheet(isPresented: $showNewEntry) {
            NewEntrySheet(date: selectedDate ?? Date())
        }
        .sheet(item: $selectedEntry) { entry in
            JournalEntryDetailView(entry: entry)
        }
    }

    private func entryRow(_ entry: JournalEntry) -> some View {
        Button { selectedEntry = entry } label: {
            HStack(spacing: 12) {
                #if canImport(UIKit)
                if let image = store.entryPhoto(entry) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(palette.accentGlow))
                        .foregroundStyle(palette.ink)
                }
            }
            .padding(12)
            .cardBackground(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }

    private var filteredEntries: [JournalEntry] {
        let entries = store.entries(inMonthContaining: displayedMonth)
        guard let selectedDate else { return entries }
        let key = store.dayKey(selectedDate)
        return entries.filter { $0.id == key }
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
