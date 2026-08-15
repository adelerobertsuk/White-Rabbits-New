//
//  ShareCardView.swift
//  WhiteRabbits
//
//  Turns an intention or a journal page into a real story card: a tall
//  9:16 image with a warm-to-dark gradient, a thin gold frame, the
//  month's charm badge straddling the photo, and a fixed ritual footer.
//  Rendered off-screen with ImageRenderer, so the iOS share sheet offers
//  a real "Save Image" option (and Messages/Instagram get a photo to
//  work with) instead of a bare line of text.
//
//  Always drawn in the light palette, regardless of the phone's current
//  mode, so a card saved tonight looks the same as one saved next month.
//

import SwiftUI

struct ShareCardView: View {
    /// e.g. "August 2026".
    let monthYear: String
    /// The main line: an intention, or a journal entry's text.
    let headline: String
    /// A quiet second line under the headline, e.g. the day's
    /// inspiration line. Left out entirely when `nil`.
    let subtitle: String?
    let photo: PlatformImage?
    let bunny: Bunny

    static let size = CGSize(width: 360, height: 640)

    private let palette = Palette.light
    private let gold = Color(hex: "C4A36A")

    private var background: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color(hex: "F6F1EB"), location: 0),
                .init(color: Color(hex: "C7BEAF"), location: 0.22),
                .init(color: Color(hex: "84795A"), location: 0.5),
                .init(color: Color(hex: "49402F"), location: 0.78),
                .init(color: Color(hex: "221C13"), location: 1),
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        ZStack {
            background

            VStack(alignment: .leading, spacing: 0) {
                Text("WHITE RABBITS")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(3.4)
                    .foregroundStyle(gold)
                    .padding(.top, 34)

                Text(monthYear.uppercased())
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(gold.opacity(0.72))
                    .padding(.top, 4)

                ZStack(alignment: .bottom) {
                    photoBlock
                        .frame(height: 196)
                        .frame(maxWidth: .infinity)

                    badge
                        .offset(y: 39)
                }
                .padding(.top, 18)
                .padding(.bottom, 39)

                Text(headline)
                    .font(.system(size: 25, weight: .bold))
                    .tracking(-0.3)
                    .lineSpacing(2)
                    .foregroundStyle(palette.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)
                    .padding(.top, 22)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color(hex: "D8CFB8").opacity(0.85))
                        .lineLimit(2)
                        .padding(.top, 14)
                }

                Spacer(minLength: 20)

                Text("PAUSE  ·  REFLECT  ·  INTEND  ·  BEGIN")
                    .font(.system(size: 10.5, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(gold.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 30)
            }
            .padding(.horizontal, 28)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(gold.opacity(0.85), lineWidth: 1)
                .padding(16)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
    }

    @ViewBuilder
    private var photoBlock: some View {
        ZStack {
            #if canImport(UIKit)
            if let photo {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
            } else {
                photoFallback
            }
            #else
            photoFallback
            #endif
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var photoFallback: some View {
        ZStack {
            Color(hex: bunny.fillHex)
            BunnyMarkView(bunny: bunny, style: .charm)
                .frame(width: 84, height: 84)
                .opacity(0.6)
        }
    }

    private var badge: some View {
        Circle()
            .fill(Color(hex: "FBF7EF"))
            .frame(width: 78, height: 78)
            .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 4)
            .overlay(
                BunnyMarkView(bunny: bunny, style: .charm)
                    .frame(width: 46, height: 46)
            )
    }
}

#if canImport(UIKit)
import UIKit

/// Renders a `ShareCardView` to a real `UIImage`, at 3x scale so it looks
/// crisp saved to Photos or posted anywhere else.
@MainActor
enum ShareCardRenderer {
    static func render(monthYear: String, headline: String, subtitle: String?, photo: PlatformImage?, bunny: Bunny) -> UIImage? {
        let card = ShareCardView(monthYear: monthYear, headline: headline, subtitle: subtitle, photo: photo, bunny: bunny)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}
#endif

#Preview {
    ShareCardView(
        monthYear: "August 2026",
        headline: "Make an app that is good enough for the App Store",
        subtitle: "Golden hour lives in ordinary rooms too.",
        photo: nil,
        bunny: BunnyData.bunny(forMonth: 8)
    )
}
