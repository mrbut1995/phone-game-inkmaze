#!/usr/bin/env python3
"""BỘ ART "CHIP GIẤY" (cùng phong cách chip Xu/Mạng + Dock J) — SVG là NGUỒN, PNG xuất 2x.
Mặt trắng, viền kem #E3D8C6, gờ đáy #D9CCB8, glyph navy #164663. MẶT NÚT cao đúng 46 = chip Xu/Mạng, căn giữa hộp nút
(gờ đáy nằm dưới) ⇒ đáy các nút trên thanh trên thẳng hàng với chip.
Ra (SVG ở assets/images/…, PNG 2x ở assets/images-png/… cùng đường dẫn):
  common/settings_btn_{normal,pressed}            56×56
  game/btn_{pause,help}_chip_{normal,pressed,disabled}   56×56
  btn_header_back_{normal,pressed,disabled,focus} 48×53   (nút Back MỌI màn — thay file cùng tên)
  shop/tab_{active,inactive}                      120×67  PNG 1x (tab Cửa hàng kiểu J: thẻ trắng + huy hiệu xanh; icon/nhãn do script đặt lên)
ĐỔI THEME = thay các file cùng tên + cùng kích thước logic.  Dùng: python3 gen_chip_ui.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
INK, EDGE, BASE = "#164663", "#E3D8C6", "#D9CCB8"
GEAR = '<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>'
PAUSE = '<rect x="6" y="4" width="4" height="16" rx="1"/><rect x="14" y="4" width="4" height="16" rx="1"/>'
HELP = '<circle cx="12" cy="12" r="10"/><path d="M9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>'
CHEV = '<path d="m15 18-6-6 6-6"/>'

def glyph(g, cx, cy, size):
    return (f'<g transform="translate({cx-size/2:.2f} {cy-size/2:.2f}) scale({size/24:.4f})" fill="none" stroke="{INK}" '
            f'stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{g}</g>')

def face_btn(W, H, g, pressed=False, op=1.0, ring=False, gsize=24):
    """Mặt 46×46 căn giữa theo chiều ngang; theo dọc: mặt + gờ 4 nằm trọn trong H, mặt căn giữa hộp."""
    x = (W - 46) / 2
    y = (H - 46) / 2 + (3 if pressed else 0)
    sh = '' if pressed else f'<rect x="{x}" y="{y+4}" width="46" height="46" rx="16" fill="{BASE}"/>'
    rg = ''
    edge = "#3B9BFF" if ring else EDGE
    return (f'<g opacity="{op}">{sh}<rect x="{x+1}" y="{y+1}" width="44" height="44" rx="15" fill="#FFFFFF" stroke="{edge}" stroke-width="2"/>'
            + glyph(g, x + 23, y + 23, gsize) + rg + '</g>')

BLUE, BLUE_D = "#3B9BFF", "#1D5FB8"
def shop_tab(active):
    # icon do script đặt: tâm x=60, y≈21 (ICON_TOP .10 · ICON_SIZE .43 của cao 67) ⇒ huy hiệu cùng tâm
    badge = (f'<circle cx="60" cy="25" r="17" fill="{BLUE_D}"/><circle cx="60" cy="21" r="17" fill="{BLUE}" stroke="#FFFFFF" stroke-width="3"/>')
    if not active:
        return badge
    card = (f'<rect x="3" y="5" width="114" height="61" rx="16" fill="{BLUE_D}"/>'
            f'<rect x="3" y="1.5" width="114" height="61" rx="16" fill="#FFFFFF" stroke="{BLUE}" stroke-width="3"/>')
    return card + badge

jobs = []   # (rel, W, H, body)
for st in ("normal", "pressed"):
    jobs.append((f"common/settings_btn_{st}", 56, 56, face_btn(56, 56, GEAR, st == "pressed")))
for nm, g in (("pause", PAUSE), ("help", HELP)):
    for st in ("normal", "pressed", "disabled"):
        jobs.append((f"game/btn_{nm}_chip_{st}", 56, 56, face_btn(56, 56, g, st == "pressed", .45 if st == "disabled" else 1)))
for st in ("normal", "pressed", "disabled", "focus"):
    jobs.append((f"btn_header_back_{st}", 48, 53, face_btn(48, 53, CHEV, st == "pressed", .45 if st == "disabled" else 1, st == "focus", 26)))
# Tab Shop: script đọc CHIỀU CAO PNG làm mốc cỡ hàng tab (art_height) ⇒ PNG phải 1x = 120×67 (xuất 2x sẽ làm tab to gấp đôi)
ONE_X = {"shop/tab_active", "shop/tab_inactive"}
jobs.append(("shop/tab_active", 120, 67, shop_tab(True)))
jobs.append(("shop/tab_inactive", 120, 67, shop_tab(False)))

with sync_playwright() as p:
    br = p.chromium.launch()
    for rel, w, h, body in jobs:
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>'
        for root in (f"{A}/images", f"{A}/images-png"):
            os.makedirs(os.path.dirname(f"{root}/{rel}") or ".", exist_ok=True)
        open(f"{A}/images/{rel}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=1 if rel in ONE_X else 2)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{A}/images-png/{rel}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(jobs))
