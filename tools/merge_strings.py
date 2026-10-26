#!/usr/bin/env python3
"""Gộp một file csv khoá mới vào file csv dịch chính của project (dùng chung cho gói Main).

Chạy từ thư mục gốc project:  python3 tools/merge_strings.py <csv_nguồn> [csv_đích]
· Mặc định tìm `resources/localization/string_extra.csv` (nơi có STR_CHAPTER_FORMAT).
· An toàn chạy nhiều lần: khoá đã có thì BỎ QUA, không ghi đè bản dịch bạn đã sửa.
· Sau khi chạy, mở Godot để nó import lại csv (sinh .translation).
"""
import csv, io, os, sys

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(root, "resources", "localization", "string_level_new.csv")
dst = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, "resources", "localization", "string_extra.csv")

with open(src, encoding="utf-8", newline="") as f:
    new_rows = list(csv.reader(f))[1:]
with open(dst, encoding="utf-8", newline="") as f:
    text = f.read()
rows = list(csv.reader(io.StringIO(text)))
have = {r[0] for r in rows if r}
add = [r for r in new_rows if r and r[0] not in have]
if not add:
    print("Không có khoá mới — đã đủ.")
    sys.exit(0)
if not text.endswith("\n"):
    text += "\n"
buf = io.StringIO()
csv.writer(buf, lineterminator="\n").writerows(add)
with open(dst, "w", encoding="utf-8", newline="") as f:
    f.write(text + buf.getvalue())
print("Đã thêm %d khoá vào %s" % (len(add), dst))
for r in add:
    print("  +", r[0])
