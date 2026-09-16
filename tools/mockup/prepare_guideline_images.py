#!/usr/bin/env python3
"""Chuẩn hoá ảnh guideline cho Godot/ThorVG.

Godot (ThorVG) KHÔNG render `<text>` và `<use>` trong SVG. Ảnh guideline của bạn giữ
lại số trên grid + vài ký hiệu (S/F/?/=/</>/✓/➔) dưới dạng <text>, và cầu thang dưới
dạng <use> → nếu để nguyên sẽ MẤT SỐ và MẤT CẦU THANG khi hiển thị trong game.

Tool này ghi lại ảnh (in-place) với:
  - `<use href="#id">`  -> nhúng thẳng nội dung được trỏ tới
  - `<text>`            -> `<path>` vẽ bằng glyph THẬT (Be Vietnam Pro Black, thiếu
                           ký tự thì fallback Noto Sans JP Black, ➔ -> →)
  - giữ nguyên mọi thứ khác (màu, hình khối, filter - filter sẽ bị ThorVG bỏ qua)

Ảnh gốc được sao lưu 1 lần vào mockup/instruction/_extracted_source/.

Chạy:  python tools/mockup/prepare_guideline_images.py [--check]
"""

from __future__ import annotations

import copy
import re
import shutil
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
IMG_DIR = ROOT / "assets" / "images" / "instructions" / "guideline_image"
BACKUP_DIR = ROOT / "mockup" / "instruction" / "_extracted_source"

FONT_MAIN = ROOT / "assets" / "fonts" / "Be_Vietnam_Pro" / "BeVietnamPro-Black.ttf"
FONT_FALLBACK = ROOT / "assets" / "fonts" / "Noto_Sans_JP" / "static" / "NotoSansJP-Black.ttf"

# ký tự font chính thiếu -> thay thế/thêm font dự phòng
SUBSTITUTE = {"➔": "→", "➜": "→", "➕": "+"}

SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)

TAG = re.compile(r"\{.*\}")
NUM = re.compile(r"[,\s]+")


def tag(e) -> str:
    return TAG.sub("", e.tag)


def parse_transform(s: str):
    tx = ty = 0.0
    sx = sy = 1.0
    if not s:
        return tx, ty, sx, sy
    for m in re.finditer(r"(translate|scale|matrix)\s*\(([^)]*)\)", s):
        kind = m.group(1)
        nums = [float(v) for v in NUM.split(m.group(2).strip()) if v]
        if kind == "translate":
            tx += nums[0]
            ty += nums[1] if len(nums) > 1 else 0.0
        elif kind == "scale":
            sx *= nums[0]
            sy *= nums[1] if len(nums) > 1 else nums[0]
        elif kind == "matrix" and len(nums) == 6:
            tx += nums[4]
            ty += nums[5]
            sx *= nums[0]
            sy *= nums[3]
    return tx, ty, sx, sy


class FontSet:
    def __init__(self, path: Path, fallback: Path):
        self.fonts = [self._load(path), self._load(fallback)]

    @staticmethod
    def _load(path: Path):
        font = TTFont(str(path))
        upem = font["head"].unitsPerEm
        cmap = font.getBestCmap()
        return {
            "font": font,
            "glyphset": font.getGlyphSet(),
            "cmap": cmap,
            "upem": upem,
        }

    def glyph_path(self, ch: str):
        """-> (path_d, advance_units, upem) dùng đơn vị font (Y-up)."""
        ch = SUBSTITUTE.get(ch, ch)
        for f in self.fonts:
            name = f["cmap"].get(ord(ch))
            if name is None:
                continue
            pen = SVGPathPen(f["glyphset"])
            glyph = f["glyphset"][name]
            glyph.draw(pen)
            d = pen.getCommands()
            return d, glyph.width, f["upem"]
        return "", 0.0, 1000


class Converter:
    def __init__(self, fonts: FontSet):
        self.fonts = fonts
        self.all_ids: dict = {}

    # ------------------------------------------------------------------ <use>
    def inline_use(self, elem) -> ET.Element:
        href = elem.get("href") or elem.get("{http://www.w3.org/1999/xlink}href") or ""
        target = self.all_ids.get(href.lstrip("#"))
        wrapper = ET.Element(f"{{{SVG_NS}}}g")
        if elem.get("transform"):
            wrapper.set("transform", elem.get("transform"))
        if target is None:
            return wrapper
        for sub in target:
            wrapper.append(copy.deepcopy(sub))
        return wrapper

    # ----------------------------------------------------------------- <text>
    def text_to_paths(self, elem, tx, ty, sx, sy, style) -> ET.Element:
        style = dict(style)
        for key, attr in (("size", "font-size"), ("fill", "fill"), ("anchor", "text-anchor"),
                          ("baseline", "dominant-baseline"), ("weight", "font-weight")):
            if elem.get(attr) is not None:
                style[key] = elem.get(attr)
        x = tx + float(elem.get("x", 0)) * sx
        y = ty + float(elem.get("y", 0)) * sy
        size = float(style.get("size", "0") or 0) * sy
        fill = elem.get("fill", style.get("fill", "#000000")) or "#000000"
        anchor = style.get("anchor", "start") or "start"
        baseline = style.get("baseline", "") or ""
        text = (elem.text or "")
        if "central" in baseline:
            y += size * 0.35    # dominant-baseline="central"

        # đo bề rộng để căn trái/giữa/phải
        glyphs = []
        total = 0.0
        for ch in text:
            d, adv, upem = self.fonts.glyph_path(ch)
            if size > 0.0 and upem > 0:
                adv_px = adv * size / upem
            else:
                adv_px = 0.0
            glyphs.append((d, adv_px, size / upem if upem else 0.0))
            total += adv_px
        start = x
        if anchor == "middle":
            start = x - total * 0.5
        elif anchor == "end":
            start = x - total

        # trả về <g> đặt tại vị trí (đã quy về toạ độ LOCAL của parent)
        lx = (start - tx) / sx if sx else start
        ly = (y - ty) / sy if sy else y
        group = ET.Element(f"{{{SVG_NS}}}g")
        group.set("transform", "translate(%g, %g)" % (round(lx, 3), round(ly, 3)))
        pen_x = 0.0
        for d, adv_px, scale in glyphs:
            if not d:
                pen_x += adv_px
                continue
            path = ET.SubElement(group, f"{{{SVG_NS}}}path")
            path.set("d", d)
            path.set("fill", fill)
            sc = scale / (sx if sx else 1.0)
            path.set("transform", "translate(%g, 0) scale(%g, %g)"
                     % (round(pen_x, 3), round(sc, 6), round(-sc, 6)))
            pen_x += adv_px
        return group

    # ------------------------------------------------------------------ walk
    def walk(self, elem, tx=0.0, ty=0.0, sx=1.0, sy=1.0, style=None) -> None:
        style = style or {"size": "0", "fill": "#000000", "anchor": "start",
                          "baseline": "", "weight": ""}
        i = 0
        while i < len(elem):
            child = elem[i]
            t = tag(child)
            if t == "g":
                dx, dy, dsx, dsy = parse_transform(child.get("transform", ""))
                sub_style = dict(style)
                for key, attr in (("size", "font-size"), ("fill", "fill"),
                                  ("anchor", "text-anchor"), ("baseline", "dominant-baseline"),
                                  ("weight", "font-weight")):
                    if child.get(attr) is not None:
                        sub_style[key] = child.get(attr)
                self.walk(child, tx + dx * sx, ty + dy * sy, sx * dsx, sy * dsy, sub_style)
                i += 1
            elif t == "use":
                elem[i] = self.inline_use(child)
                i += 1
            elif t == "text":
                elem[i] = self.text_to_paths(child, tx, ty, sx, sy, style)
                i += 1
            else:
                i += 1

    # ---------------------------------------------------------------- convert
    def convert(self, path: Path) -> tuple[int, int]:
        tree = ET.parse(path)
        root = tree.getroot()
        self.all_ids = {}
        for e in root.iter():
            if e.get("id"):
                self.all_ids[e.get("id")] = e
        n_text = sum(1 for e in root.iter() if tag(e) == "text")
        n_use = sum(1 for e in root.iter() if tag(e) == "use")
        self.walk(root)
        ET.indent(root, space="  ")
        xml = '<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(root, encoding="unicode")
        path.write_text(xml, encoding="utf-8")
        return n_text, n_use


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    check_only = "--check" in sys.argv
    fonts = FontSet(FONT_MAIN, FONT_FALLBACK)
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    files = sorted(IMG_DIR.glob("*.svg"))
    if not files:
        print("[LOI] khong tim thay anh nao trong", IMG_DIR)
        return 1
    total_t = total_u = 0
    for f in files:
        data = f.read_text(encoding="utf-8")
        n_text = data.count("<text")
        n_use = data.count("<use")
        if n_text == 0 and n_use == 0:
            print(f"[SKIP] {f.name} (da sach)")
            continue
        if not check_only:
            backup = BACKUP_DIR / f.name
            if not backup.exists():
                shutil.copy2(f, backup)
            conv = Converter(fonts)
            t, u = conv.convert(f)
            total_t += t
            total_u += u
            print(f"[OK]   {f.name}  text={t} use={u}")
        else:
            print(f"[CAN]  {f.name}  text={n_text} use={n_use}")
    print(f"[DONE] {len(files)} anh | chuyen {total_t} text + {total_u} use"
          + (" (chi kiem tra)" if check_only else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
