//
//  TabIcons.swift
//  WhiteRabbits
//
//  The four tab bar glyphs, transcribed line for line from the web
//  app's own line-art icons (a target ring, a notebook, a four-lobed
//  charm, and two overlapping circles), not generic system symbols.
//
//  Tab bar icons must be plain Images, so each shape is rendered once
//  into a small template image (so iOS still tints it automatically
//  for the selected/unselected state) and cached for reuse.
//

import SwiftUI

enum TabIconKind {
    case today, journal, charms, circle
}

private struct TabIconShape: Shape {
    let kind: TabIconKind

    func path(in rect: CGRect) -> Path {
        let scale = rect.width / 18
        let transform = CGAffineTransform(translationX: rect.minX, y: rect.minY).scaledBy(x: scale, y: scale)

        switch kind {
        case .today:
            var path = Path()
            path.addPath(svgCircle(9, 9, 6.2).applying(transform))
            path.addPath(svgCircle(9, 9, 2.4).applying(transform))
            return path
        case .journal:
            var path = Path()
            path.addPath(
                Path(roundedRect: CGRect(x: 3.5, y: 2.5, width: 11, height: 13), cornerRadius: 1.6)
                    .applying(transform)
            )
            path.addPath(svgPath("M6.5 6h5M6.5 9h5M6.5 12h3").applying(transform))
            return path
        case .charms:
            return svgPath("M6 14c-2-4-1.2-8 1.4-9.5C6 2 8.2 1 9.4 4.2 11.2 1.6 14 3 12.2 6.2 15 7.4 15 11 12 14c-1.2 1.2-3.4 1.4-6 0z")
                .applying(transform)
        case .circle:
            var path = Path()
            path.addPath(svgCircle(7.2, 9, 4.1).applying(transform))
            path.addPath(svgCircle(10.8, 9, 4.1).applying(transform))
            return path
        }
    }
}

@MainActor
enum TabIcons {
    static let today = render(.today)
    static let journal = render(.journal)
    static let charms = render(.charms)
    static let circle = render(.circle)

    private static func render(_ kind: TabIconKind) -> Image {
        let view = TabIconShape(kind: kind)
            .stroke(Color.black, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
            .frame(width: 24, height: 24)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 3
        #if canImport(UIKit)
        if let uiImage = renderer.uiImage {
            // `.renderingMode(.template)` here is the SwiftUI-level flag that
            // actually gets the tab bar to tint this like a system glyph
            // (soft grey unselected, accent when selected). Without it the
            // baked-in black stroke shows through at full strength always,
            // which is what was making these look too dark.
            return Image(uiImage: uiImage.withRenderingMode(.alwaysTemplate))
                .renderingMode(.template)
        }
        #endif
        return Image(systemName: "circle")
    }
}
