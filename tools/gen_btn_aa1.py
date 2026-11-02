#!/usr/bin/env python3
"""Nút BẤM KIỂU AA1 — HUY HIỆU TRÒN ĐẶC MÀU (viền trắng · gờ đáy sẫm · biểu tượng trắng), để KHÁC HẲN chip hiển thị Xu/Mạng (kính mờ phẳng).
SVG là NGUỒN, PNG xuất từ SVG. Giữ nguyên TÊN + KÍCH THƯỚC PNG cũ. Ra:
  btn_header_back_{normal,pressed,disabled,focus}          48×53 (PNG 2×)  xanh dương
  common/settings_btn_{normal,pressed}                     56×56 (2×)      tím
  game/btn_pause_chip_{normal,pressed,disabled}            56×56 (2×)      xanh dương
  game/btn_help_chip_{normal,pressed,disabled}             56×56 (2×)      tím
  game/btn_eraser_normal 118×80 · btn_restart_* · btn_skip_* · btn_undo_* · btn_hint_*  91×92 (1×)   công cụ: xanh dương · tím · xanh lá · hổ phách
Dùng: python3 gen_btn_aa1.py [thư_mục_assets]"""
import os, sys
from playwright.sync_api import sync_playwright
A = sys.argv[1] if len(sys.argv) > 1 else "../package_merge/assets"
COL = {"blue": ("#3B9BFF", "#1D5FB8", "#6DB8FF"), "purple": ("#9B6BFF", "#5F36B8", "#B491FF"), "green": ("#22B26B", "#12703F", "#4CD08C"),
       "amber": ("#F59E0B", "#B86A00", "#FFC04A"), "grey": ("#C9CED4", "#A3AAB3", "#DDE1E6")}
G = dict(
 back='<polyline points="15 5 8 12 15 19"/>',
 pause='<path d="M8 5v14M16 5v14"/>',
 help='<circle cx="12" cy="12" r="10"/><path d="M9.1 9a3 3 0 0 1 5.8 1c0 2-3 3-3 3"/><path d="M12 17h.01"/>',
 gear='<path d="M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z"/><circle cx="12" cy="12" r="3"/>',
 eraser='<path d="m7 21-4.3-4.3c-1-1-1-2.5 0-3.4l9.6-9.6c1-1 2.5-1 3.4 0l5.6 5.6c1 1 1 2.5 0 3.4L13 21"/><path d="M22 21H7"/><path d="m5 11 9 9"/>',
 skip='<polygon points="5 4 15 12 5 20 5 4"/><line x1="19" x2="19" y1="5" y2="19"/>',
 undo='<path d="M9 14 4 9l5-5"/><path d="M4 9h10.5a5.5 5.5 0 0 1 5.5 5.5a5.5 5.5 0 0 1-5.5 5.5H11"/>',
 hint='<path d="M15 14c.2-1 .7-1.7 1.5-2.5 1-.9 1.5-2.2 1.5-3.5A6 6 0 0 0 6 8c0 1 .2 2.2 1.5 3.5.7.7 1.3 1.5 1.5 2.5"/><path d="M9 18h6"/><path d="M10 22h4"/>')
def badge(W, H, glyph, color, state):
    f, d, top = COL["grey" if state == "disabled" else color]
    D = min(W, H - max(3, H * 0.07)); bw = max(2.5, D * 0.06); ridge = max(3, D * 0.075)
    D = min(W, H - ridge - 1)
    cx = W / 2; r = D / 2
    dy = ridge * 0.45 if state == "pressed" else 0
    rd = ridge * 0.4 if state == "pressed" else ridge
    gs = D * 0.5; gx = cx - gs / 2; gy = 1 + r + dy - gs / 2
    sw = max(2.2, 2.4 * gs / 24 * 0.9)
    return (f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="0.6" stop-color="{f}"/></linearGradient></defs>'
            f'<circle cx="{cx}" cy="{1+r+rd+dy:.2f}" r="{r:.2f}" fill="{d}"/>'
            f'<circle cx="{cx}" cy="{1+r+dy:.2f}" r="{r-bw/2:.2f}" fill="url(#g)" stroke="#FFFFFF" stroke-width="{bw:.2f}"/>'
            f'<g transform="translate({gx:.2f} {gy:.2f}) scale({gs/24:.4f})" fill="none" stroke="#FFFFFF" stroke-width="{2.4 if state!="disabled" else 2.4}" stroke-linecap="round" stroke-linejoin="round" opacity="{0.85 if state=="disabled" else 1}">{G[glyph]}</g>')
jobs = []  # (dir, name, W, H, scale, glyph, color, state)
for st in ("normal", "pressed", "disabled", "focus"):
    jobs.append(("", f"btn_header_back_{st}", 48, 53, 2, "back", "blue", st))
for st in ("normal", "pressed"):
    jobs.append(("common", f"settings_btn_{st}", 56, 56, 2, "gear", "purple", st))
for st in ("normal", "pressed", "disabled"):
    jobs += [("game", f"btn_pause_chip_{st}", 56, 56, 2, "pause", "blue", st), ("game", f"btn_help_chip_{st}", 56, 56, 2, "help", "purple", st)]
jobs.append(("game", "btn_eraser_normal", 118, 80, 1, "eraser", "blue", "normal"))
for nm, g, c, sts in (("restart", "eraser", "blue", ("normal", "pressed", "focus", "disabled")), ("skip", "skip", "purple", ("normal", "pressed", "focus", "disable")),
                      ("undo", "undo", "green", ("normal", "pressed", "disabled")), ("hint", "hint", "amber", ("normal", "pressed", "disabled"))):
    for st in sts:
        jobs.append(("game", f"btn_{nm}_{st}", 91, 92, 1, g, c, "disabled" if st.startswith("disab") else ("focus" if st == "focus" else st)))
with sync_playwright() as p:
    br = p.chromium.launch()
    for g, name, W, H, sc, gl, col, st in jobs:
        sd, pd = (f"{A}/images/{g}".rstrip("/"), f"{A}/images-png/{g}".rstrip("/"))
        os.makedirs(sd, exist_ok=True); os.makedirs(pd, exist_ok=True)
        sv = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">{badge(W, H, gl, col, st)}</svg>'
        open(f"{sd}/{name}.svg", "w", encoding="utf-8").write('<?xml version="1.0" encoding="utf-8"?>\n' + sv + "\n")
        pg = br.new_page(viewport={"width": W, "height": H}, device_scale_factor=sc)
        pg.set_content(f'<html><body style="margin:0;background:transparent">{sv}</body></html>')
        pg.screenshot(path=f"{pd}/{name}.png", omit_background=True, clip={"x": 0, "y": 0, "width": W, "height": H}); pg.close()
    br.close()
print("OK", len(jobs))
