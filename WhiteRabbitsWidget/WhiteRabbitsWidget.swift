//
//  WhiteRabbitsWidget.swift
//  WhiteRabbitsWidget
//
//  The same paper and ink bunny as Home. A little luck, no homework.
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

    private var palette: Palette { Palette.current(for: colorScheme) }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let scale = side / 248

            ZStack {
                Circle()
                    .stroke(palette.track, lineWidth: max(2.2, 3.2 * scale))
                    .padding(10 * scale)

                Circle()
                    .fill(palette.card)
                    .padding(26 * scale)
                    .shadow(color: palette.ink.opacity(0.08), radius: 12 * scale, y: 10 * scale)

                BunnyMarkView(bunny: entry.bunny, style: .asset)
                    .padding(50 * scale)
            }
            .frame(width: side, height: side)
            .shadow(color: palette.accentGlow, radius: 16 * scale, y: 12 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .environment(\.palette, palette)
        .containerBackground(for: .widget) {
            ZStack {
                palette.bg
                EllipticalGradient(
                    gradient: Gradient(colors: [palette.accentGlow, Color.clear]),
                    center: .center,
                    startRadiusFraction: 0,
                    endRadiusFraction: 0.72
                )
            }
        }
    }
}

struct WhiteRabbitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WhiteRabbitsCharm", provider: CharmProvider()) { entry in
            CharmWidgetView(entry: entry)
        }
        .configurationDisplayName("Lucky bunny")
        .description("A little luck, on your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WhiteRabbitsWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhiteRabbitsWidget()
    }
}
