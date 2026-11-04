#!/usr/bin/env python3
"""Tutorial kiểu AO4 (scrapbook). SVG -> assets/images/tutorial ; PNG xuất từ SVG scale 1 -> assets/images-png/tutorial"""
import os,re
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def svg(w,h,body,defs=''): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{defs}\n{body}\n</svg>\n'
SH='<defs><filter id="s" x="-10%" y="-10%" width="125%" height="135%"><feDropShadow dx="0" dy="4" stdDeviation="3" flood-color="#2D2115" flood-opacity=".22"/></filter></defs>'
RED='#D9453F'
A={}
# huy hiệu số bước 110x110
A['tut_step_badge']=svg(110,110,f'<g filter="url(#s)"><circle cx="55" cy="53" r="46" fill="#fff" stroke="{RED}" stroke-width="6"/></g>',SH)
# nhãn "Bỏ qua" 9-patch (viền đỏ nét đứt) 96x64, margin 24 ; + pressed
def tag(fill,dy=0): return svg(96,64,f'<g filter="url(#s)"><rect x="5" y="{4+dy}" width="86" height="50" rx="11" fill="{fill}"/></g><rect x="5" y="{4+dy}" width="86" height="50" rx="11" fill="none" stroke="{RED}" stroke-width="3" stroke-dasharray="9 6"/>',SH)
A['tut_skip_tag']=tag('#fff'); A['tut_skip_tag_pressed']=tag('#FBE7E3',2)
# dải giấy xé làm thẻ thoại 9-patch 360x150 (margin trái/phải 24, trên/dưới 22)
top='M0 14'+''.join(f'L{i*18+9} {3+(i%2)*9}L{i*18+18} 13' for i in range(20))+'L360 14'
bot='L360 130'+''.join(f'L{360-i*18-9} {143-(i%2)*8}L{360-i*18-18} 131' for i in range(20))+'L0 130Z'
A['tut_msg_strip']=svg(360,150,f'<g filter="url(#s)"><path d="{top}{bot}" fill="#FFFDF5"/></g>',SH)
# nút Tiếp tục vàng 9-patch 128x96 (pill cao 84 + 3D dưới)
def nxt(fill,edge,dy):
    return svg(128,96,f'<rect x="4" y="{10+dy}" width="120" height="82" rx="41" fill="{edge}"/><rect x="4" y="{4}" width="120" height="82" rx="41" fill="{fill}" transform="translate(0 {dy})"/><rect x="8" y="{8+dy}" width="112" height="74" rx="37" fill="none" stroke="#fff" stroke-width="4"/>')
A['tut_next_normal']=nxt('#F5B83A','#C98A15',0); A["tut_next_pressed"]=nxt("#EBA92A","#C98A15",4)
# sao tiến độ 40x40
star='M20 3L25 14L37 15L28 23L31 35L20 29L9 35L12 23L3 15L15 14Z'
A['tut_star_on']=svg(40,40,f'<path d="{star}" fill="#F5B83A" stroke="#C98A15" stroke-width="2.5" stroke-linejoin="round"/>')
A['tut_star_off']=svg(40,40,f'<path d="{star}" fill="#E8E0C8" stroke="#CFC4A8" stroke-width="2.5" stroke-linejoin="round"/>')
# kéo cắt 36x36 (đỏ)
A['tut_scissors']=svg(36,36,f'<g fill="none" stroke="{RED}" stroke-width="3.4" stroke-linecap="round"><circle cx="9" cy="27" r="5"/><circle cx="27" cy="27" r="5"/><path d="M12.5 23L28 5M23.5 23L8 5"/></g>')
# nền: ô ly 96x96, lề đỏ 4x96, lỗ bấm 28x92
g=''.join(f'<path d="M{i*24} 0V96M0 {i*24}H96" stroke="#EFE6CB" stroke-width="1"/>' for i in range(4))
A['tut_page_grid']=svg(96,96,g)
A['tut_page_margin']=svg(4,96,'<rect x="1" y="0" width="2" height="96" fill="#E05A5A" fill-opacity=".45"/>')
A['tut_page_holes']=svg(28,92,'<circle cx="14" cy="46" r="7" fill="#EDE3CB"/><circle cx="14" cy="47" r="7" fill="none" stroke="rgba(0,0,0,.12)" stroke-width="1.5"/>')
with sync_playwright() as pw:
    b=pw.chromium.launch(); pg=b.new_page(device_scale_factor=1)
    for n,s in A.items():
        open(f'{ROOT}/assets/images/tutorial/{n}.svg','w',encoding='utf-8').write(s)
        w,h=map(int,re.search(r'width="(\d+)" height="(\d+)"',s).groups())
        pg.set_viewport_size({'width':w,'height':h})
        pg.set_content(f'<html><body style="margin:0;background:transparent">{s}</body></html>')
        pg.screenshot(path=f'{ROOT}/assets/images-png/tutorial/{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h})
    b.close()
print('ok')
