#!/usr/bin/env python3
"""Nút kiểu Z3 (huy hiệu tròn / viên thuốc: viền trắng 3px · gờ đáy sẫm · màu theo vai trò) cho Daily. SVG nguồn, PNG xuất 2×. Ra:
  daily/btn_cta_blue_{normal,pressed}   viên thuốc CHƠI NGAY (xanh dương)   — TextureButton ignore_texture_size ⇒ co theo nút (~190×38)
  daily/btn_cta_amber_{normal,pressed}  viên thuốc THỬ SỨC (hổ phách)
  daily/btn_month_{normal,pressed}      36×46  nút mở lịch (tím + biểu tượng lịch)
  daily/btn_nav_{normal,pressed}        27×27  nút ‹ tháng trước (kem + mũi tên navy)
  daily/btn_nav_r_{normal,pressed}      27×27  nút › tháng sau
ĐỔI THEME = thay file cùng tên. Dùng: python3 gen_btn_z3.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
BLUE, AMB, PUR = ("#3B9BFF", "#1D5FB8"), ("#F59E0B", "#B86A00"), ("#9B6BFF", "#5F36B8")
INK, EDGE, BASE = "#164663", "#E3D8C6", "#D9CCB8"
def shape(w, h, rad, face, ridge, border, press, bw=3, rd=3):
    dy = 2 if press else 0; r = 1 if press else rd; fh = h - rd - 1
    return (f'<rect x="1" y="{1+r+dy}" width="{w-2}" height="{fh}" rx="{rad}" fill="{ridge}"/>'
            f'<rect x="{1+bw/2}" y="{1+bw/2+dy}" width="{w-2-bw}" height="{fh-bw}" rx="{rad-bw/2}" fill="{face}" stroke="{border}" stroke-width="{bw}"/>')
def cal(cx, cy, s, dy):
    return (f'<g transform="translate({cx-s/2} {cy-s/2+dy}) scale({s/24})" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round">'
            '<rect width="18" height="18" x="3" y="4" rx="2"/><path d="M8 2v4M16 2v4M3 10h18"/></g>')
def chev(cx, cy, left, dy):
    d = 4 if left else -4
    return (f'<polyline points="{cx+d*.8:.1f},{cy-6+dy} {cx-d*.8:.1f},{cy+dy} {cx+d*.8:.1f},{cy+6+dy}" fill="none" stroke="{INK}" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>')
jobs = []
for nm, pr in (("normal", False), ("pressed", True)):
    dy = 2 if pr else 0
    jobs += [("daily", f"btn_cta_blue_{nm}", 190, 38, shape(190, 38, 17, BLUE[0], BLUE[1], "#fff", pr)),
             ("daily", f"btn_cta_amber_{nm}", 190, 38, shape(190, 38, 17, AMB[0], AMB[1], "#fff", pr)),
             ("daily", f"btn_month_{nm}", 36, 46, shape(36, 46, 13, PUR[0], PUR[1], "#fff", pr) + cal(18, 20, 18, dy)),
             ("daily", f"btn_nav_{nm}", 27, 27, shape(27, 27, 12.5, "#FFFFFF", BASE, EDGE, pr, 2, 2) + chev(13.5, 11.5, True, dy)),
             ("daily", f"btn_nav_r_{nm}", 27, 27, shape(27, 27, 12.5, "#FFFFFF", BASE, EDGE, pr, 2, 2) + chev(13.5, 11.5, False, dy))]
with sync_playwright() as p:
    br = p.chromium.launch()
    for g, name, w, h, body in jobs:
        for r in (f"{A}/images/{g}", f"{A}/images-png/{g}"): os.makedirs(r, exist_ok=True)
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>'
        open(f"{A}/images/{g}/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=2)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/{g}/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(jobs))
