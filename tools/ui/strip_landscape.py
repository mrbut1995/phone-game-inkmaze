"""Dọn toàn bộ phần LANDSCAPE khỏi các màn (branch portrait-only).

Việc script làm (chỉ sửa file .tscn + project.godot, KHÔNG đụng code .gd):
  1. Xoá node `Landscape` (và mọi node con của nó) trong từng `scenes/<màn>.tscn`.
  2. Xoá `[connection]` trỏ tới node đã xoá.
  3. Xoá `[ext_resource ...]` không còn được dùng ở đâu trong file.
  4. Đánh số lại `index=` cho từng nhóm node cùng cha (tránh khoảng trống).
  5. `project.godot`: `window/handheld/orientation` -> 1 (dọc).

Chạy:  .venv\\Scripts\\python.exe tools/ui/strip_landscape.py            (xem trước: --dry-run)
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[2]
SCENES = ROOT / "scenes"

NODE_RE = re.compile(r'^\[node name="([^"]+)"(?: type="([^"]+)")? parent="([^"]*)"(.*)\]$')


def _parent_path(name: str, parent: str) -> str:
    return name if parent in (".", "") else f"{parent}/{name}"


def strip_landscape(text: str) -> tuple[str, int]:
    """Xoá node Landscape + con của nó, connection và ext_resource không dùng."""
    lines = text.splitlines()
    out: list[str] = []
    removed = 0
    skip_prefix: str | None = None

    for line in lines:
        m = NODE_RE.match(line)
        if m:
            name, _type, parent = m.group(1), m.group(2), m.group(3)
            path_full = _parent_path(name, parent)
            if name == "Landscape" and parent == ".":
                skip_prefix = "Landscape"
                removed += 1
                continue
            if skip_prefix is not None:
                if path_full.startswith(skip_prefix + "/"):
                    removed += 1
                    continue
                skip_prefix = None
        if skip_prefix is not None and line.startswith("[node "):
            skip_prefix = None
        out.append(line)

    kept: list[str] = []
    for line in out:
        if line.startswith("[connection ") and "Landscape" in line:
            removed += 1
            continue
        kept.append(line)

    # ext_resource không còn ai dùng
    body = "\n".join(kept)
    final: list[str] = []
    for line in kept:
        m = re.match(r'^\[ext_resource .*id="([^"]+)"\]$', line)
        if m and f'ExtResource("{m.group(1)}")' not in body:
            removed += 1
            continue
        final.append(line)

    # Đánh số lại index= theo từng cha
    counters: dict[str, int] = {}
    numbered: list[str] = []
    for line in final:
        m = NODE_RE.match(line)
        if m:
            name, parent = m.group(1), m.group(3)
            if parent != ".":  # node gốc không có index
                idx = counters.get(parent, 0)
                counters[parent] = idx + 1
                head, tail = line.rsplit("]", 1)
                tail = re.sub(r' index="\d+"', "", tail)
                tail = re.sub(r" index=\d+", "", tail)
                line = f'{head} index="{idx}"{tail}]'
        numbered.append(line)
    return "\n".join(numbered) + "\n", removed


def lock_portrait(text: str) -> tuple[str, bool]:
    if "window/handheld/orientation" in text:
        new = re.sub(r"(window/handheld/orientation=)\d+", r"\g<1>1", text)
        return new, new != text
    return text, False


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    targets = sorted(p for p in SCENES.glob("*.tscn"))
    total = 0
    for path in targets:
        text = path.read_text(encoding="utf-8")
        if 'name="Landscape"' not in text:
            continue
        new, n = strip_landscape(text)
        total += n
        print(f"  {path.relative_to(ROOT)}: xoá {n} mục")
        if not args.dry_run:
            path.write_text(new, encoding="utf-8")

    pg = ROOT / "project.godot"
    pg_text = pg.read_text(encoding="utf-8")
    pg_new, changed = lock_portrait(pg_text)
    print(f"  project.godot: khoá dọc = {changed}")
    if changed and not args.dry_run:
        pg.write_text(pg_new, encoding="utf-8")

    print(f"TỔNG: {total} mục đã xoá khỏi {len(targets)} màn")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
