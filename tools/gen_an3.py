#!/usr/bin/env python3
"""Splash + Title kiểu AN3 (bàn học: ghi chú dán, polaroid, chồng giấy, con dấu CHƠI).
SVG -> assets/images/{splash,main}; PNG (xuất từ SVG, scale 1) -> assets/images-png/{splash,main}."""
import os,re,random
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INK='#3E4249'
def svg(w,h,body,defs=''): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs}\n{body}\n</svg>\n'
SH='<defs><filter id="s" x="-10%" y="-10%" width="125%" height="130%"><feDropShadow dx="0" dy="5" stdDeviation="4" flood-color="#2D2115" flood-opacity=".22"/></filter></defs>'
A={'splash':{},'main':{}}
def note(fill,fold):
    return svg(160,150,f'<g filter="url(#s)"><path d="M5 4H155V108L123 140H5Z" fill="{fill}"/></g><path d="M155 108L123 140V116Q123 108 131 108Z" fill="{fold}"/>',SH)
A['splash']['splash_note_yellow']=note('#FFF3A8','#E9D470')
A['splash']['splash_note_blue']=note('#CFE4F7','#AFC8E2')
A['splash']['splash_polaroid']=svg(200,240,'<g filter="url(#s)"><rect x="5" y="3" width="190" height="230" rx="3" fill="#fff"/></g><rect x="18" y="16" width="164" height="164" fill="#F4F6F4" stroke="#E3E6E3" stroke-width="1.5"/>',SH)
def stripes(c1,c2,w=36,h=34,r=6):
    # sọc xiên chu kỳ ngang 20px, neo tại x=8 (đúng vùng lặp của NinePatch margin 8)
    p=f'<rect width="{w}" height="{h}" fill="{c1}"/>'
    for k in range(-3,5): p+=f'<polygon points="{-12+k*20},{h} {-12+k*20+10},{h} {-12+k*20+10+h},0 {-12+k*20+h},0" fill="{c2}"/>'
    return p
cp='<clipPath id="c"><rect width="36" height="34" rx="6"/></clipPath>'
A['splash']['loading_track_tape']=svg(36,34,f'<g clip-path="url(#c)">{stripes("#EFE9D6","#E4DCC4")}</g><rect x="1" y="1" width="34" height="32" rx="6" fill="none" stroke="#CFC4A8" stroke-width="2" stroke-dasharray="6 4"/>',f'<defs>{cp}</defs>')
A['splash']['loading_fill_tape']=svg(36,34,f'<g clip-path="url(#c)">{stripes("#7FC8CD","#9AD6DA")}</g><rect x="0" y="30" width="36" height="4" fill="#000" opacity=".1"/>',f'<defs>{cp}</defs>')
# ---- title: chồng giấy 514x1040 ----
def sheet(fill,rot,dy,stroke='#E0CE9E'): return f'<g transform="rotate({rot} 257 {420+dy})"><rect x="38" y="{110+dy}" width="438" height="620" rx="6" fill="{fill}" stroke="{stroke}" stroke-width="2.5"/></g>'
stack=('<g filter="url(#s)">'+sheet('#F4ECD6',3,18)+sheet('#FFFDF5',-2,0)+'</g>'
 '<g transform="rotate(-18 112 118)"><rect x="56" y="104" width="112" height="30" fill="rgba(127,200,205,.78)"/></g>'
 '<g transform="rotate(16 380 126)"><rect x="326" y="112" width="112" height="30" fill="rgba(127,200,205,.78)"/></g>'
 f'<g transform="translate(402 600) rotate(32)"><rect x="-13" y="-120" width="26" height="140" fill="#F7D54A" stroke="{INK}" stroke-width="3.5"/><rect x="-13" y="-136" width="26" height="16" rx="6" fill="#E05A5A" stroke="{INK}" stroke-width="3.5"/><path d="M-13 20L13 20L0 52Z" fill="#F4D7A8" stroke="{INK}" stroke-width="3.5" stroke-linejoin="round"/><path d="M-5 40L5 40L0 52Z" fill="{INK}"/></g>')
A['main']['title_paper_stack']=svg(514,1040,stack,SH)
# dải giấy xé 380x96
rnd=random.Random(5);top='M0 14'+''.join(f'L{i*20+10} {2+(i%2)*10}L{i*20+20} 14' for i in range(19))+'L380 14'
bot='L380 82'+''.join(f'L{380-i*20-10} {94-(i%2)*10}L{380-i*20-20} 82' for i in range(19))+'L0 82Z'
A['main']['title_banner_torn']=svg(380,96,f'<g filter="url(#s)"><path d="{top}{bot}" fill="#FFF3C9"/></g>',SH)
# con dấu CHƠI 160x160
ticks=''.join(f'<line x1="80" y1="14" x2="80" y2="22" stroke="#E5202A" stroke-width="3" transform="rotate({a} 80 80)"/>' for a in range(0,360,30))
A['main']['title_stamp_play']=svg(160,160,f'<circle cx="80" cy="80" r="72" fill="#fff" fill-opacity=".45" stroke="#E5202A" stroke-width="6"/><circle cx="80" cy="80" r="60" fill="none" stroke="#E5202A" stroke-width="1.8" stroke-dasharray="3 4"/>{ticks}')
with sync_playwright() as pw:
    b=pw.chromium.launch(); pg=b.new_page(device_scale_factor=1)
    for grp,d in A.items():
        sv=os.path.join(ROOT,'assets/images',grp); pn=os.path.join(ROOT,'assets/images-png',grp)
        for n,s in d.items():
            open(f'{sv}/{n}.svg','w',encoding='utf-8').write(s)
            w,h=map(int,re.search(r'width="(\d+)" height="(\d+)"',s).groups())
            pg.set_viewport_size({'width':w,'height':h})
            pg.set_content(f'<html><body style="margin:0;background:transparent">{s}</body></html>')
            pg.screenshot(path=f'{pn}/{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h})
    b.close()
print('ok')
