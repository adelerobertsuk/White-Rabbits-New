//
//  WhiteRabbitsWidget.swift
//  WhiteRabbitsWidget
//
//  Home Screen: small is a charm, medium is the charm plus today's line.
//  Lock Screen: a circular bunny, and a rectangular daily line.
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

    private var isLockScreen: Bool {
        family == .accessoryCircular || family == .accessoryRectangular
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                medium
            case .accessoryCircular:
                lockCircular
            case .accessoryRectangular:
                lockRectangular
            default:
                CharmRingView(bunny: entry.bunny)
            }
        }
        .environment(\.palette, isLockScreen ? palette.withInk(.primary) : palette)
        .containerBackground(for: .widget) {
            if isLockScreen {
                AccessoryWidgetBackground()
            } else {
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
    }

    private var lockCircular: some View {
        BunnyMarkView(bunny: entry.bunny, style: .mark)
            .padding(8)
            .widgetAccentable()
    }

    private var lockRectangular: some View {
        HStack(alignment: .center, spacing: 10) {
            BunnyMarkView(bunny: entry.bunny, style: .mark)
                .frame(width: 28, height: 28)
                .widgetAccentable()
            Text(entry.line)
                .font(.system(size: 13, weight: .light))
                .tracking(-0.2)
                .lineSpacing(2)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .description("A little luck on your Home Screen and Lock Screen. The larger Home Screen size keeps today's line beside the bunny.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

@main
struct WhiteRabbitsWidgetBundle: WidgetBundle {
    var body: some Widget {
        WhiteRabbitsWidget()
    }
}
