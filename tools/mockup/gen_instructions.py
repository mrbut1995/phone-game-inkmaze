#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sinh ảnh hướng dẫn cho popup HƯỚNG DẪN trong game (assets/images/instructions/*.svg).

Mỗi ảnh = 1 "thẻ vẽ tay" 780x460 minh hoạ luật của 1 trang hướng dẫn:
  - guide_control.svg      : cách điều khiển chung (vẽ đường S -> F, Gợi ý, Hoàn tác)
  - guide_score.svg        : hệ thống Thử thách / Sao / thưởng Xu
  - mode_<mode_id>.svg     : luật riêng của từng chế độ chơi (10 mode)

LƯU Ý ThorVG (SVG importer của Godot) KHÔNG render <text>/<use>/<filter>/<pattern>:
ảnh KHÔNG chứa chữ — mọi số vẽ bằng nét 7 đoạn, icon vẽ bằng path/circle.

Chạy:  python tools/mockup/gen_instructions.py          (ghi vào assets/images/instructions/)
       python tools/mockup/gen_instructions.py --list   (liệt kê file sẽ sinh)
"""

from __future__ import annotations

import argparse
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT_DIR = os.path.join(ROOT, "assets", "images", "instructions")

W, H = 780, 460

INK = "#224C6D"
INK_SOFT = "#718B9E"
BLUE = "#6EA0C8"
BLUE_DARK = "#3D83AE"
RED = "#D84444"
AMBER = "#D97706"
AMBER_LIGHT = "#FBBF24"
GREEN = "#2E7D32"
PAPER = "#FEFDFA"
PAPER_SOFT = "#FBF7EE"
GRID = "#BACEDC"
FOG = "#B9CDDC"
DARK = "#3D5A73"


# ---------------------------------------------------------------------------
# Primitive vẽ
# ---------------------------------------------------------------------------
def line(x1, y1, x2, y2, color, w, cap="round", dash=None):
    d = ' stroke-dasharray="%s"' % dash if dash else ""
    return ('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" '
            'stroke-linecap="%s"%s/>' % (x1, y1, x2, y2, color, w, cap, d))


def rect(x, y, w, h, rx, fill, stroke=None, sw=0, dash=None, opacity=1.0):
    s = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if stroke else ""
    d = ' stroke-dasharray="%s"' % dash if dash else ""
    o = ' opacity="%s"' % opacity if opacity != 1.0 else ""
    return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s"%s%s%s/>' % (
        x, y, w, h, rx, fill, s, d, o)


def circle(cx, cy, r, fill="none", stroke=None, sw=0, dash=None, opacity=1.0):
    s = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if stroke else ""
    d = ' stroke-dasharray="%s"' % dash if dash else ""
    o = ' opacity="%s"' % opacity if opacity != 1.0 else ""
    return '<circle cx="%s" cy="%s" r="%s" fill="%s"%s%s%s/>' % (cx, cy, r, fill, s, d, o)


def poly(points, color, w, fill="none", dash=None, cap="round", join="round"):
    pts = " ".join("%s,%s" % (round(x, 1), round(y, 1)) for x, y in points)
    d = ' stroke-dasharray="%s"' % dash if dash else ""
    return ('<polyline points="%s" fill="%s" stroke="%s" stroke-width="%s" '
            'stroke-linecap="%s" stroke-linejoin="%s"%s/>' % (pts, fill, color, w, cap, join, d))


def polyg(points, fill, stroke=None, sw=0, opacity=1.0):
    pts = " ".join("%s,%s" % (round(x, 1), round(y, 1)) for x, y in points)
    s = ' stroke="%s" stroke-width="%s"' % (stroke, sw) if stroke else ""
    o = ' opacity="%s"' % opacity if opacity != 1.0 else ""
    return '<polygon points="%s" fill="%s"%s%s/>' % (pts, fill, s, o)


def path(d, color, w, fill="none", cap="round", join="round", dash=None, opacity=1.0):
    da = ' stroke-dasharray="%s"' % dash if dash else ""
    o = ' opacity="%s"' % opacity if opacity != 1.0 else ""
    return ('<path d="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linecap="%s" '
            'stroke-linejoin="%s"%s%s/>' % (d, fill, color, w, cap, join, da, o))


# ---------------------------------------------------------------------------
# Số vẽ bằng nét 7 đoạn (ThorVG không render <text>)
# ---------------------------------------------------------------------------
SEGMENTS = {
    "a": ((0.06, 0.07), (0.54, 0.07)),
    "b": ((0.58, 0.11), (0.58, 0.46)),
    "c": ((0.58, 0.54), (0.58, 0.89)),
    "d": ((0.06, 0.93), (0.54, 0.93)),
    "e": ((0.02, 0.54), (0.02, 0.89)),
    "f": ((0.02, 0.11), (0.02, 0.46)),
    "g": ((0.06, 0.50), (0.54, 0.50)),
}
DIGITS = {
    "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
    "5": "afgcd", "6": "afgecd", "7": "abc", "8": "abcdefg", "9": "abcdfg",
}


def digit(x, y, h, ch, color=INK, w=None):
    """Vẽ 1 chữ số 7 đoạn; (x, y) = góc trên-trái, h = cao chữ số."""
    segs = DIGITS.get(str(ch), "abcdefg")
    w = w if w else max(h * 0.15, 2.5)
    parts = []
    for s in segs:
        (x1, y1), (x2, y2) = SEGMENTS[s]
        parts.append(line(x + x1 * h, y + y1 * h, x + x2 * h, y + y2 * h, color, w))
    return parts


def number(x, y, h, text, color=INK, w=None):
    """Vẽ chuỗi số 7 đoạn."""
    if w is None:
        w = h * 0.62
    parts = []
    for i, ch in enumerate(str(text)):
        parts.extend(digit(x + i * (w + h * 0.18), y, h, ch, color))
    return parts


# ---------------------------------------------------------------------------
# Icon
# ---------------------------------------------------------------------------
def icon_start(cx, cy, r=15):
    return [circle(cx, cy, r, GREEN, PAPER, 3), circle(cx, cy, r * 0.38, PAPER)]


def icon_flag(cx, cy, s=17):
    return [
        line(cx - s * 0.55, cy + s, cx - s * 0.55, cy - s, INK, 3),
        polyg([(cx - s * 0.55, cy - s), (cx + s * 0.75, cy - s * 0.45), (cx - s * 0.55, cy + s * 0.15)], RED),
    ]


def icon_bomb(cx, cy, r=13):
    parts = []
    for i in range(6):
        import math
        a = math.radians(i * 60 - 90)
        parts.append(line(cx + math.cos(a) * (r + 1), cy + math.sin(a) * (r + 1),
                          cx + math.cos(a) * (r + 6), cy + math.sin(a) * (r + 6), DARK, 3))
    parts.append(circle(cx, cy, r, DARK))
    parts.append(circle(cx - r * 0.3, cy - r * 0.3, r * 0.28, "#8CA6B8"))
    return parts


def icon_clock(cx, cy, r=34):
    parts = [
        circle(cx, cy, r, PAPER, BLUE_DARK, 5),
        line(cx, cy, cx, cy - r * 0.55, INK, 5),
        line(cx, cy, cx + r * 0.42, cy + r * 0.22, INK, 5),
        line(cx - r + 6, cy - r + 6, cx - r + 6, cy - r + 6, INK, 5),
    ]
    for i in range(4):
        import math
        a = math.radians(i * 90)
        parts.append(circle(cx + math.cos(a) * (r - 6), cy + math.sin(a) * (r - 6), 2.4, INK))
    return parts


def icon_hourglass(cx, cy, s=34):
    w = s * 0.78
    return [
        polyg([(cx - w / 2, cy - s / 2), (cx + w / 2, cy - s / 2), (cx, cy)], BLUE_DARK),
        polyg([(cx - w / 2, cy + s / 2), (cx + w / 2, cy + s / 2), (cx, cy)], AMBER_LIGHT),
        line(cx - w / 2 - 4, cy - s / 2, cx + w / 2 + 4, cy - s / 2, INK, 4),
        line(cx - w / 2 - 4, cy + s / 2, cx + w / 2 + 4, cy + s / 2, INK, 4),
    ]


def icon_ink(cx, cy, s=26):
    return [
        path("M %s %s C %s %s, %s %s, %s %s C %s %s, %s %s, %s %s Z" % (
            cx, cy - s, cx + s * 0.9, cy + s * 0.1, cx + s * 0.55, cy + s * 0.85, cx, cy + s * 0.85,
            cx - s * 0.55, cy + s * 0.85, cx - s * 0.9, cy + s * 0.1, cx, cy - s),
            DARK, 0, fill=DARK),
        circle(cx - s * 0.25, cy + s * 0.25, s * 0.16, "#8CA6B8"),
    ]


def icon_cloud(cx, cy, s=1.0):
    return [
        circle(cx - 16 * s, cy + 4 * s, 14 * s, FOG),
        circle(cx + 4 * s, cy - 4 * s, 18 * s, FOG),
        circle(cx + 22 * s, cy + 6 * s, 13 * s, FOG),
        rect(cx - 30 * s, cy + 2 * s, 56 * s, 16 * s, 8 * s, FOG),
    ]


def icon_coin(cx, cy, r=22):
    return [
        circle(cx, cy, r, AMBER_LIGHT, AMBER, 3),
        circle(cx, cy, r * 0.55, "none", "#F59E0B", 2.4, dash="5 4"),
        path("M %s %s A 10 10 0 0 0 %s %s" % (cx - r * 0.3, cy - r * 0.42, cx - r * 0.3, cy + r * 0.42),
             "#78350F", 3),
    ]


def icon_star(cx, cy, r=30, filled=True):
    import math
    pts = []
    for i in range(10):
        a = math.radians(i * 36 - 90)
        rr = r if i % 2 == 0 else r * 0.45
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    return [polyg(pts, AMBER_LIGHT if filled else "none", AMBER, 4)]


def icon_check(cx, cy, s=13, color=GREEN, w=6):
    return [poly([(cx - s, cy + s * 0.1), (cx - s * 0.25, cy + s * 0.8), (cx + s, cy - s * 0.75)], color, w)]


def icon_cross(cx, cy, s=12, color=RED, w=6):
    return [line(cx - s, cy - s, cx + s, cy + s, color, w), line(cx + s, cy - s, cx - s, cy + s, color, w)]


def icon_plus(cx, cy, s=12, color=INK, w=6):
    return [line(cx - s, cy, cx + s, cy, color, w), line(cx, cy - s, cx, cy + s, color, w)]


def icon_minus(cx, cy, s=12, color=INK, w=6):
    return [line(cx - s, cy, cx + s, cy, color, w)]


def icon_equals(cx, cy, s=12, color=INK, w=6):
    return [line(cx - s, cy - s * 0.45, cx + s, cy - s * 0.45, color, w),
            line(cx - s, cy + s * 0.45, cx + s, cy + s * 0.45, color, w)]


def icon_undo(cx, cy, s=30):
    return [
        path("M %s %s A %s %s 0 1 0 %s %s" % (cx + s * 0.7, cy - s * 0.5, s * 0.85, s * 0.85, cx + s, cy + s * 0.5),
             BLUE_DARK, 6),
        polyg([(cx + s * 0.95, cy - s * 0.95), (cx + s * 0.35, cy - s * 0.5), (cx + s, cy - s * 0.05)], BLUE_DARK),
    ]


def icon_bulb(cx, cy, s=28):
    return [
        circle(cx, cy - s * 0.15, s * 0.62, AMBER_LIGHT, AMBER, 3),
        rect(cx - s * 0.24, cy + s * 0.42, s * 0.48, s * 0.3, 4, INK_SOFT),
        line(cx - s * 0.95, cy - s * 0.85, cx - s * 0.7, cy - s * 0.62, AMBER, 3),
        line(cx + s * 0.95, cy - s * 0.85, cx + s * 0.7, cy - s * 0.62, AMBER, 3),
        line(cx, cy - s * 1.05, cx, cy - s * 0.72, AMBER, 3),
    ]


def icon_loop(cx, cy, s=30):
    parts = [
        path("M %s %s A %s %s 0 1 1 %s %s" % (cx, cy - s * 0.8, s * 0.8, s * 0.8, cx, cy + s * 0.8),
             BLUE_DARK, 6, cap="round"),
        polyg([(cx - s * 0.62, cy - s * 0.62), (cx - s * 0.15, cy - s * 0.92), (cx - s * 0.55, cy - s * 0.15)], BLUE_DARK),
    ]
    return parts


def icon_stairs(cx, cy, s=30):
    parts = []
    for i in range(4):
        parts.append(rect(cx - s + i * s * 0.5, cy + s * 0.5 - (i + 1) * s * 0.5, s * 0.5, s * 0.5,
                          3, [INK, BLUE_DARK, BLUE_DARK, INK][i]))
    return parts


def icon_calendar(cx, cy, s=30):
    return [
        rect(cx - s, cy - s * 0.8, s * 2, s * 1.7, 8, PAPER, BLUE_DARK, 4),
        line(cx - s, cy - s * 0.25, cx + s, cy - s * 0.25, BLUE_DARK, 4),
        rect(cx - s * 0.55, cy - s * 1.1, s * 0.22, s * 0.6, 2, RED),
        rect(cx + s * 0.33, cy - s * 1.1, s * 0.22, s * 0.6, 2, RED),
        circle(cx - s * 0.5, cy + s * 0.5, 3.4, INK_SOFT),
        circle(cx + s * 0.5, cy + s * 0.5, 3.4, INK_SOFT),
    ]


def icon_touch(cx, cy, r=20):
    return [circle(cx, cy, r, "none", BLUE_DARK, 4, dash="7 5"), circle(cx, cy, 6, BLUE_DARK)]


# ---------------------------------------------------------------------------
# Bàn cờ 5x5 dùng chung
# ---------------------------------------------------------------------------
class Board:
    def __init__(self, x, y, n=5, cell=62):
        self.x, self.y, self.n, self.cell = x, y, n, cell
        self.size = n * cell

    def node(self, gx, gy):
        return (self.x + gx * self.cell, self.y + gy * self.cell)

    def center(self, cx, cy):
        return (self.x + (cx + 0.5) * self.cell, self.y + (cy + 0.5) * self.cell)

    def bg(self):
        """Nền bàn cờ (trả về LIST để dùng `parts += board.bg()`)."""
        return [rect(self.x, self.y, self.size, self.size, 18, PAPER, BLUE, 4)]

    def grid(self):
        parts = []
        for i in range(1, self.n):
            parts.append(line(self.x + i * self.cell, self.y + 3, self.x + i * self.cell,
                              self.y + self.size - 3, GRID, 1.6))
            parts.append(line(self.x + 3, self.y + i * self.cell, self.x + self.size - 3,
                              self.y + i * self.cell, GRID, 1.6))
        return parts

    def wall(self, a, b, color=INK, w=8, dash=None):
        (x1, y1), (x2, y2) = self.node(*a), self.node(*b)
        return line(x1, y1, x2, y2, color, w, dash=dash)

    def path_line(self, nodes, color=RED, w=9, dash=None):
        return poly([self.node(*p) for p in nodes], color, w, dash=dash)

    def digit_cell(self, cx, cy, ch, h=26, color=INK):
        px, py = self.center(cx, cy)
        return number(px - h * 0.31, py - h * 0.5, h, ch, color)


def chip(x, y, w=112, h=112, accent=BLUE):
    """Thẻ tròn bo làm nền icon ở cột phải (trả về LIST để dùng `parts += chip(...)`)."""
    return [rect(x, y, w, h, 24, PAPER, accent, 3)]


def arrow(x1, y1, x2, y2, color=BLUE_DARK, w=6):
    import math
    a = math.atan2(y2 - y1, x2 - x1)
    s = 16
    p1 = (x2 - math.cos(a - 0.45) * s, y2 - math.sin(a - 0.45) * s)
    p2 = (x2 - math.cos(a + 0.45) * s, y2 - math.sin(a + 0.45) * s)
    return [line(x1, y1, x2, y2, color, w), polyg([(x2, y2), p1, p2], color)]


# ---------------------------------------------------------------------------
# Khung chung của mỗi ảnh
# ---------------------------------------------------------------------------
def card(parts, accent=BLUE):
    head = [rect(0, 0, W, H, 26, PAPER, accent, 4)]
    return head + parts


def _flatten(parts):
    out = []
    for item in parts:
        if isinstance(item, (list, tuple)):
            out.extend(_flatten(item))
        else:
            out.append(item)
    return out


def svg(parts):
    body = "\n  ".join(_flatten(parts))
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">\n'
            '  %s\n</svg>\n' % (W, H, W, H, body))


# ---------------------------------------------------------------------------
# 1. Cách điều khiển (dùng chung mọi chế độ)
# ---------------------------------------------------------------------------
def img_control():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    parts.append(b.path_line([(0, 0), (2, 0), (2, 2), (4, 2), (4, 4)]))
    sx, sy = b.center(0, 0)
    fx, fy = b.center(4, 4)
    parts += icon_start(sx, sy)
    parts += icon_flag(fx, fy)
    parts += [arrow(b.node(0, 0)[0] + 40, b.node(0, 0)[1] + 14, b.node(1, 0)[0] + 34, b.node(0, 0)[1] + 14)]
    parts += icon_touch(sx + 16, sy + 16)
    parts += chip(408, 106)
    parts += icon_undo(464, 162)
    parts += chip(408, 252)
    parts += icon_bulb(464, 306)
    return card(parts)


# ---------------------------------------------------------------------------
# 2. Play / Level — tường ẩn, chạm là thua
# ---------------------------------------------------------------------------
def img_play():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    parts.append(b.wall((2, 2), (3, 2), color=INK_SOFT, dash="9 7"))
    parts.append(b.path_line([(0, 0), (0, 4), (4, 4)]))
    sx, sy = b.center(0, 0)
    fx, fy = b.center(4, 4)
    parts += icon_start(sx, sy)
    parts += icon_flag(fx, fy, 15)
    wx, wy = b.node(3, 2)
    parts += icon_cross(wx - 30, wy - 20, 13, RED, 7)
    parts += chip(432, 96, 128, 128)
    parts += icon_cross(496, 160, 26, RED, 9)
    parts += chip(432, 262, 128, 128)
    parts += icon_flag(496, 320, 22)
    return card(parts)


# ---------------------------------------------------------------------------
# 3. Dungeon — tháp vô tận, +3 bước khi hồi sinh
# ---------------------------------------------------------------------------
def img_dungeon():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    parts.append(b.path_line([(0, 0), (2, 0), (2, 2), (4, 2), (4, 4)]))
    sx, sy = b.center(0, 0)
    sx4, sy4 = b.center(4, 4)
    parts += icon_start(sx, sy)
    parts += icon_stairs(sx4 - 2, sy4 - 4, 26)
    parts += chip(408, 96, 112, 112)
    parts += icon_loop(464, 152)
    parts += chip(408, 236, 200, 112)
    parts += icon_plus(444, 292, 14, AMBER, 7)
    parts += number(470, 272, 40, "3", AMBER)
    return card(parts)


# ---------------------------------------------------------------------------
# 4. Time Attack — đua đồng hồ, không giới hạn bước
# ---------------------------------------------------------------------------
def img_time_attack():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    parts.append(b.path_line([(0, 0), (2, 0), (2, 2), (4, 2), (4, 4)]))
    sx, sy = b.center(0, 0)
    fx, fy = b.center(4, 4)
    parts += icon_start(sx, sy)
    parts += icon_flag(fx, fy, 15)
    parts += [line(b.node(1, 0)[0] - 6, b.node(0, 0)[1] + 8, b.node(1, 0)[0] + 10, b.node(0, 0)[1] + 8, RED, 5),
              line(b.node(1, 0)[0] - 2, b.node(0, 0)[1] + 22, b.node(1, 0)[0] + 14, b.node(0, 0)[1] + 22, RED, 5)]
    parts += chip(408, 90, 160, 160)
    parts += icon_clock(488, 170, 56)
    parts += chip(408, 274, 160, 96)
    parts += [circle(452, 322, 20, "none", BLUE_DARK, 6), circle(510, 322, 20, "none", BLUE_DARK, 6)]
    return card(parts)


# ---------------------------------------------------------------------------
# 5. Minesweeper — số = mìn quanh ô, dẫm mìn là thua
# ---------------------------------------------------------------------------
def img_minesweeper():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    for cell in [(1, 1), (3, 1), (1, 3), (3, 3)]:
        px, py = b.center(*cell)
        parts += icon_bomb(px, py, 15)
    parts += [b.digit_cell(0, 1, "2", 24, INK), b.digit_cell(2, 0, "1", 24, INK)]
    parts.append(b.path_line([(0, 0), (2, 0), (2, 4), (4, 4)]))
    sx, sy = b.center(0, 0)
    fx, fy = b.center(4, 4)
    parts += icon_start(sx, sy)
    parts += icon_flag(fx, fy, 15)
    parts += chip(408, 96, 112, 112)
    parts += number(444, 130, 56, "2", INK)
    parts += chip(536, 96, 112, 112)
    parts += icon_bomb(592, 152, 26)
    return card(parts)


# ---------------------------------------------------------------------------
# 6. Sum Path — tổng đường đi phải thỏa MỤC TIÊU
# ---------------------------------------------------------------------------
def img_sum_path():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    route = {(0, 0): "3", (2, 0): "5", (2, 2): "2", (4, 2): "4", (4, 4): "1"}
    others = {(1, 1): "7", (3, 0): "6", (0, 3): "9", (2, 4): "8"}
    for cell, ch in others.items():
        px, py = b.center(*cell)
        parts += number(px - 12, py - 12, 24, ch, INK_SOFT)
    parts.append(b.path_line([(0, 0), (2, 0), (2, 2), (4, 2), (4, 4)]))
    for cell, ch in route.items():
        parts += b.digit_cell(cell[0], cell[1], ch, 26, INK)
    sx, sy = b.center(0, 0)
    fx, fy = b.center(4, 4)
    parts += icon_start(sx - 19, sy - 19, 10)
    parts += icon_flag(fx + 8, fy + 8, 11)
    parts += chip(408, 96, 112, 112)
    parts += icon_plus(444, 152, 13, GREEN, 7)
    parts += icon_minus(484, 152, 13, RED, 7)
    parts += chip(536, 96, 112, 112)
    parts += icon_equals(572, 140, 13, INK, 7)
    parts += number(586, 158, 30, "12", AMBER)
    return card(parts)


# ---------------------------------------------------------------------------
# 7. Countdown Cost — số trên ô = cước phí trừ quỹ bước
# ---------------------------------------------------------------------------
def img_countdown_cost():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    costs = {(0, 0): "1", (2, 0): "2", (2, 2): "1", (4, 2): "3", (4, 4): "2", (1, 4): "4", (3, 1): "3"}
    for cell, ch in costs.items():
        parts += b.digit_cell(cell[0], cell[1], ch, 26, INK)
    parts.append(b.path_line([(0, 0), (2, 0), (2, 2), (4, 2), (4, 4)]))
    sx, sy = b.center(0, 0)
    fx, fy = b.center(4, 4)
    parts += icon_start(sx - 19, sy - 19, 10)
    parts += icon_flag(fx + 8, fy + 8, 11)
    parts += chip(408, 96, 112, 112)
    parts += icon_hourglass(464, 152, 46)
    seg_x, seg_y = 408, 262
    for i in range(8):
        filled = i < 5
        parts.append(rect(seg_x + i * 21, seg_y, 16, 26, 5,
                          BLUE_DARK if filled else "none", BLUE if not filled else None, 0 if filled else 3))
    parts += [rect(408, 312, 168, 12, 6, GRID)]
    return card(parts)


# ---------------------------------------------------------------------------
# 8. Blind Memory — ghi nhớ tường rồi đi theo trí nhớ
# ---------------------------------------------------------------------------
def img_blind_memory():
    a = Board(48, 118, 4, 52)
    bb = Board(452, 118, 4, 52)
    parts = [a.bg()]
    parts += a.grid()
    for seg in [((1, 0), (1, 2)), ((2, 1), (2, 3)), ((0, 3), (2, 3)), ((3, 1), (3, 4))]:
        parts.append(a.wall(*seg))
    cxa, cya = a.center(0, 0)
    cxa2, cya2 = a.center(3, 3)
    parts += icon_start(cxa, cya, 11)
    parts += icon_flag(cxa2, cya2, 11)
    parts += [rect(78, 74, 56, 40, 12, PAPER, RED, 3), number(96, 82, 24, "3", RED)]
    parts += bb.bg()
    parts += bb.grid()
    for seg in [((1, 0), (1, 2)), ((2, 1), (2, 3)), ((0, 3), (2, 3)), ((3, 1), (3, 4))]:
        parts.append(bb.wall(*seg, color=INK_SOFT, w=6, dash="8 7"))
    cxb, cyb = bb.center(0, 0)
    cxb2, cyb2 = bb.center(3, 3)
    parts += icon_start(cxb, cyb, 11)
    parts += icon_flag(cxb2, cyb2, 11)
    parts += icon_touch(*bb.center(2, 2), 24)
    parts += arrow(332, 236, 404, 236, BLUE_DARK, 7)
    return card(parts)


# ---------------------------------------------------------------------------
# 9. Fog of War — chỉ thấy vùng quanh vị trí hiện tại
# ---------------------------------------------------------------------------
def img_fog_of_war():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    around = {(2, 2): "4", (2, 1): "2", (1, 2): "1", (3, 2): "3"}
    for cell, ch in around.items():
        parts += b.digit_cell(cell[0], cell[1], ch, 26, INK)
    parts.append(circle(*b.center(2, 2), 92, PAPER_SOFT))
    for corner, off in [((0, 0), (24, 24)), ((4, 0), (-24, 24)), ((0, 4), (24, -24)), ((4, 4), (-24, -24))]:
        px, py = b.center(*corner)
        parts += icon_cloud(px + off[0] * 0.1, py + off[1] * 0.1, 1.5)
    parts += icon_touch(*b.center(2, 2), 26)
    parts += chip(408, 96, 112, 112)
    parts += icon_cloud(464, 152, 1.5)
    parts += chip(536, 96, 112, 112)
    parts += [circle(592, 152, 34, PAPER_SOFT, BLUE_DARK, 4, dash="7 5")]
    parts += number(578, 136, 32, "4", INK)
    return card(parts)


# ---------------------------------------------------------------------------
# 10. Fading Ink — mỗi bước làm mọi ô mất 1 mực
# ---------------------------------------------------------------------------
def img_fading_ink():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    route = [((0, 0), "5", 1.0), ((1, 0), "4", 0.85), ((2, 0), "3", 0.7),
             ((2, 1), "2", 0.5), ((2, 2), "1", 0.32)]
    for cell, ch, op in route:
        px, py = b.center(*cell)
        parts.append('<g opacity="%s">%s</g>' % (op, "".join(number(px - 12, py - 13, 26, ch, INK))))
    parts.append(b.path_line([(0, 0), (2, 0), (2, 2)]))
    sx, sy = b.center(0, 0)
    parts += icon_start(sx - 19, sy - 19, 10)
    px, py = b.center(3, 2)
    parts += [rect(px - 26, py - 26, 52, 52, 12, "none", INK_SOFT, 5, dash="9 7")]
    parts += icon_cross(px, py, 13, INK_SOFT, 6)
    parts += chip(408, 96, 112, 112)
    parts += icon_ink(464, 148, 30)
    parts += chip(536, 96, 146, 112)
    parts += icon_minus(576, 152, 14, AMBER, 7)
    parts += number(600, 130, 44, "1", AMBER)
    return card(parts)


# ---------------------------------------------------------------------------
# 11. Daily Classic — maze thường của ngày (20 bước, 60 giây, thưởng Xu)
# ---------------------------------------------------------------------------
def img_daily_classic():
    b = Board(48, 76, 5, 62)
    parts = [b.bg()]
    parts += b.grid()
    parts.append(b.path_line([(0, 0), (2, 0), (2, 2), (4, 2), (4, 4)]))
    sx, sy = b.center(0, 0)
    fx, fy = b.center(4, 4)
    parts += icon_start(sx, sy)
    parts += icon_flag(fx, fy, 15)
    parts += chip(408, 96, 112, 112)
    parts += icon_calendar(464, 152, 30)
    parts += chip(536, 96, 112, 112)
    parts += icon_clock(592, 152, 38)
    parts += chip(408, 226, 240, 112)
    parts += number(444, 250, 46, "20", INK)
    parts += icon_coin(596, 282, 26)
    return card(parts)


# ---------------------------------------------------------------------------
# 12. Hệ thống Thử thách / Sao / Xu
# ---------------------------------------------------------------------------
def img_score():
    parts = []
    rows = [(96, True), (186, True), (276, False)]
    for y, done in rows:
        parts.append(circle(128, y, 26, PAPER if not done else "#E8F4EC", GREEN if done else INK_SOFT, 4,
                            dash=None if done else "7 6"))
        if done:
            parts += icon_check(128, y, 14, GREEN, 7)
        parts.append(rect(176, y - 12, 320, 24, 12, GRID))
        if done:
            parts.append(rect(176, y - 12, 320, 24, 12, GREEN))
        else:
            parts.append(rect(176, y - 12, 168, 24, 12, "none", INK_SOFT, 3, dash="8 6"))
    parts += icon_star(544, 120, 34, True)
    parts += icon_star(544, 206, 34, False)
    parts.append(rect(408, 288, 240, 96, 20, PAPER, AMBER, 3))
    parts += icon_coin(470, 336, 28)
    parts += number(520, 312, 40, "10", AMBER)
    parts += icon_cross(556, 336, 12, INK_SOFT, 6)
    parts += number(580, 312, 40, "50", INK_SOFT)
    return card(parts)


IMAGES = {
    "guide_control": img_control,
    "guide_score": img_score,
    "mode_play": img_play,
    "mode_dungeon": img_dungeon,
    "mode_time_attack": img_time_attack,
    "mode_minesweeper": img_minesweeper,
    "mode_sum_path": img_sum_path,
    "mode_countdown_cost": img_countdown_cost,
    "mode_blind_memory": img_blind_memory,
    "mode_fog_of_war": img_fog_of_war,
    "mode_fading_ink": img_fading_ink,
    "mode_daily_classic": img_daily_classic,
}


def main(argv=None):
    parser = argparse.ArgumentParser(description="Sinh ảnh hướng dẫn cho popup HƯỚNG DẪN")
    parser.add_argument("--list", action="store_true", help="liệt kê file sẽ sinh")
    parser.add_argument("--out", default=OUT_DIR, help="thư mục ghi (mặc định assets/images/instructions)")
    args = parser.parse_args(argv)

    if args.list:
        for name in sorted(IMAGES):
            print("%s.svg" % name)
        return 0

    os.makedirs(args.out, exist_ok=True)
    for name, builder in sorted(IMAGES.items()):
        content = svg(builder())
        path = os.path.join(args.out, "%s.svg" % name)
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(content)
        print("wrote %s (%d bytes)" % (os.path.relpath(path, ROOT), len(content)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
