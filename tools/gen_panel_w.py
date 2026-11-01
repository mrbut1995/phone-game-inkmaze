#!/usr/bin/env python3
"""PANEL GIẤY (kiểu W) cho thanh tab Cửa hàng + Sổ tay thành tựu — giấy kẻ dòng, viền kem, gờ đáy (cùng ngôn ngữ Dock J) + 2 miếng washi ghim góc.
SVG là NGUỒN, PNG xuất 1x (NinePatchRect, lề giữ nguyên scene cũ). Ra:
  shop/nav_bar            120×76  PNG 1x  (lề 24/24/24/26)
  achievements/seg_track  120×78  PNG 1x  (lề 26/26/26/30)
  common/washi_teal · washi_amber   64×20  PNG 2x (đặt bằng TextureRect, xoay nhẹ trong scene)
ĐỔI THEME = thay file cùng tên + cùng kích thước logic.  Dùng: python3 gen_panel_w.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
PAPER, EDGE, BASE, LINE = "#FBF7EC", "#E3D8C6", "#D9CCB8", "#E6EEF4"
def panel(w, h):
    fh = h - 6   # mặt giấy; 4px dưới là gờ đáy
    lines = "".join(f'<line x1="14" y1="{y}" x2="{w-14}" y2="{y}" stroke="{LINE}" stroke-width="1"/>' for y in range(24, fh - 4, 14))
    return (f'<rect x="1.5" y="5.5" width="{w-3}" height="{fh}" rx="22" fill="{BASE}"/>'
            f'<rect x="1.5" y="1.5" width="{w-3}" height="{fh}" rx="22" fill="{PAPER}" stroke="{EDGE}" stroke-width="3"/>' + lines)
def washi(c):  # đầu băng hơi răng cưa
    return (f'<polygon points="0,0 64,0 61,5 64,10 61,15 64,20 0,20 3,15 0,10 3,5" fill="{c}"/>'
            f'<rect x="6" y="3" width="52" height="1.5" fill="#FFFFFF" fill-opacity=".35"/>')
jobs = [("shop", "nav_bar", 120, 76, 1, panel(120, 76)), ("achievements", "seg_track", 120, 78, 1, panel(120, 78)),
        ("common", "washi_teal", 64, 20, 2, washi("#8FD3C6")), ("common", "washi_amber", 64, 20, 2, washi("#FFCD78"))]
with sync_playwright() as p:
    br = p.chromium.launch()
    for grp, name, w, h, sc, body in jobs:
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>'
        for r in (f"{A}/images/{grp}", f"{A}/images-png/{grp}"): os.makedirs(r, exist_ok=True)
        open(f"{A}/images/{grp}/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=sc)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/{grp}/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(jobs))
