#!/usr/bin/env python3
"""Rule lint for instruction R1-R7 (heuristics, no Godot needed). Exit 1 if there are NEW errors.

  python tools/lint_rules.py                     # report new findings (baselined ones are hidden)
  python tools/lint_rules.py --rule R2,R3        # only some rules
  python tools/lint_rules.py --all               # also show baselined (legacy) findings
  python tools/lint_rules.py --update-baseline   # accept current findings as legacy debt
  python tools/lint_rules.py --max 40

Severity: ERROR = definite violation, WARN = needs a human/agent judgement (allowed category or tag required).
Only ERROR findings fail the run. A finding is silenced by `# EXCEPTION(R<n>...)` on the same or previous line.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

from _common import ROOT, class_index, iter_files, load_json, parse_gd, parse_tscn, read_text, resolve_scene, setup_stdout

_WS = re.compile(r"\s+")
CONFIG = load_json(ROOT / "tools" / "lint_config.json", {})
BASELINE_PATH = ROOT / "tools" / "lint_baseline.json"
EXEMPT = tuple(CONFIG.get("exempt_dirs", []))
NODE_NEW = re.compile(r"\b(Node|Node2D|Node3D|Control|CanvasLayer|Label|Button|Timer|Sprite2D|AnimatedSprite2D|"
                      r"CollisionShape2D|Area2D|AudioStreamPlayer\w*|AnimationPlayer|ColorRect|TextureRect|"
                      r"Panel\w*|\w+Container)\.new\(")
RES_NEW = re.compile(r"\b(SpriteFrames|StyleBox\w*|Theme|Animation|AnimationLibrary|ShaderMaterial|Shader)\.new\(")


def is_exempt(path: str) -> bool:
    return path.startswith(EXEMPT)


class Finding:
    def __init__(self, rule, sev, path, line, text, msg):
        self.rule, self.sev, self.path, self.line, self.text, self.msg = rule, sev, path, line, text.strip(), msg

    @property
    def key(self) -> str:
        flat = _WS.sub(" ", self.text)[:100]
        return f"{self.rule}|{self.path}|{flat}"

    def __str__(self):
        return f"{self.sev:5s} {self.rule} {self.path}:{self.line}: {self.msg} | {self.text[:90]}"


def tagged(lines, i, rule) -> bool:
    tag = re.compile(r"EXCEPTION\(" + rule + r"[^)]*\)")
    return bool(tag.search(lines[i]) or (i > 0 and tag.search(lines[i - 1])))


def code_lines(text):
    """Yield (index, line) skipping blank lines and comment-only lines."""
    lines = text.splitlines()
    for i, line in enumerate(lines):
        s = line.strip()
        if s and not s.startswith("#"):
            yield i, line, lines


GODOT3 = [
    (r"\byield\s*\(", "yield() was removed: use `await`"),
    (r"^\s*onready\s+var", "`onready var` -> `@onready var`"),
    (r"^\s*export\s*(\(|var)", "`export` -> `@export`"),
    (r"\.connect\(\s*\"", "string-based connect() is Godot 3: use `signal.connect(callable)`"),
    (r"\.instance\(\)", "`.instance()` -> `.instantiate()`"),
    (r"\b(KinematicBody2D|KinematicBody|Spatial|PoolStringArray|PoolVector2Array|PoolIntArray|PoolByteArray|PoolRealArray)\b", "Godot 3 class: use CharacterBody2D/Node3D/PackedXArray"),
    (r"\brand_range\(", "`rand_range` -> `randf_range` / `randi_range`"),
    (r"\bOS\.get_ticks_msec\(", "`OS.get_ticks_msec` -> `Time.get_ticks_msec`"),
    (r"\bsetget\b", "`setget` -> property setter/getter blocks"),
    (r"^\s*tool\s*$", "`tool` -> `@tool`"),
    (r"get_tree\(\)\.change_scene\(", "`change_scene(path)` -> `change_scene_to_file` / `change_scene_to_packed`"),
    (r"\bmove_and_slide\([^)]", "`move_and_slide()` takes no arguments in Godot 4 (set `velocity`)"),
    (r"\bis_connected\(\s*\"", "string-based is_connected() is Godot 3"),
    (r"\bTween\.new\(", "use `create_tween()`"),
    (r"\bOS\.window_fullscreen\b", "use `DisplayServer.window_set_mode`"),
]


_NODE_CLASSES = None


def node_classes():
    """class_names of project scripts whose base chain ends in a Node type (not RefCounted/Resource/Object)."""
    global _NODE_CLASSES
    if _NODE_CLASSES is None:
        base = {}
        for f in (ROOT / "scripts").rglob("*.gd"):
            txt = read_text(f)
            cn = re.search(r"^class_name\s+(\w+)", txt, re.M)
            ex = re.search(r"^extends\s+(\w+)", txt, re.M)
            if cn and ex:
                base[cn.group(1)] = ex.group(1)
        found = set()
        for name in base:
            cur, seen = name, set()
            while cur in base and cur not in seen:
                seen.add(cur)
                cur = base[cur]
            if cur not in ("RefCounted", "Resource", "Object"):
                found.add(name)
        _NODE_CLASSES = found
    return _NODE_CLASSES


def check_gd(path, out):
    text = read_text(ROOT / path)
    in_func = False
    for i, line, lines in code_lines(text):
        s = line.strip()
        code = re.sub(r'"[^"\n]*"', '""', s.split("#")[0])
        if s.startswith("func ") or s.startswith("static func "):
            in_func = True
        elif not line.startswith("\t") and not line.startswith(" "):
            in_func = False
        for pattern, message in GODOT3:
            if re.search(pattern, code):
                out.append(Finding("GODOT3", "ERROR", path, i + 1, s, message))
        if NODE_NEW.search(code) and not tagged(lines, i, "R2"):
            out.append(Finding("R2", "ERROR", path, i + 1, s, "node built in code (use the .tscn)"))
        m_new = re.search(r"\b([A-Z]\w+)\.new\(", code)
        if m_new and m_new.group(1) in node_classes() and not tagged(lines, i, "R2"):
            out.append(Finding("R2", "ERROR", path, i + 1, s, f"node class {m_new.group(1)} built in code (instance a scene / PackedScene export)"))
        if re.search(r"\bClassDB\.instantiate\(", code) and not tagged(lines, i, "R2"):
            out.append(Finding("R2", "ERROR", path, i + 1, s, "ClassDB.instantiate builds nodes in code (use the .tscn)"))
        if RES_NEW.search(code) and not tagged(lines, i, "R2"):
            out.append(Finding("R2", "ERROR", path, i + 1, s, "resource built in code (author .tres / sub-resource)"))
        if re.search(r"add_theme_\w+_override", code) and not tagged(lines, i, "R2"):
            out.append(Finding("R2", "ERROR", path, i + 1, s, "theme override in code (use Theme / scene)"))
        if re.search(r"get_node\(|\$\"?\.\.|\bget_parent\(\)|\bowner\.", code) and not tagged(lines, i, "R2"):
            out.append(Finding("R2", "WARN", path, i + 1, s, "reaching other nodes by path/parent (use export, %Unique, signal)"))
        if re.search(r"\$[A-Za-z_]\w*/", code):
            out.append(Finding("R2", "WARN", path, i + 1, s, "deep $A/B path (use %UniqueName or export)"))
        if ".connect(" in code and not tagged(lines, i, "R3"):
            if re.search(r"connect\(\s*func", code):
                out.append(Finding("R3", "ERROR", path, i + 1, s, "lambda connection (use a named _on_ method)"))
            elif "EventBus." not in code and not re.search(r"code-connect:\s*(model|runtime|tree|eventbus)", lines[i] + (lines[i - 1] if i else "")):
                out.append(Finding("R3", "WARN", path, i + 1, s, "code connection: add marker `# code-connect: model|runtime|tree` (allowed categories) or # EXCEPTION(R3)"))
        if re.search(r"create_tween|\bTween\b", code) and not tagged(lines, i, "R4"):
            out.append(Finding("R4", "ERROR", path, i + 1, s, "Tween needs # EXCEPTION(R4-tween) with criterion"))
        if re.search(r"\b\w*(animation_player|sprite)\w*\.(play|play_backwards)\(", code) and not path.endswith(("AnimationController.gd", "FrameTextureRect.gd")) \
                and not tagged(lines, i, "R4"):
            out.append(Finding("R4", "WARN", path, i + 1, s, "playing an AnimationPlayer/sprite outside an AnimationController (add a play_*() method there)"))
        if re.match(r"const\s+[A-Z][A-Z0-9_]*\s*(:\s*int)?\s*:?=\s*-?\d+\s*$", code.strip()) and path.startswith(("scripts/components/", "scripts/objects/", "scripts/screens/", "scripts/systems/")) \
                and not tagged(lines, i, "R1"):
            out.append(Finding("R1", "WARN", path, i + 1, s, "numeric const in a scene/system script: tuning value -> @export (or tag # EXCEPTION(R1): not tunable)"))
        if re.search(r"create_timer\(", code):
            out.append(Finding("R4", "WARN", path, i + 1, s, "create_timer: use animation_finished / Timer node / exported duration"))
        if re.search(r"(?<![\w.])(preload|load)\(", code) and path not in CONFIG.get("load_allowed_files", []):
            out.append(Finding("R1", "WARN", path, i + 1, s, "preload/load path: use @export PackedScene/Resource"))
        if in_func and not s.startswith(("const ", "@export", "func ", "static func ")) and \
                re.search(r"(?<![\w.\"&$%])-?(?!(?:0|1)\.0(?![\d\w]))\d+\.\d+(?![\w])", code) and not tagged(lines, i, "R1"):
            out.append(Finding("R1", "WARN", path, i + 1, s, "magic float in logic (export or const)"))
        if re.match(r"\s*var\s+\w+\s*=\s", line) and ":=" not in line:
            out.append(Finding("STYLE", "WARN", path, i + 1, s, "untyped var (declare a type)"))
        if re.match(r"\s*(static\s+)?func\s+\w+\(.*\)\s*:", line) and "->" not in line and "func _init" not in line:
            out.append(Finding("STYLE", "WARN", path, i + 1, s, "function without return type"))
        if re.search(r"\b_draw\(", code) and not tagged(lines, i, "R5"):
            out.append(Finding("R5", "WARN", path, i + 1, s, "drawing/placeholder shapes in code (use SVG placeholder)"))


def check_godot3_only(path, out):
    """Exempt folders (editor, tests, debug) still must not contain Godot 3 syntax."""
    for i, line in enumerate(read_text(ROOT / path).splitlines()):
        code = re.sub(r'"[^"\n]*"', '""', line.split("#")[0])
        for pattern, message in GODOT3:
            if re.search(pattern, code):
                out.append(Finding("GODOT3", "ERROR", path, i + 1, line, message))


def check_scene(path, out):
    if re.search(r"^\[gd_scene[^\]]*format=2", read_text(ROOT / path), re.M):
        out.append(Finding("GODOT3", "ERROR", path, 1, "format=2", "Godot 3 scene format: write `format=3`"))
    data = parse_tscn(read_text(ROOT / path))
    allowed = set(CONFIG.get("ui_structure_names", []))
    names = {n["name"] for n in data["nodes"]}
    for n in data["nodes"]:
        if n["type"] in ("ColorRect", "Polygon2D", "Line2D") and n["name"] not in allowed:
            out.append(Finding("R5", "WARN", path, n["line"], f"{n['name']}: {n['type']}", "placeholder art as node (use SVG texture)"))
    parts = path.split("/")
    kind = parts[1] if len(parts) > 2 and parts[0] == "scenes" else ""
    for n in data["nodes"]:
        ip = n["instance_path"]
        tk = ip.split("/")[1] if ip.startswith("scenes/") and ip.count("/") >= 2 else ""
        if n["parent"] is not None and ((kind == "components" and tk in ("objects", "screens")) or (kind == "objects" and tk == "screens")):
            out.append(Finding("STRUCT", "ERROR", path, n["line"], f"{n['name']} -> {ip}", f"dependency direction: {kind} must not instance {tk}"))
    if kind == "variants":
        if not data["nodes"] or not data["nodes"][0]["instance_path"]:
            out.append(Finding("STRUCT", "ERROR", path, 1, path, "variant must inherit a base scene"))
        for n in data["nodes"][1:]:
            if n["type"] or n["instance_path"]:
                out.append(Finding("STRUCT", "ERROR", path, n["line"], n["name"], "variant must keep the base node tree (no added nodes)"))
    types = {n["type"] for n in data["nodes"]}
    if ({"AnimationPlayer", "AnimatedSprite2D", "AnimationTree"} & types) and "AnimationController" not in names \
            and path.startswith("scenes/") and not path.startswith(("scenes/base",)):
        out.append(Finding("R4", "WARN", path, 1, "animated scene", "AnimationPlayer/AnimatedSprite2D without an AnimationController node"))
    if path.startswith("scenes/") and path.count("/") >= 2:
        nodes = resolve_scene(path)
        root_script = nodes.get("", {}).get("script", "")
        if root_script:
            parts = path.split("/")
            expected = "scripts/" + "/".join(parts[1:-1])
            actual = str(Path(root_script).parent.as_posix())
            if actual != expected:
                out.append(Finding("R2", "WARN", path, 1, root_script, f"root script should live in mirror folder {expected}"))
            if not parse_gd(read_text(ROOT / root_script))["has_contract"] and not root_script.startswith("scripts/base"):
                out.append(Finding("R3", "WARN", root_script, 1, "scene script", "missing '## Scene contract' header"))


def check_structure(out):
    for p in iter_files():
        if p.startswith("scenes/") and p.endswith(".gd"):
            out.append(Finding("STRUCT", "ERROR", p, 1, p, ".gd inside scenes/"))
        if p.startswith("scripts/") and p.endswith(".tscn"):
            out.append(Finding("STRUCT", "ERROR", p, 1, p, ".tscn inside scripts/"))
        if p.startswith("scripts/constants/") and p.endswith(".gd"):
            t = read_text(ROOT / p)
            if re.search(r"^(func|var|@export)\b", t, re.M) or not re.search(r"^extends RefCounted", t, re.M):
                out.append(Finding("STRUCT", "ERROR", p, 1, p, "constants file must extend RefCounted and hold only const/enum"))
        if p.startswith("scripts/utils/") and p.endswith(".gd"):
            t = read_text(ROOT / p)
            if re.search(r"^func\b", t, re.M) or re.search(r"^extends\s+(Node|Control|Node2D)", t, re.M) or re.search(r"^var\b", t, re.M):
                out.append(Finding("STRUCT", "ERROR", p, 1, p, "utils must be stateless: all `static func`, no Node, no vars"))
        if p.startswith("scripts/editor/") and p.endswith(".gd") and "EXCEPTION(R2,R3,R5)" not in read_text(ROOT / p):
            out.append(Finding("R7", "WARN", p, 1, p, "editor custom type missing '# EXCEPTION(R2,R3,R5)' header"))
    # R5 manifest consistency
    manifest = ROOT / "assets/images-placeholder/MANIFEST.md"
    svgs = [p for p in iter_files("assets/images-placeholder", exts={".svg"})]
    mtext = read_text(manifest) if manifest.exists() else ""
    for s in svgs:
        if Path(s).name not in mtext:
            out.append(Finding("R5", "ERROR", s, 1, s, "placeholder SVG not listed in MANIFEST.md"))
    for row in re.findall(r"^\|\s*`?([\w/.\-]+\.svg)`?\s*\|", mtext, re.M):
        if not (ROOT / "assets/images-placeholder" / row).exists() and row not in svgs and not (ROOT / row).exists():
            out.append(Finding("R5", "ERROR", "assets/images-placeholder/MANIFEST.md", 1, row, "manifest row points to a missing SVG"))
    # R8 tests mention each logic class
    tests = " ".join(read_text(ROOT / p) for p in iter_files("tests", exts={".gd"}))
    for cname, cpath in class_index().items():
        if cpath.startswith(tuple(CONFIG.get("need_test_dirs", []))) and not re.search(r"\b" + cname + r"\b", tests):
            out.append(Finding("R8", "WARN", cpath, 1, cname, "no test mentions this class"))


def check_dead_code(out):
    allow = set(CONFIG.get("dead_code_allow", []))
    godot = read_text(ROOT / "project.godot") if (ROOT / "project.godot").exists() else ""
    texts = {p: read_text(ROOT / p) for p in iter_files(exts={".gd", ".tscn", ".tres"}) if not p.startswith(("tests/", "tools/"))}
    for cname, cpath in class_index().items():
        if cpath.startswith(("scripts/editor/", "tests/")) or cname in allow:
            continue
        path_ref = "res://" + cpath
        rx = re.compile(r"\b" + cname + r"\b")
        used = path_ref in godot
        for p, t in texts.items():
            if used:
                break
            if p == cpath:
                continue
            if (p.endswith(".gd") and rx.search(t)) or path_ref in t or f'script_class="{cname}"' in t:
                used = True
        if not used:
            out.append(Finding("DEAD", "WARN", cpath, 1, cname, "class is never used outside tests: dead code? remove it (or add to dead_code_allow in lint_config.json)"))


def check_naming(out):
    for p in list(iter_files("instruction")) + list(iter_files("plan")):
        name = Path(p).name
        if " " in name:
            out.append(Finding("NAMING", "WARN", p, 1, name, "file names must not contain spaces (use snake_case: <game_name>_gameplay.md)"))
        if p.startswith("instruction/") and name.endswith((".txt", ".log")):
            out.append(Finding("NAMING", "WARN", p, 1, name, "reports/logs belong in docs/reports/, not in instruction/"))


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--rule", default="")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--update-baseline", action="store_true")
    ap.add_argument("--strict", action="store_true", help="WARN findings also fail the run (used by run_checks)")
    ap.add_argument("--max", type=int, default=60)
    a = ap.parse_args()

    findings: list = []
    for p in iter_files(exts={".gd"}):
        if not is_exempt(p):
            check_gd(p, findings)
        elif not p.startswith("tools/"):
            check_godot3_only(p, findings)
    for p in iter_files(exts={".tscn"}):
        check_scene(p, findings)
    check_structure(findings)
    check_dead_code(findings)
    check_naming(findings)
    if a.rule:
        wanted = {r.strip().upper() for r in a.rule.split(",")}
        findings = [f for f in findings if f.rule in wanted]

    if a.update_baseline:
        BASELINE_PATH.write_text(json.dumps(sorted({f.key for f in findings}), indent=1), encoding="utf-8")
        print(f"baseline updated: {len(findings)} findings accepted as legacy -> {BASELINE_PATH.relative_to(ROOT)}")
        return 0

    baseline = set(load_json(BASELINE_PATH, []))
    new = [f for f in findings if f.key not in baseline]
    shown = findings if a.all else new
    for f in shown[: a.max]:
        print(f)
    if len(shown) > a.max:
        print(f"... {len(shown) - a.max} more (use --max / --rule)")
    errors = [f for f in new if f.sev == "ERROR"]
    by_rule: dict = {}
    for f in new:
        by_rule[f.rule] = by_rule.get(f.rule, 0) + 1
    print(f"lint_rules: {len(new)} new ({len(errors)} errors), {len(findings) - len(new)} baselined"
          + (" | " + ", ".join(f"{k}:{v}" for k, v in sorted(by_rule.items())) if by_rule else ""))
    return 1 if errors or (a.strict and new) else 0


if __name__ == "__main__":
    sys.exit(main())
