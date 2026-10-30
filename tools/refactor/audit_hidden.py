#!/usr/bin/env python3
"""Quét node bị ẩn (`visible = false`) trong mọi .tscn của project Godot 4 và phân loại.

Cách chạy:  python3 -I tools/audit_hidden.py <project_root> [--json out.json]

Phân loại (cột CAT):
  DEAD          ẩn + không script/signal/@export-bind/animation-track/ref code theo tên  -> XÓA
  BASE-DEAD     là override trong scene KẾ THỪA, và TẤT CẢ scene con cùng base đều ẩn nó  -> XÓA Ở BASE
                (rồi xóa các stanza override ở scene con)
  SPLIT-BASE    override ẩn ở một số scene con nhưng scene khác lại hiện -> tách base
                (đưa node xuống đúng scene cần, hoặc tạo base trung gian)
  REVIEW        ẩn nhưng tên node có xuất hiện trong code (có thể trùng tên ngẫu nhiên) -> đọc code
  LIVE          ẩn trong .tscn nhưng được code/animation/signal/@export dùng -> GIỮ (bật lúc runtime)

Đây là phân tích TĨNH theo tên — luôn kiểm tra tay các mục REVIEW/LIVE trước khi xóa.
"""
import re, sys, os, json, collections

root = sys.argv[1]
out = sys.argv[sys.argv.index('--json') + 1] if '--json' in sys.argv else None

gd_text = {}
tscn = {}
for d, _, fs in os.walk(root):
    for f in fs:
        p = os.path.join(d, f)
        rel = os.path.relpath(p, root).replace(os.sep, '/')
        if f.endswith('.gd'):
            gd_text[rel] = open(p, encoding='utf-8', errors='ignore').read()
        elif f.endswith('.tscn'):
            tscn[rel] = open(p, encoding='utf-8', errors='ignore').read().split('\n')
all_gd = "\n".join(gd_text.values())

def node_header(ln):
    """Parse header `[node ...]` với thứ tự thuộc tính bất kỳ -> (name, type, parent) hoặc None."""
    if not ln.startswith('[node '): return None
    g = lambda k: (re.search(r'(?<![\w_])%s="([^"]*)"' % k, ln) or [None, None])[1]
    return g('name'), g('type'), g('parent')

def parse(lines):
    nodes, conns, cur = [], [], None
    for i, ln in enumerate(lines):
        m = node_header(ln)
        if m:
            cur = dict(name=m[0], type=m[1], parent=m[2], header=ln, line=i + 1, props={})
            nodes.append(cur); continue
        if ln.startswith('[connection'):
            conns.append(ln); cur = None; continue
        if ln.startswith('['):
            cur = None; continue
        if cur is not None and ' = ' in ln:
            k, v = ln.split(' = ', 1); cur['props'][k.strip()] = v.strip()
    return nodes, conns

def npath(n):
    if n['parent'] is None: return '.'
    return n['name'] if n['parent'] == '.' else n['parent'] + '/' + n['name']

parsed = {rel: parse(lines) for rel, lines in tscn.items()}

def base_of(rel):
    """Scene gốc mà scene này kế thừa (root node có instance=ExtResource)."""
    nodes, _ = parsed[rel]
    if not nodes: return None
    m = re.search(r'instance=ExtResource\("([^"]+)"\)', nodes[0]['header'])
    if not m: return None
    t = "\n".join(tscn[rel])
    r = re.search(r'\[ext_resource[^\]]*path="res://([^"]+)"[^\]]*id="%s"' % re.escape(m.group(1)), t)
    return r.group(1) if r else None

heirs = collections.defaultdict(list)
for rel in tscn:
    b = base_of(rel)
    if b: heirs[b].append(rel)

def hidden_paths(rel):
    nodes, _ = parsed[rel]
    return {npath(n) for n in nodes if n['props'].get('visible') == 'false'}

res = []
for rel, (nodes, conns) in parsed.items():
    text = "\n".join(tscn[rel])
    base = base_of(rel)
    for n in nodes:
        if n['props'].get('visible') != 'false': continue
        pth, name = npath(n), n['name']
        is_override = (n['type'] is None and 'instance=' not in n['header'] and n['parent'] is not None)
        has_script = 'script' in n['props']
        sig = [c for c in conns if re.search(r'(from|to)="%s"' % re.escape(pth), c)]
        kids = [k for k in nodes if k['parent'] and (k['parent'] == pth or k['parent'].startswith(pth + '/'))]
        kid_script = any('script' in k['props'] for k in kids)
        bound = len(re.findall(r'NodePath\("%s"\)' % re.escape(pth), text))
        anim = len(re.findall(r'NodePath\("%s(?::|/)' % re.escape(pth), text))
        refs = len(re.findall(r'(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])' % re.escape(name), all_gd))
        if n.get('props', {}).get('unique_name_in_owner'):
            refs += len(re.findall(r'%%%s(?![A-Za-z0-9_])' % re.escape(name), all_gd))
        extra = ''
        if is_override and base:
            sibs = heirs.get(base, [])
            hid = [s for s in sibs if pth in hidden_paths(s)]
            if len(hid) == len(sibs):
                cat = 'BASE-DEAD' if (not bound and not anim and not sig) else 'LIVE'
            else:
                cat = 'SPLIT-BASE'
            extra = f'hidden in {len(hid)}/{len(sibs)} scenes inheriting {base}'
        elif has_script or sig or bound or anim:
            cat = 'LIVE'
        elif kid_script:
            cat = 'REVIEW'
        elif refs == 0:
            cat = 'DEAD'
        else:
            cat = 'REVIEW'
        res.append(dict(scene=rel, line=n['line'], path=pth, type=n['type'] or ('instance' if 'instance=' in n['header'] else 'override'),
                        category=cat, name_refs_in_code=refs, exported_bind=bound, anim_tracks=anim,
                        signals=len(sig), kids=len(kids), note=extra))

order = ['DEAD', 'BASE-DEAD', 'SPLIT-BASE', 'REVIEW', 'LIVE']
cnt = collections.Counter(r['category'] for r in res)
print({k: cnt[k] for k in order}, 'total', len(res))
for cat in order:
    rows = sorted((r for r in res if r['category'] == cat), key=lambda r: (r['scene'], r['line']))
    if not rows: continue
    print(f'\n== {cat} ({len(rows)})')
    for r in rows:
        print(f"{r['scene']}:{r['line']}  {r['path']} [{r['type']}] refs={r['name_refs_in_code']} bind={r['exported_bind']} "
              f"anim={r['anim_tracks']} sig={r['signals']} kids={r['kids']} {r['note']}")
if out:
    json.dump(res, open(out, 'w'), ensure_ascii=False, indent=1)
