"""Nút màn kiểu AB3: nhãn giấy vở dán băng dính washi. SVG nguồn + PNG 224x224 xuất từ SVG."""
import sys, os
from playwright.sync_api import sync_playwright
OUT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
SVG = f'{OUT}/assets/images/level_selector'; PNG = f'{OUT}/assets/images-png/level_selector'

# (paper, border, tape, shadow, rule)
SK = {
 'normal':  ('#FFF8DC', '#E3D8C6', '#7FC4FF', '#B9A97F', '#7FA6C2'),
 'current': ('#FFE9A8', '#E9B93A', '#E05A5A', '#C9962A', '#C98A0A'),
 'disabled':('#F1F0EA', '#D3D0C4', '#C9D3DC', '#C4C0B2', '#B9C7D3'),
 'bonus_normal':  ('#FFE6D6', '#E8895A', '#FF9E57', '#C4724A', '#E8895A'),
 'bonus_current': ('#FFD9B8', '#E8622E', '#E05A5A', '#B8481F', '#E8622E'),
 'bonus_disabled':('#EFE7E0', '#D6C9BE', '#D5CCC4', '#C7BCB0', '#CFC3B8'),
}
def tape(c, dy):
    # băng dính nghiêng, 2 đầu răng cưa
    pts = '-34,-14 -30,-9 -34,-4 -30,1 -34,6 -30,11 -34,14 34,14 30,9 34,4 30,-1 34,-6 30,-11 34,-14'
    return (f'<g transform="translate(112 {26+dy}) rotate(-4)">'
            f'<polygon points="{pts}" fill="{c}" fill-opacity=".82"/>'
            f'<path d="M-24 -8h48M-24 0h48M-24 8h48" stroke="#fff" stroke-opacity=".35" stroke-width="2"/></g>')
def svg(kind, lift=0, sink=0):
    paper, border, tp, sh, rule = SK[kind]
    dy = sink - lift
    sdy = 7 if sink == 0 and lift == 0 else (9 if lift else 2)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="224" height="224" viewBox="0 0 224 224">
<rect x="24" y="{28+dy+sdy}" width="176" height="164" rx="14" fill="{sh}" fill-opacity=".55"/>
<rect x="24" y="{28+dy}" width="176" height="164" rx="14" fill="{paper}" stroke="{border}" stroke-width="4"/>
<path d="M50 {34+dy}v152" stroke="#E05A5A" stroke-opacity=".35" stroke-width="2.5"/>
<path d="M62 {152+dy}h126M62 {170+dy}h126" stroke="{rule}" stroke-opacity=".28" stroke-width="2.5" stroke-linecap="round"/>
{tape(tp, dy)}
</svg>'''
def halo():
    return '''<svg xmlns="http://www.w3.org/2000/svg" width="224" height="224" viewBox="0 0 224 224">
<rect x="10" y="12" width="204" height="190" rx="26" fill="#F59E0B" fill-opacity=".10"/>
<rect x="10" y="12" width="204" height="190" rx="26" fill="none" stroke="#F59E0B" stroke-width="5" stroke-linecap="round" stroke-dasharray="14 10" stroke-opacity=".85"/>
</svg>'''
FILES = {}
for k in ('normal','current','disabled','bonus_normal','bonus_current','bonus_disabled'):
    base = 'lv_node_' + k
    FILES[base] = svg(k)
FILES['lv_node_hover'] = svg('normal', lift=3)
FILES['lv_node_pressed'] = svg('normal', sink=10)
FILES['lv_node_bonus_pressed'] = svg('bonus_normal', sink=10)
FILES['lv_node_halo'] = halo()
os.makedirs(SVG, exist_ok=True); os.makedirs(PNG, exist_ok=True)
with sync_playwright() as p:
    b = p.chromium.launch(); pg = b.new_page(viewport={'width':224,'height':224}, device_scale_factor=1)
    for n, s in FILES.items():
        open(f'{SVG}/{n}.svg','w').write(s)
        pg.set_content(f'<body style="margin:0;background:transparent">{s}</body>')
        pg.screenshot(path=f'{PNG}/{n}.png', omit_background=True, clip={'x':0,'y':0,'width':224,'height':224})
    b.close()
print(sorted(FILES))
