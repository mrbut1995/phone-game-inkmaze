#!/usr/bin/env python3
"""Board art kiểu AJ1: panel thước kẻ (AH1) + ô/tường/neo/cầu thang kiểu AG2.
Chạy:  python3 tools/gen_board_ag2.py   (cần playwright + chromium)
Ghi SVG vào assets/images/game, PNG (xuất từ SVG, scale 1) vào assets/images-png/game."""
import os,sys
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SV=os.path.join(ROOT,'assets/images/game'); PN=os.path.join(ROOT,'assets/images-png/game')
os.makedirs(SV,exist_ok=True); os.makedirs(PN,exist_ok=True)
INK='#3E4249'; LINE='#B9CDB0'
UP='<path d="M6 26h7v-7h7v-7h7V5" fill="none" stroke="{c}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M22 5h5v5" fill="none" stroke="{c}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>'
DN='<path d="M6 6h7v7h7v7h7v6" fill="none" stroke="{c}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M22 26h5v-5" fill="none" stroke="{c}" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>'
def svg(w,h,vb,body): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="{vb}" width="{w}" height="{h}">\n{body}\n</svg>\n'
def cell_bg(fill,stroke,sw=2.2):
    i=sw/2
    return f'<rect x="{i}" y="{i}" width="{176-sw}" height="{176-sw}" fill="{fill}"/><rect x="{i}" y="{i}" width="{176-sw}" height="{176-sw}" fill="none" stroke="{stroke}" stroke-width="{sw}"/>'
def card(fill,icon,ic,stroke=INK):
    # thẻ giấy cắt góc phải-trên, trong ô 176
    return (f'<path d="M14 14H128L162 48V162H14Z" fill="#000" opacity=".12" transform="translate(0 4)"/>'
            f'<path d="M14 14H128L162 48V162H14Z" fill="{fill}" stroke="{stroke}" stroke-width="5" stroke-linejoin="round"/>'
            f'<path d="M128 14V48H162" fill="none" stroke="{stroke}" stroke-width="3" stroke-linejoin="round" opacity=".55"/>'
            f'<g transform="translate(40 40) scale(3.1)">{icon.format(c=ic)}</g>')
LOCK=('<g transform="translate(88 94)"><path d="M-17 -6V-18a17 17 0 0 1 34 0V-6" fill="none" stroke="#3E4249" stroke-width="7" stroke-linecap="round"/>'
      '<rect x="-26" y="-6" width="52" height="40" rx="7" fill="#E9B949" stroke="#3E4249" stroke-width="5"/><circle cx="0" cy="12" r="5.5" fill="#3E4249"/><rect x="-2.5" y="14" width="5" height="11" rx="2" fill="#3E4249"/></g>')
A={}
A['cell_normal']=svg(88,88,'0 0 176 176',cell_bg('#FBFDF6',LINE))
A['cell_normal_alt']=svg(88,88,'0 0 176 176',cell_bg('#EEF5E6',LINE))
A['cell_pressed']=svg(88,88,'0 0 176 176',cell_bg('#D5E5C6','#7FA06A'))
A['cell_disabled']=svg(88,88,'0 0 176 176',cell_bg('#E8E8E2','#CACAC2'))
A['cell_start']=svg(88,88,'0 0 176 176',cell_bg('#FBFDF6',LINE)+card('#BFD6EA',DN,INK))
A['cell_finish']=svg(88,88,'0 0 176 176',cell_bg('#FBFDF6',LINE)+card('#F6D58A',UP,INK))
A['cell_finish_closed']=svg(88,88,'0 0 176 176',cell_bg('#FBFDF6',LINE)+card('#D3D5D0','','#8A8F98','#6B7078')+LOCK)
# ---- neo 27x27 (viewBox 54) ----
def sq(x,fill,stroke,sw=4.4,r=0): return f'<rect x="{27-x}" y="{27-x}" width="{2*x}" height="{2*x}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"/>'
A['anchor_normal']=svg(27,27,'0 0 54 54',sq(13,'#FFFFFF',INK))
A['anchor_pressed']=svg(27,27,'0 0 54 54',sq(13,'#C9CED6',INK))
A['anchor_focus']=svg(27,27,'0 0 54 54','<rect x="6" y="6" width="42" height="42" fill="none" stroke="#F2A21B" stroke-width="3.4" stroke-dasharray="7 5"/>'+sq(12,'#FFFFFF',INK))
A['anchor_disabled']=svg(27,27,'0 0 54 54',sq(13,'#F1F1EC','#B5B9BF'))
A['anchor_selected']=svg(27,27,'0 0 54 54','<rect x="5" y="5" width="44" height="44" fill="none" stroke="#E04B4B" stroke-width="3.6" stroke-dasharray="8 6"/>'+sq(14,'#F2A21B',INK,4.8))
# ---- panel 505x508: tờ giấy x19..486, y6..485 ----
tk=''.join(f'<line x1="{44+i*10}" y1="6" x2="{44+i*10}" y2="{6+(14 if i%5==0 else 8)}" stroke="#0F3A6B" stroke-width="1.2"/>' for i in range(0,44))
tl=''.join(f'<line x1="19" y1="{30+i*10}" x2="{19+(14 if i%5==0 else 8)}" y2="{30+i*10}" stroke="#0F3A6B" stroke-width="1.2"/>' for i in range(0,45))
panel=('<defs><filter id="sh" x="-5%" y="-5%" width="110%" height="115%"><feDropShadow dx="0" dy="9" stdDeviation="7" flood-color="#2D2115" flood-opacity=".22"/></filter>'
 '<clipPath id="cp"><rect x="19" y="6" width="467" height="479" rx="12"/></clipPath></defs>'
 '<g filter="url(#sh)"><rect x="19" y="6" width="467" height="479" rx="12" fill="#FCFEFF"/></g>'
 '<g clip-path="url(#cp)">'
 +''.join(f'<line x1="{x}" y1="26" x2="{x}" y2="485" stroke="#DCE7F5" stroke-width="1"/>' for x in range(63,486,22))
 +''.join(f'<line x1="39" y1="{y}" x2="486" y2="{y}" stroke="#DCE7F5" stroke-width="1"/>' for y in range(48,485,22))
 +'<rect x="19" y="6" width="467" height="20" fill="#FFE9A8"/><rect x="19" y="6" width="20" height="479" fill="#FFE9A8"/>'
 +tk.replace('x1="44"','x1="44"')+tl+
 '<rect x="39" y="26" width="2.2" height="459" fill="#E05A5A"/><rect x="39" y="25" width="447" height="1.6" fill="#C9B27A" opacity=".7"/></g>'
 '<rect x="19" y="6" width="467" height="479" rx="12" fill="none" stroke="#6C8FBF" stroke-width="2.5"/>')
A['card_board']=svg(505,508,'0 0 505 508',panel)
for n,s in A.items(): open(f'{SV}/{n}.svg','w',encoding='utf-8').write(s)
with sync_playwright() as p:
    b=p.chromium.launch(); pg=b.new_page(device_scale_factor=1)
    for n,s in A.items():
        import re
        w,h=map(int,re.search(r'width="(\d+)" height="(\d+)"',s).groups())
        pg.set_viewport_size({'width':w,'height':h})
        pg.set_content(f'<html><body style="margin:0;background:transparent">{s}</body></html>')
        pg.screenshot(path=f'{PN}/{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h})
    b.close()
print('ok',len(A))
