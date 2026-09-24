"""Chuyển `scripts/scenes/levels.gd` sang dùng TRỰC TIẾP export của `LevelsLayout`.

- Bỏ các dòng khai báo local đã bị comment (`# var btn_back: BaseButton = null` …).
- `_bind_refs()` chỉ còn lấy `layout = active_layout() as LevelsLayout` + cảnh báo nếu thiếu.
- Mọi chỗ dùng `btn_back`, `scroll`, `dots_box`… -> `layout.<tên>` (không đụng comment, không đụng
  tên khác chứa cùng chuỗi như `_scroll_tween`, `BANNER_FOCUS`, `_banner_focus`…).

Chạy:  .venv\\Scripts\\python.exe tools/ui/direct_layout_refs.py [--dry-run]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[2]
TARGET = ROOT / "scripts/scenes/levels.gd"

NAMES = [
    "btn_back", "btn_continue", "lbl_continue", "lbl_stars", "lbl_chapter",
    "lbl_change_chapter", "banner", "scroll", "pages_host", "dots_box",
]

NEW_BIND = (
    "func _bind_refs() -> void:\n"
    "\tlayout = active_layout() as LevelsLayout\n"
    "\tif layout == null:\n"
    "\t\tpush_warning(\"LevelScenes: bố cục chưa gắn LevelsLayout — thiếu binding trong scenes/layout/<hướng>/levels.tscn\")\n"
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    text = TARGET.read_text(encoding="utf-8")
    orig = text

    # 1. bỏ dòng khai báo local đã comment
    lines = [
        ln for ln in text.splitlines()
        if not re.match(r"^#\s*var\s+(btn_|lbl_|banner|scroll|pages_host|dots_box)\w*\s*:", ln)
    ]
    text = "\n".join(lines) + "\n"

    # 2. rút gọn _bind_refs (tới hết thân hàm = trước 2 dòng trống)
    text, n_bind = re.subn(
        r"func _bind_refs\(\) -> void:.*?\n\n\n",
        NEW_BIND + "\n\n",
        text,
        count=1,
        flags=re.S,
    )

    # 3. đổi chỗ dùng sang layout.<tên>
    out_lines: list[str] = []
    n_refs = 0
    for ln in text.splitlines(True):
        if ln.lstrip().startswith("#") or ln.lstrip().startswith("func "):
            out_lines.append(ln)
            continue
        new = ln
        for name in NAMES:
            new, k = re.subn(rf"(?<![\w.]){name}\b", f"layout.{name}", new)
            n_refs += k
        out_lines.append(new)
    text = "".join(out_lines)

    if text != orig and not args.dry_run:
        TARGET.write_text(text, encoding="utf-8")

    print(f"{'[DRY-RUN] ' if args.dry_run else ''}bỏ khai báo local: {len(lines)} dòng còn lại/ban đầu "
          f"{len(orig.splitlines())}")
    print(f"rút gọn _bind_refs: {n_bind} lần | đổi sang layout.<tên>: {n_refs} chỗ")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
