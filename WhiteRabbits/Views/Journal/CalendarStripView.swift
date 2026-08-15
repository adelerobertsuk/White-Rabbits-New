//
//  CalendarStripView.swift
//  WhiteRabbits
//
//  A simple month calendar. Days with an entry get a small dot, and
//  tapping a day filters the list below to just that date.
//
//  This reads `hasEntry` live from the store every time it draws, so
//  a page saved a second ago shows up immediately. That's the fix for
//  the calendar sync bug.
//

import SwiftUI

struct CalendarStripView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date?
    let hasEntry: (Date) -> Bool

    @Environment(\.palette) private var palette
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Button { changeMonth(by: -1) } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(palette.muted)
                }
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(palette.ink)
                Spacer()
                Button { changeMonth(by: 1) } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(palette.muted)
                }
            }
            .buttonStyle(.plain)

            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(palette.faint)
                        .frame(maxWidth: .infinity)
                }
            }

            let rows = daysGrid()
            VStack(spacing: 8) {
                ForEach(0..<rows.count, id: \.self) { rowIndex in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { columnIndex in
                            let day = rows[rowIndex][columnIndex]
                            if let day {
                                dayCell(day)
                            } else {
                                Spacer().frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .cardBackground()
    }

    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let filled = hasEntry(date)

        return Button {
            Haptics.light()
            if isSelected {
                selectedDate = nil
            } else {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 14, weight: isToday ? .semibold : .regular))
                    .foregroundStyle(isSelected ? palette.bg : palette.ink)
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(isSelected ? palette.ink : (isToday ? palette.accentGlow : Color.clear))
                    )
                Circle()
                    .fill(filled ? palette.accent : Color.clear)
                    .frame(width: 4, height: 4)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMMyyyy")
        return formatter.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday // 1 = Sunday by default in most locales
        return Array(symbols[(firstWeekday - 1)...] + symbols[..<(firstWeekday - 1)])
    }

    private func changeMonth(by delta: Int) {
        guard let newDate = calendar.date(byAdding: .month, value: delta, to: displayedMonth) else { return }
        displayedMonth = newDate
        selectedDate = nil
    }

    /// Six rows of seven days (with nils for padding), calendar-accurate for the current locale.
    private func daysGrid() -> [[Date?]] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }
        let firstOfMonth = monthInterval.start
        let daysInMonth = calendar.range(of: .day, in: .month, for: displayedMonth)?.count ?? 30
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<daysInMonth {
            if let date = calendar.date(byAdding: .day, value: offset, to: firstOfMonth) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }

        var rows: [[Date?]] = []
        var index = 0
        while index < days.count {
            rows.append(Array(days[index..<min(index + 7, days.count)]))
            index += 7
        }
        return rows
    }
}
