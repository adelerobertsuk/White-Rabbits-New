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
        ZStack {
            // Outer card background & border
            palette.bg
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(gold.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    Text("WHITE RABBITS")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2.5)
                        .foregroundColor(gold)
                    Text(monthYear.uppercased())
                        .font(.system(size: 10, weight: .regular))
                        .tracking(2)
                        .foregroundColor(gold.opacity(0.8))
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)
                .padding(.bottom, 16)

                // Photo container with embedded floating badge layout
                ZStack(alignment: .bottom) {
                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 304, height: 210)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Rectangle()
                            .fill(gold.opacity(0.1))
                            .frame(width: 304, height: 210)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    // Floating circular badge overlapping bottom edge of photo
                    ZStack {
                        Circle()
                            .fill(palette.card)
                            .frame(width: 64, height: 64)
                            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                        
                        // Bunny graphic
                        BunnyMarkView(bunny: bunny, style: .mark)
                            .frame(width: 32, height: 32)
                    }
                    .overlay(
                        Circle()
                            .stroke(gold.opacity(0.3), lineWidth: 1)
                    )
                    .offset(y: 32)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24) // Room for the badge offset

                // Text Content
                VStack(alignment: .leading, spacing: 8) {
                    Text("THIS MONTH I INTEND")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(.secondary)

                    Text(headline)
                        .font(.system(size: 22, weight: .regular, design: .serif))
                        .foregroundColor(palette.ink)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(palette.muted)
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal, 28)

                Spacer(minLength: 0)

                // Footer Navigation Tabs
                HStack {
                    Text("PAUSE")
                    Spacer()
                    Text("REFLECT")
                    Spacer()
                    Text("INTEND")
                    Spacer()
                    Text("BEGIN")
                }
                .font(.system(size: 9, weight: .semibold))
                .tracking(2)
                .foregroundColor(gold)
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
            }
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
