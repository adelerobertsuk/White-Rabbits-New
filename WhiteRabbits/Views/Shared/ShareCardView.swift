//
//  ShareCardView.swift
//  WhiteRabbits
//
//  Turns an intention or a journal page into an actual picture, rendered
//  off-screen with ImageRenderer, so the iOS share sheet offers a real
//  "Save Image" option (and Messages/Instagram get a photo to work with)
//  instead of a bare line of text.
//
//  Always drawn in the light palette, regardless of the phone's current
//  mode, so a card saved tonight looks the same as one saved next month.
//

import SwiftUI

struct ShareCardView: View {
    let kicker: String
    let bodyText: String
    let photo: PlatformImage?
    let bunny: Bunny
    let footer: String

    static let size = CGSize(width: 360, height: 450)

    private let palette = Palette.light

    var body: some View {
        ZStack {
            palette.bg

            EllipticalGradient(
                gradient: Gradient(colors: [palette.accentGlow, palette.accentGlow.opacity(0)]),
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.55
            )
            .frame(width: Self.size.width * 1.2, height: Self.size.height * 0.7)
            .position(x: Self.size.width / 2, y: -20)

            VStack(spacing: 0) {
                Spacer(minLength: 30)

                BunnyMarkView(bunny: bunny, style: .charm)
                    .frame(width: 46, height: 46)
                    .padding(.bottom, 14)

                Text(kicker.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(palette.muted)
                    .padding(.bottom, 14)

                if let photo {
                    #if canImport(UIKit)
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.bottom, 18)
                    #endif
                }

                Text(bodyText)
                    .font(.system(size: 19, weight: .light))
                    .tracking(-0.2)
                    .foregroundStyle(palette.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .lineLimit(6)
                    .padding(.horizontal, 34)

                Spacer(minLength: 20)

                Text(footer)
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(palette.faint)
                    .padding(.bottom, 26)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }
}

#if canImport(UIKit)
import UIKit

/// Renders a `ShareCardView` to a real `UIImage`, at 3x scale so it looks
/// crisp saved to Photos or posted anywhere else.
@MainActor
enum ShareCardRenderer {
    static func render(kicker: String, bodyText: String, photo: PlatformImage?, bunny: Bunny, footer: String) -> UIImage? {
        let card = ShareCardView(kicker: kicker, bodyText: bodyText, photo: photo, bunny: bunny, footer: footer)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
#endif

#Preview {
    ShareCardView(
        kicker: "August intention",
        bodyText: "Golden hour, gathered.",
        photo: nil,
        bunny: BunnyData.bunny(forMonth: 8),
        footer: "White Rabbits"
    )
}
