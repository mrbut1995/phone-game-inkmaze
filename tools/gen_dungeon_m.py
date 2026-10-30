#!/usr/bin/env python3
"""ART nút DUNGEON kiểu M (vé giấy đục lỗ) — SVG là NGUỒN, PNG xuất 2x.
Ra: assets/images/dungeon/{dungeon_ticket,dungeon_ticket_pressed,dungeon_icon}.svg  +  assets/images-png/dungeon/*.png (2x)
  dungeon_ticket          244×86  vé kem viền navy, khía đục lỗ trên/dưới + đường xé nét đứt, bóng cứng lệch (3,5)
  dungeon_ticket_pressed  244×86  cùng vé nhưng lún (dịch 2,3 · bóng thu lại)
  dungeon_icon            50×50   ô navy bo góc + lâu đài vàng
ĐỔI THEME = thay 3 file này (cùng tên + cùng kích thước logic). Dùng: python3 gen_dungeon_m.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
SV, PN = f"{A}/images/dungeon", f"{A}/images-png/dungeon"
os.makedirs(SV, exist_ok=True); os.makedirs(PN, exist_ok=True)
INK, CREAM = "#164663", "#FFF6D6"
CASTLE = '<path d="M22 20v-9H2v9a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2Z"/><path d="M18 11V4H6v7"/><path d="M15 22v-4a3 3 0 0 0-3-3a3 3 0 0 0-3 3v4"/><path d="M22 11V9"/><path d="M2 11V9"/><path d="M6 4V2"/><path d="M18 4V2"/><path d="M10 4V2"/><path d="M14 4V2"/>'
def write(name, w, h, body):
    open(f"{SV}/{name}.svg", "w", encoding="utf-8").write(f'<?xml version="1.0" encoding="utf-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">{body}</svg>\n')
    return (name, w, h)
def ticket(dx, dy, sx, sy):
    x, y, w, h, nx = 1.5 + dx, 1.5 + dy, 233, 75, 78
    notch = f'<circle cx="{nx + dx}" cy="{y}" r="10" fill="black"/><circle cx="{nx + dx}" cy="{y + h}" r="10" fill="black"/>'
    return (f'<defs><mask id="m" maskUnits="userSpaceOnUse" x="0" y="0" width="244" height="86"><rect width="244" height="86" fill="white"/>{notch}</mask>'
            f'<clipPath id="c"><rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18"/></clipPath></defs>'
            f'<g mask="url(#m)"><rect x="{x + sx}" y="{y + sy}" width="{w}" height="{h}" rx="18" fill="{INK}"/>'
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="18" fill="{CREAM}" stroke="{INK}" stroke-width="3"/></g>'
            f'<g clip-path="url(#c)" fill="none" stroke="{INK}" stroke-width="3"><circle cx="{nx + dx}" cy="{y}" r="10"/><circle cx="{nx + dx}" cy="{y + h}" r="10"/></g>'
            f'<line x1="{nx + dx}" y1="{y + 14}" x2="{nx + dx}" y2="{y + h - 14}" stroke="{INK}" stroke-opacity=".45" stroke-width="3" stroke-dasharray="6 5"/>')
jobs = [write("dungeon_ticket", 244, 86, ticket(0, 0, 3, 5)),
        write("dungeon_ticket_pressed", 244, 86, ticket(2, 3, 1, 2)),
        write("dungeon_icon", 50, 50, f'<rect x="1" y="1" width="48" height="48" rx="14" fill="{INK}"/><g transform="translate(10 10) scale(1.2)" fill="none" stroke="#FFD98A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">{CASTLE}</g>')]
with sync_playwright() as p:
    br = p.chromium.launch()
    for n, w, h in jobs:
        pg = br.new_page(viewport={"width": w, "height": h}, device_scale_factor=2)
        s = open(f"{SV}/{n}.svg", encoding="utf-8").read()
        pg.set_content(f'<html><body style="margin:0;background:transparent">{s[s.index("<svg"):]}</body></html>')
        pg.screenshot(path=f"{PN}/{n}.png", omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h}); pg.close()
    br.close()
print("OK", len(jobs))
