"""Nút ĐẦU MÀN CHƠI (Tạm dừng · Hướng dẫn) cùng phong cách nút Cài đặt/chip: nền trắng bo, viền kem, gờ đáy, glyph navy.
Ra: assets/images/game/btn_{pause,help}_chip_*.svg (NGUỒN, 56x56 logic) + assets/images-png/game/*.png (112x112, 2x).
Thay theme = thay file cùng tên. Dùng: python3 gen_topbar_btns.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
OUT, SV = f"{A}/images-png/game", f"{A}/images/game"
os.makedirs(OUT, exist_ok=True); os.makedirs(SV, exist_ok=True)
G = {"pause": '<rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/>',
     "help": '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>'}
def svg(g, st):
    dy = 5 if st == "pressed" else 0; base = 0 if st == "pressed" else 7
    op = .45 if st == "disabled" else 1
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="56" height="56" viewBox="0 0 112 112"><g opacity="{op}">
<rect x="6" y="{6+dy+base}" width="100" height="94" rx="30" fill="#D9CCB8"/>
<rect x="6" y="{6+dy}" width="100" height="94" rx="30" fill="#FFFFFF" stroke="#E3D8C6" stroke-width="4"/>
<g transform="translate(28 {26+dy}) scale(2.2)" fill="none" stroke="#164663" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{G[g]}</g></g></svg>'''
with sync_playwright() as p:
    br = p.chromium.launch(); pg = br.new_page(viewport={"width": 56, "height": 56}, device_scale_factor=2)
    for g in G:
        for st in ("normal", "pressed", "disabled"):
            sv = svg(g, st)
            open(f"{SV}/btn_{g}_chip_{st}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
            pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
            pg.screenshot(path=f"{OUT}/btn_{g}_chip_{st}.png", omit_background=True, clip={"x":0,"y":0,"width":56,"height":56})
print("OK")
