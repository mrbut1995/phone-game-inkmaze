"""Đổi TOÀN BỘ tham chiếu asset PNG -> SVG (hoàn tác tools/switch_refs_svg_to_png.py).

Logic + quy ước nằm ở tools/switch_refs_svg_to_png.py (import lại — một nguồn sự thật).

    res://assets/images-png/<rel>.png            -> res://assets/images/<rel>.svg
    res://assets/images-png/<tên>.png            -> res://<tên>.svg  (icon app ở gốc, nếu có file gốc)
    (ref theo quy ước CŨ `assets/images/png/…` cũng revert được)

CHẠY:
    .venv\\Scripts\\python.exe tools/switch_refs_png_to_svg.py            # xem trước (dry-run)
    .venv\\Scripts\\python.exe tools/switch_refs_png_to_svg.py --apply    # ghi thật
"""

from __future__ import annotations

import sys

sys.stdout.reconfigure(encoding="utf-8")

from switch_refs_svg_to_png import main  # cùng thư mục tools/ nên import trực tiếp được

if __name__ == "__main__":
    raise SystemExit(main(direction="svg"))
