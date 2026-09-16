import difflib
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.path.insert(0, str(Path("tools/mockup").resolve()))
sys.path.insert(0, str(Path("tools/content").resolve()))
import instruction_mockup as im
from guide_text_en import EN

missing = [
    "Càng lên cao tường sẵn càng biến mất — hãy nối Anchor trước khi đặt bút vẽ đường!",
    "Luôn để mắt tới thẻ HUD Bom để biết mình đã cô lập hết bom trên bàn chưa!",
    "Khi mục tiêu còn xa: Ưu tiên gom các ô số to. Khi gần chạm mốc: Rẽ qua ô số nhỏ để chốt hạ!",
]
for m in missing:
    print("=== MISSING:", m)
    for k in difflib.get_close_matches(m, EN.keys(), n=3, cutoff=0.6):
        print("   gan nhat:", repr(k))
        for i, s in enumerate(difflib.ndiff(m, k)):
            if s[0] != " ":
                print("     ", s)
