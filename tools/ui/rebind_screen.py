"""Chuyển `@onready var x: T = $Path` trong 1 script màn → gắn lại theo LAYOUT đang hiển thị.

Sinh thêm `_bind_refs()` (dùng `ui_path` của BaseScene) và gọi nó ở đầu `_ready()`,
để màn vẫn chạy sau khi tách thành `Portrait`/`Landscape` (node nằm trong layout, không còn ở root).

Usage: python tools/ui/rebind_screen.py splash title credit debug
"""

from __future__ import annotations

import pathlib
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]
REF = re.compile(r"^@onready var (\w+): ([\w\[\]]+) = \$([^\s]+)$", re.M)


def rebind(screen: str) -> None:
    path = ROOT / "scripts" / "scenes" / f"{screen}.gd"
    if not path.exists():
        print(f"  !! thiếu {path.relative_to(ROOT)}")
        return
    text = path.read_text(encoding="utf-8")
    if "_bind_refs()" in text:
        print(f"  (đã có _bind_refs) {path.relative_to(ROOT)}")
        return
    refs = REF.findall(text)
    if not refs:
        print(f"  (không có @onready $path) {path.relative_to(ROOT)}")
        return
    text = REF.sub(lambda m: f"var {m.group(1)}: {m.group(2)} = null", text)

    body = "\n".join(
        f'\t{name} = ui_path("{node_path}") as {type_name}' for name, type_name, node_path in refs)
    func_text = (
        "## Gắn node của layout đang hiển thị (2 layout giữ CÙNG đường dẫn node)\n"
        "func _bind_refs() -> void:\n" + body + "\n\n\n")

    first_func = text.find("func ")
    text = text[:first_func] + func_text + text[first_func:]
    text = re.sub(r"(func _ready\(\) -> void:\n)", r"\1\t_bind_refs()\n", text, count=1)
    path.write_text(text, encoding="utf-8")
    print(f"  OK {screen}: {len(refs)} node → _bind_refs()")


def main() -> None:
    names = sys.argv[1:]
    if not names:
        print(__doc__)
        return
    for name in names:
        rebind(name)


if __name__ == "__main__":
    main()
