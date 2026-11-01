#!/usr/bin/env python3
"""PANEL GIẤY LÒ XO (kiểu U) cho thanh tab Cửa hàng + Sổ tay thành tựu — CÙNG hình học với dock_panel (gen_dock_j.py):
giấy kẻ dòng, viền kem, gờ đáy, vòng lò xo nhô 12px khỏi mép trên; giữa = 1 chu kỳ vòng (32px) lát NGANG (TILE_FIT).
SVG là NGUỒN, PNG xuất 1x (NinePatchRect). Ra:
  shop/nav_bar            88×88  (thân 76 + vòng nhô 12)   lề 28/30/28/30
  achievements/seg_track  88×90  (thân 78 + vòng nhô 12)   lề 28/30/28/30
  achievements/seg_track_land 88×88 (BẢN NGANG: vòng lò xo ở mép trái, lát DỌC)   lề 30/28/30/28
ĐỔI THEME = thay file cùng tên + cùng kích thước logic.  Dùng: python3 gen_panel_u.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
PAPER, EDGE, BASE, LINE, RING_F, RING_E = "#FBF7EC", "#E3D8C6", "#D9CCB8", "#CFE0EC", "#8FA3B3", "#5E7586"
def panel(W, H, TOP=12, ruled=True):
    lines = ""
    if ruled: lines = "".join(f'<line x1="{x0}" y1="{y}" x2="{x1}" y2="{y}" stroke="{LINE}" stroke-width="1"/>'
                    for y in range(TOP + 24, H - 14, 22) for x0, x1 in ((16, 28), (28, 60), (60, 72)))
    body_h = H - TOP - 6   # gờ đáy 4px
    return (f'<rect x="1.5" y="{TOP+5.5}" width="{W-3}" height="{body_h}" rx="26" fill="{BASE}"/>'
            f'<rect x="1.5" y="{TOP+1.5}" width="{W-3}" height="{body_h}" rx="26" fill="{PAPER}" stroke="{EDGE}" stroke-width="3"/>' + lines +
            f'<rect x="39" y="1" width="10" height="22" rx="5" fill="{RING_F}" stroke="{RING_E}" stroke-width="2"/>')
jobs = [("shop", "nav_bar", 88, 88), ("achievements", "seg_track", 88, 90), ("achievements", "seg_track_land", 88, 88)]
def body_for(name, w, h):
    if name == "seg_track_land":   # bản NGANG: cột tab dọc — vòng lò xo nằm mép TRÁI (xoay panel -90°)
        return f'<g transform="translate(0 {h}) rotate(-90)">{panel(h, w, ruled=False)}</g>'   # không kẻ dòng: lát/giãn NGANG sẽ làm nét dọc dày lên
    return panel(w, h)
with sync_playwright() as p:
    br = p.chromium.launch()
    for grp, name, w, h in jobs:
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body_for(name, w, h)}</svg>'
        for r in (f"{A}/images/{grp}", f"{A}/images-png/{grp}"): os.makedirs(r, exist_ok=True)
        open(f"{A}/images/{grp}/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/{grp}/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK")
