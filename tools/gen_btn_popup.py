#!/usr/bin/env python3
"""Nút POPUP kiểu Z3 (viên thuốc · viền trắng · gờ đáy sẫm) — GIỮ NGUYÊN MÀU CŨ (xanh lá · xám · xanh dương · hổ phách), GIỮ NGUYÊN KÍCH THƯỚC PNG cũ
(TextureButton lấy cỡ từ PNG ⇒ 1×). SVG là NGUỒN, PNG xuất từ SVG. Ra (mỗi nút 3 trạng thái normal · pressed · focus), thư mục popups/:
  go_btn_resume 382×74 (lá) · go_btn_retry 262×74 (lá) · go_btn_half 185×74 (xám) · go_btn_home 110×74 (xám)
  retry_btn_ad 186×104 (dương) · retry_btn_gold 186×104 (lá) · oof_btn_shop 186×104 (hổ phách) · oof_btn_exit 186×104 (xám)
Dùng: python3 gen_btn_popup.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
COL = {"green": ("#7BCB38", "#6DBE2A", "#4A9418"), "grey": ("#BAC6D0", "#A9B6C1", "#7D8D9A"),
       "blue": ("#6DB3DE", "#5BA3D2", "#3D83AE"), "amber": ("#FAC95A", "#F7BC3C", "#C98A12")}
JOBS = [("go_btn_resume", 382, 74, "green"), ("go_btn_retry", 262, 74, "green"), ("go_btn_half", 185, 74, "grey"), ("go_btn_home", 110, 74, "grey"),
        ("retry_btn_ad", 186, 104, "blue"), ("retry_btn_gold", 186, 104, "green"), ("oof_btn_shop", 186, 104, "amber"), ("oof_btn_exit", 186, 104, "grey")]
def art(w, h, key, state, uid):
    top, face, ridge = COL[key]
    sh = 6                                   # gờ đáy
    fh = h - sh - 4                          # mặt nút (chừa 4px cho bóng mềm bên dưới)
    rad = fh / 2 if h < 90 else 30           # nút thấp = viên thuốc; nút cao 104 = chữ nhật bo lớn
    dy = 3 if state == "pressed" else 0
    r = 3 if state == "pressed" else sh
    bd = "#FFF1B8" if state == "focus" else "#FFFFFF"
    bw = 4
    return (f'<defs><linearGradient id="g{uid}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="0.55" stop-color="{face}"/></linearGradient></defs>'
            f'<rect x="1" y="{1+r+dy+3}" width="{w-2}" height="{fh}" rx="{rad}" fill="#1A1A33" opacity="0.14"/>'
            f'<rect x="1" y="{1+r+dy}" width="{w-2}" height="{fh}" rx="{rad}" fill="{ridge}"/>'
            f'<rect x="{1+bw/2}" y="{1+bw/2+dy}" width="{w-2-bw}" height="{fh-bw}" rx="{rad-bw/2}" fill="url(#g{uid})" stroke="{bd}" stroke-width="{bw}"/>')
os.makedirs(f"{A}/images/popups", exist_ok=True); os.makedirs(f"{A}/images-png/popups", exist_ok=True)
n = 0
with sync_playwright() as p:
    br = p.chromium.launch()
    for name, w, h, key in JOBS:
        for st in ("normal", "pressed", "focus"):
            sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{art(w, h, key, st, n)}</svg>'
            open(f"{A}/images/popups/{name}_{st}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
            pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
            pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
            pg.screenshot(path=f"{A}/images-png/popups/{name}_{st}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close(); n += 1
    br.close()
print("OK", n)
