#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh mockup/matchup_<mode>.svg cho từng chế độ chơi (HUD matchup).

- Toạ độ lấy ĐÚNG theo game: scenes/game.tscn (khung HUD 980x249 tại (50,175),
  Board (41,420)-(1061,1440), thanh nút dưới (73,1528)-(1031,1688), Status (50,85)).
- Thẻ HUD vẽ lại theo đúng art thật trong assets/images/game/*.svg (viền + lề + dòng kẻ),
  kèm chú thích tên art để dev đối chiếu.

Chạy:  python tools/mockup/gen_matchup.py            (ghi vào mockup/)
       python tools/mockup/gen_matchup.py --list     (liệt kê mode có mockup)
Ghi chú: KHÔNG ghi đè matchup_level.svg / matchup_dungeon.svg (art tay của user).
"""

from __future__ import annotations

import argparse
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MOCKUP_DIR = os.path.join(ROOT, "mockup")

W, H = 1080, 1920
# Khung HUD thật trong scenes/game.tscn
HUD_X, HUD_Y, HUD_W, HUD_H = 50, 175, 980, 249
# Bàn cờ thật (Board node): anchors 0.037778..0.982778 / 0.218646..0.749646
BOARD = (41, 420, 1020, 1020)
# Thanh nút dưới
BUTTONS = (73, 1528, 958, 160)

INK = "#224C6D"
INK_SOFT = "#718B9E"
BLUE = "#6EA0C8"
BLUE_DARK = "#3D83AE"
RED = "#D84444"
PAPER = "#FEFDFA"
PAPER_BG = "#FAF5EB"
RULED = "#9FC0D6"
GRID_LINE = "#BACEDC"

FONT_UI = "sans-serif"


# ---------------------------------------------------------------------------
# Helpers vẽ
# ---------------------------------------------------------------------------
def esc(s: str) -> str:
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def text(x, y, s, size, color=INK, weight=800, anchor="start", family=FONT_UI,
         letter=0, opacity=1.0):
    a = ' text-anchor="%s"' % anchor if anchor != "start" else ""
    l = ' letter-spacing="%s"' % letter if letter else ""
    o = ' opacity="%s"' % opacity if opacity != 1.0 else ""
    return ('<text x="%s" y="%s" font-family="%s" font-size="%s" font-weight="%s" '
            'fill="%s"%s%s%s>%s</text>' % (x, y, family, size, weight, color, a, l, o, esc(s)))


def slip(x, y, w, h, border=BLUE, thick=4, rx=24, margin=None, ruled=None,
         shadow="uiShadow", bg=PAPER):
    """Mẩu giấy: viền + lề sổ tay + dòng kẻ ngang (đúng chất liệu card_*.svg)."""
    margin = border if margin is None else margin
    out = ['<g transform="translate(%s, %s)" filter="url(#%s)">' % (x, y, shadow)]
    out.append('<rect width="%s" height="%s" rx="%s" fill="%s"/>' % (w, h, rx, border))
    out.append('<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"/>'
               % (thick, thick, w - 2 * thick, h - 2 * thick, max(rx - 4, 6), bg))
    if ruled:
        step = 40
        yy = int(h * 0.29)
        while yy < h - 12:
            out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="2" opacity="0.5"/>'
                       % (int(w * 0.065), yy, w - 8, yy, RULED))
            yy += step
    if margin:
        mx = 18 if w <= 260 else 24
        out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="3"/>'
                   % (mx, thick, mx, h - thick, margin))
    out.append("</g>")
    return "\n  ".join(out)


def marker(n, x, y, color=RED):
    """Badge số tròn đánh dấu thành phần trong mockup (khớp bảng legend ở dưới)."""
    return ('<g transform="translate(%s, %s)" filter="url(#uiShadow)">'
            '<circle r="16" fill="%s"/>%s</g>'
            % (x, y, color, text(0, 7, str(n), 21, "#FFFFFF", 900, "middle")))


def legend(items):
    """Bảng chú thích dưới thanh nút: [(số, nội dung)]"""
    out = []
    y = 1716
    for n, label in items:
        out.append("  " + marker(n, 70, y - 7, BLUE_DARK))
        out.append("  " + text(100, y, label, 20, INK_SOFT, 700))
        y += 34
    return "\n".join(out)


def board_frame():
    x, y, w, h = BOARD
    return ('<g transform="translate(%s, %s)">'
            '<g clip-path="url(#boardClip)">'
            '<rect width="%s" height="%s" fill="%s"/>'
            '<line x1="42" y1="0" x2="42" y2="%s" stroke="%s" stroke-width="3"/>'
            "</g>"
            '<rect width="%s" height="%s" rx="28" fill="none" stroke="%s" stroke-width="6" filter="url(#boardShadow)"/>'
            "</g>" % (x, y, w, h, PAPER, h, RED, w, h, BLUE))


def board_grid(cols, rows, dimmed=(), notes=None, hide_numbers=()):
    """Lưới ô + số minh hoạ. notes: {(cx, cy): text}. dimmed: ô mờ (Fading Ink)."""
    bx, by, bw, bh = BOARD
    pad = 12
    cell = min(176, (bw - 2 * pad) / cols, (bh - 2 * pad) / rows)
    gx = bx + (bw - cell * cols) / 2
    gy = by + (bh - cell * rows) / 2
    out = []
    for r in range(rows):
        for c in range(cols):
            out.append('<rect x="%s" y="%s" width="%s" height="%s" fill="#CEE0EC" '
                       'fill-opacity="0.12" stroke="%s" stroke-width="1.5"/>'
                       % (gx + c * cell, gy + r * cell, cell, cell, GRID_LINE))
    for (c, r), label in (notes or {}).items():
        is_badge = label in ("S", "F")
        cx = gx + c * cell + cell / 2
        cy = gy + r * cell + cell / 2
        alpha = 0.4 if (c, r) in dimmed else 1.0
        if is_badge:
            out.append('<g opacity="%s"><rect x="%s" y="%s" width="%s" height="%s" rx="10" '
                       'fill="%s" stroke="%s" stroke-width="3"/>%s</g>'
                       % (alpha, cx - cell * 0.22, cy - cell * 0.22, cell * 0.44, cell * 0.44,
                          "#E7F0F7", BLUE_DARK,
                          text(cx, cy + cell * 0.09, label, cell * 0.30, BLUE_DARK, 900, "middle")))
        elif label:
            out.append('%s' % text(cx, cy + cell * 0.20, label, cell * 0.34, INK, 900, "middle",
                                   opacity=alpha))
    return "\n  ".join(out)


def board_walls(cols, rows, walls, color=INK, dashed=True, opacity=0.85):
    """walls: [(x1, y1, x2, y2)] theo đơn vị LƯỚI (0..cols)."""
    bx, by, bw, bh = BOARD
    pad = 12
    cell = min(176, (bw - 2 * pad) / cols, (bh - 2 * pad) / rows)
    gx = bx + (bw - cell * cols) / 2
    gy = by + (bh - cell * rows) / 2
    dash = ' stroke-dasharray="12 8"' if dashed else ""
    out = []
    for (x1, y1, x2, y2) in walls:
        out.append('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="7" '
                   'stroke-linecap="round" opacity="%s"%s/>'
                   % (gx + x1 * cell, gy + y1 * cell, gx + x2 * cell, gy + y2 * cell,
                      color, opacity, dash))
    return "\n  ".join(out)


def board_path(points, cols, rows, color="#2575A7"):
    bx, by, bw, bh = BOARD
    pad = 12
    cell = min(176, (bw - 2 * pad) / cols, (bh - 2 * pad) / rows)
    gx = bx + (bw - cell * cols) / 2
    gy = by + (bh - cell * rows) / 2
    pts = " ".join("%s,%s" % (gx + (c + 0.5) * cell, gy + (r + 0.5) * cell) for c, r in points)
    return ('<polyline points="%s" fill="none" stroke="%s" stroke-width="14" '
            'stroke-linecap="round" stroke-linejoin="round" opacity="0.55" filter="url(#pathGlow)"/>'
            % (pts, color))


def bottom_bar():
    x, y, w, h = BUTTONS
    out = []
    wide = 300
    out.append('<g transform="translate(%s, %s)" filter="url(#uiShadow)">'
               '<rect width="%s" height="%s" rx="26" fill="%s" stroke="%s" stroke-width="3"/>'
               '<path d="M42 34 L74 60 L42 86 Z" fill="%s"/>%s</g>'
               % (x, y, wide, h, PAPER, BLUE, BLUE_DARK, text(96, 95, "VẼ ĐƯỜNG", 34, INK, 800)))
    out.append('<g transform="translate(%s, %s)" filter="url(#uiShadow)">'
               '<rect width="%s" height="%s" rx="26" fill="%s" stroke="%s" stroke-width="3"/>'
               '<rect x="34" y="42" width="46" height="76" rx="8" fill="none" stroke="%s" stroke-width="4"/>'
               '%s</g>'
               % (x + wide + 20, y, wide, h, PAPER, BLUE, BLUE_DARK,
                  text(x=96, y=95, s="GHI NHỚ", size=34, color=INK, weight=800).replace(
                      'x="96"', 'x="96"')))
    sq = h
    out.append('<g transform="translate(%s, %s)" filter="url(#uiShadow)">'
               '<rect width="%s" height="%s" rx="24" fill="%s" stroke="%s" stroke-width="3"/>'
               '<path d="M%s %s A %s %s 0 1 1 %s %s" fill="none" stroke="%s" stroke-width="6" '
               'stroke-linecap="round"/>'
               '<polyline points="%s,%s %s,%s %s,%s" fill="none" stroke="%s" stroke-width="5" '
               'stroke-linecap="round" stroke-linejoin="round"/></g>'
               % (x + 2 * wide + 40, y, sq, sq, PAPER, BLUE,
                  sq * 0.70, sq * 0.26, sq * 0.20, sq * 0.20, sq * 0.66, sq * 0.30, BLUE_DARK,
                  sq * 0.60, sq * 0.20, sq * 0.72, sq * 0.28, sq * 0.70, sq * 0.42, BLUE_DARK))
    out.append('<g transform="translate(%s, %s)" filter="url(#uiShadow)">'
               '<rect width="%s" height="%s" rx="24" fill="%s" stroke="%s" stroke-width="3"/>'
               '<circle cx="%s" cy="%s" r="%s" fill="none" stroke="#E0A32A" stroke-width="5"/>'
               '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#E0A32A" stroke-width="5" stroke-linecap="round"/>'
               '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#E0A32A" stroke-width="5" stroke-linecap="round"/>'
               '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#E0A32A" stroke-width="5" stroke-linecap="round"/>'
               "</g>" % (x + 2 * wide + 40 + sq + 20, y, sq, sq, PAPER, BLUE,
                          sq * 0.5, sq * 0.42, sq * 0.20,
                          sq * 0.38, sq * 0.06, sq * 0.62, sq * 0.06,
                          sq * 0.30, sq * 0.34, sq * 0.30, sq * 0.62,
                          sq * 0.70, sq * 0.34, sq * 0.70, sq * 0.62))
    return "\n  ".join(out)


def head(title, subtitle=None):
    out = ['<g fill="#3D5A73" font-family="%s" font-size="28" font-weight="600">'
           '<text x="60" y="55">09:41</text></g>' % FONT_UI]
    out.append('<g transform="translate(50, 85)" filter="url(#uiShadow)">'
               '<rect width="70" height="70" rx="18" fill="%s" stroke="%s" stroke-width="3"/>'
               '<line x1="26" y1="22" x2="26" y2="48" stroke="%s" stroke-width="4.5" stroke-linecap="round"/>'
               '<line x1="44" y1="22" x2="44" y2="48" stroke="%s" stroke-width="4.5" stroke-linecap="round"/>'
               "</g>" % (PAPER, BLUE, BLUE_DARK, BLUE_DARK))
    out.append('<g transform="translate(960, 85)" filter="url(#uiShadow)">'
               '<rect width="70" height="70" rx="18" fill="%s" stroke="%s" stroke-width="3"/>'
               '<path d="M50 25 A 15 15 0 1 0 52 42" fill="none" stroke="%s" stroke-width="4" '
               'stroke-linecap="round"/>'
               '<polyline points="42,20 52,24 50,34" fill="none" stroke="%s" stroke-width="3.5" '
               'stroke-linecap="round" stroke-linejoin="round"/></g>'
               % (PAPER, BLUE, BLUE_DARK, BLUE_DARK))
    cy = 120 if subtitle else 133
    if subtitle:
        out.append(text(540, cy - 26, subtitle, 26, RED, 800, "middle", letter=1))
    out.append(text(540, cy + 8, title, 42, INK, 800, "middle", letter=2))
    return "\n  ".join(out)


def defs():
    return """<defs>
    <pattern id="notebookGrid" width="40" height="40" patternUnits="userSpaceOnUse">
      <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#8FB9D2" stroke-width="1.2" opacity="0.6"/>
      <line x1="0" y1="0" x2="40" y2="0" stroke="#3D83AE" stroke-width="2" opacity="0.2"/>
    </pattern>
    <filter id="boardShadow" x="-10%" y="-10%" width="125%" height="130%">
      <feDropShadow dx="0" dy="14" stdDeviation="16" flood-color="#1E1610" flood-opacity="0.25"/>
      <feDropShadow dx="0" dy="4" stdDeviation="5" flood-color="#1E1610" flood-opacity="0.10"/>
    </filter>
    <filter id="uiShadow" x="-10%" y="-15%" width="125%" height="140%">
      <feDropShadow dx="0" dy="5" stdDeviation="5" flood-color="#1E2830" flood-opacity="0.14"/>
    </filter>
    <filter id="heroShadow" x="-15%" y="-15%" width="130%" height="140%">
      <feDropShadow dx="0" dy="8" stdDeviation="8" flood-color="#1E2830" flood-opacity="0.18"/>
    </filter>
    <filter id="pathGlow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="0" stdDeviation="6" flood-color="#2575A7" flood-opacity="0.45"/>
    </filter>
    <clipPath id="boardClip"><rect width="1020" height="1020" rx="28"/></clipPath>
  </defs>"""


def write_svg(name, comment, body):
    path = os.path.join(MOCKUP_DIR, name)
    parts = [
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %s %s" width="%s" height="%s">' % (W, H, W, H),
        "  <!-- MOCKUP: %s -->" % comment,
        "  <!-- Toa do lay tu scenes/game.tscn + nodes/hud/*.tscn (khung HUD 980x249 tai (50,175)) -->",
        "  " + defs(),
        '  <rect width="%s" height="%s" fill="%s"/>' % (W, H, PAPER_BG),
        '  <rect width="%s" height="%s" fill="url(#notebookGrid)"/>' % (W, H),
        '  <line x1="90" y1="0" x2="90" y2="%s" stroke="%s" stroke-width="3.5"/>' % (H, RED),
        body,
        "</svg>",
        "",
    ]
    with io.open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(parts))
    return path


# ---------------------------------------------------------------------------
# Đọc toạ độ THẬT từ nodes/hud/*.tscn (để spec mockup khớp game)
# ---------------------------------------------------------------------------
import re

NODE_RE = re.compile(r'\[node name="([^"]+)"(.*?)\]')
NUM_RE = r'%s\s*=\s*(-?[0-9.]+)'


def _num(block, key, default=None):
    m = re.search(NUM_RE % key, block)
    return float(m.group(1)) if m else default


def scene_rects(scene, w=980.0, h=249.0):
    """Dict: tên node -> (x, y, x2, y2) trong khung HUD 980x249."""
    with io.open(os.path.join(ROOT, scene), encoding="utf-8") as f:
        txt = f.read()
    out = {}
    for block in re.split(r"\n(?=\[node )", txt):
        m = NODE_RE.match(block.strip())
        if not m:
            continue
        name = m.group(1)
        al = _num(block, "anchor_left", 0.0)
        at = _num(block, "anchor_top", 0.0)
        ar = _num(block, "anchor_right", 0.0)
        ab = _num(block, "anchor_bottom", 0.0)
        ol = _num(block, "offset_left", 0.0)
        ot = _num(block, "offset_top", 0.0)
        orr = _num(block, "offset_right", 0.0)
        ob = _num(block, "offset_bottom", 0.0)
        out[name] = (al * w + ol, at * h + ot, ar * w + orr, ab * h + ob)
    return out


def dump():
    for scene in ("nodes/hud/level_mode.tscn", "nodes/hud/dungeon_mode.tscn",
                  "nodes/hud/minesweep_hud.tscn", "nodes/hud/sum_path_hud.tscn",
                  "nodes/hud/blind_memory_hud.tscn"):
        print("== %s" % scene)
        for name, r in scene_rects(scene).items():
            print("  %-14s (%6.0f, %6.0f) - (%6.0f, %6.0f)   %4.0f x %4.0f"
                  % (name, r[0], r[1], r[2], r[3], r[2] - r[0], r[3] - r[1]))


# ---------------------------------------------------------------------------
# Thẻ HUD (theo đúng nodes/hud/*.tscn — toạ độ trong khung 980x249)
# ---------------------------------------------------------------------------
def card_time(x, y, value="01:24", title="THỜI GIAN"):
    s = slip(x, y, 250, 138, BLUE, 3, 20, ruled=True)
    s += text(x + 32, y + 34, title, 18, INK_SOFT, 800)
    s += text(x + 62, y + 95, value, 46, INK, 950, family="'Segoe UI', monospace")
    return s


def card_steps(x, y, value="14", title="SỐ BƯỚC"):
    s = slip(x, y, 440, 158, RED, 4, 24, shadow="heroShadow")
    s += text(x + 44, y + 42, title, 30, RED, 900, letter=1)
    s += text(x + 44, y + 122, value, 72, RED, 950)
    return s


def bomb_icon(cx, cy, size=80):
    """Icon mìn (vẽ lại icon_bomb.svg) tại tâm (cx, cy) với cạnh `size`."""
    return ('<g transform="translate(%s, %s) scale(%s)">'
            '<circle cx="0" cy="4" r="24" fill="#2B3646" stroke="#1E283A" stroke-width="3"/>'
            '<circle cx="-8" cy="-4" r="6" fill="#5A6C82" opacity="0.85"/>'
            '<g stroke="#1E283A" stroke-width="3" stroke-linecap="round">'
            '<line x1="0" y1="-28" x2="0" y2="-36"/><line x1="0" y1="36" x2="0" y2="44"/>'
            '<line x1="-28" y1="4" x2="-36" y2="4"/><line x1="32" y1="4" x2="40" y2="4"/>'
            '<line x1="-19" y1="-13" x2="-25" y2="-19"/><line x1="21" y1="-13" x2="27" y2="-19"/>'
            '<line x1="-19" y1="25" x2="-25" y2="31"/><line x1="21" y1="25" x2="27" y2="31"/>'
            "</g>"
            '<path d="M 6 -24 Q 16 -34 11 -42" fill="none" stroke="#1E283A" stroke-width="3"/>'
            '<g stroke="#D84444" stroke-width="3" stroke-linecap="round">'
            '<line x1="11" y1="-42" x2="6" y2="-48"/><line x1="11" y1="-42" x2="20" y2="-46"/>'
            "</g></g>" % (cx, cy, size / 80.0))


def card_bomb(x, y, value="2/3", title="BOM CÒN LẠI"):
    s = slip(x, y, 440, 158, RED, 4, 24, shadow="heroShadow")
    s += text(x + 44, y + 42, title, 30, RED, 900, letter=1)
    s += text(x + 44, y + 122, value, 72, RED, 950)
    s += bomb_icon(x + 376, y + 75, 80)      # sticker icon_bomb.svg (80x80) góc phải
    return s


def card_sum(x, y, value="17", title="TỔNG HIỆN TẠI"):
    s = slip(x, y, 440, 158, BLUE_DARK, 4, 24, shadow="heroShadow")
    s += text(x + 44, y + 42, title, 30, INK_SOFT, 900, letter=1)
    s += text(x + 44, y + 122, value, 72, INK, 950)
    return s


def card_op(x, y, op="="):
    s = slip(x, y, 112, 112, BLUE, 3, 18, margin=RED, ruled=True)
    s += text(x + 62, y + 76, op, 58, RED, 950, "middle")
    return s


def card_target(x, y, value="24", title="MỤC TIÊU"):
    s = slip(x, y, 250, 138, BLUE, 3, 20, ruled=True)
    s += text(x + 34, y + 36, title, 18, INK_SOFT, 800)
    s += text(x + 34, y + 116, value, 58, INK, 950)
    return s


def card_challenge(rows, title="THỬ THÁCH", count="1/3 ✓", note="1 ĐÃ HOÀN THÀNH"):
    """Thẻ THỬ THÁCH 720x246 tại (271,-29) — dùng cho các mode mặc định LevelHUD."""
    x, y = 271, -29
    s = slip(x, y, 720, 246, BLUE, 4, 24)
    s += text(x + 32, y + 42, title, 24, RED, 900, letter=1)
    s += text(x + 44, y + 138, count, 62, INK, 950, "middle")
    s += text(x + 111, y + 190, note, 24, INK_SOFT, 700, "middle")
    s += '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#E2EBF1" stroke-width="3"/>' % (
        x + 190, y + 18, x + 190, y + 228)
    for i, (name, status, done) in enumerate(rows):
        ry = y + 28 + i * 66
        s += ('<rect x="%s" y="%s" width="490" height="58" rx="12" fill="%s" stroke="%s" stroke-width="2"/>'
              % (x + 205, ry, "#F4F9FC" if not done else "#FDF3F3", "#DCE8F0" if not done else "#F0D5D5"))
        s += ('<rect x="%s" y="%s" width="30" height="30" rx="7" fill="%s" stroke="%s" stroke-width="3"/>'
              % (x + 219, ry + 14, PAPER, RED if done else "#B9CDDB"))
        if done:
            s += ('<polyline points="%s,%s %s,%s %s,%s" fill="none" stroke="%s" stroke-width="4" '
                  'stroke-linecap="round" stroke-linejoin="round"/>'
                  % (x + 226, ry + 29, x + 232, ry + 36, x + 242, ry + 22, RED))
        s += text(x + 259, ry + 38, name, 22, INK, 800)
        s += text(x + 665, ry + 38, status, 22, RED if done else INK_SOFT, 800, "end")
    return s


def card_note(x, y, title, hint, phase):
    s = slip(x, y, 440, 158, BLUE_DARK, 4, 24)
    s += text(x + 44, y + 44, title, 30, INK, 900, letter=1)
    s += text(x + 44, y + 96, hint, 20, INK_SOFT, 700)
    s += text(x + 44, y + 138, phase, 20, RED, 800)
    return s


# ---------------------------------------------------------------------------
# Spec từng chế độ
# ---------------------------------------------------------------------------
def level_hud_cards(time_value, rows, time_title="THỜI GIAN"):
    return [{"draw": lambda: card_time(0, 31, time_value, time_title)},
            {"draw": lambda: card_challenge(rows)}]


DEFAULT_ROWS = [("Không đâm vào tường", "✓ ĐẠT", True),
                ("Đi không quá 14 bước", "0/14 bước", False),
                ("Về đích dưới 42 giây", "còn 42s", False)]

MODES = [
    {
        "id": "time_attack",
        "comment": "MÀN CHƠI — TIME ATTACK MAZE (HUD mặc định: THỬ THÁCH + THỜI GIAN đếm ngược)",
        "title": "TIME ATTACK MAZE",
        "subtitle": "DAILY CHALLENGE · MODE time_attack",
        "hud": "level_mode.tscn (LevelHUD)",
        "cards": lambda: level_hud_cards("00:42 ↓", DEFAULT_ROWS),
        "grid": (4, 4),
        "notes": {(0, 0): "S", (3, 3): "F", (1, 0): "2", (0, 1): "1", (1, 1): "3",
                  (2, 1): "2", (1, 2): "1", (2, 2): "2", (3, 2): "1"},
        "walls": [(1, 1, 1, 2), (3, 0, 3, 1), (2, 2, 3, 2), (0, 2, 1, 2)],
        "path": [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2), (3, 2), (3, 3)],
        "markers": [
            (1, 175, 275, "Thẻ THỜI GIAN 250×138 (card_time_slip.svg) — đếm ngược, hết giờ = thua"),
            (2, 681, 214, "Thẻ THỬ THÁCH 720×246 (card_challenge.svg) — 3 dải 490×58"),
            (3, 540, 700, "Số trên ô = số tường quanh ô (0..4) · tường ẩn vẽ nét đứt"),
        ],
        "footer": "Luật: đâm tường về S và mất thời gian · thắng khi tới F trước khi hết giờ.",
    },
    {
        "id": "minesweeper",
        "comment": "MÀN CHƠI — MINESWEEPER MAZE (HUD: BOM CÒN LẠI + THỜI GIAN)",
        "title": "MINESWEEPER MAZE",
        "subtitle": "DAILY CHALLENGE · MODE minesweeper",
        "hud": "minesweep_hud.tscn (MinesweepHUD)",
        "cards": lambda: [{"draw": lambda: card_time(0, 31, "00:37")},
                          {"draw": lambda: card_bomb(270, 18, "2/3")}],
        "grid": (3, 3),
        "notes": {(0, 0): "S", (2, 2): "F", (1, 0): "2", (0, 1): "1", (1, 1): "3",
                  (2, 1): "1", (0, 2): "1", (1, 2): "2"},
        "path": [(0, 0), (0, 1), (1, 1), (2, 1), (2, 2)],
        "bomb_mark": (1, 0),
        "markers": [
            (1, 175, 275, "Thẻ THỜI GIAN 250×138 (card_time_slip.svg)"),
            (2, 540, 272, "Thẻ BOM CÒN LẠI 440×158 (card_bomb.svg + sticker icon_bomb.svg)"),
            (3, 540, 700, "Số = số mìn 8 ô lân cận · đạp mìn = THUA NGAY + hiện icon Bomb"),
        ],
        "footer": "Luật: đạp mìn đứng nguyên tại ô, hiện Bomb, giữ nguyên số, mở popup thua.",
    },
    {
        "id": "sum_path",
        "comment": "MÀN CHƠI — SUM PATH (HUD: TỔNG HIỆN TẠI · TOÁN TỬ · MỤC TIÊU · THỜI GIAN)",
        "title": "SUM PATH",
        "subtitle": "DAILY CHALLENGE · MODE sum_path",
        "hud": "sum_path_hud.tscn (SumPathHUD)",
        "cards": lambda: [{"draw": lambda: card_time(0, 31, "00:58")},
                          {"draw": lambda: card_sum(270, 18, "17")},
                          {"draw": lambda: card_op(664, 68, "=")},
                          {"draw": lambda: card_target(730, 28, "24")}],
        "grid": (4, 4),
        "notes": {(0, 0): "S", (3, 3): "F", (1, 0): "4", (0, 1): "7", (1, 1): "9",
                  (2, 1): "6", (1, 2): "8", (2, 2): "5", (3, 2): "7", (2, 0): "3"},
        "path": [(0, 0), (1, 0), (1, 1), (2, 2), (3, 2), (3, 3)],
        "markers": [
            (1, 175, 275, "Thẻ THỜI GIAN 250×138 (card_time_slip.svg)"),
            (2, 540, 272, "TỔNG HIỆN TẠI 440×158 (card_sum.svg)"),
            (3, 770, 299, "Thẻ TOÁN TỬ 112×112 (card_op.svg) nằm GIỮA hai thẻ"),
            (4, 905, 272, "MỤC TIÊU 250×138 — chỉ hiện con số"),
            (5, 540, 760, "Đọc như một phép tính: `17 = 24` · ô tính điểm 1 lần"),
        ],
        "footer": "Luật: không tường · mỗi ô là điểm 1..9 · tới F với tổng thỏa điều kiện (`<`, `>`, `=`).",
    },
    {
        "id": "countdown_cost",
        "comment": "MÀN CHƠI — COUNTDOWN COST (HUD mặc định: THỬ THÁCH + THỜI GIAN · ngân sách bước)",
        "title": "COUNTDOWN COST",
        "subtitle": "DAILY CHALLENGE · MODE countdown_cost",
        "hud": "level_mode.tscn (LevelHUD)",
        "cards": lambda: level_hud_cards("01:07", [("Không đâm vào tường", "✓ ĐẠT", True),
                                                   ("Đi không quá 18 bước", "4/18 bước", False),
                                                   ("Về đích dưới 54 giây", "còn 54s", False)]),
        "grid": (4, 4),
        "notes": {(0, 0): "S", (3, 3): "F", (1, 0): "1", (2, 0): "3", (0, 1): "2",
                  (1, 1): "1", (2, 1): "4", (3, 1): "2", (0, 2): "3", (1, 2): "1",
                  (2, 2): "2", (3, 2): "1", (1, 3): "2", (2, 3): "1"},
        "path": [(0, 0), (1, 0), (1, 1), (2, 1), (2, 2), (3, 2), (3, 3)],
        "markers": [
            (1, 175, 275, "Thẻ THỜI GIAN 250×138 (card_time_slip.svg)"),
            (2, 681, 214, "Thẻ THỬ THÁCH 720×246 — dải 2 đóng vai ngân sách bước"),
            (3, 540, 700, "Số trên ô = CHI PHÍ BƯỚC (1..4), KHÔNG liên quan số tường"),
        ],
        "footer": "Luật: vào ô nào trừ đúng chi phí ô đó · đâm tường về S, trừ chi phí ô đích.",
    },
    {
        "id": "blind_memory",
        "comment": "MÀN CHƠI — BLIND MEMORY MAZE (HUD: GHI NHỚ VỊ TRÍ TƯỜNG + THỜI GIAN · POPUP ĐẾM NGƯỢC)",
        "title": "BLIND MEMORY",
        "subtitle": "DAILY CHALLENGE · MODE blind_memory",
        "hud": "blind_memory_hud.tscn (BlindMemoryHUD)",
        "cards": lambda: [{"draw": lambda: card_time(0, 31, "00:00")},
                          {"draw": lambda: card_note(270, 18, "GHI NHỚ VỊ TRÍ TƯỜNG",
                                                     "Nhìn kỹ các bức tường rồi đi bằng trí nhớ",
                                                     "CHẾ ĐỘ: NORMAL")}],
        "grid": (5, 5),
        "notes": {(0, 0): "S", (4, 4): "F"},
        "walls_all": [(1, 1, 1, 3), (2, 0, 2, 2), (3, 2, 4, 2), (0, 3, 2, 3), (3, 3, 3, 4), (1, 4, 2, 4)],
        "extra": "POPUP",
        "markers": [
            (1, 175, 275, "Thẻ THỜI GIAN 250×138 — đồng hồ ĐỨNG YÊN lúc ghi nhớ"),
            (2, 540, 272, "Thẻ GHI NHỚ 440×158 (card_sum.svg) — KHÔNG có thẻ Thử thách"),
            (3, 838, 190, "Popup đếm ngược 3→2→1→GO! (memory_countdown.tscn), không nền mờ"),
            (4, 540, 760, "Tường hiện toàn bộ khi ghi nhớ, sau đó ẩn hết để đi bằng trí nhớ"),
        ],
        "footer": "Luật: Thường = về S khi đâm tường, Hardcore = thua ngay.",
    },
    {
        "id": "fog_of_war",
        "comment": "MÀN CHƠI — FOG OF WAR MAZE (HUD mặc định: THỬ THÁCH + THỜI GIAN · sương mù quanh nhân vật)",
        "title": "FOG OF WAR MAZE",
        "subtitle": "DAILY CHALLENGE · MODE fog_of_war",
        "hud": "level_mode.tscn (LevelHUD)",
        "cards": lambda: level_hud_cards("00:51", DEFAULT_ROWS),
        "grid": (5, 5),
        "notes": {(0, 0): "S", (4, 4): "F", (1, 0): "2", (0, 1): "1", (1, 1): "3", (2, 1): "2"},
        "fog": True,
        "walls": [(1, 1, 1, 3), (2, 0, 2, 2), (3, 2, 4, 2), (0, 3, 2, 3)],
        "path": [(0, 0), (1, 0), (1, 1), (2, 1)],
        "markers": [
            (1, 175, 275, "Thẻ THỜI GIAN 250×138 (card_time_slip.svg)"),
            (2, 681, 214, "HUD mặc định (LevelHUD) — THỬ THÁCH + THỜI GIAN"),
            (3, 540, 700, "Chỉ ô trong bán kính 1 quanh nhân vật mới hiện số"),
            (4, 540, 980, "Ô ngoài bán kính bị phủ mờ (alpha 0.4) — tường vẫn ẩn"),
        ],
        "footer": "Luật: Thường = về S khi đâm tường, Hardcore = thua ngay.",
    },
    {
        "id": "fading_ink",
        "comment": "MÀN CHƠI — FADING INK / MỰC PHAI (HUD mặc định: THỬ THÁCH + THỜI GIAN · ô hết mực mờ đi)",
        "title": "FADING INK",
        "subtitle": "DAILY CHALLENGE · MODE fading_ink",
        "hud": "level_mode.tscn (LevelHUD)",
        "cards": lambda: level_hud_cards("00:33", [("Không đâm vào tường", "✓ ĐẠT", True),
                                                   ("Đi không quá 10 bước", "3/10 bước", False),
                                                   ("Về đích dưới 30 giây", "còn 30s", False)]),
        "grid": (4, 4),
        "notes": {(0, 0): "S", (3, 3): "F", (1, 0): "6", (0, 1): "4", (1, 1): "5",
                  (2, 1): "3", (2, 2): "4", (3, 2): "1"},
        "dimmed": [(1, 0), (3, 2)],
        "path": [(0, 0), (0, 1), (1, 1), (2, 2), (3, 3)],
        "markers": [
            (1, 175, 275, "Thẻ THỜI GIAN 250×138 (card_time_slip.svg)"),
            (2, 681, 214, "HUD mặc định (LevelHUD) — mode không có thẻ riêng"),
            (3, 540, 700, "Ô còn mực = có số · MỖI BƯỚC ĐI làm MỌI ô phai 1 điểm"),
            (4, 540, 980, "Ô phai hết mực: mất số + mờ đi (alpha 0.4), KHÔNG đi vào được"),
        ],
        "footer": "Luật: chỉ đi trên ô còn số · hết lối đi mà chưa tới F = THUA (`HẾT ĐƯỜNG ĐI!`).",
    },
]


def _annotations(markers):
    """markers: [(số, x, y, mô tả)] — badge số đặt trên thành phần tương ứng trong mockup."""
    return "\n".join("  " + marker(n, x, y) for (n, x, y, _label) in markers)


def _footer(m):
    return ('  <g transform="translate(70, 1852)">'
            "%s%s</g>" % (
                text(0, 0, "MOCKUP HUD · %s  →  %s" % (m["title"], m["hud"]), 24, INK, 800),
                text(0, 30, "mode_id = %s · mockup/matchup_%s.svg · %s" % (
                    m["id"], m["id"], m["footer"]), 19, INK_SOFT, 700)))


def _blind_memory_popup():
    return ('<g transform="translate(220, 150)" filter="url(#uiShadow)">'
            '<rect width="640" height="280" rx="26" fill="%s" stroke="%s" stroke-width="4"/>'
            '<rect x="12" y="-24" width="226" height="54" rx="6" fill="#E8D9A8" opacity="0.85" '
            'transform="rotate(-3 125 3)"/>'
            '%s%s%s</g>'
            % (PAPER, BLUE,
               text(320, 66, "GHI NHỚ!", 40, RED, 900, "middle"),
               text(320, 196, "3", 132, RED, 950, "middle"),
               text(320, 248, "Tường sẽ biến mất khi đếm ngược kết thúc", 20, INK_SOFT, 700, "middle")))


def build(m):
    parts = [head(m["title"], m.get("subtitle"))]
    parts.append("  <!-- ===== HUD theo chế độ: khung 980x249 tại (50,175) ===== -->")
    parts.append('  <g transform="translate(%s, %s)">' % (HUD_X, HUD_Y))
    for card in m["cards"]():
        parts.append("  " + card["draw"]())
    parts.append("  </g>")
    parts.append("")
    parts.append("  <!-- ===== Bàn cờ (Board node: 41,420 → 1061,1440) ===== -->")
    parts.append("  " + board_frame())
    cols, rows = m["grid"]
    parts.append("  " + board_grid(cols, rows, dimmed=m.get("dimmed", ()),
                                   notes=m.get("notes", {})))
    parts.append("  " + board_walls(cols, rows, m.get("walls_all", m.get("walls", [])),
                                    dashed=not m.get("walls_all")))
    if m.get("path"):
        parts.append("  " + board_path(m["path"], cols, rows))
    if m.get("bomb_mark"):
        c, r = m["bomb_mark"]
        bx, by, bw, bh = BOARD
        cell = min(176, (bw - 24) / cols, (bh - 24) / rows)
        gx = bx + (bw - cell * cols) / 2 + (c + 0.5) * cell
        gy = by + (bh - cell * rows) / 2 + (r + 0.5) * cell
        parts.append("  " + bomb_icon(gx, gy, cell * 0.52))
    if m.get("fog"):
        parts.append('  <rect x="%s" y="%s" width="%s" height="%s" rx="28" fill="#5E7484" opacity="0.42"/>'
                     % (BOARD[0], BOARD[1], BOARD[2], BOARD[3]))
    if m.get("extra") == "POPUP":
        parts.append("  " + _blind_memory_popup())
    parts.append("")
    parts.append("  <!-- ===== Thanh nút dưới ===== -->")
    parts.append("  " + bottom_bar())
    parts.append("")
    parts.append("  <!-- ===== Đánh dấu + bảng chú thích ===== -->")
    parts.append(_annotations(m["markers"]))
    parts.append("")
    parts.append(legend([(n, label) for (n, _x, _y, label) in m["markers"]]))
    parts.append("")
    parts.append("  " + _footer(m))
    return "\n".join(parts)


def main(argv=None):
    ap = argparse.ArgumentParser(description="Sinh mockup matchup HUD cho từng chế độ")
    ap.add_argument("--dump", action="store_true", help="In toạ độ node của các scene HUD")
    ap.add_argument("--list", action="store_true", help="Liệt kê mode sẽ sinh mockup")
    args = ap.parse_args(argv)

    if args.dump:
        dump()
        return 0
    if args.list:
        for mode in MODES:
            print("%-14s -> mockup/matchup_%s.svg" % (mode["id"], mode["id"]))
        return 0

    for mode in MODES:
        body = build(mode)
        path = write_svg("matchup_%s.svg" % mode["id"], mode["comment"], body)
        print("  [OK] %s" % os.path.relpath(path, ROOT).replace("\\", "/"))
    print("Xong: %d mockup (khong ghi de matchup_level/dungeon)." % len(MODES))
    return 0


if __name__ == "__main__":
    sys.exit(main())

