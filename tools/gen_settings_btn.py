"""Nút CÀI ĐẶT đồng bộ với chip Xu/Mạng: nền trắng bo tròn, viền kem #E3D8C6, gờ đáy, bánh răng navy #164663.
Ra: assets/images-png/common/settings_btn_{normal,pressed}.png (112x112)."""
import os, sys
from playwright.sync_api import sync_playwright
OUT = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets/images-png/common"
os.makedirs(OUT, exist_ok=True)
GEAR = ('<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>')
def svg(pressed):
    dy = 5 if pressed else 0          # nhấn: mặt nút lún xuống, gờ đáy thu lại
    base = 0 if pressed else 7
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="112" height="112" viewBox="0 0 112 112">
<rect x="6" y="{6+dy+base}" width="100" height="94" rx="30" fill="#D9CCB8"/>
<rect x="6" y="{6+dy}" width="100" height="94" rx="30" fill="#FFFFFF" stroke="#E3D8C6" stroke-width="4"/>
<g transform="translate({28} {26+dy}) scale(2.2)" fill="none" stroke="#164663" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{GEAR}</g></svg>'''
with sync_playwright() as p:
    br = p.chromium.launch(); pg = br.new_page(viewport={"width": 112, "height": 112})
    for st in ("normal", "pressed"):
        pg.set_content(f'<html><body style="margin:0;background:transparent">{svg(st=="pressed")}</body></html>')
        pg.screenshot(path=f"{OUT}/settings_btn_{st}.png", omit_background=True, clip={"x":0,"y":0,"width":112,"height":112})
print("OK")
