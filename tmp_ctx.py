import re
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
d = open("mockup/instruction/instruction_dungeon_p1.svg", encoding="utf-8").read()
i = d.find("DUNGEON MODE")
print(d[max(0, i - 1400):i + 260])
