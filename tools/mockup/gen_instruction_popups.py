#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Sinh scene NỘI DUNG hướng dẫn theo chế độ: `nodes/popups/instruction/<mode>.tscn`.

KIẾN TRÚC (đợt tách POPUP ⇄ NỘI DUNG):
  · `page.tscn`               (viết tay) — TRANG nền: Image (các label chữ-trên-ảnh PT# là CON của
                                            Image) · Title · Section · Instruction (VBoxContainer
                                            chứa các hàng luật Row1..3)
  · `content_instruction.tscn`(viết tay) — NỘI DUNG nền: Chip · Tabs/Tab1..3 · Pages · Prev/Next ·
                                            Dots/Dot1..3 · Index (+ script lật trang)
  · `<mode>.tscn`  — FILE NÀY SINH — KẾ THỪA content_instruction: override chip/tab/nav/paper theo
                                            mockup của chế độ, thêm Page1..3 (mỗi trang kế thừa
                                            `page.tscn`) và đổ nội dung từng trang vào.
  · `popup_instruction.tscn`  (viết tay) — popup DUY NHẤT (base + Panel/Washi/PaperDetail/Content)
                                            nạp `<mode>.tscn` vào Panel/Content theo mode_id.

Toạ độ mockup là FULL-scale (hệ giấy 920×1480) -> nhân S = 0.5 khi ghi ra scene
(khớp canvas 540×920 của project). Chữ dùng khoá dịch STR_GI_* từ tools/content/_guide_keys.json.

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
GUIDE_IMG_DIR = "res://assets/images/instructions/guideline_image"
FONT_DIR = "res://assets/fonts/Be_Vietnam_Pro"
CONTENT_SCENE = "res://nodes/popups/instruction/content_instruction.tscn"
PAGE_SCENE = "res://nodes/popups/instruction/page.tscn"

S = 0.5

# — hệ toạ độ mockup (FULL-scale) —
PANEL = {"x": 105.0, "y": 210.0, "w": 755.0, "h": 510.0}
IMG_RECT = {"x": 90.0, "y": 200.0, "w": 785.0, "h": 535.0}
ROW_H = 76.0
ROW_RADIUS = 14.0
## Bề ngang TỐI THIỂU của hàng luật (full-scale) — nhỏ hơn để hàng co được theo cột chữ
## khi nội dung nằm trong khung Hẹp (ví dụ khung Hướng dẫn của HUD ngang)
ROW_MIN_W = 480.0

# — ĐIỂM (chữ nằm trong KHUNG CHÚ THÍCH của mockup) —
# Trên ảnh KHÔNG viết chữ nữa (chữ nhỏ bị tràn khi ảnh co): chỉ giữ BADGE SỐ; chuỗi gốc
# nằm trong Label ẨN (metadata/point) để content_instruction.gd đổ xuống section “chi tiết
# điểm” (Points/List/PointRow…). Kích thước FULL-scale (×S khi ghi vào scene):
POINT_BADGE_D = 80.0       # đường kính badge số trên ảnh
POINT_BADGE_FONT = 44.0    # cỡ số trong badge
POINT_ROW_BADGE = 34.0     # vòng số trong section điểm
POINT_ROW_FONT = 20.0      # số trong vòng
POINT_TITLE_SIZE = 20.0    # chữ tiêu đề của điểm (dòng chữ đầu)
POINT_DESC_SIZE = 18.0     # chữ mô tả của điểm (các dòng còn lại)
## Bề ngang TỐI THIỂU của khối chữ trong hàng điểm — cần cho Label autowrap tính
## đúng bề cao tối thiểu (không có số này, Godot coi như bề ngang 0 → panel cao vọt).
## ⚠ Đừng đặt lớn hơn cột ĐIỂM hẹp nhất: cột = bề ngang khối − ảnh − lề. Ở popup
## (460 ngang) cột còn ~200px (scene) → 300 full-scale (150 scene) là ngưỡng an toàn,
## chữ vẫn tự xuống dòng nhờ autowrap.
POINT_TEXT_MIN_W = 250.0
CTA_RECT = {"x": 105.0, "y": 1180.0, "w": 755.0, "h": 100.0}
CTA_RADIUS = 22.0
LINK_H = 56.0

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


def fmt(v: float) -> str:
    """Số gọn cho .tscn: nguyên -> '19', lẻ -> '171.6'."""
    if abs(v - round(v)) < 0.0005:
        return str(int(round(v)))
    return ("%.1f" % round(v, 1)).rstrip("0").rstrip(".")


def n(v: float) -> str:
    """Giá trị mockup (FULL-scale) -> chuỗi đã nhân S."""
    return fmt(v * S)


def nf(v: float) -> str:
    """Giá trị đã ở hệ scene -> chuỗi gọn."""
    return fmt(v)


class Metrics:
    """Đo chữ bằng chính file font (đơn vị font -> px theo font-size, FULL-scale)."""

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


class Scene:
    """Gom text .tscn cho một scene chế độ."""

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
        self._n_sub += 1
        sid = f"sb{self._n_sub}"
        lines = []
        bg = params.get("bg")
        if bg is not None:
            lines.append(f'bg_color = {bg}')
        if params.get("bw"):
            for attr in ("border_width_left", "border_width_top",
                         "border_width_right", "border_width_bottom"):
                lines.append(f"{attr} = {fmt(params['bw'])}")
            if params.get("border"):
                lines.append(f'border_color = {params["border"]}')
        r = params.get("radius")
        if r is not None:
            lines.append(f"corner_radius_top_left = {fmt(r)}")
            lines.append(f"corner_radius_top_right = {fmt(r)}")
            lines.append(f"corner_radius_bottom_right = {fmt(r)}")
            lines.append(f"corner_radius_bottom_left = {fmt(r)}")
        self.sub.append(f'[sub_resource type="StyleBoxFlat" id="{sid}"]\n' + "\n".join(lines))
        return sid

    def stylebox_empty(self) -> str:
        self._n_sub += 1
        sid = f"sb{self._n_sub}"
        self.sub.append(f'[sub_resource type="StyleBoxEmpty" id="{sid}"]')
        return sid

    # ---------------------------------------------------------------- nodes
    def root(self, name: str, ext_key: str, props: list[str]) -> None:
        extra = f" unique_id={self.unique_id}" if self.unique_id else ""
        self.nodes.append(
            f'[node name="{name}"{extra} instance=ExtResource("{ext_key}")]\n'
            + "\n".join(props))

    def override(self, name: str, parent: str, index: int, props: list[str]) -> None:
        """Sửa node CÓ SẴN của scene nền (không ghi `type=`)."""
        self.nodes.append(f'[node name="{name}" parent="{parent}" index="{index}"]\n'
                          + "\n".join(props))

    def node(self, name: str, type_: str, parent: str, index: int, props: list[str]) -> None:
        """Thêm node MỚI."""
        self.nodes.append(
            f'[node name="{name}" type="{type_}" parent="{parent}" index="{index}"]\n'
            + "\n".join(props))

    def instance(self, name: str, parent: str, index: int, ext_key: str,
                 props: list[str] | None = None) -> None:
        """Thêm node INSTANCE của scene khác (Page kế thừa page.tscn…)."""
        head = f'[node name="{name}" parent="{parent}" index="{index}" instance=ExtResource("{ext_key}")]'
        self.nodes.append(head + ("\n" + "\n".join(props) if props else ""))

    def editable(self, path: str) -> None:
        self.nodes.append(f'[editable path="{path}"]')

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


def esc(text: str) -> str:
    for a, b in _SUBST.items():
        text = text.replace(a, b)
    return text.replace("\\", "\\\\").replace('"', '\\"')


class Builder:
    def __init__(self, mode: str, pages: dict, keymap: dict, metrics: Metrics) -> None:
        self.mode = mode
        self.pages = pages
        self.km = keymap["modes"][mode]
        self.metrics = metrics

    # --------------------------------------------------------------- helpers
    def font(self, sc: Scene, weight: str) -> str:
        key = pick_weight(weight)
        return sc.ext(f"font_{key}", "FontFile", FONT_FILES[key])

    def baseline_rect(self, bx: float, by: float, text: str, size: float,
                      weight: str) -> tuple:
        """Rect (x, top, w, h) của label đặt theo baseline mockup (FULL-scale)."""
        w = self.metrics.width(text, weight, size)
        h = size * 1.5
        return (bx, by - self.metrics.ascent(weight, size), w + 4.0, h)

    # ----------------------------------------------------------------- build
    def build(self, uid: str, unique_id: str, panel_keys: dict) -> str:
        self._panel_keys = panel_keys
        sc = Scene(uid, unique_id)
        base_key = sc.ext("content", "PackedScene", CONTENT_SCENE)
        page_key = sc.ext("page", "PackedScene", PAGE_SCENE)
        sc.root("ContentInstruction", base_key, self.build_shared_styles(sc))
        self.build_chip(sc)
        self.build_tab_texts(sc)
        self.build_nav(sc)
        for p in (1, 2, 3):
            self.build_page(sc, p, page_key)
        for p in (1, 2, 3):
            sc.editable(f"Pages/Page{p}")
        return sc.finish()

    def build_shared_styles(self, sc: Scene) -> list:
        """Style tab/dot nướng sẵn qua export của root (nửa cỡ mockup)."""
        p1 = self.pages[1]
        on_tab = next((t for t in p1["tabs_style"] if t["on"]), p1["tabs_style"][0])
        off_tab = next((t for t in p1["tabs_style"] if not t["on"]), p1["tabs_style"][-1])
        on_dot = next((d for d in p1["dots"] if d["on"]), p1["dots"][0])
        off_dot = next((d for d in p1["dots"] if not d["on"]), p1["dots"][1])

        def tab_sb(st):
            return {"bg": col(st["fill"]), "radius": 7.0,
                    "bw": 1.0 if st["stroke"] else 0.0,
                    "border": col(st["stroke"] or "#00000000")}

        sb_on = sc.sub_stylebox(tab_sb(on_tab))
        sb_off = sc.sub_stylebox(tab_sb(off_tab))
        ring_on = sc.sub_stylebox({"bg": col("#00000000"), "radius": 6.5, "bw": 1.1,
                                   "border": col(on_tab["text_fill"])})
        ring_off = sc.sub_stylebox({"bg": col("#00000000"), "radius": 6.5, "bw": 1.1,
                                    "border": col(off_tab["text_fill"])})
        dot_on = sc.sub_stylebox({"bg": col(on_dot.get("fill", "#F59E0B")), "radius": 4.5})
        dot_off = sc.sub_stylebox({"bg": col(off_dot.get("fill", "#D1E2ED")), "radius": 4.0})
        return [
            f'tab_on_style = SubResource("{sb_on}")',
            f'tab_off_style = SubResource("{sb_off}")',
            f'tab_on_ring_style = SubResource("{ring_on}")',
            f'tab_off_ring_style = SubResource("{ring_off}")',
            f'tab_on_text_color = {col(on_tab["text_fill"])}',
            f'tab_off_text_color = {col(off_tab["text_fill"])}',
            f'dot_on_style = SubResource("{dot_on}")',
            f'dot_off_style = SubResource("{dot_off}")',
            f"paper_bg = {col(p1['paper_bg'])}",
            f"paper_accent = {col(p1['accent'])}",
        ]

    def build_chip(self, sc: Scene) -> None:
        """Chip tên chế độ — override khung + chữ + màu theo mockup."""
        p1 = self.pages[1]
        chip_key, _vi = self.km["chip"]
        chip = p1["chip_rect"]
        sb = sc.sub_stylebox({
            "bg": col(p1["chip_bg"]), "radius": 4.0,
            "bw": 1.0 if p1["chip_stroke"] else 0.0,
            "border": col(p1["chip_stroke"] or "#00000000")})
        sc.override("Chip", ".", 0, [
            f"offset_left = {n(chip['x'])}",
            f"offset_top = {n(chip['y'])}",
            f"offset_right = {n(chip['x'] + chip['w'])}",
            f"offset_bottom = {n(chip['y'] + chip['h'])}",
            f'theme_override_styles/panel = SubResource("{sb}")'])
        sc.override("ChipText", "Chip", 0, [
            f'text = "{esc(chip_key)}"',
            f'theme_override_fonts/font = ExtResource("{self.font(sc, p1["chip_weight"])}")',
            f"theme_override_font_sizes/font_size = {n(p1['chip_size'])}",
            f"theme_override_colors/font_color = {col(p1['chip_fg'])}"])

    def build_tab_texts(self, sc: Scene) -> None:
        """Chữ 3 tab (số thứ tự + style đổi theo trang do script lo)."""
        tabs = self.km["pages"]["1"].get("tabs", [])
        for i, key in enumerate(tabs):
            sc.override("Label", f"Tabs/Tab{i + 1}/Row", 1, [f'text = "{esc(key[0])}"'])

    def build_nav(self, sc: Scene) -> None:
        """Màu viền/mũi tên nút ‹ › theo chế độ (style khoá giữ nguyên trong scene nền)."""
        nav = self.pages[2]["nav"]
        for name, idx, key in (("Prev", 3, "prev"), ("Next", 4, "next")):
            on_sb = sc.sub_stylebox({"bg": col("#FFFDF9"), "radius": 7.0, "bw": 1.0,
                                     "border": col(nav[f"{key}_border"])})
            fg = nav[f"{key}_fg"]
            props = []
            for state in ("normal", "hover", "pressed", "focus"):
                props.append(f"theme_override_colors/icon_{state}_color = {col(fg)}")
            for state in ("normal", "hover", "pressed"):
                props.append(f'theme_override_styles/{state} = SubResource("{on_sb}")')
            sc.override(name, ".", idx, props)

    # ------------------------------------------------------------------ page
    def build_page(self, sc: Scene, p: int, page_key: str) -> None:
        d = self.pages[p]
        ppath = f"Pages/Page{p}"
        props = None if p == 1 else ["visible = false"]
        sc.instance(f"Page{p}", "Pages", p - 1, page_key, props)

        # ảnh minh hoạ (label chữ-trên-ảnh là CON của node Image — thêm bên dưới)
        img_key = sc.ext(f"img_p{p}", "Texture2D", f"{GUIDE_IMG_DIR}/{d['img']}")
        sc.override("Image", f"{ppath}/Body/Top", 0, [f'texture = ExtResource("{img_key}")'])

        # tiêu đề + mục của trang
        tkey = self.km["pages"][str(p)].get("title")
        if tkey:
            ts = d["title_style"]
            sc.override("Title", ppath, 0, [
                f'text = "{esc(tkey[0])}"',
                f'theme_override_fonts/font = ExtResource("{self.font(sc, ts["weight"])}")',
                f"theme_override_font_sizes/font_size = {n(ts['size'])}",
                f"theme_override_colors/font_color = {col(ts['fill'])}"])
        skey = self.km["pages"][str(p)].get("section")
        if skey:
            sc.override("Section", f"{ppath}/Body", 1, [
                f'text = "{esc(skey[0])}"',
                f"theme_override_colors/font_color = {col(d['section_fg'])}"])

        # chữ trên khung minh hoạ — CON của Image, neo TỈ LỆ theo ảnh.
        # Chữ nằm trong KHUNG CHÚ THÍCH (comment CALLOUT/CHÚ THÍCH/DẢI của mockup) KHÔNG
        # viết lên ảnh nữa: ảnh chỉ nhận BADGE SỐ, chuỗi gốc giữ trong Label ẨN
        # (metadata/point + point_order) cho content_instruction.gd đọc và đổ xuống
        # section “chi tiết điểm” (Points/List/PointRow…).
        points = self.collect_points(d)
        point_at = {}
        for pn, grp in enumerate(points, 1):
            for order, (ti, _txt) in enumerate(grp["texts"]):
                point_at[ti] = (pn, order)
        child = 0
        for i, t in enumerate(d["panel_texts"], 1):
            if i in point_at:
                pn, order = point_at[i]
                self.build_point_src(sc, ppath, i, child, t, pn, order)
            else:
                self.build_pt(sc, ppath, i, child, t)
            child += 1
        for pn, grp in enumerate(points, 1):
            self.build_point_badge(sc, ppath, child + pn - 1, pn, grp)
        for pn, grp in enumerate(points, 1):
            self.build_point_row(sc, ppath, pn, grp)

        # 3 hàng luật trong VBox `Instruction`
        rules = self.km["pages"][str(p)].get("rules", [])
        for i in range(3):
            self.build_row(sc, ppath, i, d["rows"][i], rules[i] if i < len(rules) else None)

        # CTA + link (giữ trong trang — mockup vẽ khác nhau từng trang)
        ckey = self.km["pages"][str(p)].get("cta")
        if ckey:
            self.build_cta(sc, ppath, ckey[0], d)
        lkey = self.km["pages"][str(p)].get("link")
        if lkey:
            self.build_link(sc, ppath, lkey[0], d)

    def _text_key(self, txt: str) -> str:
        """Khoá dịch của một chuỗi mockup (chuỗi số/ký hiệu thì ghi thẳng)."""
        key = self._panel_keys.get(txt)
        if key is None:
            if im.is_literal_text(txt):
                return txt
            raise SystemExit(f"[LOI] {self.mode}: thieu khoa dich cho '{txt}'")
        return key

    def text_rect(self, t: dict) -> tuple:
        """Rect (x, top, w, h) FULL-scale của một chữ theo vị trí/neo trong mockup."""
        size, weight = t["size"], t["weight"]
        w = self.metrics.width(t["text"], weight, size) + 4.0
        h = size * 1.5
        by = t["y"] + (size * 0.35 if t["center"] else 0.0)
        top = by - self.metrics.ascent(weight, size)
        x = t["x"]
        if t["anchor"] == "middle":
            x -= w * 0.5
        elif t["anchor"] == "end":
            x -= w
        return (x, top, w, h)

    def image_anchor(self, x: float, y: float) -> tuple:
        """Toạ độ panel-local (FULL-scale) -> tỉ lệ neo trong hệ node `Image`."""
        ax = round(((PANEL["x"] + x) - IMG_RECT["x"]) / IMG_RECT["w"], 4)
        ay = round(((PANEL["y"] + y) - IMG_RECT["y"]) / IMG_RECT["h"], 4)
        return ax, ay

    def collect_points(self, d: dict) -> list:
        """Gom các chữ trong KHUNG CHÚ THÍCH thành từng ĐIỂM (theo comment mockup)."""
        groups = []
        seen = {}
        for i, t in enumerate(d["panel_texts"], 1):
            if not t.get("point"):
                continue
            name = t.get("comment", "")
            if name not in seen:
                seen[name] = len(groups)
                groups.append({"comment": name, "texts": []})
            groups[seen[name]]["texts"].append((i, t))
        return groups

    def build_pt(self, sc: Scene, ppath: str, i: int, index: int, t: dict) -> None:
        """Label chữ-trên-ảnh: neo theo TÂM (tỉ lệ trong ảnh) — ảnh co giãn là chữ đi theo.

        `metadata/base_font` = cỡ chữ lúc thiết kế để `page.gd` co lại theo cỡ ảnh thật
        (tránh chữ tràn khung khi ảnh nhỏ hơn cỡ thiết kế).
        """
        key = self._text_key(t["text"])
        size, weight = t["size"], t["weight"]
        rect = self.text_rect(t)
        w2 = round(rect[2] * S, 1)
        h2 = round(rect[3] * S, 1)
        ax, ay = self.image_anchor(rect[0] + rect[2] * 0.5, rect[1] + rect[3] * 0.5)
        sc.node(f"PT{i}", "Label", f"{ppath}/Body/Top/Image", index, [
            "layout_mode = 1", "anchors_preset = -1",
            f"anchor_left = {ax}", f"anchor_top = {ay}",
            f"anchor_right = {ax}", f"anchor_bottom = {ay}",
            f"offset_left = {nf(-w2 * 0.5)}", f"offset_top = {nf(-h2 * 0.5)}",
            f"offset_right = {nf(w2 * 0.5)}", f"offset_bottom = {nf(h2 * 0.5)}",
            "grow_horizontal = 2", "grow_vertical = 2", "mouse_filter = 2",
            "horizontal_alignment = 1", "vertical_alignment = 1",
            f'theme_override_fonts/font = ExtResource("{self.font(sc, weight)}")',
            f"theme_override_font_sizes/font_size = {n(size)}",
            f"theme_override_colors/font_color = {col(t['fill'])}",
            f"metadata/base_font = {n(size)}",
            f'text = "{esc(key)}"'])

    # ----------------------------------------------------------------- điểm
    def build_point_src(self, sc: Scene, ppath: str, i: int, index: int, t: dict,
                        point: int, order: int) -> None:
        """Label ẨN giữ CHUỖI GỐC của chữ trong khung chú thích.

        content_instruction.gd đọc theo `metadata/point` (+ thứ tự `point_order`)
        rồi đổ xuống section “chi tiết điểm” — nhờ vậy không cần viết chữ lên ảnh.
        """
        key = self._text_key(t["text"])
        sc.node(f"PT{i}", "Label", f"{ppath}/Body/Top/Image", index, [
            "visible = false",
            "layout_mode = 0",
            "mouse_filter = 2",
            f"metadata/point = {point}",
            f"metadata/point_order = {order}",
            f'text = "{esc(key)}"'])

    def build_point_badge(self, sc: Scene, ppath: str, index: int, point: int, grp: dict) -> None:
        """Badge SỐ trên ảnh — đặt tại tâm vùng chữ của khung chú thích (thay chữ cũ)."""
        rects = [self.text_rect(t) for (_i, t) in grp["texts"]]
        x0 = min(r[0] for r in rects)
        y0 = min(r[1] for r in rects)
        x1 = max(r[0] + r[2] for r in rects)
        y1 = max(r[1] + r[3] for r in rects)
        ax, ay = self.image_anchor((x0 + x1) * 0.5, (y0 + y1) * 0.5)
        fill = grp["texts"][0][1].get("fill") or "#D97706"
        size = POINT_BADGE_D * S
        sb = sc.sub_stylebox({"bg": col(fill), "radius": size * 0.5})
        sc.node(f"Point{point}", "Panel", f"{ppath}/Body/Top/Image", index, [
            "layout_mode = 0", "anchors_preset = -1",
            f"anchor_left = {ax}", f"anchor_top = {ay}",
            f"anchor_right = {ax}", f"anchor_bottom = {ay}",
            f"offset_left = {nf(-size * 0.5)}", f"offset_top = {nf(-size * 0.5)}",
            f"offset_right = {nf(size * 0.5)}", f"offset_bottom = {nf(size * 0.5)}",
            "grow_horizontal = 2", "grow_vertical = 2", "mouse_filter = 2",
            f"metadata/base_size = {nf(size)}",
            f"metadata/base_font = {n(POINT_BADGE_FONT)}",
            f'theme_override_styles/panel = SubResource("{sb}")'])
        sc.node("Num", "Label", f"{ppath}/Body/Top/Image/Point{point}", 0, [
            "layout_mode = 1", "anchors_preset = 15",
            "anchor_right = 1.0", "anchor_bottom = 1.0",
            "grow_horizontal = 2", "grow_vertical = 2", "mouse_filter = 2",
            "horizontal_alignment = 1", "vertical_alignment = 1",
            f'theme_override_fonts/font = ExtResource("{self.font(sc, "900")}")',
            f"theme_override_font_sizes/font_size = {n(POINT_BADGE_FONT)}",
            f"theme_override_colors/font_color = {col("#FFFFFF")}",
            f'text = "{point}"'])

    def build_point_row(self, sc: Scene, ppath: str, point: int, grp: dict) -> None:
        """Hàng của section “chi tiết điểm” — vỏ sẵn, chữ do content_instruction.gd đổ vào."""
        fill = grp["texts"][0][1].get("fill") or "#D97706"
        weight = grp["texts"][0][1].get("weight", "900")
        list_path = f"{ppath}/Body/Top/Points/List"
        row = f"{list_path}/PointRow{point}"
        size = POINT_ROW_BADGE * S
        circ = sc.sub_stylebox({"bg": col(fill), "radius": size * 0.5})
        sc.node(f"PointRow{point}", "HBoxContainer", list_path, point - 1, [
            "layout_mode = 2",
            "size_flags_horizontal = 3",
            f"theme_override_constants/separation = {n(8.0)}",
            "mouse_filter = 2"])
        sc.node("NumCircle", "Panel", row, 0, [
            f"custom_minimum_size = Vector2({n(POINT_ROW_BADGE)}, {n(POINT_ROW_BADGE)})",
            "layout_mode = 2",
            "size_flags_vertical = 4",
            "mouse_filter = 2",
            f'theme_override_styles/panel = SubResource("{circ}")'])
        sc.node("NumText", "Label", f"{row}/NumCircle", 0, [
            "layout_mode = 1", "anchors_preset = 15",
            "anchor_right = 1.0", "anchor_bottom = 1.0",
            "grow_horizontal = 2", "grow_vertical = 2", "mouse_filter = 2",
            "horizontal_alignment = 1", "vertical_alignment = 1",
            f'theme_override_fonts/font = ExtResource("{self.font(sc, "900")}")',
            f"theme_override_font_sizes/font_size = {n(POINT_ROW_FONT)}",
            f"theme_override_colors/font_color = {col("#FFFFFF")}",
            f'text = "{point}"'])
        sc.node("Body", "VBoxContainer", row, 1, [
            "layout_mode = 2",
            "size_flags_horizontal = 3",
            f"theme_override_constants/separation = {n(2.0)}",
            "mouse_filter = 2"])
        sc.node("Title", "Label", f"{row}/Body", 0, [
            "layout_mode = 2",
            "mouse_filter = 2",
            "autowrap_mode = 3",
            f"custom_minimum_size = Vector2({n(POINT_TEXT_MIN_W)}, 0)",
            f'theme_override_fonts/font = ExtResource("{self.font(sc, weight)}")',
            f"theme_override_font_sizes/font_size = {n(POINT_TITLE_SIZE)}",
            f"theme_override_colors/font_color = {col(fill)}"])
        sc.node("Desc", "Label", f"{row}/Body", 1, [
            "layout_mode = 2",
            "mouse_filter = 2",
            "autowrap_mode = 3",
            f"custom_minimum_size = Vector2({n(POINT_TEXT_MIN_W)}, 0)",
            f'theme_override_fonts/font = ExtResource("{self.font(sc, "600")}")',
            f"theme_override_font_sizes/font_size = {n(POINT_DESC_SIZE)}",
            f"theme_override_colors/font_color = {col(fill, 0.78)}"])

    def build_row(self, sc: Scene, ppath: str, i: int, row: dict, rule) -> None:
        """Một hàng luật — con của VBoxContainer `Instruction` (tự xếp dọc)."""
        name = f"Row{i + 1}"
        box = f"{ppath}/Body/Instruction/{name}"
        sb = sc.sub_stylebox({
            "bg": col(row["bg"]), "radius": ROW_RADIUS * S,
            "bw": 1.0 if row["border"] else 0.0,
            "border": col(row["border"] or "#00000000")})
        sc.node(name, "Panel", f"{ppath}/Body/Instruction", i, [
            f"custom_minimum_size = Vector2({n(ROW_MIN_W)}, {n(ROW_H)})",
            "layout_mode = 2",
            "size_flags_horizontal = 3",
            "mouse_filter = 2",
            f'theme_override_styles/panel = SubResource("{sb}")'])
        circ_sb = sc.sub_stylebox({"bg": col(row["num"]), "radius": 16.0 * S})
        sc.node("NumCircle", "Panel", box, 0, [
            "layout_mode = 0",
            f"offset_left = {n(20)}", f"offset_top = {n(22)}",
            f"offset_right = {n(52)}", f"offset_bottom = {n(54)}",
            "mouse_filter = 2",
            f'theme_override_styles/panel = SubResource("{circ_sb}")'])
        idx = 1
        if rule and rule.get("num"):
            sc.node("NumText", "Label", box, idx, [
                "layout_mode = 0",
                f"offset_left = {n(20)}", f"offset_top = {n(22)}",
                f"offset_right = {n(52)}", f"offset_bottom = {n(54)}",
                "mouse_filter = 2",
                f'theme_override_fonts/font = ExtResource("{self.font(sc, "900")}")',
                f"theme_override_font_sizes/font_size = {n(row.get('num_size', 15.0))}",
                f"theme_override_colors/font_color = {col(row.get('num_fg', '#FFFFFF'))}",
                f'text = "{i + 1}"',
                "horizontal_alignment = 1", "vertical_alignment = 1"])
            idx += 1
        if rule and rule.get("title"):
            rect = self.baseline_rect(68.0, 32.0, rule["title"][1], 18.0,
                                      row.get("tfg_weight", "900"))
            sc.node("Title", "Label", box, idx, [
                "layout_mode = 0",
                "anchor_right = 1.0",
                f"offset_left = {n(68.0)}", f"offset_top = {n(rect[1])}",
                f"offset_right = {n(-24.0)}", f"offset_bottom = {n(rect[1] + rect[3])}",
                "mouse_filter = 2",
                f'theme_override_fonts/font = ExtResource("{self.font(sc, row.get("tfg_weight", "900"))}")',
                f"theme_override_font_sizes/font_size = {n(18.0)}",
                f"theme_override_colors/font_color = {col(row['tfg'])}",
                f'text = "{esc(rule["title"][0])}"'])
            idx += 1
        if rule and rule.get("desc"):
            rect = self.baseline_rect(68.0, 58.0, rule["desc"][1], 16.0,
                                      row.get("dfg_weight", "600"))
            sc.node("Desc", "Label", box, idx, [
                "layout_mode = 0",
                "anchor_right = 1.0",
                f"offset_left = {n(68.0)}", f"offset_top = {n(rect[1])}",
                f"offset_right = {n(-24.0)}", f"offset_bottom = {n(rect[1] + rect[3])}",
                "mouse_filter = 2",
                f'theme_override_fonts/font = ExtResource("{self.font(sc, row.get("dfg_weight", "600"))}")',
                f"theme_override_font_sizes/font_size = {n(16.0)}",
                f"theme_override_colors/font_color = {col(row['dfg'])}",
                f'text = "{esc(rule["desc"][0])}"'])

    def build_cta(self, sc: Scene, ppath: str, key: str, d: dict) -> None:
        sb = sc.sub_stylebox({
            "bg": col(d["cta_fill"]), "radius": CTA_RADIUS * S, "bw": 3.5 * S,
            "border": col(d["cta_stroke"])})
        empty = sc.stylebox_empty()
        # offset chỉ là giá trị tạm — page.gd dàn lại theo khung khi chạy
        sc.node("Cta", "Button", ppath, 2, [
            "layout_mode = 0",
            f"offset_left = {n(CTA_RECT['x'])}", "offset_top = 0",
            f"offset_right = {n(CTA_RECT['x'] + CTA_RECT['w'])}",
            f"offset_bottom = {n(CTA_RECT['h'])}",
            "focus_mode = 0",
            f'theme_override_fonts/font = ExtResource("{self.font(sc, d["cta_text_weight"])}")',
            f"theme_override_font_sizes/font_size = {n(d['cta_text_size'])}",
            f"theme_override_colors/font_color = {col(d['cta_text_fill'])}",
            f"theme_override_colors/font_hover_color = {col(d['cta_text_fill'])}",
            f"theme_override_colors/font_pressed_color = {col(d['cta_text_fill'])}",
            f'theme_override_styles/normal = SubResource("{sb}")',
            f'theme_override_styles/hover = SubResource("{sb}")',
            f'theme_override_styles/pressed = SubResource("{sb}")',
            f'theme_override_styles/focus = SubResource("{empty}")',
            f'text = "{esc(key)}"'])

    def build_link(self, sc: Scene, ppath: str, key: str, d: dict) -> None:
        empty = sc.stylebox_empty()
        sc.node("Link", "Button", ppath, 3, [
            "layout_mode = 0",
            f"offset_left = {n(CTA_RECT['x'])}", "offset_top = 0",
            f"offset_right = {n(CTA_RECT['x'] + CTA_RECT['w'])}",
            f"offset_bottom = {n(LINK_H)}",
            "focus_mode = 0",
            "flat = true",
            f'theme_override_fonts/font = ExtResource("{self.font(sc, d["link_weight"])}")',
            f"theme_override_font_sizes/font_size = {n(d['link_size'])}",
            f"theme_override_colors/font_color = {col(d['link_fill'])}",
            f"theme_override_colors/font_hover_color = {col(d['link_fill'], 0.75)}",
            f"theme_override_colors/font_pressed_color = {col(d['link_fill'], 0.75)}",
            f'theme_override_styles/normal = SubResource("{empty}")',
            f'theme_override_styles/hover = SubResource("{empty}")',
            f'theme_override_styles/pressed = SubResource("{empty}")',
            f'theme_override_styles/focus = SubResource("{empty}")',
            f'text = "{esc(key)}"'])


def read_scene_ids(path: Path) -> tuple:  # noqa: D401
    """-> (uid, unique_id) của scene đang có (nếu có).

    CHỈ đọc dòng đầu ([gd_scene ...]) — nếu đọc cả file sẽ vớ phải uid của
    ext_resource(content_instruction) khi scene chưa có uid riêng.
    """
    if not path.exists():
        return ("", "")
    text = path.read_text(encoding="utf-8")
    first = text.splitlines()[0]
    m = re.search(r'uid="(uid://[^"]+)"', first)
    uid = m.group(1) if m else ""
    if uid == "uid://j75ew1kc04k7":
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
        print(f"[OK]   {mode:14s} -> nodes/popups/instruction/{mode}.tscn  (~{node_count} node)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
