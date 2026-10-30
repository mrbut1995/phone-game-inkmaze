#!/usr/bin/env python3
"""Kiểm tra toàn vẹn tham chiếu của project Godot 4 (không cần cài Godot).

Cách chạy:  python3 -I tools/check_integrity.py <project_root> [--skip res://assets/ ...]

Báo lỗi (exit code 1 nếu có lỗi loại E):
  E1  `res://` path trong .tscn/.gd/.tres/.cfg/project.godot trỏ tới file KHÔNG tồn tại
  E2  NodePath trong `node_paths`/[connection] trỏ tới node KHÔNG có trong scene (kể cả node thừa kế từ scene cha)
  E3  [connection] có from/to/method trỏ tới node/hàm không tồn tại (chỉ kiểm tra node)
Cảnh báo:
  W1  ext_resource khai báo nhưng không dùng
  W2  sub_resource khai báo nhưng không dùng
Dùng sau MỖI bước xóa/di chuyển file/node để chắc chắn không để lại tham chiếu mồ côi.
"""
import re, os, sys, collections

root = os.path.abspath(sys.argv[1])
skip = []
if '--skip' in sys.argv:
    i = sys.argv.index('--skip') + 1
    while i < len(sys.argv) and not sys.argv[i].startswith('--'):
        skip.append(sys.argv[i]); i += 1

TEXT_EXT = ('.tscn', '.gd', '.tres', '.cfg', '.godot', '.import', '.remap', '.csv')
files = {}
for d, dirs, fs in os.walk(root):
    dirs[:] = [x for x in dirs if x not in ('.git', '.godot', 'node_modules')]
    for f in fs:
        if f.endswith(TEXT_EXT) or f == 'project.godot':
            p = os.path.join(d, f)
            files[os.path.relpath(p, root).replace(os.sep, '/')] = open(p, encoding='utf-8', errors='ignore').read()

errors, warns = [], []
res_re = re.compile(r'res://[^\s"\'\)\]\},;]+')
for rel, t in files.items():
    if rel.endswith('.csv'): continue
    for ln_no, ln in enumerate(t.split('\n'), 1):
        for m in res_re.finditer(ln):
            pth = m.group(0).rstrip('.:')
            if any(c in pth for c in '%{*$'): continue          # đường dẫn động (format/glob)
            if any(pth.startswith(s) for s in skip): continue
            if pth.endswith('/'):                                # thư mục
                if not os.path.isdir(os.path.join(root, pth[6:])): errors.append(f'E1 {rel}:{ln_no} thư mục không tồn tại: {pth}')
                continue
            if not os.path.exists(os.path.join(root, pth[6:])):
                errors.append(f'E1 {rel}:{ln_no} file không tồn tại: {pth}')

class _NodeHeader:
    """Parse header `[node name=".." type=".." parent=".." instance=..]` với thứ tự thuộc tính BẤT KỲ."""
    def match(self, ln):
        if not ln.startswith('[node '): return None
        g = lambda k: (re.search(r'(?<![\w_])%s="([^"]*)"' % k, ln) or [None, None])[1]
        return _M((g('name'), g('type'), g('parent'), ln))
class _M:
    def __init__(self, t): self.t = t
    def groups(self): return self.t
node_re = _NodeHeader()
def scene_nodes(rel, seen=None):
    """Tập path node của scene, gộp cả node thừa kế từ scene cha. Trả (paths, instance_paths)."""
    seen = seen or set()
    if rel in seen or rel not in files: return set(), set()
    seen.add(rel)
    t = files[rel]
    ext = {m.group(2): m.group(1) for m in re.finditer(r'\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="([^"]+)"', t)}
    paths, inst = set(), set()
    for i, ln in enumerate(t.split('\n')):
        m = node_re.match(ln)
        if not m: continue
        name, typ, parent, rest = m.groups()
        p = '.' if parent is None else (name if parent == '.' else parent + '/' + name)
        paths.add(p)
        im = re.search(r'instance=ExtResource\("([^"]+)"\)', rest)
        if im and im.group(1) in ext:
            sub = ext[im.group(1)]
            if parent is None:   # root kế thừa scene cha
                bp, bi = scene_nodes(sub, seen)
                paths |= bp; inst |= bi
            else:
                inst.add(p)
    return paths, inst

def resolvable(path, paths, inst):
    if path in paths: return True
    return any(path.startswith(i + '/') for i in inst)   # nằm trong scene con được instance -> không kiểm được

for rel, t in files.items():
    if not rel.endswith('.tscn'): continue
    paths, inst = scene_nodes(rel)
    cur = '.'
    for ln_no, ln in enumerate(t.split('\n'), 1):
        m = node_re.match(ln)
        if m:
            name, typ, parent, rest = m.groups()
            cur = '.' if parent is None else (name if parent == '.' else parent + '/' + name)
            continue
        if ln.startswith('[connection'):
            for key in ('from', 'to'):
                mm = re.search(r'%s="([^"]+)"' % key, ln)
                if mm and mm.group(1) != '.' and not resolvable(mm.group(1), paths, inst):
                    errors.append(f'E3 {rel}:{ln_no} connection.{key} không tồn tại: {mm.group(1)}')
            continue
        if ln.startswith('[') or ' = ' not in ln or ln.startswith('tracks/'):
            continue
        # NodePath export: tương đối so với CHÍNH node đang chứa property (không phải root scene)
        for mm in re.finditer(r'NodePath\("([^"]*)"\)', ln):
            tgt = mm.group(1)
            if tgt in ('', '.') or tgt.startswith('/') or ':' in tgt:
                continue
            parts = ([] if cur == '.' else cur.split('/'))
            for seg in tgt.split('/'):
                if seg == '..':
                    if parts: parts.pop()
                elif seg != '.':
                    parts.append(seg)
            full = '/'.join(parts) or '.'
            if not resolvable(full, paths, inst):
                errors.append(f'E2 {rel}:{ln_no} NodePath không tồn tại: {tgt} (từ node {cur})')
    # W1/W2
    for m in re.finditer(r'\[ext_resource[^\]]*id="([^"]+)"', t):
        if len(re.findall(r'ExtResource\("%s"\)' % re.escape(m.group(1)), t)) == 0:
            warns.append(f'W1 {rel}: ext_resource không dùng: id={m.group(1)}')
    for m in re.finditer(r'\[sub_resource[^\]]*id="([^"]+)"', t):
        if len(re.findall(r'SubResource\("%s"\)' % re.escape(m.group(1)), t)) == 0:
            warns.append(f'W2 {rel}: sub_resource không dùng: id={m.group(1)}')

for w in warns: print(w)
for e in errors: print(e)
print(f'\n{len(errors)} lỗi, {len(warns)} cảnh báo')
sys.exit(1 if errors else 0)
