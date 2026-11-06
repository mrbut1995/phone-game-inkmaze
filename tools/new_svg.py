#!/usr/bin/env python3
"""Create an SVG placeholder (instruction R5) and register it in assets/images-placeholder/MANIFEST.md.

  python tools/new_svg.py characters/goblin --size 64x64 --role enemy --used-by "data/actors/goblin.tres sprite_frames"
  python tools/new_svg.py items/potion --size 32x32 --role collectible --shape circle
  python tools/new_svg.py characters/hero_walk --role player --frames 4        # hero_walk_00..03.svg
Roles: player | enemy | neutral | collectible | obstacle        Shapes: rect | circle | diamond | hex
"""
from __future__ import annotations

import argparse
import re
import sys

from _common import ROOT, setup_stdout

COLORS = {"player": "#4C99FF", "enemy": "#E64D4D", "neutral": "#B3B3B3", "collectible": "#FFD933", "obstacle": "#8C6640"}


def darken(hex_color: str, factor: float = 0.55) -> str:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return "#%02X%02X%02X" % (int(r * factor), int(g * factor), int(b * factor))


def shape_svg(shape: str, w: int, h: int, fill: str, stroke: str) -> str:
    pad = max(2, min(w, h) // 16)
    sw = max(1, pad // 2)
    if shape == "circle":
        return f'<ellipse cx="{w / 2:g}" cy="{h / 2:g}" rx="{w / 2 - pad:g}" ry="{h / 2 - pad:g}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
    if shape == "diamond":
        pts = f"{w / 2:g},{pad} {w - pad},{h / 2:g} {w / 2:g},{h - pad} {pad},{h / 2:g}"
        return f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
    if shape == "hex":
        pts = f"{w * 0.25:g},{pad} {w * 0.75:g},{pad} {w - pad},{h / 2:g} {w * 0.75:g},{h - pad} {w * 0.25:g},{h - pad} {pad},{h / 2:g}"
        return f'<polygon points="{pts}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
    return f'<rect x="{pad}" y="{pad}" width="{w - 2 * pad}" height="{h - 2 * pad}" rx="{max(2, w // 10)}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("name", help="<category>/<snake_case_name> (no extension)")
    ap.add_argument("--size", default="64x64")
    ap.add_argument("--role", choices=sorted(COLORS), default="neutral")
    ap.add_argument("--shape", choices=["rect", "circle", "diamond", "hex"], default="rect")
    ap.add_argument("--frames", type=int, default=1)
    ap.add_argument("--label", default="")
    ap.add_argument("--used-by", default="TBD")
    ap.add_argument("--force", action="store_true")
    a = ap.parse_args()

    m = re.match(r"^(\d+)x(\d+)$", a.size)
    if not m:
        print("ERROR: --size must look like 64x64")
        return 1
    w, h = int(m.group(1)), int(m.group(2))
    rel = a.name.replace("\\", "/").strip("/")
    if not re.match(r"^[a-z0-9_]+(/[a-z0-9_]+)*$", rel):
        print("ERROR: name must be snake_case segments, e.g. characters/goblin")
        return 1
    base = ROOT / "assets" / "images-placeholder"
    manifest = base / "MANIFEST.md"
    fill = COLORS[a.role]
    stroke = darken(fill)
    rows = []
    for i in range(a.frames):
        fname = f"{rel}_{i:02d}.svg" if a.frames > 1 else f"{rel}.svg"
        path = base / fname
        if path.exists() and not a.force:
            print(f"ERROR: {fname} exists (use --force)")
            return 1
        label = (a.label or rel.split("/")[-1]) + (f" {i}" if a.frames > 1 else "")
        size = max(6, min(w, h) // 6)
        svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">\n'
               f'  {shape_svg(a.shape, w, h, fill, stroke)}\n'
               f'  <text x="{w / 2:g}" y="{h / 2 + size / 3:g}" font-family="sans-serif" font-size="{size}" '
               f'text-anchor="middle" fill="#FFFFFF">{label[: max(4, w // max(size // 2, 1))]}</text>\n</svg>\n')
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(svg, encoding="utf-8", newline="\n")
        rows.append(f"| {fname} | {a.used_by} | {w}x{h} | center | {a.frames} | placeholder | - |")
        print(f"created assets/images-placeholder/{fname}")
    if not manifest.exists():
        manifest.write_text("# Placeholder manifest\n\n| File | Used by (scene/resource + property) | Size | Pivot | Frames | Status | Final path |\n|---|---|---|---|---|---|---|\n", encoding="utf-8")
    with manifest.open("a", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(rows) + "\n")
    print("manifest updated. Next: `godot --headless --path . --import` so Godot imports the SVG.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
