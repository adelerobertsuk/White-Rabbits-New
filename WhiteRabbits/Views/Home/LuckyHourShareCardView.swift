//
//  LuckyHourShareCardView.swift
//  WhiteRabbits
//
//  A small wink. The app bunny and the sparkles. A little nod to pass on.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum LuckyMinuteCopy {
    static let sparkle = "✨11:11✨"
    static let notificationTitle = "11:11"

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
    private let palette = Palette.light
    private let bunny = BunnyData.bunny(forMonth: 1)

    static let cardSize = CGSize(width: 240, height: 280)

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            BunnyMarkView(bunny: bunny, style: .mark)
                .frame(width: 56, height: 56)
                .environment(\.palette, palette)

            Text(LuckyMinuteCopy.sparkle)
                .font(.system(size: 28, weight: .light))
                .tracking(-0.6)
                .foregroundStyle(palette.ink)
                .padding(.top, 18)

            Text(LuckyMinuteCopy.whisper())
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Spacer(minLength: 0)
        }
        .frame(width: Self.cardSize.width, height: Self.cardSize.height)
        .background(palette.bg)
        .environment(\.colorScheme, .light)
        .environment(\.palette, palette)
    }
}

/// One tap. The postcard only. No extra words in the message box.
struct LuckyHourShareLink<Label: View>: View {
    @ViewBuilder var label: () -> Label

    @State private var image: PlatformImage?
    @State private var fileURL: URL?

    var body: some View {
        Group {
            if let fileURL, let image {
                ShareLink(
                    item: fileURL,
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
                    prepare()
                } label: {
                    label()
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear { prepare() }
    }

    private func prepare() {
        guard image == nil else { return }
        #if canImport(UIKit)
        let size = LuckyHourShareCardView.cardSize
        let renderer = ImageRenderer(content: LuckyHourShareCardView())
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height)
        renderer.isOpaque = true
        guard let rendered = renderer.uiImage, let data = rendered.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("white-rabbits-1111.png")
        do {
            try data.write(to: url, options: .atomic)
            image = rendered
            fileURL = url
        } catch {
            return
        }
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

#Preview {
    LuckyHourShareCardView()
}
