import sys
from fontTools.ttLib import TTFont

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
FONTS = [
    "assets/fonts/Be_Vietnam_Pro/BeVietnamPro-Black.ttf",
    "assets/fonts/Be_Vietnam_Pro/BeVietnamPro-ExtraBold.ttf",
    "assets/fonts/Be_Vietnam_Pro/BeVietnamPro-Bold.ttf",
    "assets/fonts/Be_Vietnam_Pro/BeVietnamPro-SemiBold.ttf",
]
CHARS = "•›·—×→➔✓①↺⏳⚠★<>+=%&:;?!'\"()/-"
for path in FONTS:
    font = TTFont(path)
    cmap = font.getBestCmap()
    missing = [c for c in CHARS if c not in " \t\n" and ord(c) not in cmap]
    print(path.split("/")[-1], "thieu:", "".join(missing) if missing else "khong")
