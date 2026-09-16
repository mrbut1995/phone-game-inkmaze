import re
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
d = open("mockup/instruction/instruction_dungeon_p1.svg", encoding="utf-8").read()
for m in re.finditer(r"<text([^>]*)>([^<]{0,60})</text>", d):
    attrs, txt = m.group(1), m.group(2)
    size = re.search(r'font-size="(\d+)"', attrs)
    fill = re.search(r'fill="([^"]+)"', attrs)
    anchor = re.search(r'text-anchor="([^"]+)"', attrs)
    x = re.search(r'\sx="([\d.]+)"', attrs)
    y = re.search(r'\sy="([\d.]+)"', attrs)
    print(f"size={size.group(1) if size else '?':>3} x={x.group(1) if x else '?':>5} y={y.group(1) if y else '?':>5} "
          f"anchor={anchor.group(1) if anchor else '-':<6} fill={fill.group(1) if fill else '-':<9} | {txt.strip()[:58]}")
