#!/usr/bin/env python3
"""Màn Splash/Loading kiểu AK2: giấy kẻ ô + thước kẻ; thanh nạp = thước vàng, cờ đỏ chạy theo %.
Ghi SVG -> assets/images/splash, PNG (xuất từ SVG, scale 1) -> assets/images-png/splash."""
import os,re
from playwright.sync_api import sync_playwright
ROOT=os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SV=os.path.join(ROOT,'assets/images/splash'); PN=os.path.join(ROOT,'assets/images-png/splash')
os.makedirs(SV,exist_ok=True); os.makedirs(PN,exist_ok=True)
def svg(w,h,body): return f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">\n{body}\n</svg>\n'
Y='#FFE9A8'; B='#6C8FBF'; T='#0F3A6B'
A={}
# ---- giấy: NinePatch 49x49  (margin trái/trên 26 = thước, phải/dưới 3 = viền; giữa 20x20 lặp) ----
p=f'<rect width="49" height="49" fill="#FCFEFF"/>'
p+=f'<rect x="26" y="26" width="20" height="1" fill="#DCE7F5"/><rect x="26" y="26" width="1" height="20" fill="#DCE7F5"/>'
p+=f'<rect x="0" y="0" width="26" height="49" fill="{Y}"/><rect x="0" y="0" width="49" height="26" fill="{Y}"/>'
p+=f'<rect x="26" y="26" width="20" height="1" fill="#DCE7F5"/><rect x="26" y="26" width="1" height="20" fill="#DCE7F5"/>'
# vạch thước (chu kỳ 20): ngắn ở đầu ô, dài ở giữa
for x0,ln in ((26,8),(36,14)): p+=f'<rect x="{x0}" y="{26-ln}" width="1.2" height="{ln}" fill="{T}"/>'
for y0,ln in ((26,8),(36,14)): p+=f'<rect x="{26-ln}" y="{y0}" width="{ln}" height="1.2" fill="{T}"/>'
p+=f'<rect x="0" y="24" width="49" height="2" fill="{B}"/><rect x="24" y="0" width="2" height="49" fill="{B}"/>'
p+=f'<rect x="46" y="26" width="3" height="23" fill="{B}"/><rect x="26" y="46" width="23" height="3" fill="{B}"/>'
p+=f'<rect x="0" y="0" width="49" height="2" fill="{B}"/><rect x="0" y="0" width="2" height="49" fill="{B}"/>'
A['splash_paper']=svg(49,49,p)
# ---- thanh thước 36x46 (margin ngang 8, giữa 20 lặp) ----
r=f'<rect width="36" height="46" fill="{Y}"/>'
for x0,ln in ((8,8),(18,14),(28,8)): r+=f'<rect x="{x0}" y="0" width="1.2" height="{ln}" fill="{T}"/>'
r+=f'<rect x="1.25" y="1.25" width="33.5" height="43.5" rx="3" fill="none" stroke="{B}" stroke-width="2.5"/>'
A['loading_ruler']=svg(36,46,r)
# ---- phần đã nạp 16x46: vệt xanh ở đáy thước ----
A['loading_fill']=svg(16,46,'<rect x="0" y="36" width="16" height="9" fill="#2575A7" opacity=".92"/>')
# ---- cờ % 56x72 ----
A['loading_flag']=svg(56,72,'<rect x="26.5" y="28" width="3" height="44" fill="#E0451F"/><path d="M4 0H52Q56 0 56 4V20Q56 24 52 24H34L28 31L22 24H4Q0 24 0 20V4Q0 0 4 0Z" fill="#E0451F"/>')
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
