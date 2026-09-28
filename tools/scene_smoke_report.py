"""Gom lỗi trong log của `scripts/test_case/dev_scene_smoke.gd` theo TỪNG scene.

Cách dùng (chạy harness với stderr GỘP vào stdout để giữ đúng thứ tự dòng):

    & .venv\\Scripts\\python.exe -c "import subprocess; p=subprocess.run([r'<godot_console>','--headless','--path','.','--script','res://scripts/test_case/dev_scene_smoke.gd'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace'); open('tmp_scene_smoke.log','w',encoding='utf-8').write(p.stdout or '')"
    python tools/scene_smoke_report.py tmp_scene_smoke.log

Kết quả: danh sách scene + số dòng lỗi theo từng kiểu (SCRIPT ERROR / ERROR: / …).
"""

from __future__ import annotations

import collections
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

PATH = sys.argv[1] if len(sys.argv) > 1 else "tmp_scene_smoke.log"
PAT = re.compile(
    r"SCRIPT ERROR|^ERROR:|Parse Error|Failed to load|Nonexistent function|"
    r"Invalid access|Out of bounds|Trying to cast|Cannot call method|Condition .* is true"
)

log = open(PATH, encoding="utf-8", errors="replace").read().splitlines()
scene = "<trước-scene>"
errors: dict[str, list[tuple[int, str, str]]] = collections.defaultdict(list)
for i, line in enumerate(log):
    if line.startswith("@@@ SCENE ") and " SCENE RESULT " not in line:
        scene = line[len("@@@ SCENE "):].strip()
        continue
    if PAT.search(line):
        # Lấy dòng ngữ cảnh "at:" ngay sau nếu có
        ctx = ""
        if i + 1 < len(log) and log[i + 1].strip().startswith("at:"):
            ctx = log[i + 1].strip()
        errors[scene].append((i + 1, line.strip(), ctx))

print(f"Tổng {len(log)} dòng log · {len(errors)} scene có lỗi\n")
for scene_path, errs in errors.items():
    sig = collections.Counter(f"{e}  <<  {c}" for _, e, c in errs)
    print(f"=== {scene_path}  ({len(errs)} dòng lỗi · {len(sig)} kiểu)")
    for text, count in sig.most_common(10):
        print(f"    ×{count}  {text}")
    print()
