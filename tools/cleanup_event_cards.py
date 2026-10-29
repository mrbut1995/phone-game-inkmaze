#!/usr/bin/env python3
"""DỌN phần THẺ EVENT cũ sau khi Main đã chuyển sang CỘT NÚT ICON event + Daily nằm ở dock.

Mặc định chỉ IN BÁO CÁO (dry-run, không đổi gì). Thêm --apply để thực sự sửa/di chuyển file.
Dùng git: commit trước khi chạy --apply để có thể hoàn tác (`git checkout .`).

    python3 tools/cleanup_event_cards.py <thư_mục_project_godot>            # xem trước
    python3 tools/cleanup_event_cards.py <thư_mục_project_godot> --apply    # làm thật

Việc script làm (theo thứ tự):
  A. Sửa `scenes/layout/portrait/main.tscn` + `landscape/main.tscn`:
       - xoá node EventHeader / EventCarousel (và cả cột `Left` của bố cục ngang);
       - xoá các export event_header / event_carousel + NodePath tương ứng; đánh lại `index` của node con;
       - BỐ CỤC DỌC: Body.offset_left 10 → 46 (dịch bản đồ + dock vào trong, không đè viền/lỗ gáy vở);
       - BỐ CỤC NGANG: tạo lại node `Stamp` (ẩn) trong Body để export stamp_* không mất; Body.offset_left 31 → 52.
  B. Sửa `scripts/scenes/layout/main_layout.gd` (bỏ 2 export event_header / event_carousel)
     và `scripts/scenes/main.gd` (bỏ đoạn code ẩn thẻ event cũ).
  C. Với MỌI file .tscn trong `nodes/` và `scenes/`: xoá [ext_resource] / [sub_resource] KHÔNG còn ai tham chiếu
     (lặp tới khi sạch) và dòng thuộc tính bị khai báo 2 lần (vd `clip_text = true` lặp).
  D. Tìm FILE MỒ CÔI của hệ thẻ event (event_header/carousel/dot(s)/card/card_compact, daily_card/daily_card_compact,
     art thẻ trong assets/**/events/): chỉ coi là mồ côi khi KHÔNG còn file nào ngoài nhóm đó tham chiếu
     (theo đường dẫn res://, uid, hoặc tên class_name). File còn được dùng ⇒ GIỮ và báo "ai đang dùng".
     Mồ côi được CHUYỂN vào `_removed_unused/` (giữ nguyên cấu trúc thư mục) — KHÔNG xoá hẳn.
Sau khi chạy: mở Godot, để nó import lại, chạy game, kiểm tra Main (dọc + ngang) + màn chi tiết Event.
"""
import os, re, sys, shutil

ROOT = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else os.getcwd()
APPLY = "--apply" in sys.argv
OUT_DIR = "_removed_unused"
overlay = {}          # đường dẫn tương đối -> nội dung mới (chưa ghi đĩa khi dry-run)
log = []


def rel(p): return os.path.relpath(p, ROOT).replace("\\", "/")
def read(r):
    if r in overlay: return overlay[r]
    with open(os.path.join(ROOT, r), encoding="utf-8") as f: return f.read()
def exists(r): return os.path.exists(os.path.join(ROOT, r))
def put(r, s, why):
    if exists(r) and read(r) == s: return
    overlay[r] = s; log.append(f"SỬA   {r}  — {why}")


# ============================================================================ phân tích .tscn
HDR = re.compile(r'^\[(\w+)(.*)\]\s*$')
def parse_tscn(text):
    """-> list block: {'kind', 'attrs'(str), 'lines'(list[str] gồm cả dòng header đầu)}"""
    blocks, cur = [], None
    for line in text.split("\n"):
        m = HDR.match(line)
        if m and (m.group(1) in ("gd_scene", "ext_resource", "sub_resource", "node", "connection", "resource", "editable")):
            cur = {"kind": m.group(1), "attrs": m.group(2), "lines": [line]}; blocks.append(cur)
        elif cur is None:
            cur = {"kind": "pre", "attrs": "", "lines": [line]}; blocks.append(cur)
        else:
            cur["lines"].append(line)
    return blocks
def dump(blocks): return "\n".join(l for b in blocks for l in b["lines"])
def attr(b, key):
    m = re.search(r'(?:^|\s)%s=("([^"]*)"|\S+)' % re.escape(key), b["attrs"])
    if not m: return None
    return m.group(2) if m.group(2) is not None else m.group(1)
def node_path(b):
    if b["kind"] != "node": return None
    name, parent = attr(b, "name"), attr(b, "parent")
    if parent is None: return ""                      # node gốc
    return name if parent == "." else f"{parent}/{name}"
def resolve(base_full, target):
    parts = [p for p in base_full.split("/") if p] if base_full else []
    for seg in target.split("/"):
        if seg in ("", "."): continue
        if seg == "..":
            if parts: parts.pop()
        else: parts.append(seg)
    return "/".join(parts)


def remove_nodes(text, match):
    """Xoá node (và con cháu) mà match(path) trả True. Trả (text_mới, tập_path_đã_xoá)."""
    blocks = parse_tscn(text)
    removed = set()
    for b in blocks:
        p = node_path(b)
        if p and match(p): removed.add(p)
    parents_hit = {attr(b, "parent") for b in blocks if b["kind"] == "node" and node_path(b) in removed}
    changed = True
    while changed:                                     # lan sang con cháu
        changed = False
        for b in blocks:
            p = node_path(b)
            if p and p not in removed and any(p.startswith(r + "/") for r in removed):
                removed.add(p); changed = True
    if not removed: return text, removed
    blocks = [b for b in blocks if not (b["kind"] == "node" and node_path(b) in removed)]
    # connection trỏ tới node đã xoá
    def conn_dead(b):
        if b["kind"] != "connection": return False
        f, t = attr(b, "from"), attr(b, "to")
        return any(x in removed or any((x or "").startswith(r + "/") for r in removed) for x in (f, t))
    blocks = [b for b in blocks if not conn_dead(b)]
    # export NodePath chết
    for b in blocks:
        if b["kind"] != "node": continue
        base = node_path(b)
        dead_props = []
        new_lines = [b["lines"][0]]
        for l in b["lines"][1:]:
            m = re.match(r'^(\w+) = NodePath\("(.*)"\)\s*$', l)
            if m:
                tgt = m.group(2)
                full = resolve(base, tgt) if tgt else ""
                if tgt == "" or full in removed or any(full.startswith(r + "/") for r in removed):
                    dead_props.append(m.group(1)); continue
            new_lines.append(l)
        if dead_props:
            def fix_np(mm):
                names = [n for n in re.findall(r'"([^"]+)"', mm.group(1)) if n not in dead_props]
                return ('node_paths=PackedStringArray(%s)' % ", ".join(f'"{n}"' for n in names)) if names else ""
            new_lines[0] = re.sub(r'\s*node_paths=PackedStringArray\(([^)]*)\)', lambda mm: (" " + fix_np(mm)) if fix_np(mm) else "", new_lines[0])
            b["attrs"] = HDR.match(new_lines[0]).group(2)
        b["lines"] = new_lines
    # đánh lại index của con cùng cha (chỉ khi mọi con của cha đó đều có index)
    groups = {}
    for b in blocks:
        if b["kind"] == "node" and attr(b, "parent") not in (None, "."):
            groups.setdefault(attr(b, "parent"), []).append(b)
    for parent, bs in groups.items():
        # chỉ đánh lại index ở nơi vừa xoá node con (parent của node đã xoá) — tránh đụng node con của scene kế thừa
        if parent not in parents_hit and parent not in {x.rsplit("/",1)[0] if "/" in x else "." for x in removed}: continue
        if not all(re.search(r'\bindex="\d+"', b["lines"][0]) for b in bs): continue
        for i, b in enumerate(bs):
            b["lines"][0] = re.sub(r'\bindex="\d+"', f'index="{i}"', b["lines"][0], count=1)
            b["attrs"] = HDR.match(b["lines"][0]).group(2)
    return dump(blocks), removed


def set_prop(text, node_full, key, value):
    """Đặt/ghi đè `key = value` của node có đường dẫn node_full (chèn ngay sau dòng header)."""
    blocks = parse_tscn(text)
    for b in blocks:
        if b["kind"] == "node" and node_path(b) == node_full:
            for i, l in enumerate(b["lines"][1:], 1):
                if re.match(r'^%s = ' % re.escape(key), l):
                    b["lines"][i] = f"{key} = {value}"; return dump(blocks)
            b["lines"].insert(1, f"{key} = {value}"); return dump(blocks)
    return text


def add_block_after(text, after_path_prefix, new_lines):
    """Chèn khối node mới ngay sau node `after_path_prefix` và toàn bộ con cháu của nó."""
    blocks = parse_tscn(text); idx = None
    for i, b in enumerate(blocks):
        p = node_path(b)
        if p is not None and (p == after_path_prefix or p.startswith(after_path_prefix + "/")): idx = i
    if idx is None: return text
    ins = parse_tscn("\n".join(new_lines))
    blocks[idx + 1:idx + 1] = ins
    return dump(blocks)


def set_root_nodepath(text, key, value_path):
    blocks = parse_tscn(text)
    root = next(b for b in blocks if b["kind"] == "node" and attr(b, "parent") is None)
    for i, l in enumerate(root["lines"][1:], 1):
        if re.match(r'^%s = NodePath' % re.escape(key), l):
            root["lines"][i] = f'{key} = NodePath("{value_path}")'; break
    else:
        root["lines"].insert(1, f'{key} = NodePath("{value_path}")')
    if f'"{key}"' not in root["lines"][0]:
        m = re.search(r'node_paths=PackedStringArray\(([^)]*)\)', root["lines"][0])
        if m:
            root["lines"][0] = root["lines"][0].replace(m.group(0), m.group(0)[:-1] + f', "{key}")')
    root["attrs"] = HDR.match(root["lines"][0]).group(2)
    return dump(blocks)


def drop_unused_resources(text):
    """Xoá ext_resource / sub_resource không ai dùng (lặp) + thuộc tính khai báo trùng trong 1 node."""
    blocks = parse_tscn(text)
    n_removed = []
    # thuộc tính trùng
    for b in blocks:
        if b["kind"] not in ("node", "sub_resource", "resource"): continue
        seen, out = set(), [b["lines"][0]]
        for l in b["lines"][1:]:
            m = re.match(r'^([\w/]+) = ', l)
            if m:
                if m.group(1) in seen:
                    n_removed.append(f"thuộc tính trùng `{m.group(1)}`"); continue
                seen.add(m.group(1))
            out.append(l)
        b["lines"] = out
    while True:
        dead = None
        for b in blocks:
            if b["kind"] not in ("ext_resource", "sub_resource"): continue
            rid = attr(b, "id")
            pat = ('ExtResource("%s")' if b["kind"] == "ext_resource" else 'SubResource("%s")') % rid
            used = any(pat in "\n".join(o["lines"]) for o in blocks if o is not b)
            if not used: dead = b; break
        if dead is None: break
        n_removed.append(f'{dead["kind"]} {attr(dead, "id")}'); blocks.remove(dead)
    return dump(blocks), n_removed


# ============================================================================ A. main.tscn dọc / ngang
def stage_a():
    for orient, left_old, left_new in (("portrait", "offset_left = 10.0", "offset_left = 46.0"),
                                        ("landscape", "offset_left = 31.0", "offset_left = 52.0")):
        r = f"scenes/layout/{orient}/main.tscn"
        if not exists(r): log.append(f"BỎ QUA {r} (không thấy file)"); continue
        s = read(r)
        s, gone = remove_nodes(s, lambda p: p.rsplit("/", 1)[-1] in ("EventHeader", "EventCarousel") or p.endswith("/Mid/Left"))
        if orient == "landscape" and any(p.endswith("/Left") for p in gone):
            # Left chứa cả con dấu phiên bản ⇒ tạo lại Stamp (ẩn) trong Body để export stamp_* còn hợp lệ
            s = add_block_after(s, "Scaler/Body/Dock", [
                '[node name="Stamp" type="Control" parent="Scaler/Body"]', "visible = false",
                "custom_minimum_size = Vector2(0, 14)", "layout_mode = 2", "mouse_filter = 2", "",
                '[node name="Label" type="Label" parent="Scaler/Body/Stamp"]', "layout_mode = 1", "anchors_preset = 15",
                "anchor_right = 1.0", "anchor_bottom = 1.0", "grow_horizontal = 2", "grow_vertical = 2",
                'theme_type_variation = &"SettingsVersion"', 'text = "STR_SETTINGS_VERSION"', "horizontal_alignment = 2", ""])
            s = set_root_nodepath(s, "stamp_panel", "Scaler/Body/Stamp")
            s = set_root_nodepath(s, "stamp_label", "Scaler/Body/Stamp/Label")
        body_hdr = '[node name="Body" type="VBoxContainer" parent="Scaler"' if orient == "landscape" else '[node name="Body" type="VBoxContainer" parent="."'
        i = s.find(body_hdr)
        if i >= 0:
            j = s.find("\n[node", i + 5); seg = s[i:j if j > 0 else len(s)]
            if left_old in seg: s = s[:i] + seg.replace(left_old, left_new, 1) + (s[j:] if j > 0 else "")
        s, res = drop_unused_resources(s)
        put(r, s, f"gỡ EventHeader/EventCarousel{' + cột Left' if orient=='landscape' else ''}, dịch Body vào trong; dọn resource: {len(res)} mục")


# ============================================================================ B. main_layout.gd / main.gd
def stage_b():
    r = "scripts/scenes/layout/main_layout.gd"
    if exists(r):
        s = read(r)
        s2 = re.sub(r'(?:^##[^\n]*\n)*@export var event_header: [^\n]*\n', '', s, flags=re.M)
        s2 = re.sub(r'(?:^##[^\n]*\n)*@export var event_carousel: [^\n]*\n', '', s2, flags=re.M)
        s2 = s2.replace("+ khối Sự kiện (header + carousel) + KHỐI BẢN ĐỒ", "+ KHỐI BẢN ĐỒ")
        put(r, s2, "bỏ export event_header / event_carousel")
    r = "scripts/scenes/main.gd"
    if exists(r):
        s = read(r)
        a = s.find("	# Khối thẻ event cũ (header + carousel)")
        b = s.find("	if _event_buttons == null or not is_instance_valid(_event_buttons)")
        if a >= 0 and b > a:
            keep = ("	var section := layout.level_section\n	if section == null:\n		return\n")
            s = s[:a] + keep + s[b:]
        put(r, s, "bỏ đoạn ẩn thẻ event cũ trong _setup_event_buttons")


# ============================================================================ C. dọn resource mọi .tscn
def stage_c():
    for base in ("nodes", "scenes"):
        for d, _, fs in os.walk(os.path.join(ROOT, base)):
            for f in fs:
                if not f.endswith(".tscn"): continue
                r = rel(os.path.join(d, f))
                if r in ("scenes/layout/portrait/main.tscn", "scenes/layout/landscape/main.tscn"): continue   # đã xử lý ở A
                s = read(r); s2, res = drop_unused_resources(s)
                if res: put(r, s2, "xoá " + ", ".join(res))


# ============================================================================ D. file mồ côi
CAND_NAMES = {"event_header", "event_carousel", "event_dot", "event_dots", "event_card", "event_card_compact",
              "daily_card", "daily_card_compact"}
TEXT_EXT = (".gd", ".tscn", ".tres", ".godot", ".cfg", ".csv")
def project_files():
    out = []
    for d, ds, fs in os.walk(ROOT):
        ds[:] = [x for x in ds if x not in (".git", ".godot", OUT_DIR, "node_modules", ".venv")]
        for f in fs: out.append(rel(os.path.join(d, f)))
    return out
def sidecars(r): return [x for x in (r + ".uid", r + ".import") if exists(x)]
def uid_of(r):
    for sc in sidecars(r):
        m = re.search(r'uid="(uid://[^"]+)"', open(os.path.join(ROOT, sc), encoding="utf-8", errors="ignore").read()) or \
            re.search(r'^(uid://\S+)', open(os.path.join(ROOT, sc), encoding="utf-8", errors="ignore").read(), re.M)
        if m: return m.group(1)
    if r.endswith((".tscn", ".tres")):
        m = re.match(r'\[gd_\w+[^\]]*uid="(uid://[^"]+)"', read(r));
        if m: return m.group(1)
    return None
def class_of(r):
    if r.endswith(".gd"):
        m = re.search(r'^class_name\s+(\w+)', read(r), re.M)
        return m.group(1) if m else None
def stage_d():
    files = project_files()
    cands = set()
    for r in files:
        stem = os.path.splitext(os.path.basename(r))[0]
        if r.endswith((".tscn", ".gd")) and stem in CAND_NAMES: cands.add(r)
        if re.match(r'assets/images(-png)?/events/', r) and not r.endswith((".import", ".uid")): cands.add(r)
    info = {c: {"uid": uid_of(c), "cls": class_of(c)} for c in cands}
    skip = set(cands) | {x for c in cands for x in sidecars(c)}
    texts = {r: read(r) for r in files if r.endswith(TEXT_EXT) and r not in skip or (r in overlay and r not in skip)}
    # gồm cả cả file candidate để biết ai tham chiếu ai
    cand_text = {c: read(c) for c in cands if c.endswith(TEXT_EXT)}
    removable = set(cands)
    why_keep = {}
    changed = True
    while changed:
        changed = False
        for c in sorted(removable):
            hits = []
            pats = [f"res://{c}"] + ([info[c]["uid"]] if info[c]["uid"] else [])
            for r, t in list(texts.items()) + [(k, v) for k, v in cand_text.items() if k in removable and k != c]:
                if r == c or r in sidecars(c): continue
                if r in removable and r in cand_text: continue         # nội bộ nhóm sẽ bị xoá cùng
                if any(p in t for p in pats): hits.append(r); continue
                if info[c]["cls"] and r.endswith((".gd", ".tres")) and re.search(r'\b%s\b' % info[c]["cls"], t): hits.append(r)
            if hits:
                removable.discard(c); why_keep[c] = hits[:4]; changed = True
    return sorted(removable), why_keep, sorted(cands)


# ============================================================================ chạy
stage_a(); stage_b(); stage_c()
if exists("project.godot"):
    orphans, kept, cands = stage_d()
else:
    orphans, kept, cands = [], {}, []
    print("!! Không thấy project.godot ở thư mục này ⇒ BỎ QUA bước D (file mồ côi) vì không thể biết hết ai tham chiếu. Hãy trỏ vào GỐC project.\n")
print(f"== PROJECT: {ROOT}   chế độ: {'LÀM THẬT (--apply)' if APPLY else 'XEM TRƯỚC (dry-run)'} ==\n")
for l in log: print(l)
print(f"\n--- File thuộc hệ thẻ event ({len(cands)}): MỒ CÔI ⇒ chuyển vào {OUT_DIR}/ : {len(orphans)} · còn được dùng ⇒ GIỮ : {len(kept)} ---")
for o in orphans: print("MỒ CÔI", o)
for k, v in kept.items(): print("GIỮ   ", k, " ← còn được dùng bởi:", ", ".join(v))
if APPLY:
    for r, s in overlay.items():
        with open(os.path.join(ROOT, r), "w", encoding="utf-8", newline="\n") as f: f.write(s)
    for o in orphans:
        for x in [o] + sidecars(o):
            dst = os.path.join(ROOT, OUT_DIR, x); os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.move(os.path.join(ROOT, x), dst)
    print(f"\nĐÃ ÁP DỤNG: sửa {len(overlay)} file, chuyển {len(orphans)} file mồ côi vào {OUT_DIR}/. Mở Godot để import lại.")
else:
    print("\n(dry-run: chưa đổi gì. Thêm --apply để làm thật.)")
