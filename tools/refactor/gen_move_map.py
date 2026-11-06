#!/usr/bin/env python3
"""Sinh các file move-map (cũ -> mới) để đưa project InkMaze về cấu trúc GodotTemplate.

Cách chạy:  python3 -I tools/refactor/gen_move_map.py <project_root> [--out docs/refactor/maps] [--overrides docs/refactor/overrides.txt]

KHÔNG di chuyển file nào. Chỉ ghi ra các file map (định dạng của tools/refactor/move_map.py: `cũ -> mới`) + báo cáo.
Sau đó áp dụng từng map bằng:  python3 -I tools/refactor/move_map.py <root> <map> [--dry-run]
rồi:  python3 -I tools/refactor/rewrite_dir_refs.py <root> <dir_refs.txt>   (các hằng số đường dẫn THƯ MỤC)
rồi:  python3 -I tools/refactor/check_integrity.py <root>                   (số lỗi E1 KHÔNG được tăng so với baseline)

Các file sinh ra (theo thứ tự áp dụng):
  P2a_data_assets.map    resources/ -> data/, shaders/ -> assets/shaders/, sfx/soundtrack -> assets/audio/, file có dấu cách
  P2b_scenes.map         .tscn -> scenes/{screens,objects,components,base,autoload}/
  P2c_scripts.map        .gd   -> scripts/<mirror của scene> | models | systems | utils | editor | autoload | constants...
                         (đồng thời đổi tên PascalCase nếu script có class_name)
  P2d_tests.map          scripts/test_case -> tests/legacy/legacy_*.gd | debug/probes
  dir_refs.txt           thay tiền tố THƯ MỤC trong chuỗi (vd "res://resources/levels/" -> "res://data/levels/")
  report.md              thống kê + CÁC TRƯỜNG HỢP CẦN NGƯỜI QUYẾT ĐỊNH (xung đột tên, script dùng chung...)

Override: file `overrides.txt`, mỗi dòng `đường/dẫn/cũ -> đường/dẫn/mới` (đích cuối cùng của file đó). Ưu tiên cao nhất.
Stdlib only.
"""
from __future__ import annotations

import collections
import os
import re
import sys

ROOT = os.path.abspath(sys.argv[1])
OUT = sys.argv[sys.argv.index("--out") + 1] if "--out" in sys.argv else os.path.join(ROOT, "docs/refactor/maps")
OVR = sys.argv[sys.argv.index("--overrides") + 1] if "--overrides" in sys.argv else os.path.join(ROOT, "docs/refactor/overrides.txt")

SKIP_DIRS = {".git", ".godot", "__pycache__", "node_modules", "dist", "build"}
ORIENTS = ("portrait", "landscape")


def rd(p: str) -> str:
    with open(os.path.join(ROOT, p), encoding="utf-8", errors="replace") as f:
        return f.read()


def walk(sub: str, exts: tuple[str, ...]) -> list[str]:
    out = []
    base = os.path.join(ROOT, sub)
    for d, dirs, fs in os.walk(base):
        dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
        for f in fs:
            if f.endswith(exts):
                out.append(os.path.relpath(os.path.join(d, f), ROOT).replace(os.sep, "/"))
    return sorted(out)


def pascal(s: str) -> str:
    return "".join(w[:1].upper() + w[1:] for w in re.split(r"[_\s]+", s) if w)


def parts(p: str) -> list[str]:
    return p.split("/")


# --------------------------------------------------------------------------- scan scenes
SCENES = [p for p in walk("scenes", (".tscn",)) + walk("nodes", (".tscn",))]
INFO: dict[str, dict] = {}
for p in SCENES:
    t = rd(p)
    ext = {}
    for m in re.finditer(r"\[ext_resource[^\]]*\]", t):
        s = m.group(0)
        pm, im, tm = re.search(r'path="res://([^"]+)"', s), re.search(r'\bid="([^"]+)"', s), re.search(r'type="(\w+)"', s)
        if pm and im:
            ext[im.group(1)] = (tm.group(1) if tm else "", pm.group(1))
    inst = {ext[i][1] for i in re.findall(r'instance=ExtResource\("([^"]+)"\)', t) if i in ext and ext[i][0] == "PackedScene"}
    # script gắn vào node: (script path, is_root)
    scripts, root_script = [], None
    node_blocks = re.split(r"(?m)^(?=\[node )", t)
    for blk in node_blocks:
        if not blk.startswith("[node "):
            continue
        sm = re.search(r'script = ExtResource\("([^"]+)"\)', blk)
        if sm and sm.group(1) in ext and ext[sm.group(1)][0] == "Script":
            sp = ext[sm.group(1)][1]
            scripts.append(sp)
            if " parent=" not in blk.split("\n", 1)[0] and root_script is None:
                root_script = sp
    rt = re.search(r'\[node name="[^"]*"(?: type="(\w+)")?', t)
    INFO[p] = dict(inst=inst, scripts=scripts, root_script=root_script, root_type=rt.group(1) if rt else None)

INSTANCED_BY: dict[str, set[str]] = collections.defaultdict(set)
for p, d in INFO.items():
    for i in d["inst"]:
        INSTANCED_BY[i].add(p)

# --------------------------------------------------------------------------- scene mapping
def is_base(p: str) -> bool:
    n = os.path.basename(p)[:-5]
    return n in ("base", "base_layout") or n.startswith("base_") or n.endswith("_base")


def domain_of(p: str) -> str:
    ps = parts(p)  # nodes/<domain>/...
    return ps[1] if ps[0] == "nodes" and len(ps) > 2 else ""


def pair_key(p: str):
    """Trả (dir_gốc, tên, orientation) nếu scene nằm trong thư mục portrait/landscape."""
    ps = parts(p)
    for i, seg in enumerate(ps[:-1]):
        if seg in ORIENTS:
            return "/".join(ps[:i] + ps[i + 1:-1]), ps[-1][:-5], seg
    return None


SCENE_MAP: dict[str, str] = {}
KIND: dict[str, str] = {}  # old -> screens|objects|components|base|autoload
for p in SCENES:
    ps, name = parts(p), os.path.basename(p)
    pk = pair_key(p)
    if p == "scenes/base.tscn":
        SCENE_MAP[p], KIND[p] = "scenes/base/base_scene.tscn", "base"
    elif p == "scenes/layout/base_layout.tscn":
        SCENE_MAP[p], KIND[p] = "scenes/base/base_layout.tscn", "base"
    elif is_base(p) and ps[0] == "nodes":
        SCENE_MAP[p], KIND[p] = f"scenes/base/{name if name.startswith('base') else 'base_' + name.replace('_base', '')}", "base"
        if ps[1] == "popups":
            SCENE_MAP[p] = "scenes/base/base_popup.tscn"
        elif ps[1] == "hud":
            SCENE_MAP[p] = "scenes/base/base_hud.tscn"
        elif ps[1] == "tutorials":
            SCENE_MAP[p] = "scenes/base/base_tutorial.tscn"
    elif INFO[p]["root_type"] == "CanvasLayer" and ps[0] == "scenes" and len(ps) == 2:
        SCENE_MAP[p], KIND[p] = f"scenes/autoload/{name}", "autoload"
    elif ps[0] == "scenes" and len(ps) == 2:
        SCENE_MAP[p], KIND[p] = f"scenes/screens/{name}", "screens"
    elif ps[:2] == ["scenes", "layout"] and pk:
        SCENE_MAP[p], KIND[p] = f"scenes/objects/layouts/{pk[1]}/{pk[2]}.tscn", "objects"
    elif ps[:2] == ["nodes", "hud"] and pk:
        sub = pk[0].replace("nodes/hud", "").strip("/")
        SCENE_MAP[p], KIND[p] = f"scenes/objects/ui/hud/{(sub + '/') if sub else ''}{pk[1]}/{pk[2]}.tscn", "objects"
    elif ps[:2] == ["nodes", "hud"]:
        SCENE_MAP[p], KIND[p] = f"scenes/objects/ui/hud/{name}", "objects"
    elif ps[:2] == ["nodes", "popups"]:
        SCENE_MAP[p], KIND[p] = f"scenes/objects/ui/popups/{name}", "objects"
    elif ps[0] == "nodes":
        dom = "vfx" if ps[1] == "sfx" else ps[1]
        SCENE_MAP[p], KIND[p] = "scenes/objects/" + "/".join([dom] + ps[2:]), "objects"
    else:
        SCENE_MAP[p], KIND[p] = "scenes/objects/" + "/".join(ps[1:]), "objects"

# Hạ cấp objects -> components: chỉ được instance bởi scene CÙNG domain nodes/<d>, và chỉ instance components/base.
changed = True
while changed:
    changed = False
    for p in SCENES:
        if KIND[p] != "objects" or not p.startswith("nodes/") or p.startswith("nodes/hud") or p.startswith("nodes/popups"):
            continue
        users = INSTANCED_BY.get(p, set())
        if not users:
            continue
        dom = domain_of(p)
        if any(not u.startswith(f"nodes/{dom}/") for u in users):
            continue
        if any(KIND.get(i) == "objects" for i in INFO[p]["inst"]):
            continue
        KIND[p] = "components"
        SCENE_MAP[p] = SCENE_MAP[p].replace("scenes/objects/", "scenes/components/", 1)
        changed = True

# --------------------------------------------------------------------------- overrides
OVERRIDES: dict[str, str] = {}
if os.path.exists(OVR):
    for ln in open(OVR, encoding="utf-8"):
        ln = ln.split("#")[0].strip()
        if "->" in ln:
            a, b = [x.strip().removeprefix("res://") for x in ln.split("->")]
            OVERRIDES[a] = b
for a, b in OVERRIDES.items():
    if a in SCENE_MAP:
        SCENE_MAP[a] = b

# --------------------------------------------------------------------------- scripts
GD = walk("scripts", (".gd",))
SINFO: dict[str, dict] = {}
for p in GD:
    t = rd(p)
    cn = re.search(r"^class_name\s+(\w+)", t, re.M)
    ex = re.search(r"^extends\s+([\w\"/.:]+)", t, re.M)
    SINFO[p] = dict(
        cn=cn.group(1) if cn else None,
        ex=ex.group(1).strip('"') if ex else None,
        nonstatic=bool(re.search(r"^(func|var)\b", t, re.M)),
        tool=bool(re.search(r"^@tool", t, re.M)),
    )

ATT: dict[str, list[str]] = collections.defaultdict(list)    # script -> scenes dùng
ROOT_OF: dict[str, list[str]] = collections.defaultdict(list)  # script -> scenes mà nó là script gốc
for sc, d in INFO.items():
    for sp in set(d["scripts"]):
        ATT[sp].append(sc)
    if d["root_script"]:
        ROOT_OF[d["root_script"]].append(sc)


def newname(sp: str) -> str:
    """Tên file mới: class_name -> PascalCase; không có class_name giữ snake_case."""
    cn = SINFO[sp]["cn"]
    return (cn if cn else os.path.basename(sp)[:-3]) + ".gd"


def mirror_dir(scene_new: str) -> str:
    d = os.path.dirname(scene_new)  # scenes/...
    return "scripts/" + d[len("scenes/"):]


def common_dir(dirs: list[str]) -> str:
    sp = [d.split("/") for d in dirs]
    out = []
    for seg in zip(*sp):
        if len(set(seg)) == 1:
            out.append(seg[0])
        else:
            break
    return "/".join(out)


DECIDE: list[str] = []
SCRIPT_MAP: dict[str, str] = {}
CLASS_TO_SCRIPT = {si["cn"]: sp for sp, si in SINFO.items() if si["cn"]}
CORE_MODEL_HINT = re.compile(r"(_store|_data|_state|_context|_types|_inventory|_profile)$")
for sp in GD:
    ps, name, si = parts(sp), newname(sp), SINFO[sp]
    base = os.path.basename(sp)[:-3]
    if sp in OVERRIDES:
        SCRIPT_MAP[sp] = OVERRIDES[sp]
    elif ps[:2] == ["scripts", "autoload"]:
        SCRIPT_MAP[sp] = f"scripts/autoload/{pascal(base)}.gd"
    elif ps[:2] == ["scripts", "test_case"]:
        continue  # xử lý ở P2d
    elif sp in ROOT_OF:
        dirs = sorted({os.path.dirname(SCENE_MAP[s]) for s in ROOT_OF[sp]})
        if len(dirs) == 1:
            SCRIPT_MAP[sp] = f"scripts/{dirs[0][len('scenes/'):]}/{name}"
        else:
            SCRIPT_MAP[sp] = f"scripts/{dirs[0][len('scenes/'):]}/{name}"
            DECIDE.append(f"script gốc dùng chung nhiều thư mục scene (chọn thư mục của scene đầu tiên): {sp} -> {SCRIPT_MAP[sp]} (scenes: {', '.join(sorted(ROOT_OF[sp])[:3])})")
    elif sp in ATT:  # script của node con trong scene
        dirs = sorted({os.path.dirname(SCENE_MAP[s]) for s in ATT[sp]})
        cd = dirs[0] if len(dirs) == 1 else common_dir(dirs)
        if si["tool"] and ps[1] == "tools":
            SCRIPT_MAP[sp] = f"scripts/editor/{name}"
        elif cd.count("/") >= 2:
            SCRIPT_MAP[sp] = f"{mirror_dir(cd + '/x.tscn')}/{name}"
        else:
            SCRIPT_MAP[sp] = f"scripts/components/shared/{name}"
    elif ps[:3] == ["scripts", "tools", "nine_patch"] or (ps[:2] == ["scripts", "tools"] and (si["tool"] or si["ex"] in ("Control", "Node2D", "ConfirmationDialog", "ProgressBar"))):
        SCRIPT_MAP[sp] = "scripts/editor/" + "/".join(ps[2:-1] + [name]).lstrip("/")
    elif ps[:2] == ["scripts", "tools"]:
        SCRIPT_MAP[sp] = f"tools/godot/{base}.gd"  # EditorScript / SceneTree tool chạy tay
    elif ps[:2] == ["scripts", "data"]:
        SCRIPT_MAP[sp] = f"scripts/models/definitions/{name}"
    elif ps[:2] == ["scripts", "modes"]:
        SCRIPT_MAP[sp] = f"scripts/systems/modes/{name}"
    elif ps[:2] == ["scripts", "services"]:
        SCRIPT_MAP[sp] = f"scripts/systems/services/{name}"
    elif ps[:2] == ["scripts", "utils"]:
        SCRIPT_MAP[sp] = f"scripts/utils/{name}" if not si["nonstatic"] else f"scripts/systems/{name}"
        if si["nonstatic"]:
            DECIDE.append(f"utils không thuần static: {sp} -> {SCRIPT_MAP[sp]}")
    elif ps[:2] == ["scripts", "core"]:
        sub = "/".join(ps[2:-1])  # controllers/ ...
        kind = "models" if CORE_MODEL_HINT.search(base) else "systems"
        SCRIPT_MAP[sp] = f"scripts/{kind}/{(sub + '/') if sub and sub != 'controllers' else ''}{name}"
    elif re.match(r"^(base_|.*_base$)", base):
        SCRIPT_MAP[sp] = f"scripts/base/{name}"
    elif si["ex"] not in (None, "RefCounted", "Resource") and si["ex"] not in CLASS_TO_SCRIPT:
        # kế thừa node dựng sẵn của Godot nhưng không gắn scene nào (tạo runtime / set_script): để chung
        SCRIPT_MAP[sp] = f"scripts/components/shared/{name}"
        DECIDE.append(f"node script không gắn scene (tạo lúc chạy?): {sp} -> {SCRIPT_MAP[sp]}")
    elif si["ex"] == "RefCounted" or si["ex"] is None:
        kind = "utils" if not si["nonstatic"] else ("models" if CORE_MODEL_HINT.search(base) else "systems")
        SCRIPT_MAP[sp] = f"scripts/{kind}/{name}"
        DECIDE.append(f"script không gắn scene ở vị trí lạ: {sp} -> {SCRIPT_MAP[sp]}")
    else:  # kế thừa lớp project (BaseLayout, BaseTutorial...) mà không gắn scene nào: đặt cạnh lớp cha (pass 2)
        SCRIPT_MAP[sp] = ""

# pass 2: script con của lớp project -> cùng thư mục với lớp cha (đã có đích)
for sp, tgt in list(SCRIPT_MAP.items()):
    if tgt:
        continue
    parent = CLASS_TO_SCRIPT.get(SINFO[sp]["ex"] or "")
    pt = SCRIPT_MAP.get(parent or "", "")
    SCRIPT_MAP[sp] = (os.path.dirname(pt) or "scripts/systems") + "/" + newname(sp)
    DECIDE.append(f"script kế thừa lớp project, không gắn scene: {sp} -> {SCRIPT_MAP[sp]} (cạnh lớp cha {SINFO[sp]['ex']})")

# --------------------------------------------------------------------------- tests
TEST_MAP: dict[str, str] = {}
for sp in GD:
    if sp.startswith("scripts/test_case/"):
        b = os.path.basename(sp)
        if sp in OVERRIDES:
            TEST_MAP[sp] = OVERRIDES[sp]
        elif b.startswith("test_"):
            # tiền tố `legacy_` (KHÔNG phải `test_`): tests/run_tests.gd của template gom mọi `test_*.gd` và đòi `extends TestCase`;
            # test cũ là script `extends SceneTree` chạy riêng (godot -s) nên phải nằm ngoài luồng gom của runner.
            TEST_MAP[sp] = f"tests/legacy/legacy_{b[len('test_'):]}"
        else:
            TEST_MAP[sp] = f"debug/probes/{b}"

# --------------------------------------------------------------------------- data / assets
DATA_MAP: dict[str, str] = {}
DIR_REFS: list[tuple[str, str]] = []
RES_DIR_RENAME = {"settings": "config"}
if os.path.isdir(os.path.join(ROOT, "resources")):
    for d in sorted(os.listdir(os.path.join(ROOT, "resources"))):
        full = os.path.join(ROOT, "resources", d)
        if os.path.isdir(full):
            new = RES_DIR_RENAME.get(d, d)
            DATA_MAP[f"resources/{d}"] = f"data/{new}"
            DIR_REFS.append((f"resources/{d}/", f"data/{new}/"))
        else:
            DATA_MAP[f"resources/{d}"] = f"data/{d}"
if os.path.isdir(os.path.join(ROOT, "shaders")):
    DATA_MAP["shaders"] = "assets/shaders"
    DIR_REFS.append(("shaders/", "assets/shaders/"))
for old, new in (("assets/sfx", "assets/audio/sfx"), ("assets/soundtrack", "assets/audio/music")):
    if os.path.isdir(os.path.join(ROOT, old)):
        DATA_MAP[old] = new
        DIR_REFS.append((old + "/", new + "/"))
SPACED = []
for d, dirs, fs in os.walk(os.path.join(ROOT, "resources")):
    for f in fs:
        if " " in f:
            rel = os.path.relpath(os.path.join(d, f), ROOT).replace(os.sep, "/")
            new = "docs/prompts/" + re.sub(r"[\s]+", "_", f.lower())
            SPACED.append((rel, new))
for a, b in SPACED:
    DATA_MAP[a] = b  # (nằm trong resources/levels nên phải di chuyển TRƯỚC thư mục cha: map ghi theo thứ tự)

# --------------------------------------------------------------------------- write
os.makedirs(OUT, exist_ok=True)


def write(fn: str, pairs: list[tuple[str, str]], header: str) -> None:
    with open(os.path.join(OUT, fn), "w", encoding="utf-8", newline="\n") as f:
        f.write(f"# {header}\n")
        for a, b in pairs:
            f.write(f"{a} -> {b}\n")


spaced_first = sorted(((a, b) for a, b in DATA_MAP.items() if a in dict(SPACED)), key=lambda x: x[0])
rest = sorted(((a, b) for a, b in DATA_MAP.items() if a not in dict(SPACED)), key=lambda x: x[0])
write("P2a_data_assets.map", spaced_first + rest, "P2a: resources -> data, shaders -> assets/shaders, audio. Áp dụng TRƯỚC.")
write("P2b_scenes.map", sorted(SCENE_MAP.items()), "P2b: scene -> scenes/{screens,objects,components,base,autoload}")
write("P2c_scripts.map", sorted(SCRIPT_MAP.items()), "P2c: script -> mirror scene / models / systems / utils / editor, đổi PascalCase theo class_name")
write("P2d_tests.map", sorted(TEST_MAP.items()), "P2d: test_case -> tests/legacy/legacy_*.gd (test_*) hoặc debug/probes (dev_*, tmp_*)")
with open(os.path.join(OUT, "dir_refs.txt"), "w", encoding="utf-8", newline="\n") as f:
    f.write("# tiền tố THƯ MỤC trong chuỗi res:// (rewrite_dir_refs.py). Định dạng: cũ/ -> mới/\n")
    for a, b in DIR_REFS:
        f.write(f"{a} -> {b}\n")

# kiểm tra va chạm đích
allmaps = {**{a: b for a, b in SCENE_MAP.items()}, **SCRIPT_MAP, **TEST_MAP}
tgt = collections.defaultdict(list)
for a, b in allmaps.items():
    tgt[b.lower()].append(a)
collisions = {b: a for b, a in tgt.items() if len(a) > 1}

stat = collections.Counter(KIND.values())
rep = ["# Báo cáo gen_move_map", "", f"- scene: {len(SCENE_MAP)} ({dict(stat)})", f"- script: {len(SCRIPT_MAP)} (+{len(TEST_MAP)} test/probe)",
       f"- data/assets: {len(DATA_MAP)} dòng, dir_refs: {len(DIR_REFS)}", f"- override áp dụng: {len(OVERRIDES)}", ""]
rep.append(f"## Va chạm đích ({len(collisions)}) — PHẢI = 0 trước khi áp dụng")
for b, a in collisions.items():
    rep.append(f"- {b} <- {a}")
rep.append("")
rep.append(f"## Cần người xem lại ({len(DECIDE)})")
rep += [f"- {x}" for x in DECIDE]
rep.append("")
rep.append("## Scene bị hạ xuống components")
rep += [f"- {p} -> {SCENE_MAP[p]}" for p in SCENES if KIND[p] == "components"]
with open(os.path.join(OUT, "report.md"), "w", encoding="utf-8", newline="\n") as f:
    f.write("\n".join(rep) + "\n")
print("\n".join(rep[:12]))
print(f"-> {OUT}")
sys.exit(1 if collisions else 0)
