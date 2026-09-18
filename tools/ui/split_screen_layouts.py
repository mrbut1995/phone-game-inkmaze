"""Tách 1 màn hình thành 2 layout theo hướng (guide/GUIDE.MD §5.1) — dùng cho MỌI màn còn lại.

Với mỗi màn `<screen>`:
  · `scenes/orientation/portrait/<screen>.tscn`  ← toàn bộ nội dung hiện có của `scenes/<screen>.tscn`
      (root KẾ THỪA `scenes/orientation/portrait/portrait.tscn`, giữ NGUYÊN đường dẫn node con)
  · `scenes/<screen>.tscn`                        ← chỉ còn root (base + script) + 2 layout con
      `Portrait` / `Landscape` (Landscape chỉ được thêm khi ĐÃ có file layout ngang)

YÊU CẦU: chạy SAU khi đã tạo `scenes/orientation/landscape/<screen>.tscn` (nếu muốn thêm layout ngang).
Usage: python tools/ui/split_screen_layouts.py chapters settings levels ...
"""

from __future__ import annotations

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
PORTRAIT_SCENE = "res://scenes/orientation/portrait/portrait.tscn"
LANDSCAPE_SCENE = "res://scenes/orientation/landscape/landscape.tscn"


def strip_uid(header: str) -> str:
    return re.sub(r'\[gd_scene([^\]]*?) uid="[^"]*"', r"[gd_scene\1", header, count=1)


def add_ext(header: str, res_type: str, path: str, res_id: str) -> str:
    line = f'[ext_resource type="{res_type}" path="{path}" id="{res_id}"]\n'
    return header if line in header else header + line


def split(screen: str) -> None:
    src = ROOT / "scenes" / f"{screen}.tscn"
    if not src.exists():
        print(f"  !! không có {src.relative_to(ROOT)}")
        return
    text = src.read_text(encoding="utf-8")
    if '[node name="Landscape" parent="."' in text or '[node name="Portrait" parent="."' in text:
        # Đã tách rồi: nếu bản NGANG mới được tạo sau đó thì chỉ cần gắn thêm layout ngang
        landscape_file = ROOT / "scenes" / "orientation" / "landscape" / f"{screen}.tscn"
        if landscape_file.exists() and '[node name="Landscape" parent="."' not in text:
            ext_line = (f'[ext_resource type="PackedScene" '
                        f'path="res://scenes/orientation/landscape/{screen}.tscn" id="L_Landscape"]\n')
            lines = text.splitlines(keepends=True)
            first = next(i for i, l in enumerate(lines) if l.startswith("[node "))
            head = "".join(lines[:first]) + ext_line + "\n" + "".join(lines[first:])
            head = head.rstrip("\n") + (
                f'\n\n[node name="Landscape" parent="." index="2" instance=ExtResource("L_Landscape")]\n')
            src.write_text(head, encoding="utf-8")
            print(f"  OK {screen}: đã gắn thêm layout NGANG vào scenes/{screen}.tscn")
        else:
            print(f"  (đã tách rồi) {src.relative_to(ROOT)}")
        return

    lines = text.splitlines(keepends=True)
    first = next(i for i, l in enumerate(lines) if l.startswith("[node "))
    header = "".join(lines[:first])
    rest = "".join(lines[first:])
    blocks = [b for b in re.split(r"(?=^\[node )", rest, flags=re.M) if b.strip()]
    node_blocks = [b for b in blocks if b.startswith("[node ")]
    tail = "".join(b for b in blocks if not b.startswith("[node "))
    root_block = node_blocks[0]
    children = node_blocks[1:]
    if tail.strip():
        print(f"  !! {screen}: có [connection]/[sub_resource] ở cuối file — kiểm tra tay:\n{tail.strip()[:200]}")

    # ---- layout DỌC -----------------------------------------------------------
    out_portrait = ROOT / "scenes" / "orientation" / "portrait" / f"{screen}.tscn"
    head_p = add_ext(strip_uid(header), "PackedScene", PORTRAIT_SCENE, "1_parent")
    body = "".join(children)
    out_portrait.write_text(head_p + '\n[node name="Portrait" instance=ExtResource("1_parent")]\n\n' + body,
                            encoding="utf-8")

    # ---- màn hình (root + 2 layout) -------------------------------------------
    landscape_file = ROOT / "scenes" / "orientation" / "landscape" / f"{screen}.tscn"
    head_m = add_ext(header, "PackedScene",
                     f"res://scenes/orientation/portrait/{screen}.tscn", "L_Portrait")
    main_body = root_block + "\n" + '[node name="Portrait" parent="." index="1" instance=ExtResource("L_Portrait")]\n'
    if landscape_file.exists():
        head_m = add_ext(head_m, "PackedScene",
                         f"res://scenes/orientation/landscape/{screen}.tscn", "L_Landscape")
        main_body += "\n[node name=\"Landscape\" parent=\".\" index=\"2\" instance=ExtResource(\"L_Landscape\")]\n"
    else:
        print(f"  (chưa có layout NGANG cho {screen} — chỉ thêm Portrait)")
    src.write_text(head_m + "\n" + main_body, encoding="utf-8")
    print(f"  OK {screen}: {len(children)} node → orientation/portrait/{screen}.tscn · scenes/{screen}.tscn rewire")


def main() -> None:
    names = sys.argv[1:]
    if not names:
        print(__doc__)
        return
    for name in names:
        split(name)


if __name__ == "__main__":
    main()
