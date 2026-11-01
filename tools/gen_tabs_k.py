#!/usr/bin/env python3
"""ART TAB kiểu DOCK (như dock màn Main) cho CỬA HÀNG và SỔ TAY THÀNH TỰU — SVG là NGUỒN, PNG xuất 2x.
Mỗi tab có 2 art (icon đã nằm TRONG art; chữ nhãn do Label của scene, để dịch được):
  <nhóm>/tab_idle_<k>.svg|png   huy hiệu tròn + icon (chưa chọn)      shop 56×62 · achievements 50×56 (logic)
  <nhóm>/tab_focus_<k>.svg|png  thẻ trắng viền màu + huy hiệu to + icon (đang chọn; chừa chỗ cho nhãn phía dưới)
                                shop 96×126 · achievements 80×106 (logic)
k: shop = pen · theme · tool · coin  |  achievements = all · levels · dungeon · daily · special
ĐỔI THEME = thay file cùng tên + cùng kích thước logic (PNG = 2× logic). Dùng: python3 gen_tabs_k.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
COL = {"pen": ("#3B9BFF", "#1D5FB8"), "theme": ("#22B26B", "#12703F"), "tool": ("#9B6BFF", "#5F36B8"), "coin": ("#F59E0B", "#B86A00"),
       "all": ("#3B9BFF", "#1D5FB8"), "levels": ("#22B26B", "#12703F"), "dungeon": ("#9B6BFF", "#5F36B8"),
       "daily": ("#F2555A", "#A3262B"), "special": ("#F59E0B", "#B86A00")}
ICON = {
 "pen": '<path d="M12 20h9"/><path d="M16.376 3.622a1 1 0 0 1 3.002 3.002L7.368 18.635a2 2 0 0 1-.855.506l-2.872.838a.5.5 0 0 1-.62-.62l.838-2.872a2 2 0 0 1 .506-.854z"/>',
 "theme": '<path d="M15 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7Z"/><path d="M14 2v4a2 2 0 0 0 2 2h4"/>',
 "tool": '<path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/>',
 "coin": '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="4"/>',
 "all": '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>',
 "levels": '<path d="M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z"/><line x1="4" x2="4" y1="22" y2="15"/>',
 "dungeon": '<path d="M22 20v-9H2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2Z"/><path d="M18 11V4H6v7"/><path d="M15 22v-4a3 3 0 0 0-3-3a3 3 0 0 0-3 3v4"/><path d="M22 11V9"/><path d="M2 11V9"/><path d="M6 4V2"/><path d="M18 4V2"/><path d="M10 4V2"/><path d="M14 4V2"/>',
 "daily": '<path d="M8 2v4"/><path d="M16 2v4"/><rect width="18" height="18" x="3" y="4" rx="2"/><path d="M3 10h18"/><path d="m9 16 2 2 4-4"/>',
 "special": '<polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/>'}
def glyph(k, cx, cy, size):
    return (f'<g transform="translate({cx-size/2:.2f} {cy-size/2:.2f}) scale({size/24:.4f})" fill="none" stroke="#FFFFFF" '
            f'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{ICON[k]}</g>')
def badge(k, cx, cy, r):
    f, d = COL[k]
    return (f'<circle cx="{cx}" cy="{cy+4}" r="{r}" fill="{d}"/><circle cx="{cx}" cy="{cy}" r="{r}" fill="{f}" stroke="#FFFFFF" stroke-width="3"/>'
            + glyph(k, cx, cy, r * 1.1))
def idle(k):   # canvas 56×62 (badge r22)
    return 56, 62, badge(k, 28, 28, 22)
def focus(k):  # canvas 96×126: thẻ trắng + huy hiệu to (nhãn nằm ở nửa dưới thẻ)
    f, d = COL[k]
    return 96, 126, (f'<rect x="4" y="7" width="88" height="118" rx="22" fill="{d}"/>'
                     f'<rect x="4" y="2" width="88" height="118" rx="22" fill="#FFFFFF" stroke="{f}" stroke-width="3"/>' + badge(k, 48, 40, 29))
jobs = []
for g, keys, s in (("shop", ("pen", "theme", "tool", "coin"), 1.0), ("achievements", ("all", "levels", "dungeon", "daily", "special"), 0.8333)):
    for k in keys:
        for nm, fn in (("idle", idle), ("focus", focus)):
            w, h, body = fn(k)
            W, H = round(w * s), round(h * s)
            jobs.append((g, f"tab_{nm}_{k}", W, H, f'<g transform="scale({s})">{body}</g>'))
with sync_playwright() as p:
    br = p.chromium.launch()
    for g, name, W, H, body in jobs:
        for r in (f"{A}/images/{g}", f"{A}/images-png/{g}"): os.makedirs(r, exist_ok=True)
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">{body}</svg>'
        open(f"{A}/images/{g}/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": W, "height": H}, device_scale_factor=2)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/{g}/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": W, "height": H}); pg.close()
    br.close()
print("OK", len(jobs))
