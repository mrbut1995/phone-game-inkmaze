#!/usr/bin/env python3
"""Màn Title kiểu AM1: nút 'Chạm để bắt đầu' = thanh thước vàng, tem phiên bản cắt góc.
Ghi SVG -> assets/images/main, PNG (từ SVG, scale 1) -> assets/images-png/main."""
import os,re
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SV=os.path.join(ROOT,'assets/images/main'); PN=os.path.join(ROOT,'assets/images-png/main')
def svg(w,h,body): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">\n{body}\n</svg>\n'
Y='#FFE9A8'; B='#6C8FBF'; T='#0F3A6B'; INK='#3E4249'
A={}
# nút thước 36x64: thân 0..58, bóng 58..64. NinePatch: margin ngang 8 (giữa lặp 20), dọc trên 16 / dưới 14
r='<rect x="1" y="5" width="34" height="58" rx="5" fill="#6C8FBF" opacity=".45"/>'
r+=f'<rect width="36" height="58" rx="5" fill="{Y}"/>'
for x0,ln in ((8,8),(18,14),(28,8)): r+=f'<rect x="{x0}" y="0" width="1.2" height="{ln}" fill="{T}"/>'
r+=f'<rect x="1.25" y="1.25" width="33.5" height="55.5" rx="4" fill="none" stroke="{B}" stroke-width="2.5"/>'
A['title_btn_ruler']=svg(36,64,r)
# tem phiên bản 70x35: thẻ vàng cắt góc phải-trên
A['stamp_version']=svg(70,35,f'<path d="M2 3H50L68 16V33H2Z" fill="#000" opacity=".1"/><path d="M2 2H50L68 15V31H2Z" fill="#FFF3A8" stroke="{INK}" stroke-width="2.2" stroke-linejoin="round"/><path d="M50 2V15H68" fill="none" stroke="{INK}" stroke-width="1.6" opacity=".5" stroke-linejoin="round"/>')
os.makedirs(SV,exist_ok=True);os.makedirs(PN,exist_ok=True)
for n,s in A.items(): open(f'{SV}/{n}.svg','w',encoding='utf-8').write(s)
with sync_playwright() as pw:
    b=pw.chromium.launch(); pg=b.new_page(device_scale_factor=1)
    for n,s in A.items():
        w,h=map(int,re.search(r'width="(\d+)" height="(\d+)"',s).groups())
        pg.set_viewport_size({'width':w,'height':h})
        pg.set_content(f'<html><body style="margin:0;background:transparent">{s}</body></html>')
        pg.screenshot(path=f'{PN}/{n}.png',omit_background=True,clip={'x':0,'y':0,'width':w,'height':h})
    b.close()
print('ok')
