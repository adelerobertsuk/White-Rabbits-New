//
//  ShareCardView.swift
//  WhiteRabbits
//
//  Story card laid out on a fixed 360×640 canvas. Positions are taken
//  from the reference image (576×1024, same 9:16), scaled by 0.625, so
//  ImageRenderer cannot reflow the photo over the header or the badge
//  over the words.
//

import SwiftUI

struct ShareCardView: View {
    let monthYear: String
    let headline: String
    let subtitle: String?
    let photo: PlatformImage?
    let bunny: Bunny

    static let size = CGSize(width: 360, height: 640)

    private let palette = Palette.light
    private var gold: Color { palette.accent }

    var body: some View {
        ZStack(alignment: .topLeading) {
            background

            header
                .padding(.leading, 32)
                .padding(.top, 40)

            photoBlock
                .frame(width: 300, height: 198)
                .padding(.leading, 30)
                .padding(.top, 70)

            badge
                .frame(maxWidth: .infinity)
                .padding(.top, 230)

            VStack(spacing: 14) {
                Text(Self.cleaned(headline))
                    .font(.system(size: 22, weight: .regular))
                    .tracking(-0.3)
                    .lineSpacing(1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.ink)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(gold.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 318)
            .frame(maxWidth: .infinity, alignment: .top)

            Text("PAUSE  ·  REFLECT  ·  INTEND  ·  BEGIN")
                .font(.system(size: 9, weight: .medium))
                .tracking(1.5)
                .foregroundStyle(gold)
                .padding(.leading, 32)
                .padding(.top, 598)

            Rectangle()
                .strokeBorder(gold.opacity(0.7), lineWidth: 0.8)
                .padding(18)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipped()
        .compositingGroup()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WHITE RABBITS")
                .font(.system(size: 11, weight: .semibold))
                .tracking(3.8)
                .foregroundStyle(gold)
            Text(monthYear.uppercased())
                .font(.system(size: 10, weight: .medium))
                .tracking(2.6)
                .foregroundStyle(gold.opacity(0.75))
        }
    }

    private var background: some View {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "F6F1EB"), location: 0),
                .init(color: Color(hex: "E3D9CA"), location: 0.16),
                .init(color: Color(hex: "C2B496"), location: 0.38),
                .init(color: Color(hex: "8A7B62"), location: 0.55),
                .init(color: Color(hex: "4A4030"), location: 0.78),
                .init(color: Color(hex: "2B2418"), location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var photoBlock: some View {
        Color.clear
            .overlay {
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
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.55),
                        .init(color: .black.opacity(0.5), location: 0.78),
                        .init(color: .clear, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var photoFallback: some View {
        ZStack {
            Color(hex: bunny.fillHex)
            BunnyMarkView(bunny: bunny, style: .charm)
                .frame(width: 80, height: 80)
                .opacity(0.55)
        }
    }

    private var badge: some View {
        Circle()
            .fill(Color(hex: "F7F1E6"))
            .frame(width: 76, height: 76)
            .overlay(Circle().strokeBorder(gold.opacity(0.4), lineWidth: 0.8))
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
            .overlay {
                BunnyMarkView(bunny: bunny, style: .charm)
                    .padding(16)
            }
    }

    static func cleaned(_ text: String) -> String {
        let filtered = text.unicodeScalars.filter { scalar in
            !scalar.properties.isEmojiPresentation
                && !scalar.properties.isEmojiModifier
                && !scalar.properties.isEmojiModifierBase
        }
        return String(String.UnicodeScalarView(filtered))
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#if canImport(UIKit)
import UIKit

@MainActor
enum ShareCardRenderer {
    static func render(monthYear: String, headline: String, subtitle: String?, photo: PlatformImage?, bunny: Bunny) -> UIImage? {
        let card = ShareCardView(monthYear: monthYear, headline: headline, subtitle: subtitle, photo: photo, bunny: bunny)
        let renderer = ImageRenderer(content: card)
        renderer.proposedSize = ProposedViewSize(width: ShareCardView.size.width, height: ShareCardView.size.height)
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
