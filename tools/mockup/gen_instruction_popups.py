#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh 9 scene popup hướng dẫn: nodes/popups/instruction/<mode>.tscn.

Mỗi scene = instance của base.tscn (script thay bằng instruction_popup.gd),
trong đó mọi thứ của mockup được "nướng" thẳng vào scene:

  Panel/Guide
    ├── Washi, Paper, PaperDetail, Close          (khung giấy)
    └── Pages/Page1..3
          ├── Img          (ảnh minh hoạ, đã xử lý ThorVG-safe)
          ├── Title, Section, 3 hàng luật (Row1..3), các Label chữ trên ảnh (PT#)
          ├── Tabs/Tab1..3 (nút + vòng số vẽ bằng node)
          ├── Prev, Next, Dots/Dot1..3, Index
          └── Cta, Link

Toạ độ dùng hệ "paper-local" (gốc = góc trên-trái tờ giấy 920x1480).
Chữ dùng khoá dịch STR_GI_* lấy từ tools/content/_guide_keys.json.

Chạy: python tools/mockup/gen_instruction_popups.py [--check]
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "mockup"))
import instruction_mockup as im   # noqa: E402

KEYS_PATH = ROOT / "tools" / "content" / "_guide_keys.json"
OUT_DIR = ROOT / "nodes" / "popups" / "instruction"
CHROME_DIR = "res://assets/images/instructions"
GUIDE_IMG_DIR = "res://assets/images/instructions/guideline_image"
FONT_DIR = "res://assets/fonts/Be_Vietnam_Pro"
BASE_SCENE = "res://nodes/popups/base.tscn"
BASE_UID = "uid://j75ew1kc04k7"
SCRIPT_PATH = "res://scripts/nodes/popups/instruction_popup.gd"

PAPER_W, PAPER_H = 920.0, 1480.0
PANEL = {"x": 105.0, "y": 210.0, "w": 755.0, "h": 510.0}
IMG_RECT = {"x": 90.0, "y": 200.0, "w": 785.0, "h": 535.0}
SECTION_BASELINE = 779.0
ROW0_Y = 797.0
ROW_H = 76.0
ROW_STEP = 88.0
NAV_Y = 1100.0
NAV_SIZE = 52.0
INDEX_RIGHT = 860.0
INDEX_BASELINE = 1134.0
CTA_RECT = {"x": 105.0, "y": 1180.0, "w": 755.0, "h": 100.0}
LINK_CENTER_Y = 1316.0
LINK_H = 56.0
CLOSE_RECT = {"x": 830.0, "y": 24.0, "w": 56.0, "h": 56.0}

# — chome dùng chung cho cả 3 trang —
TAB_RING = 26.0        # đường kính vòng số thứ tự tab
TAB_GAP = 6.0          # khoảng cách vòng số -> chữ tab
DOTS_X0 = 185.0        # mép trái hàng dots (paper-local, giống mọi mockup)
DOTS_GAP = 12.0        # khoảng cách giữa các dot
DOTS_CY = 1125.0       # tâm dọc hàng dots
# Màu nút ‹ › khi bị khoá — giống nhau ở mọi chế độ theo mockup:
#   prev: mờ xanh · next: mờ xám
NAV_OFF_FG = {"prev": "#224C6D", "next": "#718B9E"}
NAV_OFF_BORDER = {"prev": "#6EA0C8", "next": "#BACEDC"}

FONT_FILES = {
    "black": f"{FONT_DIR}/BeVietnamPro-Black.ttf",
    "xb": f"{FONT_DIR}/BeVietnamPro-ExtraBold.ttf",
    "bold": f"{FONT_DIR}/BeVietnamPro-Bold.ttf",
    "sb": f"{FONT_DIR}/BeVietnamPro-SemiBold.ttf",
    "med": f"{FONT_DIR}/BeVietnamPro-Medium.ttf",
    "reg": f"{FONT_DIR}/BeVietnamPro-Regular.ttf",
}
_SUBST = {"➔": "•", "➜": "•"}


def pick_weight(weight: str) -> str:
    try:
        w = int(float(weight or "400"))
    except ValueError:
        w = 400
    if w >= 900:
        return "black"
    if w >= 800:
        return "xb"
    if w >= 700:
        return "bold"
    if w >= 600:
        return "sb"
    if w >= 500:
        return "med"
    return "reg"


class Metrics:
    """Đo chữ bằng chính file font (đơn vị font -> px theo font-size)."""

    def __init__(self) -> None:
        self._fonts: dict = {}

    def _font(self, key: str):
        if key not in self._fonts:
            f = TTFont(str(ROOT / FONT_FILES[key].replace("res://", "")))
            self._fonts[key] = {
                "cmap": f.getBestCmap(),
                "glyphset": f.getGlyphSet(),
                "upem": f["head"].unitsPerEm,
                "ascent": f["hhea"].ascent,
                "descent": f["hhea"].descent,
            }
        return self._fonts[key]

    def width(self, text: str, weight: str, size: float) -> float:
        f = self._font(pick_weight(weight))
        total = 0.0
        for ch in text:
            name = f["cmap"].get(ord(ch))
            if name is None:
                total += f["upem"] * 0.55
                continue
            total += f["glyphset"][name].width
        return total * size / f["upem"]

    def ascent(self, weight: str, size: float) -> float:
        f = self._font(pick_weight(weight))
        return f["ascent"] * size / f["upem"]

    def height(self, weight: str, size: float) -> float:
        f = self._font(pick_weight(weight))
        return (f["ascent"] - f["descent"]) * size / f["upem"]


class Scene:
    """Gom text .tscn cho một popup."""

    def __init__(self, uid: str, unique_id: str) -> None:
        self.uid = uid
        self.unique_id = unique_id
        self.ext_lines: list[str] = []
        self.sub: list[str] = []
        self.nodes: list[str] = []
        self._ext_ids: dict[str, str] = {}
        self._n_ext = 0
        self._n_sub = 0
        self._sb_cache: dict = {}
        self._sb_count = 0

    # ------------------------------------------------------------ resources
    def ext(self, self_id: str, type_: str, path: str, uid: str = "") -> str:
        if self_id in self._ext_ids:
            return self._ext_ids[self_id]
        self._n_ext += 1
        key = f"{self._n_ext}_{self_id}"
        self._ext_ids[self_id] = key
        uid_attr = f' uid="{uid}"' if uid else ""
        self.ext_lines.append(
            f'[ext_resource type="{type_}"{uid_attr} path="{path}" id="{key}"]')
        return key

    def sub_stylebox(self, params: dict) -> str:
        key = json.dumps(params, sort_keys=True)
        if key in self._sb_cache:
            return self._sb_cache[key]
        self._n_sub += 1
        sid = f"sb{self._n_sub}"
        self._sb_cache[key] = sid
        lines = [f'[sub_resource type="StyleBoxFlat" id="{sid}"]']
        bg = params.get("bg")
        if bg is not None:
            lines.append(f'bg_color = {bg}')
        for side, attr in (("left", "border_width_left"), ("top", "border_width_top"),
                           ("right", "border_width_right"), ("bottom", "border_width_bottom")):
            if params.get("bw"):
                lines.append(f"{attr} = {params['bw']}")
        if params.get("bw") and params.get("border"):
            lines.append(f'border_color = {params["border"]}')
        r = params.get("radius")
        if r is not None:
            lines.append(f"corner_radius_top_left = {r}")
            lines.append(f"corner_radius_top_right = {r}")
            lines.append(f"corner_radius_bottom_right = {r}")
            lines.append(f"corner_radius_bottom_left = {r}")
        self.sub.append("\n".join(lines))
        return sid

    def stylebox_empty(self) -> str:
        key = json.dumps({"empty": True}, sort_keys=True)
        if key in self._sb_cache:
            return self._sb_cache[key]
        self._n_sub += 1
        sid = f"sb{self._n_sub}"
        self._sb_cache[key] = sid
        self.sub.append(f'[sub_resource type="StyleBoxEmpty" id="{sid}"]')
        return sid

    # ---------------------------------------------------------------- nodes
    def node(self, name: str, type_: str, parent: str, props: list[str],
             head_extra: str = "") -> None:
        parent_attr = f' parent="{parent}"' if parent else ""
        self.nodes.append(f'[node name="{name}" type="{type_}"{parent_attr}{head_extra}]\n'
                          + "\n".join(props))

    def finish(self) -> str:
        head = f'[gd_scene load_steps={self._n_ext + self._n_sub + 1} format=3'
        if self.uid:
            head += f' uid="{self.uid}"'
        head += "]"
        return "\n\n".join([head] + self.ext_lines + self.sub + self.nodes) + "\n"


def col(hex_color: str, alpha: float = 1.0, fallback: str = "#00000000") -> str:
    """'#RRGGBB' -> 'Color(r, g, b, a)' cho tscn."""
    s = (hex_color or fallback).lstrip("#")
    if s in ("none", ""):
        s = fallback.lstrip("#")
    if len(s) == 3:
        s = "".join(c * 2 for c in s)
    if len(s) == 8:
        a = int(s[6:8], 16) / 255.0
        s = s[:6]
    else:
        a = 1.0
    r, g, b = (int(s[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return "Color(%g, %g, %g, %g)" % (round(r, 4), round(g, 4), round(b, 4), round(a * alpha, 4))


class Builder:
    def __init__(self, mode: str, pages: dict, keymap: dict, metrics: Metrics) -> None:
        self.mode = mode
        self.pages = pages
        self.km = keymap["modes"][mode]
        self.metrics = metrics
        self.styles: dict = {}

    # ------------------------------------------------------------------ util
    def key(self, field: str, vi: str) -> str:
        """Lấy khoá dịch cho chữ: chrome -> map theo mode/page, panel -> STR_GI_X###."""
        if field == "panel":
            return self.km_panel(vi)
        return vi

    def km_panel(self, vi: str) -> str:
        return self._panel_keys[vi]

    # -------------------------------------------------------------- labels
    def label(self, sc: Scene, name: str, parent: str, rect: tuple, text: str,
              size: float, weight: str, fill: str, align_h: int = 0, align_v: int = 0,
              alpha: float = 1.0) -> None:
        props = []
        x, y, w, h = rect
        props.append("offset_left = %g" % round(x, 1))
        props.append("offset_top = %g" % round(y, 1))
        props.append("offset_right = %g" % round(x + w, 1))
        props.append("offset_bottom = %g" % round(y + h, 1))
        props.append("mouse_filter = 2")
        font_key = sc.ext(f"font_{pick_weight(weight)}", "FontFile",
                          FONT_FILES[pick_weight(weight)])
        props.append(f'theme_override_fonts/font = ExtResource("{font_key}")')
        props.append(f"theme_override_font_sizes/font_size = {int(round(size))}")
        props.append(f"theme_override_colors/font_color = {col(fill, alpha)}")
        if align_h:
            props.append(f"horizontal_alignment = {align_h}")
        if align_v:
            props.append(f"vertical_alignment = {align_v}")
        props.append(f'text = "{esc(text)}"')
        sc.node(name, "Label", parent, props)

    def baseline_label(self, sc: Scene, name: str, parent: str, bx: float, by: float,
                       text: str, size: float, weight: str, fill: str,
                       anchor: str = "start", center: bool = False, extra: float = 0.0) -> None:
        """Label đặt đúng baseline trong mockup (đo bề rộng để căn trái/giữa/phải)."""
        if center:
            by += size * 0.35
        w = self.metrics.width(text, weight, size)
        x = bx - (w * 0.5 if anchor == "middle" else (w if anchor == "end" else 0.0))
        h = size * 1.5
        top = by - self.metrics.ascent(weight, size)
        self.label(sc, name, parent, (x, top, w + extra + 4.0, h), text, size, weight, fill)

    # ------------------------------------------------------------ segments
    def build(self, uid: str, unique_id: str, panel_keys: dict) -> str:
        self._panel_keys = panel_keys
        sc = Scene(uid, unique_id)
        base_id = sc.ext("base", "PackedScene", BASE_SCENE, BASE_UID)
        script_id = sc.ext("script", "Script", SCRIPT_PATH)

        # --- root (kế thừa base.tscn) + style tab/dot nướng qua @export ---
        exports = self.build_shared_styles(sc)
        extra = f' unique_id={unique_id}' if unique_id else ""
        root_props = [f'script = ExtResource("{script_id}")'] + exports
        sc.nodes.append(f'[node name="Base"{extra} instance=ExtResource("{base_id}")]\n'
                        + "\n".join(root_props))
        sc.nodes.append('[node name="Panel" parent="." index="1"]\n'
                        'offset_left = 80.0\noffset_top = 200.0\n'
                        'offset_right = 1000.0\noffset_bottom = 1680.0')
        sc.nodes.append('[node name="Art" parent="Panel" index="0"]\nvisible = false')

        # --- khung giấy ---
        p1 = self.pages[1]
        paper_sb = sc.sub_stylebox({
            "bg": col(p1["paper_bg"]), "radius": 26, "bw": 3.5,
            "border": col(p1["accent"])})
        sc.node("Guide", "Control", "Panel",
                ["layout_mode = 1", "anchors_preset = 0",
                 f"offset_right = {PAPER_W:g}", f"offset_bottom = {PAPER_H:g}",
                 "mouse_filter = 2"])

        washi_key = sc.ext("washi", "Texture2D", f"{CHROME_DIR}/guide_washi.svg")
        detail_key = sc.ext("detail", "Texture2D", f"{CHROME_DIR}/guide_paper_detail.svg")
        close_n = sc.ext("close_n", "Texture2D", f"{CHROME_DIR}/btn_guide_close_normal.svg")
        close_p = sc.ext("close_p", "Texture2D", f"{CHROME_DIR}/btn_guide_close_pressed.svg")

        sc.node("Washi", "TextureRect", "Panel/Guide",
                ["layout_mode = 0", "offset_left = 350", "offset_top = -22",
                 "offset_right = 570", "offset_bottom = 24", "mouse_filter = 2",
                 f'texture = ExtResource("{washi_key}")'])
        sc.node("Paper", "Panel", "Panel/Guide",
                ["layout_mode = 0", f"offset_right = {PAPER_W:g}",
                 f"offset_bottom = {PAPER_H:g}", "mouse_filter = 2",
                 f'theme_override_styles/panel = SubResource("{paper_sb}")'])
        sc.node("PaperDetail", "TextureRect", "Panel/Guide",
                ["layout_mode = 0", f"offset_right = {PAPER_W:g}",
                 f"offset_bottom = {PAPER_H:g}", "mouse_filter = 2",
                 f'texture = ExtResource("{detail_key}")'])
        sc.node("Close", "TextureButton", "Panel/Guide",
                ["layout_mode = 0",
                 f"offset_left = {CLOSE_RECT['x']:g}", f"offset_top = {CLOSE_RECT['y']:g}",
                 f"offset_right = {CLOSE_RECT['x'] + CLOSE_RECT['w']:g}",
                 f"offset_bottom = {CLOSE_RECT['y'] + CLOSE_RECT['h']:g}",
                 f'texture_normal = ExtResource("{close_n}")',
                 f'texture_pressed = ExtResource("{close_p}")'])

        # --- chrome DÙNG CHUNG cho cả 3 trang ---
        self.build_chip(sc)
        self.build_tabs(sc)
        sc.node("Pages", "Control", "Panel/Guide",
                ["layout_mode = 1", "anchors_preset = 15", "anchor_right = 1.0",
                 "anchor_bottom = 1.0", "grow_horizontal = 2", "grow_vertical = 2",
                 "mouse_filter = 2"])
        for p in (1, 2, 3):
            self.build_page(sc, p)
        self.build_nav(sc)
        self.build_dots(sc)
        self.build_index(sc)
        return sc.finish()

    def build_shared_styles(self, sc: Scene) -> list:
        """Sub-resource style cho tab/dot + các dòng @export gắn lên root scene.

        Tab/dots là node DÙNG CHUNG — trạng thái chọn đổi theo trang do script
        gán lại stylebox, nên cả 2 bộ style đều nướng sẵn trong scene.
        """
        p1 = self.pages[1]
        on_tab = next((t for t in p1["tabs_style"] if t["on"]), p1["tabs_style"][0])
        off_tab = next((t for t in p1["tabs_style"] if not t["on"]), p1["tabs_style"][-1])
        on_dot = next((d for d in p1["dots"] if d["on"]), p1["dots"][0])
        off_dot = next((d for d in p1["dots"] if not d["on"]), p1["dots"][1])

        def tab_sb(st):
            return {"bg": col(st["fill"]), "radius": 14,
                    "bw": 2.0 if st["stroke"] else 0.0,
                    "border": col(st["stroke"] or "#00000000")}

        sb_on = sc.sub_stylebox(tab_sb(on_tab))
        sb_off = sc.sub_stylebox(tab_sb(off_tab))
        ring_on = sc.sub_stylebox({"bg": col("#00000000"), "radius": 13, "bw": 2.2,
                                   "border": col(on_tab["text_fill"])})
        ring_off = sc.sub_stylebox({"bg": col("#00000000"), "radius": 13, "bw": 2.2,
                                    "border": col(off_tab["text_fill"])})
        dot_on = sc.sub_stylebox({"bg": col(on_dot.get("fill", "#F59E0B")), "radius": 9})
        dot_off = sc.sub_stylebox({"bg": col(off_dot.get("fill", "#D1E2ED")), "radius": 8})
        self.styles = {
            "tab_on": sb_on, "tab_off": sb_off, "ring_on": ring_on, "ring_off": ring_off,
            "dot_on": dot_on, "dot_off": dot_off,
            "on_text": on_tab["text_fill"], "off_text": off_tab["text_fill"],
            "tab_size": on_tab["text_size"], "tab_weight": "900",
        }
        return [
            f'tab_on_style = SubResource("{sb_on}")',
            f'tab_off_style = SubResource("{sb_off}")',
            f'tab_on_ring_style = SubResource("{ring_on}")',
            f'tab_off_ring_style = SubResource("{ring_off}")',
            f'tab_on_text_color = {col(on_tab["text_fill"])}',
            f'tab_off_text_color = {col(off_tab["text_fill"])}',
            f'dot_on_style = SubResource("{dot_on}")',
            f'dot_off_style = SubResource("{dot_off}")',
        ]

    def build_chip(self, sc: Scene) -> None:
        p1 = self.pages[1]
        chip_key, chip_vi = self.km["chip"]
        chip = p1["chip_rect"]
        chip_sb = sc.sub_stylebox({
            "bg": col(p1["chip_bg"]), "radius": 8,
            "bw": 2.0 if p1["chip_stroke"] else 0.0, "border": col(p1["chip_stroke"] or "#00000000")})
        sc.node("Chip", "Panel", "Panel/Guide",
                ["layout_mode = 0", f"offset_left = {chip['x']:g}", f"offset_top = {chip['y']:g}",
                 f"offset_right = {chip['x'] + chip['w']:g}",
                 f"offset_bottom = {chip['y'] + chip['h']:g}", "mouse_filter = 2",
                 f'theme_override_styles/panel = SubResource("{chip_sb}")'])
        self.label(sc, "ChipText", "Panel/Guide",
                   (chip["x"], chip["y"], chip["w"], chip["h"]), chip_key,
                   p1["chip_size"], p1["chip_weight"], p1["chip_fg"], 1, 1)

    def build_tabs(self, sc: Scene) -> None:
        """Một hàng tab DÙNG CHUNG cho cả 3 trang (script đổi màu theo trang)."""
        geom = self.pages[1]["tabs_style"]
        tabs = self.km["pages"]["1"].get("tabs", [])
        sc.node("Tabs", "Control", "Panel/Guide",
                ["layout_mode = 0", f"offset_right = {PAPER_W:g}",
                 f"offset_bottom = {geom[0]['y'] + 60:g}", "mouse_filter = 2"])
        for i, g in enumerate(geom):
            self.build_tab(sc, i + 1, g, tabs[i] if i < len(tabs) else None)

    def build_tab(self, sc: Scene, idx: int, g: dict, tab_key) -> None:
        """Nút tab trạng thái THƯỜNG — style tab đang chọn do script gán theo trang."""
        name = f"Tab{idx}"
        parent = "Panel/Guide/Tabs"
        st = self.styles
        empty = sc.stylebox_empty()
        sb_off = st["tab_off"]
        sc.node(name, "Button", parent,
                ["layout_mode = 0", f"offset_left = {g['x']:g}", f"offset_top = {g['y']:g}",
                 f"offset_right = {g['x'] + g['w']:g}",
                 f"offset_bottom = {g['y'] + g['h']:g}",
                 "focus_mode = 0", "text = \"\"",
                 f'theme_override_styles/normal = SubResource("{sb_off}")',
                 f'theme_override_styles/hover = SubResource("{sb_off}")',
                 f'theme_override_styles/pressed = SubResource("{sb_off}")',
                 f'theme_override_styles/focus = SubResource("{empty}")',
                 f'theme_override_styles/disabled = SubResource("{empty}")'])
        # vòng số + nhãn canh giữa theo bề rộng chữ tiếng Việt (đo bằng font thật)
        vi = tab_key[1] if tab_key else ""
        size = st["tab_size"]
        weight = st["tab_weight"]
        text_w = self.metrics.width(vi, weight, size)
        total = TAB_RING + TAB_GAP + text_w
        ring_x = round((g["w"] - total) * 0.5, 1)
        ring_y = round((g["h"] - TAB_RING) * 0.5, 1)
        sc.node("Ring", "Panel", f"{parent}/{name}",
                ["layout_mode = 0", f"offset_left = {ring_x:g}", f"offset_top = {ring_y:g}",
                 f"offset_right = {ring_x + TAB_RING:g}", f"offset_bottom = {ring_y + TAB_RING:g}",
                 "mouse_filter = 2",
                 f'theme_override_styles/panel = SubResource("{st["ring_off"]}")'])
        self.label(sc, "Num", f"{parent}/{name}", (ring_x, ring_y, TAB_RING, TAB_RING), str(idx),
                   14.0, "900", st["off_text"], 1, 1)
        self.label(sc, "Label", f"{parent}/{name}",
                   (ring_x + TAB_RING + TAB_GAP, 0, text_w + 4.0, g["h"]),
                   tab_key[0] if tab_key else "", size, weight, st["off_text"], 0, 1)

    def build_page(self, sc: Scene, p: int) -> None:
        """Phần NỘI DUNG riêng của một trang (khung giấy/tab/nav/dots là dùng chung)."""
        d = self.pages[p]
        parent = f"Panel/Guide/Pages/Page{p}"
        sc.node(f"Page{p}", "Control", "Panel/Guide/Pages",
                ["layout_mode = 1", "anchors_preset = 15", "anchor_right = 1.0",
                 "anchor_bottom = 1.0", "grow_horizontal = 2", "grow_vertical = 2",
                 "mouse_filter = 2", f"visible = {'true' if p == 1 else 'false'}"])

        # ảnh minh hoạ
        img_key = sc.ext(f"img_p{p}", "Texture2D", f"{GUIDE_IMG_DIR}/{d['img']}")
        sc.node("Img", "TextureRect", parent,
                ["layout_mode = 0", f"offset_left = {IMG_RECT['x']:g}",
                 f"offset_top = {IMG_RECT['y']:g}",
                 f"offset_right = {IMG_RECT['x'] + IMG_RECT['w']:g}",
                 f"offset_bottom = {IMG_RECT['y'] + IMG_RECT['h']:g}",
                 "mouse_filter = 2", "expand_mode = 1", "stretch_mode = 0",
                 f'texture = ExtResource("{img_key}")'])

        # chữ trên khung minh hoạ:
        #   - số/ký hiệu trên grid (1, 2, 15, 01:24, =, ?, S, F…) GHI THẲNG
        #   - chữ có nghĩa dùng khoá dịch STR_GI_X###
        for i, t in enumerate(d["panel_texts"], 1):
            txt = t["text"]
            key = self._panel_keys.get(txt)
            if key is None:
                if im.is_literal_text(txt):
                    key = txt
                else:
                    raise SystemExit(f"[LOI] {self.mode} p{p}: thieu khoa dich cho '{txt}'")
            self.baseline_label(
                sc, f"PT{i}", parent, PANEL["x"] + t["x"], PANEL["y"] + t["y"], key,
                t["size"], t["weight"], t["fill"], t["anchor"], t["center"])

        # tiêu đề + mục + 3 hàng luật
        tkey = self.km["pages"][str(p)].get("title")
        ts = d["title_style"]
        if tkey:
            self.baseline_label(sc, "Title", parent, 110.0, 118.0, tkey[0],
                                ts["size"], ts["weight"], ts["fill"])
        skey = self.km["pages"][str(p)].get("section")
        if skey:
            self.baseline_label(sc, "Section", parent, PANEL["x"], SECTION_BASELINE,
                                skey[0], 16.0, "900", d["section_fg"])
        rules = self.km["pages"][str(p)].get("rules", [])
        for i in range(3):
            self.build_row(sc, parent, i, d["rows"][i], rules[i] if i < len(rules) else None)

        # CTA + link: mockup vẽ KHÁC NHAU từng trang (màu/cỡ chữ) -> giữ trong trang
        ckey = self.km["pages"][str(p)].get("cta")
        if ckey:
            self.build_cta(sc, parent, ckey[0], d)
        lkey = self.km["pages"][str(p)].get("link")
        if lkey:
            self.build_link(sc, parent, lkey[0], d)

    def build_row(self, sc: Scene, parent: str, i: int, row: dict, rule) -> None:
        y = ROW0_Y + ROW_STEP * i
        name = f"Row{i + 1}"
        sb = sc.sub_stylebox({
            "bg": col(row["bg"]), "radius": 14,
            "bw": 2.0 if row["border"] else 0.0, "border": col(row["border"] or "#00000000")})
        sc.node(name, "Panel", parent,
                ["layout_mode = 0", f"offset_left = {PANEL['x']:g}", f"offset_top = {y:g}",
                 f"offset_right = {PANEL['x'] + PANEL['w']:g}",
                 f"offset_bottom = {y + ROW_H:g}", "mouse_filter = 2",
                 f'theme_override_styles/panel = SubResource("{sb}")'])
        circle_sb = sc.sub_stylebox({"bg": col(row["num"]), "radius": 16})
        sc.node("NumCircle", "Panel", f"{parent}/{name}",
                ["layout_mode = 0", "offset_left = 20", "offset_top = 22",
                 "offset_right = 52", "offset_bottom = 54", "mouse_filter = 2",
                 f'theme_override_styles/panel = SubResource("{circle_sb}")'])
        if rule and rule.get("num"):
            self.label(sc, "NumText", f"{parent}/{name}", (20, 22, 32, 32),
                       str(i + 1), row.get("num_size", 15.0), "900", row.get("num_fg", "#FFFFFF"), 1, 1)
        if rule and rule.get("title"):
            t = rule["title"]
            self.baseline_label(sc, "Title", f"{parent}/{name}", 68.0, 32.0,
                                t[0], 18.0, row.get("tfg_weight", "900"), row["tfg"])
        if rule and rule.get("desc"):
            t = rule["desc"]
            self.baseline_label(sc, "Desc", f"{parent}/{name}", 68.0, 58.0,
                                t[0], 16.0, row.get("dfg_weight", "600"), row["dfg"])

    def build_nav(self, sc: Scene) -> None:
        """Cặp nút ‹ › DÙNG CHUNG; trạng thái khoá nướng sẵn (mockup: mờ xanh/mờ xám).

        Script chỉ cần bật/tắt `disabled` theo trang — không đổi màu lúc chạy.
        """
        nav = self.pages[2]["nav"]      # trang 2: cả 2 nút đều bật -> màu chuẩn
        for side, name, key, x in (("left", "Prev", "prev", 105.0),
                                   ("right", "Next", "next", 305.0)):
            tex = sc.ext(f"chev_{side}", "Texture2D", f"{CHROME_DIR}/guide_chevron_{side}.svg")
            on_sb = sc.sub_stylebox({"bg": col("#FFFDF9"), "radius": 14, "bw": 2.0,
                                     "border": col(nav[f"{key}_border"])})
            off_sb = sc.sub_stylebox({"bg": col("#FFFDF9"), "radius": 14, "bw": 2.0,
                                      "border": col(NAV_OFF_BORDER[key])})
            fg = nav[f"{key}_fg"]
            off_fg = NAV_OFF_FG[key]
            props = [
                "layout_mode = 0",
                f"offset_left = {x:g}", f"offset_top = {NAV_Y:g}",
                f"offset_right = {x + NAV_SIZE:g}", f"offset_bottom = {NAV_Y + NAV_SIZE:g}",
                "focus_mode = 0", "expand_icon = false",
                f'icon = ExtResource("{tex}")',
                f"theme_override_colors/icon_normal_color = {col(fg)}",
                f"theme_override_colors/icon_hover_color = {col(fg)}",
                f"theme_override_colors/icon_pressed_color = {col(fg)}",
                f"theme_override_colors/icon_focus_color = {col(fg)}",
                f"theme_override_colors/icon_disabled_color = {col(off_fg)}",
                f'theme_override_styles/normal = SubResource("{on_sb}")',
                f'theme_override_styles/hover = SubResource("{on_sb}")',
                f'theme_override_styles/pressed = SubResource("{on_sb}")',
                f'theme_override_styles/disabled = SubResource("{off_sb}")',
                f'theme_override_styles/focus = SubResource("{sc.stylebox_empty()}")',
            ]
            if name == "Prev":
                props.append("disabled = true")     # mở đầu ở trang 1 -> Prev khoá
            sc.node(name, "Button", "Panel/Guide", props)

    def build_dots(self, sc: Scene) -> None:
        """Hàng dots DÙNG CHUNG; script dàn lại vị trí theo trang (dot chọn to hơn)."""
        st = self.styles
        sc.node("Dots", "Control", "Panel/Guide",
                ["layout_mode = 0", f"offset_right = {PAPER_W:g}",
                 f"offset_bottom = {PAPER_H:g}", "mouse_filter = 2"])
        x = DOTS_X0
        for i in range(len(self.pages[1]["dots"])):
            on = i == 0                     # trang 1: dot đầu đang chọn
            w, h = (38.0, 18.0) if on else (16.0, 16.0)
            sb = st["dot_on"] if on else st["dot_off"]
            sc.node(f"Dot{i + 1}", "Button", "Panel/Guide/Dots",
                    ["layout_mode = 0",
                     f"offset_left = {x:g}", f"offset_top = {DOTS_CY - h / 2:g}",
                     f"offset_right = {x + w:g}", f"offset_bottom = {DOTS_CY + h / 2:g}",
                     "focus_mode = 0",
                     f'theme_override_styles/normal = SubResource("{sb}")',
                     f'theme_override_styles/hover = SubResource("{sb}")',
                     f'theme_override_styles/pressed = SubResource("{sb}")',
                     f'theme_override_styles/focus = SubResource("{sc.stylebox_empty()}")'])
            x += w + DOTS_GAP
        # kiểm tra công thức dàn dots có khớp mockup ở mọi trang không
        for p, d in self.pages.items():
            xs = DOTS_X0
            for i, dot in enumerate(d["dots"]):
                w = 38.0 if dot["on"] else 16.0
                cx = xs + w / 2
                if abs(cx - dot["cx"]) > 2.5 or abs(DOTS_CY - dot["cy"]) > 2.5:
                    print(f"[CANH BAO] {self.mode} p{p}: dot{i + 1} lech "
                          f"({cx:.0f},{DOTS_CY:.0f}) vs mockup ({dot['cx']:.0f},{dot['cy']:.0f})")
                xs += w + DOTS_GAP

    def build_index(self, sc: Scene) -> None:
        """Nhãn 'TRANG x / 3' DÙNG CHUNG — script format lại khi đổi trang."""
        d = self.pages[1]
        top = INDEX_BASELINE - self.metrics.ascent("black", d["page_index_size"])
        self.label(sc, "Index", "Panel/Guide",
                   (INDEX_RIGHT - 220.0, top, 220.0, d["page_index_size"] * 1.5),
                   "STR_GI_PAGE_INDEX", d["page_index_size"], "black", d["page_index_fg"], 2)

    def build_cta(self, sc: Scene, parent: str, key: str, d: dict) -> None:
        sb = sc.sub_stylebox({
            "bg": col(d["cta_fill"]), "radius": 22, "bw": 3.5,
            "border": col(d["cta_stroke"])})
        x, y, w, h = (CTA_RECT["x"], CTA_RECT["y"], CTA_RECT["w"], CTA_RECT["h"])
        empty = sc.stylebox_empty()
        sc.node("Cta", "Button", parent,
                ["layout_mode = 0",
                 f"offset_left = {x:g}", f"offset_top = {y:g}",
                 f"offset_right = {x + w:g}", f"offset_bottom = {y + h:g}",
                 "focus_mode = 0",
                 f"theme_override_fonts/font = ExtResource(\"{sc.ext('font_' + pick_weight(d['cta_text_weight']), 'FontFile', FONT_FILES[pick_weight(d['cta_text_weight'])])}\")",
                 f"theme_override_font_sizes/font_size = {int(round(d['cta_text_size']))}",
                 f"theme_override_colors/font_color = {col(d['cta_text_fill'])}",
                 f"theme_override_colors/font_hover_color = {col(d['cta_text_fill'])}",
                 f"theme_override_colors/font_pressed_color = {col(d['cta_text_fill'])}",
                 f'theme_override_styles/normal = SubResource("{sb}")',
                 f'theme_override_styles/hover = SubResource("{sb}")',
                 f'theme_override_styles/pressed = SubResource("{sb}")',
                 f'theme_override_styles/focus = SubResource("{empty}")',
                 f'text = "{esc(key)}"'])

    def build_link(self, sc: Scene, parent: str, key: str, d: dict) -> None:
        x, w = CTA_RECT["x"], CTA_RECT["w"]
        y = LINK_CENTER_Y - LINK_H * 0.5
        empty = sc.stylebox_empty()
        sc.node("Link", "Button", parent,
                ["layout_mode = 0",
                 f"offset_left = {x:g}", f"offset_top = {y:g}",
                 f"offset_right = {x + w:g}", f"offset_bottom = {y + LINK_H:g}",
                 "focus_mode = 0", "flat = true",
                 f"theme_override_fonts/font = ExtResource(\"{sc.ext('font_' + pick_weight(d['link_weight']), 'FontFile', FONT_FILES[pick_weight(d['link_weight'])])}\")",
                 f"theme_override_font_sizes/font_size = {int(round(d['link_size']))}",
                 f"theme_override_colors/font_color = {col(d['link_fill'])}",
                 f"theme_override_colors/font_hover_color = {col(d['link_fill'], 0.75)}",
                 f"theme_override_colors/font_pressed_color = {col(d['link_fill'], 0.75)}",
                 f'theme_override_styles/normal = SubResource("{empty}")',
                 f'theme_override_styles/hover = SubResource("{empty}")',
                 f'theme_override_styles/pressed = SubResource("{empty}")',
                 f'theme_override_styles/focus = SubResource("{empty}")',
                 f'text = "{esc(key)}"'])


def esc(text: str) -> str:
    for a, b in (("➔", "•"), ("➜", "•")):
        text = text.replace(a, b)
    return text.replace("\\", "\\\\").replace('"', '\\"')


def read_scene_ids(path: Path) -> tuple:  # noqa: D401
    """-> (uid, unique_id) của scene placeholder đang có (nếu có).

    CHỈ đọc dòng đầu ([gd_scene ...]) — nếu đọc cả file sẽ vớ phải uid của
    ext_resource(base.tscn) khi scene chưa có uid riêng.
    """
    if not path.exists():
        return ("", "")
    text = path.read_text(encoding="utf-8")
    first = text.splitlines()[0]
    m = re.search(r'uid="(uid://[^"]+)"', first)
    uid = m.group(1) if m else ""
    if uid == BASE_UID:
        uid = ""          # không bao giờ tái dùng uid của base.tscn
    m = re.search(r'unique_id="?(\d+)"?', text)
    return (uid, m.group(1) if m else "")


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    check = "--check" in sys.argv
    keymap = json.loads(KEYS_PATH.read_text(encoding="utf-8"))
    data = im.load_all()
    metrics = Metrics()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for mode, pages in data.items():
        path = OUT_DIR / f"{mode}.tscn"
        uid, unique_id = read_scene_ids(path)
        b = Builder(mode, pages, keymap, metrics)
        text = b.build(uid, unique_id, keymap["panel_texts"])
        node_count = text.count("[node name=")
        if check:
            print(f"[CHECK] {mode:14s} uid={uid or '(moi)':<22} ~{node_count} node")
            continue
        path.write_text(text, encoding="utf-8")
        print(f"[OK] {mode:14s} -> {path.relative_to(ROOT)}  ({node_count} node)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
