//
//  BunnyMarkView.swift
//  WhiteRabbits
//
//  The seated-bunny illustration, drawn as real vector paths (not a
//  photo or a system icon), transcribed line for line from the original
//  web app's artwork, so it stays crisp at any size and themes correctly
//  for light and dark mode.
//
//  It has two looks, exactly like the web app:
//  - .mark: the plain brand silhouette (dark outline, no fill, no
//    seasonal decoration). Used for the logo and the Today ring.
//  - .charm: the collectible version, filled and stroked in that
//    month's own colors, with its seasonal prop (a scarf, a snowflake,
//    a sprig of blossom). Used for the Charms grid and Year of Luck.
//

import SwiftUI

private struct BunnyDraw {
    var path: Path
    var fill: Color?
    var stroke: Color?
    var lineWidth: CGFloat = 1.6
    var opacity: Double = 1
}

struct BunnyMarkView: View {
    enum Style {
        case mark
        case charm
    }

    let bunny: Bunny
    var unlocked: Bool = true
    var showGlow: Bool = false
    var style: Style = .charm

    @Environment(\.palette) private var palette

    private var fillColor: Color {
        guard style == .charm else { return .clear }
        return unlocked ? Color(hex: bunny.fillHex) : Color.clear
    }
    private var strokeColor: Color {
        guard style == .charm else { return palette.ink }
        return unlocked ? Color(hex: bunny.strokeHex) : palette.faint
    }
    private var accentColor: Color { unlocked ? Color(hex: bunny.accentHex) : palette.faint }

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 80
            let dx = (size.width - 80 * scale) / 2
            let dy = (size.height - 80 * scale) / 2
            let transform = CGAffineTransform(translationX: dx, y: dy).scaledBy(x: scale, y: scale)

            if showGlow, style == .charm {
                let glowColor = unlocked ? Color(hex: bunny.accentHex) : Color.clear
                context.fill(
                    svgCircle(40, 42, 36).applying(transform),
                    with: .color(glowColor.opacity(unlocked ? 0.3 : 0))
                )
            }

            for op in bodyOps() + (style == .charm ? propOps() : []) {
                let scaled = op.path.applying(transform)
                if let fill = op.fill {
                    context.fill(scaled, with: .color(fill.opacity(op.opacity)))
                }
                if let stroke = op.stroke {
                    context.stroke(
                        scaled,
                        with: .color(stroke.opacity(op.opacity)),
                        style: StrokeStyle(lineWidth: op.lineWidth * scale, lineCap: .round, lineJoin: .round)
                    )
                }
            }
        }
    }

    // MARK: - The master seated-bunny shape (same for every month)

    private func bodyOps() -> [BunnyDraw] {
        [
            BunnyDraw(path: svgEllipse(42, 58, 17, 14.5), fill: fillColor, stroke: strokeColor, lineWidth: 1.6),
            BunnyDraw(path: svgPath("M29 34C27.2 12 33.5 5.5 37.2 24.5"), fill: fillColor, stroke: strokeColor, lineWidth: 1.6),
            BunnyDraw(path: svgPath("M41 31C47.5 11 55 14.5 45.5 33"), fill: fillColor, stroke: strokeColor, lineWidth: 1.6),
            BunnyDraw(path: svgEllipse(37.5, 39, 12.2, 11), fill: fillColor, stroke: strokeColor, lineWidth: 1.6),
            BunnyDraw(path: svgCircle(58.5, 59, 4.6), fill: fillColor, stroke: strokeColor, lineWidth: 1.5),
            BunnyDraw(path: svgCircle(33.2, 38.2, 1.35), fill: strokeColor, stroke: nil),
            BunnyDraw(path: svgPath("M28.5 41.5c2.2 2.4 5.4 2.6 7.8.4"), fill: nil, stroke: strokeColor, lineWidth: 1.15),
        ]
    }

    private func scarfOps(_ a: Color) -> [BunnyDraw] {
        [
            BunnyDraw(path: svgPath("M26 47c7 5.5 18 6.2 26 1.2"), fill: nil, stroke: a, lineWidth: 2.5),
            BunnyDraw(path: svgPath("M47 49c1.4 7.5 0.2 13-3.2 17"), fill: nil, stroke: a, lineWidth: 2.3),
            BunnyDraw(path: svgPath("M41.5 65.5h9.5"), fill: nil, stroke: a, lineWidth: 1.3),
        ]
    }

    // MARK: - One seasonal prop per month, transcribed from the web app

    private func propOps() -> [BunnyDraw] {
        let a = accentColor
        let s = strokeColor
        switch bunny.id {
        case "frost":
            return scarfOps(a) + [
                BunnyDraw(path: svgPath("M16 16l.2 6M13.2 19h6"), fill: nil, stroke: a, lineWidth: 1.15),
                BunnyDraw(path: svgPath("M64 14l.15 5.5M61.2 16.7h5.6"), fill: nil, stroke: a, lineWidth: 1.15),
            ]
        case "darling":
            return [
                BunnyDraw(path: svgPath("M30 22c0-1.7 1.3-2.8 2.6-2.8.9 0 1.7.5 2.1 1.3.4-.8 1.2-1.3 2.1-1.3 1.3 0 2.6 1.1 2.6 2.8 0 3-4.7 5.4-4.7 5.4S30 25 30 22z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M62 20c0-2.2 1.6-3.6 3.2-3.6 1.2 0 2.2.6 2.6 1.6.4-1 1.4-1.6 2.6-1.6 1.6 0 3.2 1.4 3.2 3.6 0 3.8-5.8 6.8-5.8 6.8S62 23.8 62 20z"), fill: a, stroke: nil),
            ]
        case "equinox":
            return [
                BunnyDraw(path: svgPath("M28 20c-1.2-4.5 1.4-8 2.2-8 .8 0 3.4 3.5 2.2 8"), fill: a, stroke: nil, opacity: 0.9),
                BunnyDraw(path: svgPath("M40 16c-1-4.2 1.6-7.6 2.4-7.6s3.4 3.4 2.2 7.6"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M50 21c-1-3.6 1.2-6.4 2-6.4s2.8 2.8 1.8 6.4"), fill: a, stroke: nil, opacity: 0.85),
            ]
        case "shower":
            return [
                BunnyDraw(path: svgPath("M18 18c0 2.4-1.7 3.6-1.7 5.4A1.7 1.7 0 0018 25.1a1.7 1.7 0 001.7-1.7C19.7 21.6 18 20.4 18 18z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M26 14c0 2-1.4 3-1.4 4.6A1.4 1.4 0 0026 20a1.4 1.4 0 001.4-1.4C27.4 17 26 16 26 14z"), fill: a, stroke: nil, opacity: 0.7),
                BunnyDraw(path: svgPath("M66 18c0 2.3-1.6 3.5-1.6 5.2A1.6 1.6 0 0066 24.8a1.6 1.6 0 001.6-1.6C67.6 21.5 66 20.3 66 18z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M58 16c4 0 7 2 8 5H50c1-3 4-5 8-5z"), fill: a, stroke: nil, opacity: 0.8),
            ]
        case "blossom":
            return [
                BunnyDraw(path: svgCircle(28, 18, 3), fill: a, stroke: nil),
                BunnyDraw(path: svgCircle(35, 14, 3.2), fill: a, stroke: nil),
                BunnyDraw(path: svgCircle(43, 13.5, 3), fill: a, stroke: nil),
                BunnyDraw(path: svgCircle(50, 17, 2.8), fill: a, stroke: nil),
                BunnyDraw(path: svgCircle(32, 22, 2.4), fill: a, stroke: nil, opacity: 0.75),
                BunnyDraw(path: svgCircle(46, 21, 2.3), fill: a, stroke: nil, opacity: 0.75),
            ]
        case "solstice":
            // Snowflake-style sparkle, translated by (40, 12) to match the original group transform.
            return [
                BunnyDraw(path: svgCircle(40, 12, 4), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M40 3.8v2.2M40 18v2.2M31.8 12h2.2M46 12h2.2M34.2 6.2l1.6 1.6M44.2 16.2l1.6 1.6M34.2 17.8l1.6-1.6M44.2 7.8l1.6-1.6"), fill: nil, stroke: a, lineWidth: 1.15),
            ]
        case "heat":
            return [
                BunnyDraw(path: svgCircle(40, 16, 5), fill: a, stroke: nil, opacity: 0.9),
                BunnyDraw(path: svgPath("M16 48c4-8 4-14 0-20"), fill: nil, stroke: a, lineWidth: 1.3),
                BunnyDraw(path: svgPath("M22 50c3.4-6.5 3.4-12 0-17"), fill: nil, stroke: a, lineWidth: 1.15, opacity: 0.7),
            ]
        case "harvest":
            return [
                BunnyDraw(path: svgPath("M22 24c4-6 10-8 14-6-2 5-8 8-14 6z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M50 18c5-5 12-5 16-1-4 4-11 6-16 1z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M14 62c8-18 6-28 2-38"), fill: nil, stroke: a, lineWidth: 1.3),
                BunnyDraw(path: svgPath("M16 36c-4-1-6 2-4 5M16 42c-4-1-6 2-4 5M16 48c-4-1-6 2-4 5"), fill: nil, stroke: a, lineWidth: 1.15),
            ]
        case "goldleaf":
            return [
                BunnyDraw(path: svgPath("M26 18c-5 3.5-6.5 9-4.5 13 7-1.5 10.5-7 8.5-12.2-1.6 1.2-3.2 1.4-4 1.4s.6-1.8 0-2.2z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M50 14c-5.5 4-7 10-4.8 14.5 8-2 12-8 10-14-2 1.3-3.8 1.5-4.2 1.5s.8-2 1-2z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M66 22a7.2 7.2 0 107.4 8.6 5.8 5.8 0 01-7.4-8.6z"), fill: a, stroke: nil, opacity: 0.9),
            ]
        case "shadow":
            return [
                BunnyDraw(path: svgPath("M32 7.5l8.2 16.5H23.8z"), fill: s, stroke: nil, opacity: 0.92),
                BunnyDraw(path: svgPath("M23.8 24h16.4v2.2H23.8z"), fill: s, stroke: nil),
                BunnyDraw(path: svgPath("M24 46c-2 8 0 16 4 20"), fill: nil, stroke: s, lineWidth: 1.6, opacity: 0.7),
                BunnyDraw(path: svgEllipse(68, 22, 5.2, 4.2), fill: a, stroke: nil, opacity: 0.9),
                BunnyDraw(path: svgPath("M68 26.2v3.4"), fill: nil, stroke: a, lineWidth: 1.2),
            ]
        case "ember":
            return scarfOps(a) + [
                BunnyDraw(path: svgPath("M64 16c-5.5 3.5-7 9-5 14.2 7.2-1.8 11-7.2 9-13-1.8 1.2-3.4 1.4-4 1.4s.7-2 0-2.6z"), fill: a, stroke: nil),
            ]
        case "starlight":
            return scarfOps(a) + [
                BunnyDraw(path: svgPath("M40 8.5l1.15 3.5h3.7l-3 2.2 1.15 3.5L40 15.6l-3 2.1 1.15-3.5-3-2.2h3.7z"), fill: a, stroke: nil),
                BunnyDraw(path: svgPath("M18 20l.7 2.1h2.2l-1.8 1.35.7 2.15L18 24.4l-1.8 1.3.7-2.15-1.8-1.35h2.2z"), fill: a, stroke: nil, opacity: 0.8),
            ]
        default:
            return []
        }
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
        ForEach(BunnyData.all) { bunny in
            BunnyMarkView(bunny: bunny, unlocked: true, showGlow: true)
                .frame(width: 70, height: 70)
        }
    }
    .padding()
    .environment(\.palette, .light)
}
