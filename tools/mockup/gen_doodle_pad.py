#!/usr/bin/env python3
"""Sinh art cho "Bàn nháp thử bút" (tab BÚT & MỰC — mockup/shopping_pencil.svg):

    assets/images/shop/doodle_pad.svg    980x215  giấy nháp mini + lề đỏ + ghim kẹp giấy
    assets/images/shop/doodle_badge.svg  250x145  thẻ ĐANG XEM THỬ (viền nét đứt + băng dính)

LƯU Ý ThorVG (Godot SVG importer): CHỈ dùng rect/line/path/circle/polygon —
KHÔNG dùng <text> / <use> / <filter> / <pattern> / <mask>.

Chạy:  python tools/mockup/gen_doodle_pad.py
"""
from pathlib import Path

OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "images" / "shop"


def svg(width: float, height: float, parts: list) -> str:
    head = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height}" '
            f'width="{width}" height="{height}">\n')
    return head + "\n".join("  " + p for p in parts) + "\n</svg>\n"


def pad_svg() -> str:
    """980x215 — tờ giấy nháp mini: viền xanh, lề đỏ, lưới ô vuông mờ, ghim kẹp giấy."""
    parts = []
    # Tờ giấy
    parts.append('<rect x="2" y="2" width="976" height="211" rx="22" fill="#FFFDF8" '
                 'stroke="#6EA0C8" stroke-width="3"/>')
    # Lưới vở mini (chừa hàng tiêu đề phía trên)
    x = 60
    while x <= 958:
        parts.append(f'<line x1="{x}" y1="50" x2="{x}" y2="207" stroke="#8FB9D2" '
                     'stroke-width="1" opacity="0.35"/>')
        x += 24
    y = 52
    while y <= 206:
        parts.append(f'<line x1="42" y1="{y}" x2="972" y2="{y}" stroke="#8FB9D2" '
                     'stroke-width="1" opacity="0.28"/>')
        y += 24
    # Lề đỏ
    parts.append('<line x1="38" y1="8" x2="38" y2="207" stroke="#D84444" stroke-width="3"/>')
    # Ghim kẹp giấy góc trên trái
    parts.append('<g transform="translate(56, 8) rotate(-18)">'
                 '<path d="M0 34 L0 10 A9 9 0 0 1 18 10 L18 42 A13 13 0 0 1 -8 42 L-8 14" '
                 'fill="none" stroke="#7A8F9B" stroke-width="4" stroke-linecap="round"/></g>')
    return svg(980, 215, parts)


def badge_svg() -> str:
    """250x145 — thẻ ĐANG XEM THỬ: viền nét đứt + nền giấy tím nhạt + băng dính washi."""
    parts = []
    parts.append('<rect x="1.5" y="1.5" width="247" height="142" rx="16" fill="#F5F3FF" '
                 'stroke="#6EA0C8" stroke-width="2.5" stroke-dasharray="8 6"/>')
    # Góc gấp giấy nhỏ (trang trí)
    parts.append('<path d="M247 108 L247 141 A3 3 0 0 1 244 143.5 L212 143.5 Z" '
                 'fill="#EDE9FE" stroke="#C4B5FD" stroke-width="1.5"/>')
    # Băng dính washi trên mép thẻ
    parts.append('<g transform="translate(80, -8) rotate(-5)">'
                 '<rect width="90" height="24" rx="4" fill="#E7F0F7" stroke="#B8D3E4" '
                 'stroke-width="1.5" opacity="0.95"/></g>')
    return svg(250, 145, parts)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    files = {
        "doodle_pad.svg": pad_svg(),
        "doodle_badge.svg": badge_svg(),
    }
    for name, content in files.items():
        path = OUT_DIR / name
        path.write_text(content, encoding="utf-8")
        print(f"[OK] {path} ({len(content)} bytes)")


if __name__ == "__main__":
    main()
