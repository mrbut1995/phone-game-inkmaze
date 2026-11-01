#!/usr/bin/env python3
"""ART TAB kiểu S cho màn CỬA HÀNG và SỔ TAY THÀNH TỰU: tab CHỌN = thẻ ĐẶC màu tab, viền navy, gờ đáy màu đậm (cao, "phổng" lên khỏi panel);
tab CHƯA chọn = TRONG SUỐT (chỉ icon màu đậm, do script đặt). SVG là NGUỒN, PNG xuất 1x. Ra:
  shop/tab_active_<k> 120×84 (k = pen · theme · tool · coin) · shop/tab_active (chung) · shop/tab_inactive (trong suốt)
  achievements/tab_active_<k> 72×84 (cắt 9 khúc, lề 18; k = all · levels · dungeon · daily · special) · achievements/tab_inactive
Script Shop đọc CAO PNG làm mốc cỡ hàng tab ⇒ giữ 1x.  ĐỔI THEME = thay file cùng tên + cùng kích thước.
Dùng: python3 gen_tabs_j.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
COL = {"pen": ("#3B9BFF", "#1D5FB8"), "theme": ("#22B26B", "#12703F"), "tool": ("#9B6BFF", "#5F36B8"), "coin": ("#F59E0B", "#B86A00"),
       "all": ("#3B9BFF", "#1D5FB8"), "levels": ("#22B26B", "#12703F"), "dungeon": ("#9B6BFF", "#5F36B8"), "daily": ("#F2555A", "#A3262B"), "special": ("#F59E0B", "#B86A00")}
INK = "#164663"
def badge():  # canvas 34×34: ô vuông trắng bo, viền màu tab (tab CHƯA chọn)
    return lambda c, d: f'<rect x="1.5" y="1.5" width="31" height="31" rx="10" fill="#FFFFFF" stroke="{c}" stroke-width="3"/>'
def badge_box():  # canvas 56×56, cắt 9 khúc lề 18: Ô VUÔNG TRẮNG bo, viền màu tab, gờ đáy màu đậm (icon tab CHƯA chọn nằm trong)
    return lambda c, d: (f'<rect x="2.5" y="4.5" width="51" height="49" rx="16" fill="{d}"/>'
                         f'<rect x="2.5" y="1.5" width="51" height="49" rx="16" fill="#FFFFFF" stroke="{c}" stroke-width="3"/>')
def card(w, h):
    # tab ĐANG chọn: thẻ ĐẶC màu tab, viền navy, gờ đáy màu đậm
    return lambda c, d: (f'<rect x="2.5" y="4.5" width="{w-5}" height="{h-6}" rx="16" fill="{d}"/>'
                         f'<rect x="2.5" y="1.5" width="{w-5}" height="{h-6}" rx="16" fill="{c}" stroke="{INK}" stroke-width="3"/>')
jobs = []  # (grp, name, w, h, scale, bodyfn, color_key)
for k in ("pen", "theme", "tool", "coin"):
    jobs += [("shop", f"tab_active_{k}", 120, 84, 1, card(120, 84), k)]
jobs += [("shop", "tab_active", 120, 84, 1, card(120, 84), "pen"), ("shop", "tab_inactive", 120, 84, 1, lambda c, d: "", "pen")]
for k in ("all", "levels", "dungeon", "daily", "special"):
    jobs += [("achievements", f"tab_active_{k}", 72, 84, 1, card(72, 84), k)]
jobs += [("achievements", "tab_inactive", 72, 84, 1, lambda c, d: "", "all")]
for k in ("pen", "theme", "tool", "coin"):
    jobs += [("shop", f"tab_badge_{k}", 56, 56, 1, badge_box(), k)]
for k in ("all", "levels", "dungeon", "daily", "special"):
    jobs += [("achievements", f"tab_badge_{k}", 56, 56, 1, badge_box(), k)]
with sync_playwright() as p:
    br = p.chromium.launch()
    for grp, name, w, h, sc, fn, ck in jobs:
        c, d = COL[ck]
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{fn(c, d)}</svg>'
        for r in (f"{A}/images/{grp}", f"{A}/images-png/{grp}"): os.makedirs(r, exist_ok=True)
        open(f"{A}/images/{grp}/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=sc)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/{grp}/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(jobs))
