//
//  WhiteRabbitsWidget.swift
//  WhiteRabbitsWidget
//
//  Small is a charm. Medium is the charm plus today's line.
//

import SwiftUI
import WidgetKit

struct CharmEntry: TimelineEntry {
    let date: Date
    let bunny: Bunny
    let line: String
}

struct CharmProvider: TimelineProvider {
    func placeholder(in context: Context) -> CharmEntry {
        entry(for: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (CharmEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CharmEntry>) -> Void) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let entries = (0..<7).compactMap { offset -> CharmEntry? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return entry(for: date)
        }
        let refresh = calendar.date(byAdding: .day, value: 7, to: start) ?? Date().addingTimeInterval(86_400)
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    private func entry(for date: Date) -> CharmEntry {
        let month = Calendar.current.component(.month, from: date)
        return CharmEntry(
            date: date,
            bunny: BunnyData.bunny(forMonth: month),
            line: giftLine(for: date)
        )
    }

    /// The 1st says the words. Every other day is the quiet line.
    /// Intention stays in the app, so the Home Screen never feels like homework.
    private func giftLine(for date: Date) -> String {
        if Calendar.current.component(.day, from: date) == 1 {
            return String(localized: "greeting.ritual", defaultValue: "White Rabbits, White Rabbits!")
        }
        return Affirmations.line(for: date)
    }
}

struct CharmWidgetView: View {
    var entry: CharmEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    private var palette: Palette { Palette.current(for: colorScheme) }

    var body: some View {
        Group {
            if family == .systemMedium {
                medium
            } else {
                CharmRingView(bunny: entry.bunny)
            }
        }
        .environment(\.palette, palette)
        .containerBackground(for: .widget) {
            ZStack {
                palette.bg
                EllipticalGradient(
                    gradient: Gradient(colors: [palette.accentGlow, Color.clear]),
                    center: family == .systemMedium ? .leading : .center,
                    startRadiusFraction: 0,
                    endRadiusFraction: family == .systemMedium ? 0.9 : 0.72
                )
            }
        }
    }

    private var medium: some View {
        HStack(spacing: 18) {
            CharmRingView(bunny: entry.bunny)
                .frame(width: 132, height: 132)

            Text(entry.line)
                .font(.system(size: 17, weight: .light))
                .tracking(-0.425)
                .lineSpacing(5)
                .foregroundStyle(palette.ink)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.leading, 6)
        .padding(.trailing, 16)
    }
}

private struct CharmRingView: View {
    let bunny: Bunny
    @Environment(\.palette) private var palette

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

                BunnyMarkView(bunny: bunny, style: .asset)
                    .padding(50 * scale)
            }
            .frame(width: side, height: side)
            .shadow(color: palette.accentGlow, radius: 16 * scale, y: 12 * scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct WhiteRabbitsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WhiteRabbitsCharm", provider: CharmProvider()) { entry in
            CharmWidgetView(entry: entry)
        }
        .configurationDisplayName("Lucky bunny")
        .description("A little luck on your Home Screen. The larger size keeps today's line beside the bunny.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct WhiteRabbitsWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhiteRabbitsWidget()
    }
}
