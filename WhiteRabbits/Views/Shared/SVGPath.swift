//
//  SVGPath.swift
//  WhiteRabbits
//
//  A small parser that turns an SVG path "d" string into a native
//  SwiftUI Path. This lets the bunny illustrations below be transcribed
//  directly from the original web app's artwork, instead of redrawn
//  by hand, so they stay pixel-faithful to the design.
//
//  Supports the commands our illustrations actually use: move (M/m),
//  line (L/l), horizontal/vertical line (H/h V/v), cubic curve (C/c),
//  smooth cubic curve (S/s), circular arc (A/a), and close (Z/z).
//

import SwiftUI

func svgPath(_ d: String) -> Path {
    var path = Path()
    let scanner = Scanner(string: d)
    scanner.charactersToBeSkipped = CharacterSet(charactersIn: ", \n\t")
    let letters = CharacterSet(charactersIn: "MmLlHhVvCcSsAaZz")

    var current = CGPoint.zero
    var subpathStart = CGPoint.zero
    var lastCubicControl: CGPoint?
    var command: Character = " "
    var started = false

    func number() -> CGFloat? {
        scanner.scanDouble().map { CGFloat($0) }
    }

    while !scanner.isAtEnd {
        if let letterStr = scanner.scanCharacters(from: letters), let letter = letterStr.last {
            command = letter
        }

        switch command {
        case "M", "m":
            guard let x = number(), let y = number() else { return path }
            let p = command == "m" && started ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            path.move(to: p)
            current = p
            subpathStart = p
            lastCubicControl = nil
            started = true
            command = command == "m" ? "l" : "L" // subsequent implicit pairs are lineto

        case "L", "l":
            guard let x = number(), let y = number() else { return path }
            let p = command == "l" ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            path.addLine(to: p)
            current = p
            lastCubicControl = nil

        case "H", "h":
            guard let x = number() else { return path }
            let p = command == "h" ? CGPoint(x: current.x + x, y: current.y) : CGPoint(x: x, y: current.y)
            path.addLine(to: p)
            current = p
            lastCubicControl = nil

        case "V", "v":
            guard let y = number() else { return path }
            let p = command == "v" ? CGPoint(x: current.x, y: current.y + y) : CGPoint(x: current.x, y: y)
            path.addLine(to: p)
            current = p
            lastCubicControl = nil

        case "C", "c":
            guard let x1 = number(), let y1 = number(), let x2 = number(), let y2 = number(),
                  let x = number(), let y = number() else { return path }
            let isRel = command == "c"
            let c1 = isRel ? CGPoint(x: current.x + x1, y: current.y + y1) : CGPoint(x: x1, y: y1)
            let c2 = isRel ? CGPoint(x: current.x + x2, y: current.y + y2) : CGPoint(x: x2, y: y2)
            let p = isRel ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            path.addCurve(to: p, control1: c1, control2: c2)
            lastCubicControl = c2
            current = p

        case "S", "s":
            guard let x2 = number(), let y2 = number(), let x = number(), let y = number() else { return path }
            let isRel = command == "s"
            let c2 = isRel ? CGPoint(x: current.x + x2, y: current.y + y2) : CGPoint(x: x2, y: y2)
            let p = isRel ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            let c1: CGPoint
            if let last = lastCubicControl {
                c1 = CGPoint(x: 2 * current.x - last.x, y: 2 * current.y - last.y)
            } else {
                c1 = current
            }
            path.addCurve(to: p, control1: c1, control2: c2)
            lastCubicControl = c2
            current = p

        case "A", "a":
            guard let rx = number(), let ry = number(), number() != nil,
                  let laf = number(), let sf = number(),
                  let x = number(), let y = number() else { return path }
            let isRel = command == "a"
            let end = isRel ? CGPoint(x: current.x + x, y: current.y + y) : CGPoint(x: x, y: y)
            appendCircularArc(
                to: &path, from: current, radius: (rx + ry) / 2,
                largeArc: laf != 0, sweep: sf != 0, end: end
            )
            current = end
            lastCubicControl = nil

        case "Z", "z":
            path.closeSubpath()
            current = subpathStart
            lastCubicControl = nil

        default:
            return path
        }
    }
    return path
}

/// Approximates a circular arc (our illustrations never use elliptical
/// ones) as one or more cubic Bézier segments, each spanning at most 90°.
private func appendCircularArc(
    to path: inout Path, from p0: CGPoint, radius: CGFloat,
    largeArc: Bool, sweep: Bool, end p1: CGPoint
) {
    let d = CGPoint(x: p1.x - p0.x, y: p1.y - p0.y)
    let dist = (d.x * d.x + d.y * d.y).squareRoot()
    guard dist > 0.0001 else { return }

    var r = radius
    let halfDist = dist / 2
    if r < halfDist { r = halfDist }

    let mid = CGPoint(x: (p0.x + p1.x) / 2, y: (p0.y + p1.y) / 2)
    let h = max(0, r * r - halfDist * halfDist).squareRoot()
    let ux = -d.y / dist
    let uy = d.x / dist
    let sign: CGFloat = (largeArc == sweep) ? -1 : 1
    let center = CGPoint(x: mid.x + sign * h * ux, y: mid.y + sign * h * uy)

    let a1 = atan2(p0.y - center.y, p0.x - center.x)
    let a2 = atan2(p1.y - center.y, p1.x - center.x)
    var delta = a2 - a1
    if sweep {
        if delta < 0 { delta += 2 * .pi }
    } else {
        if delta > 0 { delta -= 2 * .pi }
    }

    let segments = max(1, Int(ceil(abs(delta) / (.pi / 2))))
    let segDelta = delta / CGFloat(segments)
    var angle = a1
    for _ in 0..<segments {
        let next = angle + segDelta
        let t = tan(segDelta / 4)
        let alpha = sin(segDelta) * ((4 + 3 * t * t).squareRoot() - 1) / 3
        let pStart = CGPoint(x: center.x + r * cos(angle), y: center.y + r * sin(angle))
        let pEnd = CGPoint(x: center.x + r * cos(next), y: center.y + r * sin(next))
        let c1 = CGPoint(x: pStart.x - alpha * r * sin(angle), y: pStart.y + alpha * r * cos(angle))
        let c2 = CGPoint(x: pEnd.x + alpha * r * sin(next), y: pEnd.y - alpha * r * cos(next))
        path.addCurve(to: pEnd, control1: c1, control2: c2)
        angle = next
    }
}

func svgEllipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
}

func svgCircle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
    svgEllipse(cx, cy, r, r)
}
