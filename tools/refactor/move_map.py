#!/usr/bin/env python3
"""Di chuyển/đổi tên file Godot hàng loạt và cập nhật mọi tham chiếu `res://`.

Cách chạy:  python3 -I tools/move_map.py <project_root> <map.txt> [--dry-run]
map.txt: mỗi dòng `đường/dẫn/cũ -> đường/dẫn/mới` (tương đối project root, KHÔNG có `res://`).
  - Có thể là FILE hoặc THƯ MỤC (thư mục: di chuyển cả cây).
  - File .gd tự động kéo theo .gd.uid; file bất kỳ kéo theo .import nếu có.
  - Dùng `git mv` nếu project là git repo, ngược lại dùng os.rename.
Sau khi chạy: cập nhật mọi `res://cũ` -> `res://mới` trong .tscn .gd .tres .cfg .godot .csv .json .md.
Luôn chạy check_integrity.py ngay sau đó.
"""
import os, sys, re, subprocess

root = os.path.abspath(sys.argv[1]); mapf = sys.argv[2]; dry = '--dry-run' in sys.argv
is_git = os.path.isdir(os.path.join(root, '.git'))
pairs = []
for ln in open(mapf, encoding='utf-8'):
    ln = ln.strip()
    if not ln or ln.startswith('#'): continue
    a, b = [x.strip().removeprefix('res://') for x in ln.split('->')]
    pairs.append((a, b))

def move(a, b):
    sa, sb = os.path.join(root, a), os.path.join(root, b)
    if not os.path.exists(sa):
        print('SKIP (không tồn tại):', a); return False
    print(('DRY ' if dry else '') + f'MV {a} -> {b}')
    if dry: return True
    os.makedirs(os.path.dirname(sb), exist_ok=True)
    if is_git: subprocess.check_call(['git', 'mv', sa, sb], cwd=root)
    else: os.rename(sa, sb)
    return True

expanded = []   # (old_rel, new_rel) ở mức file, để thay chuỗi
for a, b in pairs:
    sa = os.path.join(root, a)
    if os.path.isdir(sa):
        for d, _, fs in os.walk(sa):
            for f in fs:
                old = os.path.relpath(os.path.join(d, f), root).replace(os.sep, '/')
                expanded.append((old, b.rstrip('/') + '/' + os.path.relpath(os.path.join(d, f), sa).replace(os.sep, '/')))
        move(a, b)
    else:
        if move(a, b):
            expanded.append((a, b))
            for ext in ('.uid', '.import'):
                if os.path.exists(sa + ext) or dry and os.path.exists(sa + ext):
                    move(a + ext, b + ext)
                    expanded.append((a + ext, b + ext))

repl = {'res://' + a: 'res://' + b for a, b in expanded}
if dry or not repl:
    sys.exit(0)
pat = re.compile('|'.join(re.escape(k) for k in sorted(repl, key=len, reverse=True)) + r'(?![\w/])')
n = 0
for d, dirs, fs in os.walk(root):
    dirs[:] = [x for x in dirs if x not in ('.git', '.godot')]
    for f in fs:
        if not f.endswith(('.tscn', '.gd', '.tres', '.cfg', '.godot', '.csv', '.json', '.md', '.import', '.remap')) and f != 'project.godot':
            continue
        p = os.path.join(d, f)
        try: t = open(p, encoding='utf-8').read()
        except Exception: continue
        t2 = pat.sub(lambda m: repl[m.group(0)], t)
        if t2 != t:
            open(p, 'w', encoding='utf-8').write(t2); n += 1
print(f'Đã cập nhật tham chiếu trong {n} file. Chạy check_integrity.py ngay.')
