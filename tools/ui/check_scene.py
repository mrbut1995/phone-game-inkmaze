"""Kiểm tra nhanh 1 file .tscn sinh bằng tool: thứ tự node hợp lệ + không BOM + in ra chỗ hỏng.

Usage: python tools/ui/check_scene.py scenes/orientation/landscape/settings.tscn
"""

from __future__ import annotations

import pathlib
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def check(path_str: str) -> int:
    path = pathlib.Path(path_str)
    raw = path.read_bytes()
    problems: list[str] = []
    if raw.startswith(b"\xef\xbb\xbf"):
        problems.append("có BOM ở đầu file")
    text = raw.decode("utf-8").lstrip("\ufeff")
    if not text.startswith("[gd_scene"):
        problems.append(f"dòng đầu không phải [gd_scene: {text.splitlines()[0]!r}")
    lines = text.splitlines()
    first_node = next((i for i, l in enumerate(lines) if l.startswith("[node ")), len(lines))
    for i, l in enumerate(lines[:first_node]):
        if l.startswith("[node "):
            problems.append(f"dòng {i + 1}: [node] nằm trước header")
    blocks = [b for b in re.split(r"(?=^\[node )", text, flags=re.M) if b.startswith("[node ")]
    defined: set[str] = set()
    ids: set[str] = set()
    for m in re.finditer(r'^\[ext_resource[^\]]*id="([^"]*)"', text, flags=re.M):
        ids.add(m.group(1))
    for block in blocks:
        head = block.splitlines()[0]
        name = re.search(r'name="([^"]*)"', head)
        parent = re.search(r'parent="([^"]*)"', head)
        if name is None:
            problems.append(f"block thiếu name: {head!r}")
            continue
        par = parent.group(1) if parent else "."
        full = name.group(1) if par == "." else f"{par}/{name.group(1)}"
        if par != "." and par not in defined:
            problems.append(f"node '{full}' khai báo TRƯỚC cha '{par}'")
        defined.add(full)
        for ext in re.findall(r'ExtResource\("([^"]*)"\)', block):
            if ext not in ids:
                problems.append(f"node '{full}' dùng ext_resource '{ext}' không khai báo")
    print(f"{path_str}: {len(blocks)} node · {len(ids)} ext_resource")
    if problems:
        for p in problems:
            print("  !! " + p)
        return 1
    print("  OK — cấu trúc hợp lệ")
    return 0


if __name__ == "__main__":
    sys.exit(max(check(a) for a in sys.argv[1:]) if sys.argv[1:] else 0)
