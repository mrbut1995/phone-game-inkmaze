#!/usr/bin/env python3
"""Popup NGÔN NGỮ theo kiểu popup Z3: nút viên thuốc (viền trắng · gờ đáy sẫm) giữ màu cũ (Áp dụng = xanh dương, Hủy = xám)
+ thẻ dòng ngôn ngữ (thường · rê · đang chọn). SVG là NGUỒN, PNG xuất từ SVG, giữ nguyên kích thước PNG cũ (1×).
Ra trong thư mục popups/:
  btn_lang_apply_{normal,pressed,focus} 195x48 · btn_lang_cancel_{normal,pressed,focus} 90x48
  lang_item_{normal,pressed,selected} 308x53   (pressed = trạng thái rê/nhấn, selected = đang chọn)
Dùng: python3 gen_btn_lang.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
COL = {"blue": ("#6DB3DE", "#5BA3D2", "#3D83AE"), "grey": ("#BAC6D0", "#A9B6C1", "#7D8D9A")}
def pill(w, h, key, state):
    top, face, ridge = COL[key]; sh = 5; fh = h - sh - 3; rad = fh / 2
    dy = 2 if state == "pressed" else 0; r = 2 if state == "pressed" else sh
    bd = "#FFF1B8" if state == "focus" else "#FFFFFF"; bw = 3.5
    return (f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="0.55" stop-color="{face}"/></linearGradient></defs>'
            f'<rect x="1" y="{1+r+dy+2}" width="{w-2}" height="{fh}" rx="{rad}" fill="#1A1A33" opacity="0.14"/>'
            f'<rect x="1" y="{1+r+dy}" width="{w-2}" height="{fh}" rx="{rad}" fill="{ridge}"/>'
            f'<rect x="{1+bw/2}" y="{1+bw/2+dy}" width="{w-2-bw}" height="{fh-bw}" rx="{rad-bw/2}" fill="url(#g)" stroke="{bd}" stroke-width="{bw}"/>')
def card(w, h, kind):
    bg, bd, rg, bw = {"normal": ("#FFFDF5", "#E3D8C6", "#E3D8C6", 2), "pressed": ("#F3F9FD", "#9CC7E6", "#BBD9EE", 2.5),
                      "selected": ("#E8F6EC", "#3FAE6A", "#3FAE6A", 2.5)}[kind]
    fh = h - 4
    return (f'<rect x="1" y="3" width="{w-2}" height="{fh}" rx="14" fill="{rg}"/>'
            f'<rect x="{1+bw/2}" y="{1+bw/2}" width="{w-2-bw}" height="{fh-bw}" rx="{14-bw/2}" fill="{bg}" stroke="{bd}" stroke-width="{bw}"/>')
JOBS = [(f"btn_lang_apply_{s}", 195, 48, lambda w, h, s=s: pill(w, h, "blue", s)) for s in ("normal", "pressed", "focus")]
JOBS += [(f"btn_lang_cancel_{s}", 90, 48, lambda w, h, s=s: pill(w, h, "grey", s)) for s in ("normal", "pressed", "focus")]
JOBS += [(f"lang_item_{k}", 308, 53, lambda w, h, k=k: card(w, h, k)) for k in ("normal", "pressed", "selected")]
os.makedirs(f"{A}/images/popups", exist_ok=True); os.makedirs(f"{A}/images-png/popups", exist_ok=True)
with sync_playwright() as p:
    br = p.chromium.launch()
    for name, w, h, fn in JOBS:
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{fn(w, h)}</svg>'
        open(f"{A}/images/popups/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=1)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/popups/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(JOBS))
