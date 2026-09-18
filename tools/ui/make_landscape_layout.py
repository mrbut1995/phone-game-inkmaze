"""Dựng layout NGANG cho 1 màn từ BẢN DỌC bằng cách TÁI SẮP XẾP node (guide/GUIDE.MD §6).

- Nguồn: `scenes/orientation/portrait/<screen>.tscn` (đã tách trước đó bằng split_screen_layouts.py)
- Ra:    `scenes/orientation/landscape/<screen>.tscn`

Mỗi màn khai 1 SPEC: danh sách các bước theo THỨ TỰ sẽ xuất hiện trong file .tscn:
  ("keep", "<đường dẫn node trong bản dọc>", "<cha mới>", {})      -> bê node + toàn bộ con, đổi cha
  ("new",  "<tên node mới>",              "<cha mới>", {"type": ..., "props": [...]})

Node "keep" giữ NGUYÊN mọi thuộc tính (texture/theme/font…) — chỉ đổi `parent=` và bỏ `index=`
(thứ tự trong file quyết định thứ tự node). Node nằm trong container thì `layout_mode = 2`.

Usage: python tools/ui/make_landscape_layout.py settings [daily ...]
"""

from __future__ import annotations

import pathlib
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]
LANDSCAPE_SCENE = "res://scenes/orientation/landscape/landscape.tscn"
ROOT_PROPS = [
    "anchors_preset = 15",
    "anchor_right = 1.0",
    "anchor_bottom = 1.0",
    "offset_right = 0.0",
    "offset_bottom = 0.0",
]

# ---------------------------------------------------------------------------
# SPEC từng màn (thêm dần khi chuyển màn mới)
# ---------------------------------------------------------------------------
# Sửa `@export NodePath` trỏ tới node ĐÃ ĐỔI CHA ở bản ngang (màn game: Controllers trỏ tới UI của màn)
PATH_REWRITES: dict[str, list[tuple[str, str]]] = {
    "game": [
        ("../../Status/", "../../Side/Status/"),
        ("../../Button/", "../../Side/Button/"),
        ("../../Replay\"", "../../Side/Replay\""),
    ],
}

SPECS: dict[str, list[tuple]] = {    # §6.2 — Header trên cùng, thân chia 2 cột: trái (Âm thanh + Bàn cờ), phải (Hệ thống + Thao tác)
    "settings": [
        ("keep", "TopBar", ".", {}),
        ("new", "Panel", ".", {
            "type": "NinePatchRect",
            "props": [
                "layout_mode = 1",
                "anchors_preset = -1",
                "anchor_left = 0.045",
                "anchor_top = 0.145",
                "anchor_right = 0.955",
                "anchor_bottom = 0.975",
                "patch_margin_left = 70",
                "patch_margin_top = 70",
                "patch_margin_right = 70",
                "patch_margin_bottom = 70",
                "texture = ExtResource(\"{surface}\")",
            ],
        }),
        ("new", "Panel/Content", "Panel", {
            "type": "VBoxContainer",
            "props": [
                "layout_mode = 1",
                "anchors_preset = -1",
                "anchor_left = 0.035",
                "anchor_top = 0.04",
                "anchor_right = 0.965",
                "anchor_bottom = 0.96",
                "theme_override_constants/separation = 34",
            ],
        }),
        ("keep", "Panel/Content/Header", "Panel/Content", {}),
        ("new", "Panel/Content/Body", "Panel/Content", {
            "type": "HBoxContainer",
            "props": [
                "layout_mode = 2",
                "size_flags_vertical = 3",
                "theme_override_constants/separation = 80",
            ],
        }),
        ("new", "Panel/Content/Body/ColLeft", "Panel/Content/Body", {
            "type": "VBoxContainer",
            "props": [
                "layout_mode = 2",
                "size_flags_horizontal = 3",
                "theme_override_constants/separation = 34",
            ],
        }),
        ("keep", "Panel/Content/Audio", "Panel/Content/Body/ColLeft", {}),
        ("keep", "Panel/Content/Board", "Panel/Content/Body/ColLeft", {}),
        ("new", "Panel/Content/Body/ColRight", "Panel/Content/Body", {
            "type": "VBoxContainer",
            "props": [
                "layout_mode = 2",
                "size_flags_horizontal = 3",
                "theme_override_constants/separation = 34",
            ],
        }),
        ("keep", "Panel/Content/Language", "Panel/Content/Body/ColRight", {}),
        ("keep", "Panel/Content/Actions", "Panel/Content/Body/ColRight", {}),
        ("keep", "Panel/Content/Footer", "Panel/Content", {}),
    ],
    # §6.3 — Cột trái: khung Lịch Tháng · Cột phải: Streak + Bảng Nhiệm vụ + nút CHƠI
    "daily": [
        ("keep", "TopBar", ".", {
            "set": {
                "anchor_left": "0.03",
                "anchor_top": "0.028",
                "anchor_right": "0.97",
                "anchor_bottom": "0.115",
            },
        }),
        ("patch", "TopBar/Back", "", {
            "set": {"custom_minimum_size": "Vector2(133, 133)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "TopBar/Title", "", {
            "set": {"theme_override_font_sizes/font_size": "71"},
        }),
        ("new", "CalBox", ".", {
            "type": "AspectRatioContainer",
            "props": [
                "layout_mode = 1",
                "anchors_preset = -1",
                "anchor_left = 0.025",
                "anchor_top = 0.135",
                "anchor_right = 1.0",
                "anchor_bottom = 0.965",
                "offset_right = -1090.0",
                "ratio = 1.0",
            ],
        }),
        ("keep", "Calendar", "CalBox", {
            "set": {"layout_mode": "2", "size_flags_horizontal": "3", "size_flags_vertical": "3"},
        }),
        ("keep", "StreakBadge", ".", {
            "set": {"anchor_left": "0.862", "anchor_top": "0.03",
                    "anchor_right": "0.97", "anchor_bottom": "0.113",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("new", "Right", ".", {
            "type": "VBoxContainer",
            "props": [
                "layout_mode = 1",
                "anchors_preset = -1",
                "anchor_left = 1.0",
                "anchor_top = 0.135",
                "anchor_right = 1.0",
                "anchor_bottom = 0.90",
                "offset_left = -1050.0",
                "offset_right = -30.0",
                "theme_override_constants/separation = 34",
            ],
        }),
        ("keep", "Missions", "Right", {
            "set": {"layout_mode": "2", "size_flags_vertical": "3",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("keep", "Play", "Right", {
            "set": {"layout_mode": "2", "size_flags_vertical": "2",
                    "ignore_texture_size": "true", "stretch_mode": "0",
                    "custom_minimum_size": "Vector2(0, 165)"},
        }),
    ],
    # §6.4 (Sổ tay danh hiệu) — Tờ giấy trải rộng, lưới thẻ nhiều cột
    "archivement": [
        ("keep", "TopBar", ".", {
            "set": {"anchor_left": "0.05", "anchor_top": "0.03",
                    "anchor_right": "0.95", "anchor_bottom": "0.10"},
        }),
        ("patch", "TopBar/Back", "", {
            "set": {"custom_minimum_size": "Vector2(133, 133)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "TopBar/Title", "", {
            "set": {"theme_override_font_sizes/font_size": "71"},
        }),
        ("keep", "Sheet", ".", {
            "set": {"anchor_left": "0.05", "anchor_top": "0.125",
                    "anchor_right": "0.95", "anchor_bottom": "0.985",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("patch", "Sheet/Overview", "", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.015",
                    "anchor_right": "0.97", "anchor_bottom": "0.10"},
        }),
        ("patch", "Sheet/Overview/Bar", "", {
            "set": {"anchor_left": "0.05", "anchor_top": "0.52",
                    "anchor_right": "0.62", "anchor_bottom": "0.86"},
        }),
        ("patch", "Sheet/Overview/Bar/Track", "", {
            "set": {"anchor_right": "1.0", "offset_right": "0.0"},
        }),
        ("patch", "Sheet/Overview/Title", "", {
            "set": {"anchor_left": "0.09", "anchor_top": "0.08",
                    "anchor_right": "0.70", "anchor_bottom": "0.5"},
        }),
        ("patch", "Sheet/Overview/Icon", "", {
            "set": {"anchor_left": "0.02", "anchor_top": "0.14",
                    "anchor_right": "0.075", "anchor_bottom": "0.86"},
        }),
        ("patch", "Sheet/Overview/Percent", "", {
            "set": {"anchor_left": "0.66", "anchor_top": "0.05",
                    "anchor_right": "0.80", "anchor_bottom": "0.5"},
        }),
        ("patch", "Sheet/Overview/Summary", "", {
            "set": {"anchor_left": "0.66", "anchor_top": "0.52",
                    "anchor_right": "0.98", "anchor_bottom": "0.95"},
        }),
        ("patch", "Sheet/Tabs", "", {
            "set": {"anchor_left": "0.2", "anchor_top": "0.115",
                    "anchor_right": "0.8", "anchor_bottom": "0.175"},
        }),
        ("patch", "Sheet/CardArea", "", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.19",
                    "anchor_right": "0.97", "anchor_bottom": "0.86"},
        }),
        ("patch", "Sheet/Dots", "", {
            "set": {"anchor_left": "0.4", "anchor_top": "0.875",
                    "anchor_right": "0.6", "anchor_bottom": "0.91"},
        }),
        ("patch", "Sheet/Footer", "", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.915",
                    "anchor_right": "0.97", "anchor_bottom": "0.985"},
        }),
        ("patch", "Sheet/Footer/Stamp", "", {
            # Con dấu phiên bản: ghim vào mép PHẢI của chân trang (bản dọc đặt bằng toạ độ tuyệt đối)
            "set": {"anchor_left": "0.88", "anchor_top": "0.05",
                    "anchor_right": "0.995", "anchor_bottom": "0.95"},
        }),
    ],
    # §6.5 — Bảng xếp hạng NGANG: cột TRÁI (tab + bục vinh danh), cột PHẢI (danh sách cuộn + hàng của bạn)
    "ranking": [
        ("keep", "TopBar", ".", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.028",
                    "anchor_right": "0.97", "anchor_bottom": "0.115"},
        }),
        ("patch", "TopBar/Back", "", {
            "set": {"custom_minimum_size": "Vector2(133, 133)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "TopBar/Title", "", {
            "set": {"theme_override_font_sizes/font_size": "71"},
        }),
        ("keep", "Chip", ".", {
            "set": {"anchor_left": "0.80", "anchor_top": "0.028",
                    "anchor_right": "0.97", "anchor_bottom": "0.113",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("keep", "Sheet", ".", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.125",
                    "anchor_right": "0.97", "anchor_bottom": "0.985"},
        }),
        ("patch", "Sheet/Tape", "", {
            "set": {"anchor_left": "0.04", "anchor_top": "0.0",
                    "anchor_right": "0.13", "anchor_bottom": "0.035"},
        }),
        ("patch", "Sheet/Clip", "", {
            "set": {"anchor_left": "0.005", "anchor_top": "0.0",
                    "anchor_right": "0.035", "anchor_bottom": "0.07"},
        }),
        ("patch", "Sheet/Tabs", "", {
            "set": {"anchor_left": "0.12", "anchor_top": "0.02",
                    "anchor_right": "0.50", "anchor_bottom": "0.08"},
        }),
        ("patch", "Sheet/Divider1", "", {
            "set": {"anchor_left": "0.04", "anchor_top": "0.085",
                    "anchor_right": "0.50", "anchor_bottom": "0.092"},
        }),
        ("patch", "Sheet/Podium", "", {
            # Bục vinh danh giữ NGUYÊN bề rộng thiết kế (bên trong đặt toạ độ tuyệt đối) → canh giữa cột trái
            "set": {"anchor_left": "0.27", "anchor_top": "0.115",
                    "anchor_right": "0.27", "anchor_bottom": "0.43",
                    "offset_left": "-490.0", "offset_right": "490.0"},
        }),
        ("patch", "Sheet/Scroll", "", {
            "set": {"anchor_left": "0.76", "anchor_top": "0.09",
                    "anchor_right": "0.76", "anchor_bottom": "0.83",
                    "offset_left": "-420.0", "offset_right": "420.0"},
        }),
        ("patch", "Sheet/MyRank", "", {
            "set": {"anchor_left": "0.76", "anchor_top": "0.855",
                    "anchor_right": "0.76", "anchor_bottom": "0.925",
                    "offset_left": "-420.0", "offset_right": "420.0"},
        }),
        ("patch", "Sheet/Footer", "", {
            "set": {"anchor_left": "0.56", "anchor_top": "0.94",
                    "anchor_right": "0.74", "anchor_bottom": "0.985"},
        }),
        ("patch", "Sheet/FooterNote", "", {
            "set": {"anchor_left": "0.78", "anchor_top": "0.94",
                    "anchor_right": "0.96", "anchor_bottom": "0.985"},
        }),
    ],
    # §6.5 — Cửa hàng NGANG: tab hàng ngang giữa trang, lưới ô nở 2→4 cột, banner + phân trang neo đáy
    "shop": [
        ("keep", "TopBar", ".", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.028",
                    "anchor_right": "0.62", "anchor_bottom": "0.118"},
        }),
        ("patch", "TopBar/Back", "", {
            "set": {"custom_minimum_size": "Vector2(133, 133)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "TopBar/Title", "", {
            "set": {"theme_override_font_sizes/font_size": "71"},
        }),
        ("keep", "Wallet", ".", {
            "set": {"anchor_left": "0.80", "anchor_top": "0.028",
                    "anchor_right": "0.97", "anchor_bottom": "0.108",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("keep", "Tabs", ".", {
            # Hàng tab canh giữa trang (bề rộng cố định — tab do script dàn theo bề rộng này)
            "set": {"anchor_left": "0.5", "anchor_top": "0.135",
                    "anchor_right": "0.5", "anchor_bottom": "0.205",
                    "offset_left": "-700.0", "offset_right": "700.0"},
        }),
        ("keep", "TabLine", ".", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.207",
                    "anchor_right": "0.5", "anchor_bottom": "0.215",
                    "offset_left": "-700.0", "offset_right": "700.0"},
        }),
        ("keep", "Content", ".", {
            "set": {"anchor_left": "0.06", "anchor_top": "0.235",
                    "anchor_right": "0.94", "anchor_bottom": "0.80"},
        }),
        ("keep", "Pager", ".", {
            "set": {"anchor_left": "0.06", "anchor_top": "0.812",
                    "anchor_right": "0.94", "anchor_bottom": "0.858"},
        }),
        ("keep", "GiftBanner", ".", {
            "set": {"anchor_left": "0.06", "anchor_top": "0.866",
                    "anchor_right": "0.94", "anchor_bottom": "0.945",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("keep", "Footer", ".", {
            "set": {"anchor_left": "0.06", "anchor_top": "0.95",
                    "anchor_right": "0.94", "anchor_bottom": "0.985"},
        }),
    ],
    # §7.1 — MÀN CHƠI NGANG: cột TRÁI = bàn cờ; cột PHẢI = Status (header) · HUD · Tip · thanh nút
    # (giữ NGUYÊN tên + đường dẫn node như bản dọc: các `@export NodePath` của Controllers trỏ
    #  `../../Board`, `../../Status/...`, `../../Button/...` nên KHÔNG được đổi cấu trúc)
    "game": [
        ("keep", "Controllers", ".", {}),
        # Bàn cờ: cột TRÁI — phải bỏ min 1020 của board.tscn, nếu không bàn cờ đè lên sidebar ở canvas hẹp
        ("keep", "Board", ".", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.055",
                    "anchor_right": "0.53", "anchor_bottom": "0.94",
                    "custom_minimum_size": "Vector2(0, 0)"},
        }),
        # Sidebar PHẢI: 1 VBoxContainer theo TỈ LỆ (0.56→0.985) — KHÔNG dùng bề rộng cứng, tránh đè bàn cờ
        ("new", "Side", ".", {
            "type": "VBoxContainer",
            "props": [
                "layout_mode = 1",
                "anchors_preset = -1",
                "anchor_left = 0.56",
                "anchor_top = 0.055",
                "anchor_right = 0.985",
                "anchor_bottom = 0.945",
                "theme_override_constants/separation = 26",
            ],
        }),
        ("keep", "Status", "Side", {
            "set": {"layout_mode": "2", "size_flags_vertical": "0",
                    "custom_minimum_size": "Vector2(0, 140)"},
        }),
        ("patch", "Status/Pause", "", {
            "set": {"custom_minimum_size": "Vector2(124, 124)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "Status/Instruction", "", {
            "set": {"custom_minimum_size": "Vector2(124, 124)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "Status/Restart", "", {
            "set": {"custom_minimum_size": "Vector2(124, 124)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        # Khung HUD: rộng bằng sidebar; `game.gd` tự thu nhỏ (scale) nếu sidebar hẹp hơn 980
        ("keep", "Information", "Side", {
            "set": {"layout_mode": "2", "size_flags_horizontal": "3", "size_flags_vertical": "0",
                    "custom_minimum_size": "Vector2(0, 260)"},
        }),
        ("keep", "HintGuide", "Side", {
            "set": {"layout_mode": "2", "size_flags_vertical": "0",
                    "custom_minimum_size": "Vector2(0, 140)"},
        }),
        ("keep", "Button", "Side", {
            "set": {"layout_mode": "2", "size_flags_vertical": "0",
                    "custom_minimum_size": "Vector2(0, 240)"},
        }),
        ("patch", "Button/Undo", "", {
            "set": {"custom_minimum_size": "Vector2(130, 180)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "Button/Hint", "", {
            "set": {"custom_minimum_size": "Vector2(130, 180)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "Button/Tool", "", {
            "set": {"custom_minimum_size": "Vector2(0, 180)",
                    "ignore_texture_size": "true", "stretch_mode": "0",
                    "size_flags_horizontal": "3"},
        }),
        ("patch", "Button/Wall", "", {
            "set": {"custom_minimum_size": "Vector2(0, 180)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("keep", "Replay", "Side", {
            "set": {"layout_mode": "2", "size_flags_vertical": "3",
                    "custom_minimum_size": "Vector2(0, 170)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
    ],
    # Splash / Title: tờ giấy phủ kín canvas, khối nội dung CANH GIỮA (anchors), con dấu góc dưới-phải
    "splash": [
        ("keep", "Panel", ".", {
            "set": {"anchor_left": "0.0", "anchor_top": "0.0",
                    "anchor_right": "1.0", "anchor_bottom": "1.0",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("patch", "Panel/StudioLabel", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.06", "anchor_right": "0.5",
                    "anchor_bottom": "0.12", "offset_left": "-600.0", "offset_right": "600.0"},
        }),
        ("patch", "Panel/LogoContainer", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.28", "anchor_right": "0.5",
                    "anchor_bottom": "0.52", "offset_left": "-420.0", "offset_right": "420.0"},
        }),
        ("patch", "Panel/Title", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.56", "anchor_right": "0.5",
                    "anchor_bottom": "0.66", "offset_left": "-700.0", "offset_right": "700.0"},
        }),
        ("patch", "Panel/Tagline", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.67", "anchor_right": "0.5",
                    "anchor_bottom": "0.74", "offset_left": "-700.0", "offset_right": "700.0"},
        }),
        ("patch", "Panel/HintTap", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.84", "anchor_right": "0.5",
                    "anchor_bottom": "0.90", "offset_left": "-500.0", "offset_right": "500.0"},
        }),
        ("patch", "Panel/Stamp", "", {
            "set": {"anchor_left": "1.0", "anchor_top": "1.0", "anchor_right": "1.0",
                    "anchor_bottom": "1.0", "offset_left": "-460.0", "offset_top": "-250.0",
                    "offset_right": "-120.0", "offset_bottom": "-80.0"},
        }),
        ("keep", "TouchButton", ".", {
            "set": {"anchor_left": "0.0", "anchor_top": "0.0",
                    "anchor_right": "1.0", "anchor_bottom": "1.0"},
        }),
    ],
    "title": [
        ("keep", "Panel", ".", {
            "set": {"anchor_left": "0.0", "anchor_top": "0.0",
                    "anchor_right": "1.0", "anchor_bottom": "1.0",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("patch", "Panel/LogoContainer", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.20", "anchor_right": "0.5",
                    "anchor_bottom": "0.46", "offset_left": "-420.0", "offset_right": "420.0"},
        }),
        ("patch", "Panel/Title", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.50", "anchor_right": "0.5",
                    "anchor_bottom": "0.62", "offset_left": "-700.0", "offset_right": "700.0"},
        }),
        ("patch", "Panel/Subtitle", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.63", "anchor_right": "0.5",
                    "anchor_bottom": "0.70", "offset_left": "-700.0", "offset_right": "700.0"},
        }),
        ("patch", "Panel/TapContainer", "", {
            "set": {"anchor_left": "0.5", "anchor_top": "0.78", "anchor_right": "0.5",
                    "anchor_bottom": "0.88", "offset_left": "-420.0", "offset_right": "420.0"},
        }),
        ("patch", "Panel/Stamp", "", {
            "set": {"anchor_left": "1.0", "anchor_top": "1.0", "anchor_right": "1.0",
                    "anchor_bottom": "1.0", "offset_left": "-460.0", "offset_top": "-250.0",
                    "offset_right": "-120.0", "offset_bottom": "-80.0"},
        }),
    ],
    # Credit / Debug: tờ giấy phủ kín canvas + khung nội dung trải rộng (danh sách chữ tự dàn)
    "credit": [
        ("keep", "TopBar", ".", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.03",
                    "anchor_right": "0.97", "anchor_bottom": "0.115"},
        }),
        ("patch", "TopBar/Back", "", {
            "set": {"custom_minimum_size": "Vector2(133, 133)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "TopBar/Title", "", {
            "set": {"theme_override_font_sizes/font_size": "71"},
        }),
        ("keep", "Panel", ".", {
            "set": {"anchor_left": "0.06", "anchor_top": "0.14",
                    "anchor_right": "0.94", "anchor_bottom": "0.98",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("patch", "Panel/Content", "", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.03",
                    "anchor_right": "0.97", "anchor_bottom": "0.97"},
        }),
        ("patch", "Panel/Washi", "", {
            "set": {"anchor_left": "0.08", "anchor_top": "0.0", "anchor_right": "0.28",
                    "anchor_bottom": "0.03"},
        }),
        ("patch", "Panel/Clip", "", {
            "set": {"anchor_left": "0.9", "anchor_top": "0.0", "anchor_right": "0.97",
                    "anchor_bottom": "0.06"},
        }),
    ],
    "debug": [
        ("keep", "TopBar", ".", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.03",
                    "anchor_right": "0.97", "anchor_bottom": "0.115"},
        }),
        ("patch", "TopBar/Back", "", {
            "set": {"custom_minimum_size": "Vector2(133, 133)",
                    "ignore_texture_size": "true", "stretch_mode": "0"},
        }),
        ("patch", "TopBar/Title", "", {
            "set": {"theme_override_font_sizes/font_size": "71"},
        }),
        ("keep", "Panel", ".", {
            "set": {"anchor_left": "0.06", "anchor_top": "0.14",
                    "anchor_right": "0.94", "anchor_bottom": "0.98",
                    "expand_mode": "1", "stretch_mode": "0"},
        }),
        ("patch", "Panel/Content", "", {
            "set": {"anchor_left": "0.03", "anchor_top": "0.03",
                    "anchor_right": "0.97", "anchor_bottom": "0.97"},
        }),
    ],
}


def split_blocks(text: str) -> tuple[str, list[str]]:
    """Tách file .tscn thành (header, danh sách block node giữ nguyên chuỗi gốc)."""
    lines = text.splitlines(keepends=True)
    first = next(i for i, l in enumerate(lines) if l.startswith("[node "))
    header = "".join(lines[:first])
    body = "".join(lines[first:])
    blocks = [b for b in re.split(r"(?=^\[node )", body, flags=re.M) if b.strip()]
    return header, blocks


def block_info(block: str) -> tuple[str, str]:
    """(đường dẫn node, cha) đọc từ dòng `[node name="X" ... parent="Y"]`."""
    head = block.splitlines()[0]
    name = re.search(r'name="([^"]*)"', head)
    parent = re.search(r'parent="([^"]*)"', head)
    path = name.group(1)
    if parent and parent.group(1) != ".":
        path = f"{parent.group(1)}/{path}"
    return path, (parent.group(1) if parent else ".")


def rewrite_block(block: str, new_parent: str, strip_index: bool) -> str:
    lines = block.splitlines(keepends=True)
    head = lines[0]
    head = re.sub(r' parent="[^"]*"', f' parent="{new_parent}"', head)
    if strip_index:
        head = re.sub(r' index="\d+"', "", head)
    lines[0] = head
    return "".join(lines)


def child_paths(path: str, all_paths: list[str]) -> list[str]:
    prefix = path + "/"
    return [p for p in all_paths if p.startswith(prefix)]


def patch_props(block: str, changes: dict[str, str]) -> str:
    """Đặt/ghi đè vài thuộc tính của block (dùng cho node 'keep' ở bản ngang).

    Nếu có đổi `anchor_*` thì TỰ ĐỘNG đưa 4 offset về 0 (bản dọc đang ghi toạ độ tuyệt đối
    vào offset — giữ nguyên thì node sẽ lệch ra ngoài canvas).
    """
    changes = dict(changes)
    if any(k.startswith("anchor_") for k in changes):
        for key in ("offset_left", "offset_top", "offset_right", "offset_bottom"):
            changes.setdefault(key, "0.0")
        # QUAN TRỌNG: `layout_mode = 0` (chế độ Position) sẽ XOÁ anchors khi Godot nạp scene
        # ⇒ node được gắn anchors phải chuyển sang `layout_mode = 1` (chế độ Anchors).
        changes["layout_mode"] = "1"
        # `anchors_preset = 0` (preset TOP_LEFT) cũng XOÁ anchors ⇒ phải đặt về -1 (custom)
        changes["anchors_preset"] = "-1"
    for prop, value in changes.items():
        line = f"{prop} = {value}"
        if re.search(rf"^{re.escape(prop)} = .*$", block, flags=re.M):
            block = re.sub(rf"^{re.escape(prop)} = .*$", line, block, flags=re.M, count=1)
        else:
            lines = block.splitlines(keepends=True)
            head = lines[0]
            rest = "".join(lines[1:])
            block = head + line + "\n" + rest
    return block


def build(screen: str) -> None:
    """Dựng layout ngang cho 1 màn từ bản dọc (theo SPEC + bảng PATH_REWRITES)."""
    spec = SPECS.get(screen)
    if spec is None:
        print(f"  !! chưa có SPEC cho '{screen}'")
        return
    src = ROOT / "scenes" / "orientation" / "portrait" / f"{screen}.tscn"
    if not src.exists():
        print(f"  !! thiếu {src.relative_to(ROOT)} — chạy split_screen_layouts.py trước")
        return
    text = src.read_text(encoding="utf-8")
    header, blocks = split_blocks(text)
    by_path = {block_info(b)[0]: b for b in blocks}
    all_paths = list(by_path.keys())

    # header mới: bỏ node của scaffold portrait, thêm scaffold landscape
    ext_lines = [l for l in header.splitlines(keepends=True) if l.startswith("[ext_resource")]
    ext_lines = [l for l in ext_lines
                 if "scenes/orientation/portrait/portrait.tscn" not in l
                 and "scenes/orientation/landscape/landscape.tscn" not in l]
    surface = next((l for l in ext_lines if "panel" in l.lower() and "Texture2D" in l), "")
    # ` id="..."` (có dấu cách) — tránh bắt nhầm `uid="..."` khi chỉ tìm `id="`
    surface_id = re.search(r' id="([^"]*)"', surface).group(1) if surface else "surface"
    header_out = "[gd_scene format=3]\n\n"
    header_out += f'[ext_resource type="PackedScene" path="{LANDSCAPE_SCENE}" id="1_parent"]\n'
    header_out += "".join(ext_lines) + "\n\n"

    out: list[str] = []
    patches = {p[1]: p[3].get("set", {}) for p in spec if p[0] == "patch"}
    containers = {
        p[1] for p in spec if p[0] == "new"
        and p[3].get("type") in ("VBoxContainer", "HBoxContainer", "GridContainer", "CenterContainer")
    }
    for kind, node_path, parent, extra in spec:
        if kind == "patch":
            continue
        if kind == "new":
            props = "\n".join(p.format(surface=surface_id) for p in extra.get("props", []))
            out.append(f'[node name="{node_path.split("/")[-1]}" type="{extra["type"]}" '
                       f'parent="{parent}"]\n{props}\n\n')
            continue
        block = by_path.get(node_path)
        if block is None:
            print(f"  !! không thấy node '{node_path}' trong bản dọc")
            continue
        keep_parent = parent
        new_path = node_path.split("/")[-1] if parent == "." else f"{parent}/{node_path.split('/')[-1]}"
        block = patch_props(rewrite_block(block, keep_parent, strip_index=True),
                            extra.get("set", {}))
        if keep_parent in containers and "anchor_left" not in extra.get("set", {}):
            block = re.sub(r"^layout_mode = 1$", "layout_mode = 2", block, flags=re.M)
            block = re.sub(r"^(anchors_preset|anchor_[a-z]*|offset_[a-z]*|grow_[a-z]*) = .*\n",
                           "", block, flags=re.M)
        out.append(block)
        for desc in child_paths(node_path, all_paths):
            sub = desc[len(node_path):]
            sub_block = by_path[desc]
            _, old_parent = block_info(sub_block)
            new_parent = new_path + old_parent[len(node_path):]
            block_text = rewrite_block(sub_block, new_parent, strip_index=False)
            if desc in patches:
                block_text = patch_props(block_text, patches[desc])
            # node nằm trong container: bỏ anchor/offset (container tự dàn)
            if new_parent in ("Panel/Content/Body", "Panel/Content/Body/ColLeft",
                              "Panel/Content/Body/ColRight", "Panel/Content"):
                block_text = re.sub(r"^layout_mode = 1$", "layout_mode = 2", block_text, flags=re.M)
                block_text = re.sub(r"^(anchors_preset|anchor_[a-z]*|offset_[a-z]*|grow_[a-z]*) = .*\n",
                                    "", block_text, flags=re.M)
            out.append(block_text)

    root_block = ('[node name="Landscape" instance=ExtResource("1_parent")]\n'
                  + "\n".join(ROOT_PROPS) + "\n\n")
    text_out = header_out + root_block + "".join(out)
    for old, new in PATH_REWRITES.get(screen, []):
        text_out = text_out.replace(old, new)
    dst = ROOT / "scenes" / "orientation" / "landscape" / f"{screen}.tscn"
    dst.write_text(text_out, encoding="utf-8")
    print(f"  OK {screen}: {len(out)} node → {dst.relative_to(ROOT)}")


def main() -> None:
    names = sys.argv[1:]
    if not names:
        print(__doc__)
        return
    for name in names:
        build(name)


if __name__ == "__main__":
    main()
