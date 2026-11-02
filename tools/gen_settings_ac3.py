#!/usr/bin/env python3
"""Màn CÀI ĐẶT kiểu AC3 (nhãn giấy dán washi · tem BẬT/TẮT · thanh trượt thước kẻ). SVG là NGUỒN, PNG xuất từ SVG (1×),
GIỮ NGUYÊN tên + kích thước PNG cũ trong settings/ (thay file là đổi theme). File MỚI: tile_strip (thẻ ngang không băng dính), stamp_on, stamp_off.
Dùng: python3 gen_settings_ac3.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
NAVY = "#164663"
def tape(cx, cy, w, h, color, rot=-3):
    n = int(h // 5)
    pts = [(-w/2, -h/2)]
    for i in range(n + 1): pts.append((-w/2 + (3 if i % 2 else 0), -h/2 + h * i / n))
    pts += [(w/2, h/2)]
    for i in range(n, -1, -1): pts.append((w/2 - (3 if i % 2 else 0), -h/2 + h * i / n))
    p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
    return f'<g transform="translate({cx} {cy}) rotate({rot})"><polygon points="{p}" fill="{color}" fill-opacity=".82"/><path d="M{-w/2+6} {-h/6}h{w-12}M{-w/2+6} {h/6}h{w-12}" stroke="#fff" stroke-opacity=".35" stroke-width="1.5"/></g>'
BLUE, RED, GREY = "#7FC4FF", "#E05A5A", "#C9D3DC"
def card(w, h, bg, bd, top, tape_color=None, tape_w=50, tape_h=15, dy=0, ridge=3):
    hh = h - top - 3 - 1.5 - (3 if dy else 0)          # chiều cao mặt thẻ cố định (nhấn xuống thì mặt thấp bớt để khỏi bị cắt đáy)
    s = (f'<rect x="1.5" y="{top+dy+ridge}" width="{w-3}" height="{hh}" rx="8" fill="#785F3C" fill-opacity=".25"/>'
         f'<rect x="1.5" y="{top+dy}" width="{w-3}" height="{hh}" rx="8" fill="{bg}" stroke="{bd}" stroke-width="2.5"/>')
    if tape_color: s += tape(w/2, top+dy, tape_w, tape_h, tape_color)
    return s
SV = {}
# Thẻ (dùng cho ô thanh trượt · ô bật/tắt · ô đám mây): băng dính protrudes ~8px trên mép thẻ
SV["tile_off"] = (199, 117, card(199, 117, "#FFFDF5", "#E3D8C6", 9, BLUE))
SV["tile_on"] = (199, 117, card(199, 117, "#FFF3C4", "#E9C35A", 9, RED))
SV["tile_strip"] = (199, 117, card(199, 117, "#FFFDF5", "#E3D8C6", 4))          # thẻ ngang (ô Ngôn ngữ), không băng dính
# Thanh trượt = thước kẻ
def ruler(fill):
    t = "".join(f'<path d="M{x} 12V{5 if i % 5 else 2}" stroke="#B9A97F" stroke-width="1.5" stroke-linecap="round"/>' for i, x in enumerate(range(8, 180, 17)))
    return f'<rect x="1" y="1" width="184" height="12" rx="3" fill="{fill}" stroke="#D9B86A" stroke-width="2"/>{t}'
SV["slider_track"] = (186, 14, ruler("#FFF3C4"))
SV["slider_track_fill"] = (186, 14, ruler("#FFE066"))
def grab(c, edge):
    return f'<g transform="translate(15 15) rotate(-5)"><polygon points="-8,-15 8,-15 6,-11 8,-7 6,-3 8,1 6,5 8,9 6,12 8,15 -8,15 -6,12 -8,9 -6,5 -8,1 -6,-3 -8,-7 -6,-11" fill="#000" opacity=".15" transform="translate(1 2)"/><polygon points="-8,-15 8,-15 6,-11 8,-7 6,-3 8,1 6,5 8,9 6,12 8,15 -8,15 -6,12 -8,9 -6,5 -8,1 -6,-3 -8,-7 -6,-11" fill="{c}" stroke="{edge}" stroke-width="1.5"/><path d="M-3 -9v18M3 -9v18" stroke="#fff" stroke-opacity=".4" stroke-width="1.5"/></g>'
SV["slider_grabber_normal"] = (30, 30, grab("#E05A5A", "#B8403F"))
SV["slider_grabber_focus"] = (30, 30, grab("#F59E0B", "#B86A00"))
SV["slider_grabber_disabled"] = (30, 30, grab("#C9D3DC", "#9DAEBB"))
# Dropdown: dòng kẻ vở (nền giấy, gạch chân navy, chevron)
def drop(w, h, bg, line, dy=0, chev=NAVY):
    cx = w - 20; cy = h / 2 - 1 + dy
    return (f'<rect x="1.5" y="{1.5+dy}" width="{w-3}" height="{h-4}" rx="5" fill="{bg}" stroke="#E3D8C6" stroke-width="2"/>'
            f'<rect x="1.5" y="{h-5+dy}" width="{w-3}" height="3.5" rx="1.7" fill="{line}"/>'
            f'<polyline points="{cx-6},{cy-3} {cx},{cy+3} {cx+6},{cy-3}" fill="none" stroke="{chev}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>')
SV["dropdown_normal"] = (200, 41, drop(200, 41, "#FFFFFF", NAVY))
SV["dropdown_pressed"] = (200, 41, drop(200, 41, "#F3F9FD", NAVY, dy=2))
SV["dropdown_focus"] = (200, 41, drop(200, 41, "#FFFFFF", "#F59E0B", chev="#B86A00"))
SV["dropdown_disabled"] = (161, 33, drop(161, 33, "#F1F0EA", "#B9C7D3", chev="#B9C7D3"))
# Nút dòng (Hướng dẫn · Ghi công · Luật chơi · Khôi phục) — 130x69 được kéo giãn theo ô
SV["row_button_normal"] = (130, 69, card(130, 69, "#FFFDF5", "#E3D8C6", 7, BLUE, 38, 12))
SV["row_button_pressed"] = (130, 69, card(130, 69, "#F3F9FD", "#9CC7E6", 7, BLUE, 38, 12, dy=3, ridge=1))
SV["row_button_focus"] = (130, 69, card(130, 69, "#FFFDF5", "#F59E0B", 7, "#F59E0B", 38, 12))
SV["row_button_disabled"] = (361, 46, card(361, 46, "#F1F0EA", "#D3D0C4", 4))
SV["row_button_danger_normal"] = (130, 69, card(130, 69, "#FFE9E6", "#F0A8A8", 7, RED, 38, 12))
SV["row_button_danger_pressed"] = (130, 69, card(130, 69, "#FFDCD8", "#E88A8A", 7, RED, 38, 12, dy=3, ridge=1))
SV["row_button_danger_focus"] = (130, 69, card(130, 69, "#FFE9E6", "#F59E0B", 7, "#F59E0B", 38, 12))
# Chip "ĐÃ KẾT NỐI" (chữ là Label đè lên)
SV["chip_cloud_connected"] = (82, 23, '<rect x="1.5" y="1.5" width="79" height="20" rx="10" fill="#E8F6EC" stroke="#3FAE6A" stroke-width="2" stroke-dasharray="5 3"/>')
# Tem BẬT / TẮT (không chữ — hiện trạng thái bằng hình: ✓ đỏ / gạch xám)
def stamp(c, mark, fill):
    return (f'<g transform="rotate(-12 20 20)"><circle cx="20" cy="20" r="17" fill="{fill}" stroke="{c}" stroke-width="2.5" stroke-dasharray="5 3.5"/>'
            f'<circle cx="20" cy="20" r="12.5" fill="none" stroke="{c}" stroke-width="1" opacity=".6"/>{mark}</g>')
SV["stamp_on"] = (40, 40, stamp("#E05A5A", '<polyline points="13,20.5 18,25.5 27.5,14.5" fill="none" stroke="#E05A5A" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round"/>', "#E05A5A14"))
SV["stamp_off"] = (40, 40, stamp("#B9C7D3", '<path d="M14 20h12" stroke="#B9C7D3" stroke-width="3.4" stroke-linecap="round"/>', "none"))
os.makedirs(f"{A}/images/settings", exist_ok=True); os.makedirs(f"{A}/images-png/settings", exist_ok=True)
with sync_playwright() as p:
    br = p.chromium.launch()
    for name, (w, h, body) in SV.items():
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>'
        open(f"{A}/images/settings/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/settings/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(SV))
