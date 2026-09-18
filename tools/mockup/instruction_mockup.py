#!/usr/bin/env python3
"""Parser mockup popup hướng dẫn (mockup/instruction/*.svg) + ảnh guideline đã tách.

Dùng chung cho:
  - tools/mockup/prepare_guideline_images.py  (ảnh -> bản ThorVG-safe)
  - tools/content/build_instruction_data.py   (sinh khoá dịch STR_GI_*)
  - tools/mockup/gen_instruction_popups.py    (sinh 9 scene popup)

Mỗi file mockup = 1 trang của 1 chế độ. Khung chuẩn (đo từ mockup):
  - Popup:  tờ giấy 920x1480 tại (80,200)
  - Chip:   rect 190x30 tại (190,248) + chữ 13px
  - Title:  baseline (190,318), 38px
  - Tabs:   3 rect 245x48 tại y=342, x = 185/440/695
  - Panel:  khung minh hoạ 755x510 tại (185,410)
  - Section baseline (185,979) · 3 hàng luật 755x76 tại y=997/1085/1173
  - Nav:    ‹ › 52x52 tại (185,1300)/(385,1300) · dots · "TRANG x / 3" mép x=940
  - CTA:    755x100 tại (185,1380) · Link baseline (562,1522)

Ảnh guideline (assets/images/instructions/guideline_image/): viewBox -15 -10 785 535
  -> đặt tại popup-local (90,200) size 785x535 để khung 755x510 nằm đúng (105,210).
  Ảnh giữ lại SỐ TRÊN GRID + ký hiệu trong lưới (đã có tool riêng xử lý ThorVG-safe);
  các chữ đó KHÔNG cần đặt lại bằng Label.
"""

from __future__ import annotations

import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MOCK_DIR = ROOT / "mockup" / "instruction"
IMG_DIR = ROOT / "assets" / "images" / "instructions" / "guideline_image"

POPUP_X, POPUP_Y = 80.0, 200.0
PANEL_X, PANEL_Y = 105.0, 210.0
PANEL_W, PANEL_H = 755.0, 510.0
IMG_PAD = Vector2 = (15.0, 10.0)   # viewBox -15 -10 -> lề trái 15, lề trên 10

# mode_id -> (tên file mockup, tên file ảnh guideline) — {n} = số trang
MODES = {
    "normal_maze":   ("instruction_normal_maze_p{n}.svg", "image_guideline_instruction_normal_maze_p{n}.svg"),
    "dungeon":       ("instruction_dungeon_p{n}.svg", "image_guideline_instruction_dungeon_p{n}.svg"),
    "minesweeper":   ("popup_instruction_minesweeper_page{n}.svg", "image_guideline_instruction_minesweeper_page{n}.svg"),
    "sumpath":       ("popup_instruction_sumpath_page{n}.svg", "image_guideline_instruction_sumpath_page{n}.svg"),
    "countdowncost": ("popup_instruction_countdowncost_page{n}.svg", "image_guideline_instruction_countdowncost_page{n}.svg"),
    "fadingink":     ("popup_instruction_fadingink_page{n}.svg", "image_guideline_instruction_fadingink_page{n}.svg"),
    "blindmemory":   ("popup_instruction_blindmemory_page{n}.svg", "image_guideline_instruction_blindmemory_page{n}.svg"),
    "fog_of_war":    ("popup_instruction_fog_of_war_page{n}.svg", "image_guideline_instruction_fog_of_war_page{n}.svg"),
    "time_attack":   ("popup_instruction_time_attack_page{n}.svg", "image_instruction_time_attack_page{n}.svg"),
    "one_stroke":    ("popup_instruction_one_stroke_p{n}.svg", "image_guideline_instruction_one_stroke_page{n}.svg"),
    "wall_builder":  ("popup_instruction_wallbuilder_page{n}.svg", "image_guideline_instruction_wall_builder_page{n}.svg"),
}

PAGES_PER_MODE = 3

TAG = re.compile(r"\{.*\}")
NUM = re.compile(r"[,\s]+")
# Chuỗi có chữ cái (Unicode) — dùng để nhận diện chuỗi nào cần khoá dịch
HAS_LETTER = re.compile(r"[^\W\d_]", re.UNICODE)
# Token luôn giống nhau ở mọi ngôn ngữ (số trên grid, dấu, S/F...)
LITERAL_TOKENS = {"S", "F"}


def is_literal_text(txt: str) -> bool:
    """True nếu chuỗi KHÔNG cần dịch (số/ký hiệu/S/F) -> ghi thẳng vào scene."""
    return not HAS_LETTER.search(txt) or txt in LITERAL_TOKENS

# Ký tự font Be Vietnam Pro KHÔNG vẽ được -> lọc khỏi chuỗi app (số tab vẽ bằng node riêng)
UNSUPPORTED_RANGES = (
    (0x2190, 0x21FF), (0x2300, 0x23FF), (0x2460, 0x24FF), (0x2600, 0x27BF),
    (0x2B00, 0x2BFF), (0xFE00, 0xFE0F), (0x1F000, 0x1FAFF),
)


def strip_tag(t: str) -> str:
    return TAG.sub("", t)


def clean_text(txt: str) -> str:
    # mũi tên ➔ (font app không có) -> chấm • để câu không dính chữ
    txt = txt.replace("➔", " • ").replace("➜", " • ")
    out = []
    for ch in txt:
        cp = ord(ch)
        if any(a <= cp <= b for a, b in UNSUPPORTED_RANGES):
            continue
        out.append(ch)
    s = re.sub(r"[ \t]{2,}", " ", "".join(out)).strip()
    s = re.sub(r"^\s*•\s+", "", s)       # "• " trang trí đầu dòng
    s = re.sub(r"\s*•\s*$", "", s)       # "•" lơ lửng cuối dòng
    return re.sub(r"[ \t]{2,}", " ", s).strip()


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


def _inherit(style: dict, elem) -> dict:
    out = dict(style)
    for key, attr in (
        ("size", "font-size"), ("weight", "font-weight"), ("fill", "fill"),
        ("anchor", "text-anchor"), ("baseline", "dominant-baseline"),
        ("family", "font-family"),
    ):
        if elem.get(attr) is not None:
            out[key] = elem.get(attr)
    return out


class Walker:
    """Duyệt SVG: ghi text/rect/circle/path với toạ độ ABSOLUTE + style kế thừa."""

    def __init__(self):
        self.texts: list[dict] = []
        self.rects: list[dict] = []
        self.circles: list[dict] = []
        self.paths: list[dict] = []

    def walk(self, elem, tx=0.0, ty=0.0, sx=1.0, sy=1.0, style=None, opacity=1.0):
        style = style or {"size": "0", "weight": "", "fill": "", "anchor": "start",
                          "baseline": "", "family": ""}
        for child in elem:
            t = strip_tag(child.tag)
            ctx, cty, csx, csy = tx, ty, sx, sy
            cop = opacity
            if child.get("opacity") is not None:
                cop = opacity * float(child.get("opacity"))
            if t == "g":
                dx, dy, dsx, dsy = parse_transform(child.get("transform", ""))
                self.walk(child, tx + dx * sx, ty + dy * sy, sx * dsx, sy * dsy,
                          _inherit(style, child), cop)
                continue
            if t == "text":
                cs = _inherit(style, child)
                txt = " ".join((child.text or "").split())
                if txt:
                    self.texts.append({
                        "x": ctx + float(child.get("x", 0)) * csx,
                        "y": cty + float(child.get("y", 0)) * csy,
                        "size": float(cs.get("size", "0") or 0) * csy,
                        "weight": cs.get("weight", ""),
                        "fill": child.get("fill", cs.get("fill", "")),
                        "anchor": cs.get("anchor", "start") or "start",
                        "baseline": cs.get("baseline", ""),
                        "text": txt,
                    })
            elif t == "rect":
                self.rects.append({
                    "x": ctx + float(child.get("x", 0)) * csx,
                    "y": cty + float(child.get("y", 0)) * csy,
                    "w": float(child.get("width", 0)) * csx,
                    "h": float(child.get("height", 0)) * csy,
                    "rx": child.get("rx", ""),
                    "fill": child.get("fill", ""),
                    "stroke": child.get("stroke", ""),
                    "opacity": cop,
                })
            elif t == "circle":
                self.circles.append({
                    "x": ctx + float(child.get("cx", 0)) * csx,
                    "y": cty + float(child.get("cy", 0)) * csy,
                    "r": float(child.get("r", 0)) * csx,
                    "fill": child.get("fill", ""),
                })
            elif t == "path":
                self.paths.append({
                    "x": ctx, "y": cty,
                    "stroke": child.get("stroke", ""),
                })


def _find(rects, w, h, y=None, x=None, rx=None, tol=1.0):
    for r in rects:
        if abs(r["w"] - w) < tol and abs(r["h"] - h) < tol:
            if y is not None and abs(r["y"] - y) > 2.0:
                continue
            if x is not None and abs(r["x"] - x) > 2.0:
                continue
            if rx is not None and str(r["rx"]) != str(rx):
                continue
            return r
    return None


def image_texts(img_path: Path) -> list[dict]:
    """Các chữ còn lại trong ảnh guideline (giữ số trên grid...) — KHÔNG đặt lại bằng Label."""
    walker = Walker()
    walker.walk(ET.parse(img_path).getroot())
    return walker.texts


def parse_page(mode_id: str, page: int) -> dict:
    mock_name, img_name = MODES[mode_id]
    mock_path = MOCK_DIR / mock_name.format(n=page)
    img_path = IMG_DIR / img_name.format(n=page)
    walker = Walker()
    walker.walk(ET.parse(mock_path).getroot())

    data: dict = {"mode_id": mode_id, "page": page, "mock": mock_name.format(n=page),
                  "img": img_name.format(n=page)}

    # ---- màu ----
    paper_border = None
    for r in walker.rects:
        if abs(r["w"] - 920) < 1 and abs(r["h"] - 1480) < 1 and r["fill"] == "none":
            paper_border = r
    cta = _find(walker.rects, 755, 100, y=1380)
    chip = None
    for r in walker.rects:
        if abs(r["h"] - 30) < 1 and abs(r["y"] - 248) < 2 and str(r["rx"]) == "8":
            chip = r
    data["accent"] = (paper_border or {}).get("stroke", "#F59E0B")
    data["cta_fill"] = (cta or {}).get("fill", "#F59E0B")
    data["cta_stroke"] = (cta or {}).get("stroke", "#B45309")
    data["chip_bg"] = (chip or {}).get("fill", "#FEF3C7")
    data["tab_on_fill"] = data["accent"]
    for r in walker.rects:
        if abs(r["w"] - 245) < 1 and abs(r["h"] - 48) < 1 and abs(r["y"] - 342) < 2 \
                and r["fill"] not in ("#F0F7FB", "none", ""):
            data["tab_on_fill"] = r["fill"]

    # ---- phân loại chữ của popup ----
    chrome = [t for t in walker.texts if t["y"] > 210]
    row_rects = sorted([r for r in walker.rects if abs(r["w"] - 755) < 1 and abs(r["h"] - 76) < 1
                        and r["y"] > 950], key=lambda r: r["y"])

    def is_row_title(t):
        return any(abs(t["y"] - (r["y"] + 32)) < 3.5 for r in row_rects) and 15 <= t["size"] <= 22

    def is_row_desc(t):
        return any(abs(t["y"] - (r["y"] + 58)) < 3.5 for r in row_rects) and 13 <= t["size"] <= 17

    chip_txt = [t for t in chrome if 258 <= t["y"] <= 282 and t["size"] <= 14]
    title_txt = [t for t in chrome if 296 <= t["y"] <= 335 and t["size"] >= 30]
    tab_txt = sorted([t for t in chrome if 360 <= t["y"] <= 388 and 13 <= t["size"] <= 18],
                     key=lambda t: t["x"])
    section_txt = [t for t in chrome if 965 <= t["y"] <= 995 and 14 <= t["size"] <= 18]
    row_title = sorted([t for t in chrome if is_row_title(t)], key=lambda t: t["y"])
    row_desc = sorted([t for t in chrome if is_row_desc(t)], key=lambda t: t["y"])
    page_idx = [t for t in chrome if t["anchor"] == "end" and 1320 <= t["y"] <= 1345]
    cta_txt = [t for t in chrome if 1425 <= t["y"] <= 1460]
    link_txt = [t for t in chrome if 1505 <= t["y"] <= 1540]

    data["chip"] = clean_text(chip_txt[0]["text"]) if chip_txt else ""
    data["chip_fg"] = chip_txt[0]["fill"] if chip_txt else "#B45309"
    data["title"] = clean_text(title_txt[0]["text"]) if title_txt else ""
    data["tabs"] = [clean_text(t["text"]) for t in tab_txt]
    data["section"] = clean_text(section_txt[0]["text"]) if section_txt else ""
    data["section_fg"] = section_txt[0]["fill"] if section_txt else "#D97706"
    data["page_index_fg"] = page_idx[0]["fill"] if page_idx else "#D97706"
    data["cta_text"] = clean_text(cta_txt[0]["text"]) if cta_txt else ""
    data["link_text"] = clean_text(link_txt[0]["text"]) if link_txt else ""

    # ---- 3 hàng luật ----
    rows = []
    for i, r in enumerate(row_rects):
        cy = r["y"] + 38
        circle = None
        for c in walker.circles:
            if abs(c["y"] - cy) < 2 and abs(c["x"] - (r["x"] + 36)) < 2:
                circle = c
        rows.append({
            "bg": r["fill"], "border": r["stroke"],
            "num": (circle or {}).get("fill", "#D84444"),
            "tfg": row_title[i]["fill"] if i < len(row_title) else "#B91C1C",
            "dfg": row_desc[i]["fill"] if i < len(row_desc) else "#7F1D1D",
            "tfg_weight": row_title[i].get("weight", "900") if i < len(row_title) else "900",
            "dfg_weight": row_desc[i].get("weight", "600") if i < len(row_desc) else "600",
            "title": clean_text(row_title[i]["text"]) if i < len(row_title) else "",
            "desc": clean_text(row_desc[i]["text"]) if i < len(row_desc) else "",
        })
    data["rows"] = rows

    # ---- nav ----
    nav = {"prev_off": False, "next_off": False, "prev_fg": "#224C6D", "prev_border": "#6EA0C8",
           "next_fg": "#D97706", "next_border": data["accent"]}
    for p in walker.paths:
        if abs(p["y"] - 1300) < 3:
            if p["x"] < 300:
                nav["prev_fg"] = p["stroke"] or nav["prev_fg"]
            else:
                nav["next_fg"] = p["stroke"] or nav["next_fg"]
    for r in walker.rects:
        if abs(r["w"] - 52) < 1 and abs(r["h"] - 52) < 1 and abs(r["y"] - 1300) < 2:
            if r["x"] < 300:
                nav["prev_border"] = r["stroke"] or nav["prev_border"]
                if r["opacity"] < 0.9:
                    nav["prev_off"] = True
            else:
                nav["next_border"] = r["stroke"] or nav["next_border"]
                if r["opacity"] < 0.9:
                    nav["next_off"] = True
    data["nav"] = nav

    # ---- dots ----
    dots = []
    for r in walker.rects:
        if abs(r["w"] - 38) < 1 and abs(r["h"] - 18) < 1 and 1305 < r["y"] < 1330:
            dots.append({"cx": r["x"] + 19 - POPUP_X, "cy": r["y"] + 9 - POPUP_Y, "on": True})
    for c in walker.circles:
        if abs(c["r"] - 8) < 0.6 and 1305 < c["y"] < 1340 and 185 <= c["x"] <= 500:
            dots.append({"cx": c["x"] - POPUP_X, "cy": c["y"] - POPUP_Y, "on": False})
    dots.sort(key=lambda d: d["cx"])
    data["dots"] = dots

    # ---- chữ đè lên khung minh hoạ (bỏ những chữ đã nằm sẵn trong ảnh guideline) ----
    baked = image_texts(img_path)
    baked_keys = {(round(b["x"], 1), round(b["y"], 1), b["text"]) for b in baked}
    panel_texts = []
    for t in walker.texts:
        ax, ay = t["x"], t["y"]
        if not ((POPUP_X + PANEL_X - 1) <= ax <= (POPUP_X + PANEL_X + PANEL_W + 1)
                and (POPUP_Y + PANEL_Y - 1) <= ay <= (POPUP_Y + PANEL_Y + PANEL_H + 1)):
            continue
        # toạ độ panel-local (ảnh guideline dùng đúng hệ toạ độ này)
        px, py = round(ax - (POPUP_X + PANEL_X), 1), round(ay - (POPUP_Y + PANEL_Y), 1)
        if (px, py, t["text"]) in baked_keys:
            continue    # số/ký hiệu trong ảnh -> không đặt lại
        txt = clean_text(t["text"])
        if not txt:
            continue
        panel_texts.append({
            "x": round(ax - (POPUP_X + PANEL_X), 1),
            "y": round(ay - (POPUP_Y + PANEL_Y), 1),
            "size": round(t["size"], 1),
            "weight": t["weight"],
            "fill": t["fill"],
            "anchor": t["anchor"],
            "center": "central" in (t["baseline"] or ""),
            "text": txt,
        })
    data["panel_texts"] = panel_texts

    # ---- style chi tiết cho scene generator ----
    paper_bg = None
    for r in walker.rects:
        if abs(r["w"] - 920) < 1 and abs(r["h"] - 1480) < 1 and r["fill"] not in ("none", ""):
            paper_bg = r
    data["paper_bg"] = (paper_bg or {}).get("fill", "#FFFDF9")
    data["paper_rx"] = 26.0
    data["chip_rect"] = {
        "x": (chip["x"] - POPUP_X) if chip else 110.0,
        "y": (chip["y"] - POPUP_Y) if chip else 48.0,
        "w": chip["w"] if chip else 190.0,
        "h": 30.0,
    }
    chip_text = [t for t in chrome if t["anchor"] == "middle" and abs(t["y"] - 269) < 3
                 and t["size"] <= 15]
    data["chip_size"] = chip_text[0]["size"] if chip_text else 13.0
    data["chip_weight"] = chip_text[0]["weight"] if chip_text else "900"
    data["chip_stroke"] = (chip or {}).get("stroke", "") or ""
    title_style = [t for t in chrome if 300 <= t["y"] <= 335 and t["size"] >= 30]
    data["title_style"] = {
        "size": title_style[0]["size"] if title_style else 38.0,
        "fill": title_style[0]["fill"] if title_style else "#224C6D",
        "weight": title_style[0]["weight"] if title_style else "900",
    }
    tab_rects = sorted([r for r in walker.rects if abs(r["w"] - 245) < 1 and abs(r["h"] - 48) < 1
                        and abs(r["y"] - 342) < 2], key=lambda r: r["x"])
    tab_txt = sorted([t for t in chrome if 355 <= t["y"] <= 385 and t["anchor"] == "middle"
                      and 12 <= t["size"] <= 20], key=lambda t: t["x"])
    tabs_style = []
    for i, r in enumerate(tab_rects):
        t = tab_txt[i] if i < len(tab_txt) else {}
        on = r["fill"] not in ("#F0F7FB", "none", "") and r["fill"] != ""
        tabs_style.append({
            "x": r["x"] - POPUP_X, "y": r["y"] - POPUP_Y, "w": r["w"], "h": r["h"],
            "fill": r["fill"], "stroke": r["stroke"], "on": on,
            "text_fill": t.get("fill", "#718B9E"), "text_size": t.get("size", 16.0),
            "text_weight": t.get("weight", "900"),
        })
    data["tabs_style"] = tabs_style
    data["cta_text_size"] = cta_txt[0]["size"] if cta_txt else 25.0
    data["cta_text_fill"] = cta_txt[0]["fill"] if cta_txt else "#FFFFFF"
    data["cta_text_weight"] = cta_txt[0]["weight"] if cta_txt else "950"
    data["link_size"] = link_txt[0]["size"] if link_txt else 18.0
    data["link_fill"] = link_txt[0]["fill"] if link_txt else "#718B9E"
    data["link_weight"] = link_txt[0]["weight"] if link_txt else "800"
    data["page_index_size"] = page_idx[0]["size"] if page_idx else 20.0
    for i, row in enumerate(rows):
        if i >= len(row_rects):
            continue
        cy = row_rects[i]["y"] + 38
        cx = row_rects[i]["x"] + 36
        num = [t for t in chrome if t["anchor"] == "middle" and abs(t["y"] - cy) < 3
               and abs(t["x"] - cx) < 3]
        row["num_fg"] = num[0]["fill"] if num else "#FFFFFF"
        row["num_size"] = num[0]["size"] if num else 15.0
    for d in data["dots"]:
        if d["on"]:
            for r in walker.rects:
                if abs(r["x"] + 19 - (d["cx"] + POPUP_X)) < 1 and abs(r["y"] + 9 - (d["cy"] + POPUP_Y)) < 1:
                    d["fill"] = r["fill"]
        else:
            for c in walker.circles:
                if abs(c["x"] - (d["cx"] + POPUP_X)) < 1 and abs(c["y"] - (d["cy"] + POPUP_Y)) < 1:
                    d["fill"] = c["fill"]
    return data


def load_all() -> dict:
    """-> {mode_id: {1..3: page_dict}}"""
    out: dict = {}
    for mode_id in MODES:
        out[mode_id] = {}
        for p in range(1, PAGES_PER_MODE + 1):
            out[mode_id][p] = parse_page(mode_id, p)
    return out


if __name__ == "__main__":
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    write = "--strings" in sys.argv
    data = load_all()
    if write:
        idx = sys.argv.index("--strings")
        out_path = sys.argv[idx + 1] if len(sys.argv) > idx + 1 else "strings.txt"
        lines, seen = [], set()
        for mode_id, pages in sorted(data.items()):
            for pno, page in sorted(pages.items()):
                base = f"{mode_id}.p{pno}"
                pairs = [("chip", page["chip"]), ("title", page["title"]),
                         ("section", page["section"]), ("cta", page["cta_text"]),
                         ("link", page["link_text"])]
                pairs += [(f"tab{i+1}", t) for i, t in enumerate(page["tabs"])]
                for i, r in enumerate(page["rows"]):
                    pairs += [(f"row{i+1}T", r["title"]), (f"row{i+1}D", r["desc"])]
                pairs += [("panel", t["text"]) for t in page["panel_texts"]]
                for field, txt in pairs:
                    if not txt or txt in seen:
                        continue
                    seen.add(txt)
                    lines.append(f"{base}.{field:<8} :: {txt}")
        Path(out_path).write_text("\n".join(lines), encoding="utf-8")
        print(f"[OK] {len(lines)} chuoi -> {out_path}")
        raise SystemExit(0)
    for mode_id, pages in sorted(data.items()):
        for pno, page in sorted(pages.items()):
            print(f"{mode_id:<14} p{pno}  accent={page['accent']:<8} chip='{page['chip']}'  "
                  f"panel_texts={len(page['panel_texts']):>2}  rows={len(page['rows'])}  "
                  f"tabs={len(page['tabs'])}  dots={len(page['dots'])}  "
                  f"title='{page['title']}'")
