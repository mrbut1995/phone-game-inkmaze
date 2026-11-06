#!/usr/bin/env python3
"""Thay tiền tố THƯ MỤC trong chuỗi đường dẫn (move_map.py chỉ thay đường dẫn FILE đầy đủ).

Cách chạy:  python3 -I tools/refactor/rewrite_dir_refs.py <project_root> <map> [--dry-run] [--only-py]
<map>: dir_refs.txt (`cũ/ -> mới/`) HOẶC bất kỳ P2*.map (`file cũ -> file mới`), tương đối project root, không có res://.
Thay `res://cũ/...` và `res://cũ"` (hằng số thư mục như `const DIR := "res://resources/levels/"`).
--only-py: chỉ sửa file .py (move_map.py bỏ qua .py; tool Python như level_designer ghi `res://scripts/data/level_data.gd`).
Chạy thêm với P2b/P2c/P2d map + --only-py để tool Python không trỏ vào đường dẫn cũ.
In ra các dòng còn chứa tiền tố cũ sau khi thay (thường là chuỗi ghép `"resources/" + x` -> sửa tay).
"""
import os, re, sys

root = os.path.abspath(sys.argv[1]); mapf = sys.argv[2]; dry = "--dry-run" in sys.argv
pairs = []
for ln in open(mapf, encoding="utf-8"):
    ln = ln.split("#")[0].strip()
    if "->" in ln:
        a, b = [x.strip().removeprefix("res://") for x in ln.split("->")]
        pairs.append((a.rstrip("/"), b.rstrip("/")))
pairs.sort(key=lambda x: -len(x[0]))
EXT = (".py",) if "--only-py" in sys.argv else (".gd", ".tscn", ".tres", ".cfg", ".godot", ".csv", ".json", ".md", ".remap")
pats = [(re.compile(r"res://" + re.escape(a) + r"(?![\w])"), "res://" + b) for a, b in pairs]
changed = 0
left = []
for d, dirs, fs in os.walk(root):
    dirs[:] = [x for x in dirs if x not in (".git", ".godot", "node_modules", "__pycache__", "dist", "build")]
    for f in fs:
        if not (f.endswith(EXT) or (f == "project.godot" and ".py" not in EXT)):
            continue
        p = os.path.join(d, f)
        try:
            t = open(p, encoding="utf-8").read()
        except Exception:
            continue
        t2 = t
        for rx, new in pats:
            t2 = rx.sub(new, t2)
        if t2 != t:
            changed += 1
            if not dry:
                open(p, "w", encoding="utf-8", newline="").write(t2)
        for n, line in enumerate(t2.splitlines(), 1):
            for a, _ in pairs:
                if re.search(r"(?<![\w/])" + re.escape(a) + r"/", line) and "res://" + a not in line:
                    left.append(f"{os.path.relpath(p, root)}:{n}: {line.strip()[:110]}")
print(("DRY " if dry else "") + f"đã sửa {changed} file")
if left:
    print(f"CÒN {len(left)} dòng có thể ghép chuỗi (kiểm tra tay):")
    print("\n".join(sorted(set(left))[:40]))
