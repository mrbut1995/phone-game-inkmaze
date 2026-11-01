#!/usr/bin/env python3
"""Nút kiểu Y3 — HUY HIỆU TRÒN / VIÊN THUỐC cùng ngôn ngữ với Dock (hổ phách · viền trắng 3px · gờ đáy sẫm). SVG nguồn, PNG xuất. Ra:
  achievements/btn_claim_big_{normal,pressed}  200×50 (PNG 2×)  viên thuốc NHẬN
  common/btn_plus_{normal,pressed}             32×32 (PNG 1×, cắt 9 khúc lề 15/15/15/17) nút "+" của chip (dấu + là chữ của Button)
  shop/pager_{prev,next}                       40×40 (PNG 2×)   nút tròn chuyển trang, mũi tên trắng
  shop/dot_active 30×18 · shop/dot_inactive 12×18 (PNG 2×)       chấm trang: viên thuốc hổ phách viền trắng / chấm kem
ĐỔI THEME = thay file cùng tên + cùng kích thước logic. Dùng: python3 gen_btn_y3.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
F, D, E = "#F59E0B", "#B86A00", "#E3D8C6"
def pill(w, h, press, bw=3, ridge=3):  # viên thuốc / hình chữ nhật bo tròn hết cỡ
    dy = 2 if press else 0; r = 1 if press else ridge
    fh = h - ridge - 1; rad = fh / 2
    return (f'<rect x="1" y="{1+r+dy}" width="{w-2}" height="{fh}" rx="{rad}" fill="{D}"/>'
            f'<rect x="{1+bw/2}" y="{1+bw/2+dy}" width="{w-2-bw}" height="{fh-bw}" rx="{rad-bw/2}" fill="{F}" stroke="#FFFFFF" stroke-width="{bw}"/>')
def disc(s, press, bw=3, ridge=3):  # huy hiệu tròn s×s
    dy = 2 if press else 0; r = 1 if press else ridge
    d = s - ridge - 1; c = s / 2; rad = d / 2
    return (f'<circle cx="{c}" cy="{1+rad+r+dy}" r="{rad}" fill="{D}"/>'
            f'<circle cx="{c}" cy="{1+rad+dy}" r="{rad-bw/2}" fill="{F}" stroke="#FFFFFF" stroke-width="{bw}"/>')
def chev(left):
    pts = "23,12 16,20 23,28" if left else "17,12 24,20 17,28"
    return f'<polyline points="{pts}" transform="translate(0 -1.5)" fill="none" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>'
jobs = []
for nm, pr in (("normal", False), ("pressed", True)):
    jobs += [("achievements", f"btn_claim_big_{nm}", 200, 50, 2, pill(200, 50, pr)),
             ("common", f"btn_plus_{nm}", 32, 32, 1, disc(32, pr))]
jobs += [("shop", "pager_prev", 40, 40, 2, disc(40, False) + chev(True)), ("shop", "pager_next", 40, 40, 2, disc(40, False) + chev(False)),
         ("shop", "dot_active", 30, 18, 2, pill(30, 18, False, 2.5, 2)),
         ("shop", "dot_inactive", 12, 18, 2, f'<circle cx="6" cy="8" r="5" fill="#FFFFFF" stroke="{E}" stroke-width="2"/><path d="M1.2 10.5a5 5 0 0 0 9.6 0" fill="none" stroke="#D9CCB8" stroke-width="2"/>')]
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
