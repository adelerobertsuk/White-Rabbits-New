//
//  LuckyHourShareCardView.swift
//  WhiteRabbits
//
//  A little postcard of 11:11. The bunny, the numbers, the name.
//  People send it on. That is how luck travels.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct LuckyHourShareCardView: View {
    let bunny: Bunny
    private let palette = Palette.light

    var body: some View {
        ZStack {
            palette.bg
            EllipticalGradient(
                gradient: Gradient(colors: [palette.accentGlow, Color.clear]),
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.52
            )
            .frame(width: 432, height: 252)
            .offset(y: -96)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .stroke(palette.track, lineWidth: 2.4)
                        .padding(8)

                    Circle()
                        .fill(palette.card)
                        .padding(20)
                        .shadow(color: palette.ink.opacity(0.08), radius: 16, y: 12)

                    BunnyMarkView(bunny: bunny, style: .asset)
                        .padding(40)
                }
                .frame(width: 188, height: 188)
                .shadow(color: palette.accentGlow, radius: 14, y: 16)
                .environment(\.palette, palette)

                Text("11:11")
                    .font(.system(size: 52, weight: .light))
                    .tracking(-1.6)
                    .foregroundStyle(palette.ink)
                    .padding(.top, 28)

                Text("White Rabbits")
                    .font(.system(size: 20, weight: .light))
                    .tracking(-0.7)
                    .foregroundStyle(palette.ink)
                    .padding(.top, 8)

                Text(String(localized: "luckyHour.share.wish", defaultValue: "Make a wish."))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(palette.muted)
                    .padding(.top, 16)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 36)
        }
        .frame(width: 360, height: 480)
        .environment(\.colorScheme, .light)
        .environment(\.palette, palette)
    }
}

/// One tap opens the system share sheet with the postcard and a quiet line of copy.
struct LuckyHourShareLink<Label: View>: View {
    let bunny: Bunny
    @ViewBuilder var label: () -> Label

    @State private var image: PlatformImage?
    @State private var fileURL: URL?

    private var message: String {
        String(localized: "luckyHour.share.message", defaultValue: "11:11. Make a wish. White Rabbits.")
    }

    var body: some View {
        Group {
            if let fileURL, let image {
                ShareLink(
                    item: fileURL,
                    subject: Text("11:11"),
                    message: Text(message),
                    preview: SharePreview(
                        String(localized: "luckyHour.share.preview", defaultValue: "White Rabbits"),
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
        let renderer = ImageRenderer(content: LuckyHourShareCardView(bunny: bunny))
        renderer.scale = 3
        renderer.proposedSize = ProposedViewSize(width: 360, height: 480)
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
    LuckyHourShareCardView(bunny: BunnyData.bunny(forMonth: 8))
}
