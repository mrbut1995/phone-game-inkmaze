"""Bước cuối dọn PORTRAIT-ONLY: gỡ code nhận diện/xoay hướng còn sót + test còn kỳ vọng layout ngang.

Chạy:  .venv\\Scripts\\python.exe tools/ui/strip_orientation_code.py [--dry-run]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[2]

# --- 1. base.gd: bỏ signal/hướng, luôn dùng cột dọc ------------------------------------
BASE_SIGNAL_OLD = """## Phát khi màn hình ĐỔI HƯỚNG (dọc ⇄ ngang) để màn con đổi layout Portrait ⇄ Landscape.
signal orientation_changed(is_landscape: bool)

## Màn hình đang là NGANG hay không (canvas rộng hơn cao)
var is_landscape := false

var _responsive_ready := false
var _orientation_ready := false
"""
BASE_SIGNAL_NEW = """## Game chỉ chạy DỌC (portrait) — giữ hằng số này để các màn cũ không phải sửa.
const is_landscape := false

var _responsive_ready := false
"""

BASE_LAYOUT_OLD = """	var landscape_layout := get_node_or_null("Landscape") as CanvasItem
	var portrait_layout := get_node_or_null("Portrait") as CanvasItem
	var landscape_now := canvas.x > canvas.y
	var use_landscape := landscape_now and landscape_layout != null

	if portrait_layout != null:
		portrait_layout.visible = not use_landscape
	if landscape_layout != null:
		landscape_layout.visible = use_landscape
	# Neo 2 layout phụ kín khung nội dung: layout đang ẨN vẫn phải co theo cột,
	# nếu không các node con giữ kích thước của lần NGANG trước đó (bị báo "tràn màn hình").
	var portrait_ctrl: Control = portrait_layout as Control
	var landscape_ctrl: Control = landscape_layout as Control
	for ctrl: Control in [portrait_ctrl, landscape_ctrl]:
		if ctrl == null:
			continue
		if ctrl.anchor_right != 1.0 or ctrl.anchor_bottom != 1.0 \\
				or ctrl.offset_right != 0.0 or ctrl.offset_bottom != 0.0:
			ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if use_landscape:
		# Bố cục NGANG tự dàn bằng anchors/container tỉ lệ 0..1 → root phủ KÍN canvas
		if position != Vector2.ZERO:
			position = Vector2.ZERO
		if size != canvas:
			size = canvas
	else:
		var column := DESIGN_WIDTH
		if landscape_layout != null:
			# Màn đã có layout ngang → màn dọc nở tối đa 1440 (dùng hết bề ngang tablet 3:4)
			column = clampf(canvas.x, DESIGN_WIDTH, MAX_CONTENT_WIDTH)
		var target_pos := Vector2(floorf((canvas.x - column) * 0.5), 0.0)
		var target_size := Vector2(column, canvas.y)
		if position != target_pos:
			position = target_pos
		if size != target_size:
			size = target_size
	_apply_background_sides(canvas)

	if not _orientation_ready or landscape_now != is_landscape:
		_orientation_ready = true
		is_landscape = landscape_now
		orientation_changed.emit(is_landscape)
"""

BASE_LAYOUT_NEW = """	# Màn chỉ có 1 bố cục DỌC: neo phủ kín cột nội dung
	var portrait_ctrl := get_node_or_null("Portrait") as Control
	if portrait_ctrl != null:
		portrait_ctrl.visible = true
		if portrait_ctrl.anchor_right != 1.0 or portrait_ctrl.anchor_bottom != 1.0 \\
				or portrait_ctrl.offset_right != 0.0 or portrait_ctrl.offset_bottom != 0.0:
			portrait_ctrl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Cột nội dung canh giữa (tablet 3:4 nở tối đa 1440, còn lại đúng 1080 thiết kế)
	var column := clampf(canvas.x, DESIGN_WIDTH, MAX_CONTENT_WIDTH)
	var target_pos := Vector2(floorf((canvas.x - column) * 0.5), 0.0)
	var target_size := Vector2(column, canvas.y)
	if position != target_pos:
		position = target_pos
	if size != target_size:
		size = target_size
	_apply_background_sides(canvas)
"""


def _drop_function(text: str, header: str) -> tuple[str, int]:
    """Xoá hàm `header ...` (tới `func ` kế tiếp hoặc hết file)."""
    idx = text.find(header)
    if idx < 0:
        return text, 0
    nxt = text.find("\nfunc ", idx + len(header))
    end = len(text) if nxt < 0 else nxt + 1
    # nuốt luôn dòng trống ngay trước hàm
    start = idx
    while start > 0 and text[start - 1] == "\n" and (start < 2 or text[start - 2] == "\n"):
        start -= 1
    return text[:start] + text[end:], 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    done: list[str] = []

    # 1. base.gd
    p = ROOT / "scripts/scenes/base.gd"
    t = p.read_text(encoding="utf-8")
    if BASE_SIGNAL_OLD in t and BASE_LAYOUT_OLD in t:
        t = t.replace(BASE_SIGNAL_OLD, BASE_SIGNAL_NEW).replace(BASE_LAYOUT_OLD, BASE_LAYOUT_NEW)
        done.append("base.gd: bỏ signal/switch hướng")
        if not args.dry_run:
            p.write_text(t, encoding="utf-8")

    # 2. script màn: bỏ connect + handler orientation
    for p in sorted((ROOT / "scripts/scenes").glob("*.gd")):
        if p.name == "base.gd":
            continue
        t = p.read_text(encoding="utf-8")
        orig = t
        kept = [ln for ln in t.splitlines() if "orientation_changed.connect(" not in ln]
        t = "\n".join(kept) + "\n"
        t, n = _drop_function(t, "func _on_orientation_changed(")
        if t != orig:
            done.append(f"{p.name}: {'bỏ handler' if n else 'bỏ connect'}")
            if not args.dry_run:
                p.write_text(t, encoding="utf-8")

    # 3. test còn kỳ vọng layout ngang
    for name in ("test_hud_modes.gd", "test_main_layout.gd"):
        p = ROOT / "scripts/test_case" / name
        t = p.read_text(encoding="utf-8")
        orig = t
        t = "\n".join(
            ln for ln in t.splitlines()
            if not re.search(r'landscape|Landscape', ln, re.IGNORECASE)
        ) + "\n"
        if t != orig:
            done.append(f"{name}: bỏ mục landscape")
            if not args.dry_run:
                p.write_text(t, encoding="utf-8")

    for d in done:
        print("  " + d)
    print(f"TỔNG: {len(done)} việc")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
