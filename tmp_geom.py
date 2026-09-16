import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.path.insert(0, str(Path("tools/mockup").resolve()))
import instruction_mockup as im
import xml.etree.ElementTree as ET

w = im.Walker()
w.walk(ET.parse("mockup/instruction/instruction_dungeon_p1.svg").getroot())
print("== rects quanh washi/close/paper/dots ==")
for r in w.rects:
    ax, ay, aw, ah = r["x"], r["y"], r["w"], r["h"]
    if (abs(aw - 220) < 1 and abs(ah - 46) < 1) or (abs(aw - 56) < 1 and abs(ah - 56) < 1) \
       or (abs(aw - 920) < 1 and abs(ah - 1480) < 1) or (abs(aw - 38) < 1 and abs(ah - 18) < 1):
        print(f"abs=({ax:.0f},{ay:.0f}) {aw:.0f}x{ah:.0f} rx={r['rx']} fill={r['fill']} stroke={r['stroke']} op={r['opacity']:.2f} -> paper-local ({ax-80:.0f},{ay-200:.0f})")
print("== circles nho (dots, close?) ==")
for c in w.circles:
    if c["r"] < 30:
        print(f"abs=({c['x']:.0f},{c['y']:.0f}) r={c['r']:.0f} fill={c['fill']} -> local ({c['x']-80:.0f},{c['y']-200:.0f})")
