import re
import sys
from pathlib import Path

from fontTools.ttLib import TTFont

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
font = TTFont("assets/fonts/Be_Vietnam_Pro/BeVietnamPro-Black.ttf")
cmap = font.getBestCmap()
font2 = TTFont("assets/fonts/Noto_Sans_JP/static/NotoSansJP-Black.ttf")
cmap2 = font2.getBestCmap()

root = Path("mockup/instruction")
seen: dict = {}
for f in sorted(root.glob("*.svg")):
    for m in re.finditer(r"<text[^>]*>([^<]*)</text>", f.read_text(encoding="utf-8")):
        t = m.group(1)
        for ch in t:
            if ord(ch) in cmap or ch in " \t\n":
                continue
            ctx = t.strip()[:70]
            seen.setdefault(ch, [0, in2 := (ord(ch) in cmap2), ctx])
            seen[ch][0] += 1
for ch, (n, in2, ctx) in sorted(seen.items(), key=lambda kv: -kv[1][0]):
    print(f"U+{ord(ch):04X} {ch!r}  x{n}  noto={'co' if in2 else 'KHONG'}  vi du: {ctx}")
