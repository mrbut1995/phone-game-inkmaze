"""Chia đôi KHÔNG GIAN TOẠ ĐỘ THIẾT KẾ: 1080x1920 -> 540x960.

Nguyên tắc:
  · GIỮ NGUYÊN mọi giá trị TỈ LỆ / KHÔNG PHẢI PIXEL: anchor_* (0..1), size_flags, modulate,
    scale, rotation, index/id/uid/load_steps/unique_id, alpha, wait_time, các cờ bool, enum...
  · CHIA ĐÔI các giá trị PIXEL: offset_*, custom_minimum_size, pivot_offset, position, size,
    separation (+ theme_override_constants/*), font_size (mọi biến thể), LABEL SETTINGS font_size,
    patch_margin_*/texture_margin_*/expand_margin_*/content_margin_*/corner_radius_*/border_width_*,
    cell_size, outline_size, line_spacing/paragraph_spacing, shadow_offset_*/shadow_size.

Phạm vi: `scenes/**/*.tscn`, `nodes/**/*.tscn`, `resources/**/*.tres`, `project.godot`
        (GDScript KHÔNG bị đụng — xem phần "CÒN LẠI" in ra cuối để rà tay).

Chạy:  .venv\\Scripts\\python.exe tools/ui/half_scale.py [--dry-run]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[2]

SKIP_KEYS = re.compile(
    r"^(anchor_|size_flags|grow_|layout_mode|mouse_filter|modulate|self_modulate|scale|rotation|"
    r"alpha|index|id|uid|load_steps|unique_id|metadata/_|visible|flip_|show_|expand_mode|"
    r"stretch_mode|text|theme|theme_type_variation|texture|region_rect|axis_stretch|fill_|"
    r"alignment|autowrap|clip_|top_level|z_index|pivot_offset_none)$"
)

# key -> phải chia đôi (khớp cả khi có tiền tố như "MainTitle/font_sizes/font_size")
HALF_KEY = re.compile(
    r"^(?:[\w]+/)?(?:font_sizes/)?(?:font_size|offset_(?:left|top|right|bottom)|"
    r"custom_minimum_size|pivot_offset|position|size|separation|cell_size|outline_size|"
    r"line_spacing|paragraph_spacing|shadow_size|shadow_offset_\w+|"
    r"(?:theme_override_constants/)[\w/]+|"
    r"(?:patch|texture|expand|content)_margin_\w+|corner_radius_\w+|border_width_\w+|"
    r"metadata/title_left)$"
)

NUM = re.compile(r"(?<![\w.])\d+(?:\.\d+)?(?![\w.])")


def half_num(m: re.Match) -> str:
    v = float(m.group(0))
    h = v / 2.0
    return str(int(h)) if h == int(h) and "." not in m.group(0) else f"{h:g}"


def process_lines(path: Path, lines: list[str]) -> tuple[list[str], int]:
    out: list[str] = []
    changed = 0
    for line in lines:
        raw = line.rstrip("\n")
        if raw.lstrip().startswith("#") or raw.startswith("["):
            out.append(line)
            continue
        if "=" not in raw:
            out.append(line)
            continue
        key, _, val = raw.partition("=")
        key = key.strip()
        if SKIP_KEYS.match(key) or key.startswith("metadata/") and key != "metadata/title_left":
            out.append(line)
            continue
        if not HALF_KEY.match(key):
            out.append(line)
            continue
        new_val, n = NUM.subn(half_num, val)
        if n:
            changed += 1
            out.append(f"{key} = {new_val}" + ("\n" if line.endswith("\n") else ""))
        else:
            out.append(line)
    return out, changed


def half_project_godot(t: str) -> tuple[str, int]:
    n = 0
    for key, old, new in (
        ("window/size/viewport_width", "1080", "540"),
        ("window/size/viewport_height", "1920", "960"),
    ):
        pat = re.compile(rf"^{re.escape(key)}=(\d+)$", re.M)
        t, k = pat.subn(f"{key}={new}", t)
        n += k
    return t, n


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    targets: list[Path] = []
    for pat in ("scenes/**/*.tscn", "nodes/**/*.tscn", "resources/**/*.tres"):
        targets += [p for p in ROOT.glob(pat) if "orientation/landscape" not in p.as_posix()]

    total_files = 0
    total_lines = 0
    for p in sorted(targets):
        text = p.read_text(encoding="utf-8")
        new_lines, n = process_lines(p, text.splitlines(True))
        if n:
            total_files += 1
            total_lines += n
            if not args.dry_run:
                p.write_text("".join(new_lines), encoding="utf-8")

    pg = ROOT / "project.godot"
    t = pg.read_text(encoding="utf-8")
    t2, pn = half_project_godot(t)
    if pn and not args.dry_run:
        pg.write_text(t2, encoding="utf-8")

    print(f"{'[DRY-RUN] ' if args.dry_run else ''}Đã chia đôi: {total_lines} dòng / {total_files} file scene+resource")
    print(f"project.godot: {pn} dòng (viewport 1080x1920 -> 540x960)")
    print("\nCÒN LẠI phải rà tay trong GDScript (hằng số pixel cứng):")
    for gd in sorted((ROOT / "scripts").rglob("*.gd")):
        hits = [
            (i + 1, ln.strip()) for i, ln in enumerate(gd.read_text(encoding="utf-8").splitlines())
            if re.search(r"const [A-Z_]*\s*:=\s*\d+(\.\d+)?\b", ln) or re.search(r"_SIZE|_WIDTH|_HEIGHT|_PADDING|_MARGIN|_PITCH", ln)
        ]
        if hits:
            print(f"  {gd.relative_to(ROOT)} ({len(hits)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
