import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
root = Path("mockup/instruction")
for f in sorted(root.glob("*.svg")):
    for m in re.finditer(r"<text[^>]*>([^<]*)</text>", f.read_text(encoding="utf-8")):
        t = m.group(1)
        if "➔" in t or "↺" in t or "✕" in t:
            print(f.name, "|", t.strip()[:95])
