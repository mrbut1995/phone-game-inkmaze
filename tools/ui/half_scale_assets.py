"""Chia đôi nốt phần còn lại của việc hạ thiết kế 1080x1920 -> 540x960.

  A. ART SVG trong `assets/**` (TRỪ `mockup/**` — mockup giữ nguyên):
     chia đôi `width=` / `height=` (giữ nguyên `viewBox` ⇒ nội dung vẽ y hệt, texture nhẹ hơn 4 lần).
  B. `region_rect = Rect2(x, y, w, h)` trong scene/resource: đây là vùng cắt tính theo
     PIXEL CỦA ART gốc ⇒ phải chia đôi cho khớp art mới (bỏ sót là 9-slice cắt sai/trắng).
  C. Hằng số PIXEL trong `scripts/**/*.gd`: chỉ chia các tên thuộc whitelist
     (SIZE, WIDTH, HEIGHT, PADDING, MARGIN, PITCH, RADIUS, THICKNESS, GAP, SPACING, OFFSET...),
     TUYỆT ĐỐI không đụng số logic (thời gian, tỉ lệ, xác suất, số ô, index...).

Chạy:  .venv\\Scripts\\python.exe tools/ui/half_scale_assets.py [--dry-run]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")
ROOT = Path(__file__).resolve().parents[2]

NUM = re.compile(r"(?<![\w.])\d+(?:\.\d+)?(?![\w.])")
DIM = re.compile(r'(?<=\s)(width|height)="([0-9.]+)(px)?"')

GD_OK = re.compile(r"(SIZE|WIDTH|HEIGHT|PADDING|MARGIN|PITCH|RADIUS|THICKNESS|THICK|GAP|SPACING|"
                   r"OFFSET|INSET|CORNER|BORDER|LINE_W|CELL|TILE|ICON|STAMP|CHIP|SLOT)_?\w*$")
GD_NO = re.compile(r"(SEC|MS|TIME|SPEED|DUR|ALPHA|FACTOR|RATIO|SCALE|COUNT|PERCENT|CHANCE|PROB|"
                   r"STEPS|LEVEL|FLOOR|INDEX|ID$|VERSION|MAX_|MIN_)")
GD_CONST = re.compile(r"^(\s*(?:const|var)\s+)([A-Za-z_][A-Za-z0-9_]*)(\s*(?::=|=)\s*)(\d+(?:\.\d+)?)\b(.*)$")


def half(v: str) -> str:
    h = float(v) / 2.0
    return str(int(h)) if h == int(h) else f"{h:g}"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    write = not args.dry_run

    # A. SVG art
    svg_files = 0
    svg_dims = 0
    for p in sorted((ROOT / "assets").rglob("*.svg")):
        if "mockup" in p.parts or p.name.endswith(".import"):
            continue
        t = p.read_text(encoding="utf-8", errors="ignore")
        new, n = DIM.subn(lambda m: f'{m.group(1)}="{half(m.group(2))}{m.group(3) or ""}"', t)
        if n:
            svg_files += 1
            svg_dims += n
            if write:
                p.write_text(new, encoding="utf-8")
    print(f"A. SVG art: {svg_dims} thuộc tính width/height / {svg_files} file")

    # B. region_rect
    rr_files = 0
    rr_lines = 0
    pat = re.compile(r"^(region_rect\s*=\s*)Rect2\(([^)]*)\)(.*)$")
    for pat_glob in ("scenes/**/*.tscn", "nodes/**/*.tscn", "resources/**/*.tres"):
        for p in sorted(ROOT.glob(pat_glob)):
            lines = p.read_text(encoding="utf-8").splitlines(True)
            changed = False
            for i, ln in enumerate(lines):
                m = pat.match(ln.rstrip("\n"))
                if not m:
                    continue
                parts = [x.strip() for x in m.group(2).split(",")]
                if len(parts) != 4:
                    continue
                lines[i] = m.group(1) + f"Rect2({', '.join(half(x) for x in parts)})" + m.group(3) + "\n"
                changed = True
                rr_lines += 1
            if changed:
                rr_files += 1
                if write:
                    p.write_text("".join(lines), encoding="utf-8")
    print(f"B. region_rect: {rr_lines} dòng / {rr_files} file")

    # C. hằng số pixel trong GDScript
    gd_files = 0
    gd_lines = 0
    for p in sorted((ROOT / "scripts").rglob("*.gd")):
        lines = p.read_text(encoding="utf-8").splitlines(True)
        changed = False
        for i, ln in enumerate(lines):
            m = GD_CONST.match(ln.rstrip("\n"))
            if not m:
                continue
            name = m.group(2)
            if not GD_OK.search(name) or GD_NO.search(name):
                continue
            lines[i] = f"{m.group(1)}{name}{m.group(3)}{half(m.group(4))}{m.group(5)}\n"
            changed = True
            gd_lines += 1
        if changed:
            gd_files += 1
            if write:
                p.write_text("".join(lines), encoding="utf-8")
    print(f"C. GDScript: {gd_lines} hằng số / {gd_files} file")
    print("(DRY-RUN — chưa ghi gì)" if args.dry_run else "Đã ghi.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
