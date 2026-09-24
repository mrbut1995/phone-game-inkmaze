"""Đổi CHA của mọi scene bố cục `scenes/layout/<hướng>/<màn>.tscn` sang `scenes/layout/base_layout.tscn`.

Trước: kế thừa scaffold `scenes/layout/portrait/portrait.tscn` · `scenes/layout/landscape/landscape.tscn`
Sau  : kế thừa thẳng `scenes/layout/base_layout.tscn` (root Control full-rect + script `BaseLayout` —
       mọi script bố cục đều `extends BaseLayout` nên vẫn tương thích).

Usage: python tools/ui/inherit_base_layout.py [--dry-run]
"""

from __future__ import annotations

import pathlib
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE_REL = "scenes/layout/base_layout.tscn"
BASE_UID = "uid://d28jmv5bkqkx5"  # đọc lại từ file cho chắc


def base_uid() -> str:
    text = (ROOT / BASE_REL).read_text(encoding="utf-8")
    m = re.search(r'\[gd_scene[^\]]*uid="([^"]+)"', text)
    return m.group(1) if m else BASE_UID


def convert(path: pathlib.Path, uid: str, dry: bool) -> str:
    text = path.read_text(encoding="utf-8")
    rel = path.relative_to(ROOT).as_posix()
    orientation = "portrait" if "/portrait/" in f"/{rel}" else "landscape"
    old_path = f"res://scenes/layout/{orientation}/{orientation}.tscn"
    if old_path not in text:
        return f"  = {rel} (đã là base_layout hoặc không kế thừa scaffold)"
    # thay CẢ `uid=` và `path=` trong đúng dòng ext_resource đó
    pattern = re.compile(
        r'\[ext_resource type="PackedScene" uid="[^"]*" path="' + re.escape(old_path) + r'" id="([^"]+)"\]')
    hits = pattern.findall(text)
    if len(hits) != 1:
        return f"  !! {rel}: thấy {len(hits)} dòng ext_resource scaffold (cần đúng 1) — bỏ qua"
    new_line = f'[ext_resource type="PackedScene" uid="{uid}" path="res://{BASE_REL}" id="{hits[0]}"]'
    text = pattern.sub(lambda _m: new_line, text, count=1)
    if not dry:
        path.write_text(text, encoding="utf-8")
    return f"  {'(dry) ' if dry else ''}OK {rel}: {orientation}.tscn → base_layout.tscn"


def main() -> None:
    dry = "--dry-run" in sys.argv
    uid = base_uid()
    scenes = sorted(p for p in (ROOT / "scenes/layout").glob("*/*.tscn")
                    if p.stem not in ("portrait", "landscape"))
    print(f"base = {BASE_REL} (uid {uid}) · {len(scenes)} scene bố cục")
    problems = 0
    for path in scenes:
        line = convert(path, uid, dry)
        if line.strip().startswith("!!"):
            problems += 1
        print(line)
    print(f"\n>>> {'OK' if problems == 0 else str(problems) + ' vấn đề'}"
          f"{' (dry-run)' if dry else ''}")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
