//
//  WhiteRabbitsWidget.swift
//  WhiteRabbitsWidget
//
//  This month's lucky charm. Small, magical, no homework.
//

import SwiftUI
import WidgetKit

struct CharmEntry: TimelineEntry {
    let date: Date
    let bunny: Bunny
}

struct CharmProvider: TimelineProvider {
    func placeholder(in context: Context) -> CharmEntry {
        CharmEntry(date: Date(), bunny: BunnyData.bunny(forMonth: Calendar.current.component(.month, from: Date())))
    }

    func getSnapshot(in context: Context, completion: @escaping (CharmEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CharmEntry>) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        let bunny = BunnyData.bunny(forMonth: calendar.component(.month, from: now))
        let entry = CharmEntry(date: now, bunny: bunny)
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? now.addingTimeInterval(86_400)
        completion(Timeline(entries: [entry], policy: .after(nextMonth)))
    }
}

struct CharmWidgetView: View {
    var entry: CharmEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    private var palette: Palette { Palette.current(for: colorScheme) }
    private var bunny: Bunny { entry.bunny }
    private var charmSize: CGFloat { family == .systemSmall ? 92 : 128 }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: bunny.accentHex).opacity(0.22))
                .frame(width: charmSize + 36, height: charmSize + 36)
                .blur(radius: 16)

            ZStack {
                Circle()
                    .fill(Color(hex: bunny.fillHex).opacity(0.45))
                Circle()
                    .strokeBorder(Color(hex: bunny.strokeHex).opacity(0.4), lineWidth: 1.2)
                BunnyMarkView(bunny: bunny, style: .charm)
                    .padding(charmSize * 0.14)
            }
            .frame(width: charmSize, height: charmSize)
            .shadow(color: Color(hex: bunny.accentHex).opacity(0.55), radius: family == .systemSmall ? 14 : 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.palette, palette)
        .containerBackground(for: .widget) {
            palette.bg
        }
    }
}

struct WhiteRabbitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WhiteRabbitsCharm", provider: CharmProvider()) { entry in
            CharmWidgetView(entry: entry)
        }
        .configurationDisplayName("Lucky bunny")
        .description("This month's charm. A little luck, on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WhiteRabbitsWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhiteRabbitsWidget()
    }
}
