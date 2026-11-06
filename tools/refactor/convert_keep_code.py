#!/usr/bin/env python3
"""Đổi thẻ cũ `# keep-code[: lý do]` thành thẻ của template `# EXCEPTION(<Rn>-keep): lý do` CHỈ ở dòng mà lint_rules.py báo lỗi.

Cách chạy (KHÔNG dùng -I vì lint_rules cần import _common):
  python tools/lint_rules.py --max 5000 --all > /tmp/lint.txt
  python3 -I tools/refactor/convert_keep_code.py <project_root> /tmp/lint.txt [--dry-run]

Mỗi dòng finding có dạng `ERROR|WARN <RULE> <path>:<line>: ...`. Nếu dòng (hoặc dòng ngay trên) chứa `keep-code`, thay bằng
`# EXCEPTION(<RULE>-keep): <lý do cũ>`. Dòng không có keep-code giữ nguyên (phải sửa code thật). Không bao giờ đổi GODOT3/STRUCT.
Lưu ý: lỗi GODOT3 `connect("sig", cb)` dạng chuỗi KHÔNG được miễn bằng thẻ: phải sửa thành `obj.sig.connect(cb)`.
"""
import os, re, sys

root = os.path.abspath(sys.argv[1]); dry = "--dry-run" in sys.argv
rx = re.compile(r"^(?:ERROR|WARN)\s+(R\d+b?|STYLE)\s+(\S+?):(\d+):")
tag = re.compile(r"#\s*keep-code(?::\s*(.*))?$")
hits = {}
for ln in open(sys.argv[2], encoding="utf-8"):
    m = rx.match(ln)
    if m:
        hits.setdefault(m.group(2), []).append((int(m.group(3)), m.group(1)))
n = 0
for path, items in hits.items():
    fp = os.path.join(root, path)
    if not os.path.exists(fp):
        continue
    lines = open(fp, encoding="utf-8").read().split("\n")
    for ln_no, rule in sorted(set(items)):
        if rule == "STYLE":
            continue
        for idx in (ln_no - 1, ln_no - 2):
            if 0 <= idx < len(lines) and "keep-code" in lines[idx] and "EXCEPTION(" not in lines[idx]:
                m = tag.search(lines[idx])
                if m:
                    reason = (m.group(1) or "giữ nguyên trong code").strip()
                    lines[idx] = lines[idx][: m.start()] + f"# EXCEPTION({rule}-keep): {reason}"
                    n += 1
                    break
    if not dry:
        open(fp, "w", encoding="utf-8", newline="").write("\n".join(lines))
print(("DRY " if dry else "") + f"đã đổi {n} thẻ keep-code -> EXCEPTION")
