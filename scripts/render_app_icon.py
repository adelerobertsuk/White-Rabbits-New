#!/usr/bin/env python3
"""Rasterise the seated White Rabbits bunny into App Icon PNGs."""

from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "WhiteRabbits" / "Assets.xcassets" / "AppIcon.appiconset"

# 80x80 artwork, same paths as BunnyMarkView .asset
EAR_L = ((29, 34), (27.2, 12), (33.5, 5.5), (37.2, 24.5))
EAR_R = ((41, 31), (47.5, 11), (55, 14.5), (45.5, 33))
MOUTH = ((28.5, 41.5), (30.7, 43.9), (33.9, 44.1), (36.3, 41.9))


def cubic(p0, p1, p2, p3, steps=48):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3 * p0[0] + 3 * u**2 * t * p1[0] + 3 * u * t**2 * p2[0] + t**3 * p3[0]
        y = u**3 * p0[1] + 3 * u**2 * t * p1[1] + 3 * u * t**2 * p2[1] + t**3 * p3[1]
        pts.append((x, y))
    return pts


def xf(p, s, dx, dy):
    return (p[0] * s + dx, p[1] * s + dy)


def draw_bunny(draw: ImageDraw.ImageDraw, size: int, ink: tuple[int, int, int], stroke_scale: float = 1.0):
    # Fit the 80-unit art in the middle, leaving room for iOS rounding.
    art = size * 0.62
    s = art / 80.0
    dx = (size - 80 * s) / 2
    # Sit it a touch low so the ears don't kiss the top radius.
    dy = (size - 80 * s) / 2 + size * 0.03
    w = max(size * 0.018 * stroke_scale, 2.0)
    w_mouth = max(w * (1.15 / 1.6), 1.6)
    w_tail = max(w * (1.5 / 1.6), 1.8)

    def e(cx, cy, rx, ry, width):
        box = [
            cx * s + dx - rx * s,
            cy * s + dy - ry * s,
            cx * s + dx + rx * s,
            cy * s + dy + ry * s,
        ]
        draw.ellipse(box, outline=ink, width=int(round(width)))

    def poly(points, width):
        mapped = [xf(p, s, dx, dy) for p in points]
        draw.line(mapped, fill=ink, width=int(round(width)), joint="curve")

    e(42, 58, 17, 14.5, w)
    poly(cubic(*EAR_L), w)
    poly(cubic(*EAR_R), w)
    e(37.5, 39, 12.2, 11, w)
    e(58.5, 59, 4.6, 4.6, w_tail)
    eye_r = 1.35 * s
    ex, ey = xf((33.2, 38.2), s, dx, dy)
    draw.ellipse([ex - eye_r, ey - eye_r, ex + eye_r, ey + eye_r], fill=ink)
    poly(cubic(*MOUTH), w_mouth)


def render(path: Path, size: int, bg, ink, transparent: bool = False):
    mode = "RGBA" if transparent else "RGB"
    colour = (0, 0, 0, 0) if transparent else bg
    img = Image.new(mode, (size, size), colour)
    draw = ImageDraw.Draw(img)
    draw_bunny(draw, size, ink)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")
    print("wrote", path.name, size)


def main():
    paper = (246, 241, 234)  # F6F1EA
    ink = (42, 38, 34)  # 2A2622
    dark_paper = (22, 20, 18)  # 161412
    dark_ink = (243, 236, 228)  # F3ECE4

    render(ICON_DIR / "AppIcon-1024.png", 1024, paper, ink)
    render(ICON_DIR / "AppIcon-1024-dark.png", 1024, dark_paper, dark_ink)
    render(ICON_DIR / "AppIcon-1024-tinted.png", 1024, (0, 0, 0), (0, 0, 0), transparent=True)

    mac = [
        ("AppIcon-16.png", 16),
        ("AppIcon-16@2x.png", 32),
        ("AppIcon-32.png", 32),
        ("AppIcon-32@2x.png", 64),
        ("AppIcon-128.png", 128),
        ("AppIcon-128@2x.png", 256),
        ("AppIcon-256.png", 256),
        ("AppIcon-256@2x.png", 512),
        ("AppIcon-512.png", 512),
        ("AppIcon-512@2x.png", 1024),
    ]
    for name, size in mac:
        render(ICON_DIR / name, size, paper, ink)


if __name__ == "__main__":
    main()
