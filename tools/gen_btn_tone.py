#!/usr/bin/env python3
"""Nút ĐỒNG TÔNG với cả màn (giấy kem · mực navy · hổ phách): SVG là NGUỒN, PNG xuất cho Godot. Ra:
  achievements/btn_claim_big_{normal,pressed}   200×50  (PNG 2×, nút NHẬN lớn — hổ phách + gờ đáy; TextureButton ignore_texture_size)
  common/btn_plus_{normal,pressed}              32×32   (PNG 1×, cắt 9 khúc lề 9/9/9/12 — nút "+" của chip Xu/Mạng; dấu "+" là chữ của Button)
  shop/pager_{prev,next}                        44×40   (PNG 2×, nút chuyển trang: chip kem viền be + mũi tên navy)
ĐỔI THEME = thay file cùng tên + cùng kích thước logic. Dùng: python3 gen_btn_tone.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
AMB_T, AMB_F, AMB_D, AMB_E = "#FFC04A", "#F59E0B", "#B86A00", "#D98200"   # sáng · mặt · gờ đáy · viền
INK, EDGE, BASE = "#164663", "#E3D8C6", "#D9CCB8"
def amber(w, h, rx, press, ridge=4, stroke=1.5):
    dy = 2 if press else 0
    r = 1 if press else ridge
    return (f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{AMB_T}"/><stop offset="1" stop-color="{AMB_F}"/></linearGradient></defs>'
            f'<rect x="1" y="{1+r+dy}" width="{w-2}" height="{h-2-ridge}" rx="{rx}" fill="{AMB_D}"/>'
            f'<rect x="1" y="{1+dy}" width="{w-2}" height="{h-2-ridge}" rx="{rx}" fill="url(#g)" stroke="{AMB_E}" stroke-width="{stroke}"/>'
            f'<rect x="{rx*0.7:.1f}" y="{2.5+dy}" width="{w-rx*1.4:.1f}" height="2.2" rx="1.1" fill="#FFFFFF" opacity="0.45"/>')
def chev(prev, press):
    dy = 2 if press else 0
    pts = "26,12 18,20 26,28" if prev else "18,12 26,20 18,28"
    return (f'<rect x="1" y="{5+dy}" width="42" height="33" rx="12" fill="{BASE}"/>'
            f'<rect x="1" y="{1+dy}" width="42" height="33" rx="12" fill="#FFFFFF" stroke="{EDGE}" stroke-width="2"/>'
            f'<polyline points="{pts}" transform="translate(0 {dy-2})" fill="none" stroke="{INK}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>')
jobs = []  # (grp, name, w, h, scale, body)
for nm, pr in (("normal", False), ("pressed", True)):
    jobs += [("achievements", f"btn_claim_big_{nm}", 200, 50, 2, amber(200, 50, 14, pr, 5, 2)),
             ("common", f"btn_plus_{nm}", 32, 32, 1, amber(32, 32, 9, pr, 3, 1.5))]
jobs += [("shop", "pager_prev", 44, 40, 2, chev(True, False)), ("shop", "pager_next", 44, 40, 2, chev(False, False))]
with sync_playwright() as p:
    br = p.chromium.launch()
    for g, name, w, h, sc, body in jobs:
        for r in (f"{A}/images/{g}", f"{A}/images-png/{g}"): os.makedirs(r, exist_ok=True)
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>'
        open(f"{A}/images/{g}/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=sc)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/{g}/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(jobs))
