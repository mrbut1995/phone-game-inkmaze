import re
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
data = open("assets/images/instructions/guideline_image/image_guideline_instruction_dungeon_p1.svg", encoding="utf-8").read()
groups = re.findall(r'<g transform="translate\([^"]+\)">\s*(?:<path[^>]*>\s*)*</g>', data)
print("so nhom glyph:", len(groups))
for g in groups[:3]:
    print("----")
    print(g[:520])
