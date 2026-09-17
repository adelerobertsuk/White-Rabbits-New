//
//  LuckyHourShareCardView.swift
//  WhiteRabbits
//
//  A small wink. The app bunny and the sparkles. A little nod to pass on.
//

import SwiftUI
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#endif

enum LuckyMinuteCopy {
    static let notificationTitle = "Your lucky minute"

    static func sparkle(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "✨\(formatter.string(from: date))✨"
    }

    static func whisper(for date: Date = Date()) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let lines = [
            String(localized: "luckyHour.whisper.1", defaultValue: "A little nod."),
            String(localized: "luckyHour.whisper.2", defaultValue: "A little wink."),
            String(localized: "luckyHour.whisper.3", defaultValue: "Luck likes you today."),
            String(localized: "luckyHour.whisper.4", defaultValue: "Luck is on your side."),
            String(localized: "luckyHour.whisper.5", defaultValue: "A quiet kind of luck."),
            String(localized: "luckyHour.whisper.6", defaultValue: "Something has your back."),
            String(localized: "luckyHour.whisper.7", defaultValue: "The day is still on your side."),
            String(localized: "luckyHour.whisper.8", defaultValue: "Right on time."),
            String(localized: "luckyHour.whisper.9", defaultValue: "A little moment for you."),
            String(localized: "luckyHour.whisper.10", defaultValue: "A tiny bit of luck."),
            String(localized: "luckyHour.whisper.11", defaultValue: "Keep this moment."),
            String(localized: "luckyHour.whisper.12", defaultValue: "Just because.")
        ]
        return lines[(day - 1) % lines.count]
    }
}

struct LuckyHourShareCardView: View {
    let bunny: Bunny
    let giftLine: String
    let luckyMinute: Date
    let colorScheme: ColorScheme

    private var palette: Palette {
        Palette.current(for: colorScheme)
    }

    static let cardSize = CGSize(width: 240, height: 280)

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            BunnyMarkView(bunny: bunny, style: .mark)
                .frame(width: 56, height: 56)
                .environment(\.palette, palette)

            Text(LuckyMinuteCopy.sparkle(for: luckyMinute))
                .font(.system(size: 28, weight: .light))
                .tracking(-0.6)
                .foregroundStyle(palette.ink)
                .padding(.top, 18)

            Text(giftLine)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.85)
                .padding(.horizontal, 16)
                .padding(.top, 18)

            Text("WHITE RABBITS")
                .font(.system(size: 8, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(palette.faint)
                .padding(.top, 14)

            Spacer(minLength: 0)
        }
        .frame(width: Self.cardSize.width, height: Self.cardSize.height)
        .background(palette.bg)
        .environment(\.colorScheme, colorScheme)
        .environment(\.palette, palette)
    }
}

/// Raw postcard bytes with a fresh identity on every render. Sharing a fixed file
/// path let Messages / the share sheet reuse a stale, previously-cached attachment
/// instead of reading today's rendered card, so each postcard gets a unique
/// filename and travels as image data rather than a reused on-disk URL.
private struct LuckyHourPostcard: Transferable {
    let data: Data
    let fileName: String

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { postcard in
            postcard.data
        }
        .suggestedFileName { postcard in postcard.fileName }
    }
}

/// One tap. The postcard only. No extra words in the message box.
struct LuckyHourShareLink<Label: View>: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.colorScheme) private var colorScheme

    @ViewBuilder var label: () -> Label

    @State private var image: PlatformImage?
    @State private var postcard: LuckyHourPostcard?
    @State private var renderKey = ""

    var body: some View {
        Group {
            if let postcard, let image {
                ShareLink(
                    item: postcard,
                    preview: SharePreview(
                        "\u{200B}",
                        image: Image(platformImage: image)
                    )
                ) {
                    label()
                }
            } else {
                Button {
                    Haptics.medium()
                    prepare(force: true)
                } label: {
                    label()
                }
                .buttonStyle(.plain)
            }
        }
        .simultaneousGesture(TapGesture().onEnded { Haptics.soft() })
        .onAppear { prepare(force: false) }
        .onChange(of: colorScheme) { _, _ in prepare(force: true) }
    }

    private func prepare(force: Bool) {
        let key = "\(colorScheme)-\(store.dailyGiftLine())-\(store.currentBunny().id)"
        guard force || image == nil || renderKey != key else { return }
        renderKey = key
        image = nil
        postcard = nil
        #if canImport(UIKit)
        let size = LuckyHourShareCardView.cardSize
        let card = LuckyHourShareCardView(
            bunny: store.currentBunny(),
            giftLine: store.dailyGiftLine(),
            luckyMinute: store.luckyMinuteDate,
            colorScheme: colorScheme
        )
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.isOpaque = true
        guard let rendered = renderer.uiImage, let data = rendered.pngData() else { return }
        image = rendered
        postcard = LuckyHourPostcard(
            data: data,
            fileName: "white-rabbits-lucky-minute-\(UUID().uuidString).png"
        )
        #endif
    }
}

private extension Image {
    init(platformImage: PlatformImage) {
        #if canImport(UIKit)
        self.init(uiImage: platformImage)
        #else
        self.init(nsImage: platformImage)
        #endif
    }
}

#if canImport(UIKit)
private typealias PlatformImage = UIImage
#else
private typealias PlatformImage = NSImage
#endif

#Preview("Light") {
    LuckyHourShareCardView(
        bunny: BunnyData.bunny(forMonth: 8),
        giftLine: Affirmations.line(),
        luckyMinute: Date(),
        colorScheme: .light
    )
}

#Preview("Dark") {
    LuckyHourShareCardView(
        bunny: BunnyData.bunny(forMonth: 8),
        giftLine: Affirmations.line(),
        luckyMinute: Date(),
        colorScheme: .dark
    )
}
