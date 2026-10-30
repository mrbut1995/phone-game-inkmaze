#!/usr/bin/env python3
"""Quét GDScript tìm giá trị/kết nối ĐANG ĐẶT CỨNG trong code mà lẽ ra phải nằm ở .tscn / Theme / Resource.

Cách chạy:  python3 -I tools/audit_hardcode.py <project_root> [--json out.json] [--top 25] [--file <rel.gd>]

Nhóm phát hiện:
  P  PROP    gán thuộc tính layout/giao diện bằng GIÁ TRỊ TĨNH (số/Vector2/Color/enum/load("res://..")/chuỗi) lên node tĩnh
             -> chuyển vào .tscn (hoặc Theme/StyleBox .tres nếu là style/font/màu dùng chung)
  T  THEME   add_theme_*_override(...) với giá trị tĩnh, hoặc StyleBoxFlat dựng/duplicate trong code
             -> Theme variation (`theme_type_variation`) / StyleBox .tres
  C  CONST   const Vector2/Color/kích cỡ/font/đường dẫn texture đặt ở đầu script để áp lên node
             -> @export (đặt giá trị ở .tscn) hoặc Resource
  S  SIGNAL  `.connect(` vào node TĨNH (có trong scene) -> [connection] trong .tscn
  E  EMIT    signal gọi bằng CHUỖI: emit_signal("x") / connect("x", cb) -> `x.emit()` / `obj.x.connect(cb)` (có kiểm tra lúc parse)
  D  DYNAMIC (chỉ thống kê, KHÔNG phải lỗi) gán dựa trên biến runtime — hợp lệ, giữ ở code

Quy ước: dòng bị bỏ qua nếu có `# keep-code` (hoặc `## keep-code: <lý do>`) ở cuối/ngay dòng trên.
Đây là heuristic: luôn đọc ngữ cảnh trước khi chuyển.
"""
import re, os, sys, json, collections

root = sys.argv[1]
out = sys.argv[sys.argv.index('--json') + 1] if '--json' in sys.argv else None
top = int(sys.argv[sys.argv.index('--top') + 1]) if '--top' in sys.argv else 25
only = sys.argv[sys.argv.index('--file') + 1] if '--file' in sys.argv else None

PROPS = (r'custom_minimum_size|offset_left|offset_right|offset_top|offset_bottom|anchor_left|anchor_right|anchor_top|anchor_bottom|'
         r'size_flags_horizontal|size_flags_vertical|position|size|scale|pivot_offset|rotation|rotation_degrees|z_index|mouse_filter|'
         r'stretch_mode|expand_mode|ignore_texture_size|modulate|self_modulate|texture|texture_normal|texture_pressed|texture_hover|'
         r'texture_disabled|texture_focused|text|visible|theme_type_variation|autowrap_mode|horizontal_alignment|vertical_alignment|'
         r'layout_mode|grow_horizontal|grow_vertical|clip_contents|focus_mode|custom_minimum_size|min_value|max_value|step|'
         r'separation|columns|alignment')
assign_re = re.compile(r'^\s*([\w\.\[\]\(\)"%\$/]+?)\.(' + PROPS + r')(?:\.[xyr-w])?\s*(=|\+=|-=|\*=|/=)\s*(.+?)\s*(#.*)?$')
theme_re = re.compile(r'^\s*([\w\.\[\]\(\)"%\$/]+?)\.add_theme_(\w+)_override\(\s*(.*)\)\s*(#.*)?$')
anchors_re = re.compile(r'^\s*([\w\.\[\]\(\)"%\$/]+?)\.(set_anchors_preset|set_anchors_and_offsets_preset|set_deferred)\(')
const_re = re.compile(r'^\s*const\s+(\w+)\s*(?::\s*\w+)?\s*:?=\s*(.+?)\s*(#.*)?$')
connect_re = re.compile(r'^\s*([\w\.\[\]\(\)"%\$/]+?)\.(\w+)\.connect\(')
emit_str_re = re.compile(r'emit_signal\(\s*[&"]|\.connect\(\s*[&"]|\.disconnect\(\s*[&"]|is_connected\(\s*[&"]')
decl_static_re = re.compile(r'^\s*@(onready|export)[^\n]*?\bvar\s+(\w+)')
decl_dyn_re = re.compile(r'^\s*var\s+(\w+)[^=\n]*=\s*.*?(\.new\(|instantiate\(|duplicate\()')
ident_re = re.compile(r'[A-Za-z_]\w*')
ALLOWED_IDENT = re.compile(r'^(Vector2i?|Vector3|Color|Color8|Rect2|Control|TextureButton|TextureRect|Label|Button|Node|Node2D|Theme|HORIZONTAL|VERTICAL|'
                           r'PRESET_\w+|SIZE_\w+|MOUSE_FILTER_\w+|STRETCH_\w+|EXPAND_\w+|ALIGNMENT_\w+|HORIZONTAL_ALIGNMENT_\w+|VERTICAL_ALIGNMENT_\w+|'
                           r'GROW_\w+|FOCUS_\w+|AUTOWRAP_\w+|TextServer|BaseButton|StyleBoxFlat|StringName|NodePath|'
                           r'true|false|null|ZERO|ONE|INF|PI|TAU|load|preload|res|assets|png|svg|webp|tr|WHITE|BLACK|TRANSPARENT|'
                           r'[A-Z][A-Z0-9_]*)$')

def strip_strings(s):
    return re.sub(r'"[^"\n]*"|\'[^\'\n]*\'', '""', s)

def rhs_static(rhs):
    r = strip_strings(rhs)
    r = re.sub(r'\b\d+(\.\d+)?\b', '0', r)
    for ident in ident_re.findall(r):
        if not ALLOWED_IDENT.match(ident):
            return False
    return True

findings = []
dyn = collections.Counter()
for d, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith('.gd'): continue
        p = os.path.join(d, f); rel = os.path.relpath(p, root).replace(os.sep, '/')
        if only and rel != only: continue
        if '/tool/' in rel or '/tools/' in rel or rel.startswith('scripts/tool'): continue   # script editor/CLI
        lines = open(p, encoding='utf-8', errors='ignore').read().split('\n')
        static_vars = set(); dyn_vars = set(); in_func = None
        for ln in lines:
            m = decl_static_re.match(ln)
            if m: static_vars.add(m.group(2))
        for i, ln in enumerate(lines):
            if ln.lstrip().startswith('#'): continue
            prev = lines[i - 1] if i else ''
            if 'keep-code' in ln or 'keep-code' in prev: continue
            md = decl_dyn_re.match(ln)
            if md: dyn_vars.add(md.group(1))
            if re.match(r'^\s*func ', ln): dyn_vars = set()          # biến local reset theo hàm
            m = assign_re.match(ln)
            if m:
                recv, prop, op, rhs = m.group(1), m.group(2), m.group(3), m.group(4)
                if recv in dyn_vars or recv.split('.')[0] in dyn_vars:
                    dyn['D'] += 1; continue
                if rhs_static(rhs) and not recv.startswith('self') or (rhs_static(rhs) and recv == 'self'):
                    findings.append(dict(cat='P', file=rel, line=i + 1, text=ln.strip()))
                else:
                    dyn['D'] += 1
                continue
            m = theme_re.match(ln)
            if m:
                if m.group(1) in dyn_vars: dyn['D'] += 1; continue
                if rhs_static(m.group(3)): findings.append(dict(cat='T', file=rel, line=i + 1, text=ln.strip()))
                else: dyn['D'] += 1
                continue
            if 'StyleBoxFlat.new()' in ln or re.search(r'\.duplicate\(\)\s+as\s+StyleBox', ln) or 'set_corner_radius' in ln or 'set_border_width' in ln:
                findings.append(dict(cat='T', file=rel, line=i + 1, text=ln.strip())); continue
            if anchors_re.match(ln):
                findings.append(dict(cat='P', file=rel, line=i + 1, text=ln.strip())); continue
            m = const_re.match(ln)
            if m and re.search(r'Vector2|Color|"res://assets|"#?[0-9A-Fa-f]{6}"|FONT|SIZE|HEIGHT|WIDTH|MARGIN|OFFSET|RADIUS|PADDING|GAP', m.group(1) + ' ' + m.group(2)):
                findings.append(dict(cat='C', file=rel, line=i + 1, text=ln.strip())); continue
            if emit_str_re.search(ln):
                findings.append(dict(cat='E', file=rel, line=i + 1, text=ln.strip())); continue
            m = connect_re.match(ln)
            if m:
                recv = m.group(1)
                base = recv.split('.')[0].split('[')[0]
                static = (base in static_vars or recv.startswith('$') or recv.startswith('%') or recv.startswith('layout.')
                          or 'get_node' in recv or recv.startswith('self.') and recv[5:] in static_vars)
                if base in dyn_vars: static = False
                if static: findings.append(dict(cat='S', file=rel, line=i + 1, text=ln.strip()))
                else: dyn['D'] += 1
                continue
            if emit_str_re.search(ln):
                findings.append(dict(cat='E', file=rel, line=i + 1, text=ln.strip()))

names = {'P': 'PROP  (gán thuộc tính tĩnh -> .tscn)', 'T': 'THEME (override/StyleBox trong code -> Theme/.tres)',
         'C': 'CONST (hằng kích cỡ/màu/texture -> @export/Resource)', 'S': 'SIGNAL (.connect vào node tĩnh -> [connection])',
         'E': 'EMIT  (signal gọi bằng chuỗi -> cú pháp có kiểu)'}
cnt = collections.Counter(x['cat'] for x in findings)
print({k: cnt[k] for k in names}, f'| DYNAMIC hợp lệ (bỏ qua): {dyn["D"]}')
by_file = collections.defaultdict(collections.Counter)
for x in findings: by_file[x['file']][x['cat']] += 1
print(f'\n== TOP {top} file theo số vi phạm')
for fl, c in sorted(by_file.items(), key=lambda kv: -sum(kv[1].values()))[:top]:
    print(f'{sum(c.values()):4d}  {fl}   ' + ' '.join(f'{k}={c[k]}' for k in 'PTCSE' if c[k]))
if only:
    for x in sorted(findings, key=lambda x: x['line']): print(f"{x['cat']} {x['file']}:{x['line']}  {x['text'][:140]}")
if out: json.dump(findings, open(out, 'w'), ensure_ascii=False, indent=1)
