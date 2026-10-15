"""Sinh ảnh BOOT SPLASH (ảnh tĩnh hiện ngay khi mở app, trước màn Splash động).

Vì sao có ảnh này: lúc mở app, engine phải nạp autoload + scene trước khi vẽ được frame
đầu tiên. Trước đây khoảng đó là màn hình ĐEN (export đặt `splash_screen/background_color`
đen + boot splash mặc định của Godot tối màu). Ảnh này cho engine hiện NGAY nền giấy + logo
+ tên hãng, khớp 1:1 với màn Splash (`scenes/layout/*/splash.tscn`) nên mắt không thấy "nhảy".

Chạy lại khi đổi logo/tên hãng:
    python tools/make_boot_splash.py
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "company_logo.png"
FONT = ROOT / "assets/fonts/Be_Vietnam_Pro/BeVietnamPro-Black.ttf"
OUT = ROOT / "assets/images-png/boot_splash.png"

# Khớp màu nền giấy của `nodes/common/parallax_background.tscn` và màu chữ MainTitle
PAPER = (250, 245, 235)
TITLE_COLOR = (61, 131, 174)
COMPANY = "Invisible Gear"

# Tỉ lệ khung 9:16 (canvas thiết kế 540×960 nhân 4/3) — thiết bị khác tỉ lệ sẽ thấy
# thêm nền giấy ở trên/dưới vì màu nền trùng khít.
WIDTH, HEIGHT = 720, 1280
LOGO_BOX = (94 + int(0.245 * 1140), 94 + int(0.495 * 1140))  # theo anchored của splash
LOGO_WIDTH = 400
TITLE_BASELINE_Y = 94 + int(0.54 * 1140)
TITLE_FONT_SIZE = 43


def main() -> int:
    canvas = Image.new("RGB", (WIDTH, HEIGHT), PAPER)

    logo = Image.open(LOGO).convert("RGBA")
    ratio = LOGO_WIDTH / logo.width
    logo = logo.resize((LOGO_WIDTH, max(1, int(logo.height * ratio))), Image.LANCZOS)
    top = LOGO_BOX[0] + (LOGO_BOX[1] - LOGO_BOX[0] - logo.height) // 2
    canvas.paste(logo, ((WIDTH - logo.width) // 2, top), logo)

    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(str(FONT), TITLE_FONT_SIZE)
    box = draw.textbbox((0, 0), COMPANY, font=font)
    draw.text(
        ((WIDTH - (box[2] - box[0])) // 2 - box[0], TITLE_BASELINE_Y),
        COMPANY,
        font=font,
        fill=TITLE_COLOR,
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT, optimize=True)
    print(f"Đã ghi {OUT.relative_to(ROOT)} ({WIDTH}×{HEIGHT})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
