#!/usr/bin/env python3
"""JSON spec -> AnimationLibrary .tres (instruction R4). Saves hand-writing Animation tracks.

  python tools/gen_animation.py data/animations/specs/actor_animations.json            # writes data/animations/actor_animations.tres
  python tools/gen_animation.py spec.json --out data/animations/x.tres --names         # also prints StringName consts
  python tools/gen_animation.py --example                                              # print an example spec

Spec:
{ "animations": { "<name>": { "length": 0.2, "loop": false,
    "tracks": [ { "path": ".:modulate", "type": "value", "update": "continuous|discrete", "interp": "linear|nearest|cubic",
                  "keys": [[time, value], ...] },
                { "path": ".", "type": "method", "keys": [[time, "queue_free", []]] } ] } } }
  Frame stepping (Sprite2D hframes/vframes): {"path": "Sprite:frame", "type": "frames", "fps": 8, "frames": [0,1,2,3]}  (length = frames/fps)
Values: JSON numbers/bools or a Godot literal string, e.g. "Color(1, 0.4, 0.4, 1)", "Vector2(1.5, 1.5)".
Track paths are relative to the AnimationPlayer's root_node (set `root_node` in the scene).
A `RESET` animation is required (instruction R4).
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from _common import ROOT, norm, setup_stdout

EXAMPLE = {
    "animations": {
        "RESET": {"length": 0.001, "tracks": [{"path": ".:modulate", "keys": [[0, "Color(1, 1, 1, 1)"]]}]},
        "hit": {"length": 0.2, "tracks": [{"path": ".:modulate", "keys": [[0, "Color(1, 0.4, 0.4, 1)"], [0.2, "Color(1, 1, 1, 1)"]]}]},
        "effect": {"length": 0.3, "tracks": [
            {"path": "Sprite:visible", "update": "discrete", "keys": [[0, True], [0.3, False]]},
            {"path": ".", "type": "method", "keys": [[0.3, "queue_free", []]]}]},
        "spin": {"loop": True, "tracks": [{"path": "Sprite:frame", "type": "frames", "fps": 8, "frames": [0, 1, 2, 3]}]},
    }
}
UPDATE = {"continuous": 0, "discrete": 1, "capture": 2}
INTERP = {"nearest": 0, "linear": 1, "cubic": 2}


def literal(v) -> str:
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(float(v)) if isinstance(v, float) else str(v)
    return str(v)


def fmt_times(keys) -> str:
    return "PackedFloat32Array(" + ", ".join(f"{k[0]:g}" for k in keys) + ")"


def expand_frame_tracks(anim: dict) -> None:
    """track {"type":"frames","path":"Sprite:frame","frames":[0,1,2],"fps":8} -> discrete value track; sets length if missing."""
    longest = 0.0
    for tr in anim.get("tracks", []):
        if tr.get("type") == "frames":
            fps = float(tr.get("fps", 8))
            tr["type"], tr["update"] = "value", "discrete"
            tr["keys"] = [[i / fps, int(f)] for i, f in enumerate(tr["frames"])]
            longest = max(longest, len(tr["frames"]) / fps)
    if longest and "length" not in anim:
        anim["length"] = longest


def build(spec: dict, errors: list) -> str:
    anims = spec.get("animations", {})
    if "RESET" not in anims:
        errors.append("missing required animation 'RESET'")
    sub, data = [], []
    for name, anim in anims.items():
        expand_frame_tracks(anim)
        length = float(anim.get("length", 1.0))
        if length <= 0:
            errors.append(f"{name}: length must be > 0")
        sid = f"Animation_{name}"
        lines = [f'[sub_resource type="Animation" id="{sid}"]', f'resource_name = "{name}"', f"length = {length:g}"]
        if anim.get("loop"):
            lines.append("loop_mode = 1")
        for i, tr in enumerate(anim.get("tracks", [])):
            ttype = tr.get("type", "value")
            keys = sorted(tr.get("keys", []), key=lambda k: k[0])
            if not keys:
                errors.append(f"{name} track {i}: no keys")
                continue
            if keys[0][0] < 0 or keys[-1][0] > length + 1e-6:
                errors.append(f"{name} track {i} ({tr.get('path')}): key time outside 0..{length:g}")
            lines += [f'tracks/{i}/type = "{ttype}"', f"tracks/{i}/imported = false", f"tracks/{i}/enabled = true",
                      f'tracks/{i}/path = NodePath("{tr["path"]}")',
                      f"tracks/{i}/interp = {INTERP.get(tr.get('interp', 'linear'), 1)}", f"tracks/{i}/loop_wrap = true"]
            trans = "PackedFloat32Array(" + ", ".join("1" for _ in keys) + ")"
            if ttype == "method":
                vals = ", ".join('{\n"args": [%s],\n"method": &"%s"\n}' % (", ".join(literal(a) for a in (k[2] if len(k) > 2 else [])), k[1]) for k in keys)
                lines.append('tracks/%d/keys = {\n"times": %s,\n"transitions": %s,\n"values": [%s]\n}' % (i, fmt_times(keys), trans, vals))
            else:
                upd = UPDATE.get(tr.get("update", "continuous"), 0)
                vals = ", ".join(literal(k[1]) for k in keys)
                lines.append('tracks/%d/keys = {\n"times": %s,\n"transitions": %s,\n"update": %d,\n"values": [%s]\n}' % (i, fmt_times(keys), trans, upd, vals))
        sub.append("\n".join(lines))
        data.append(f'&"{name}": SubResource("{sid}")')
    head = f'[gd_resource type="AnimationLibrary" load_steps={len(sub) + 1} format=3]\n\n'
    return head + "\n\n".join(sub) + "\n\n[resource]\n_data = {\n" + ",\n".join(data) + "\n}\n"


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("spec", nargs="?")
    ap.add_argument("--out", default="")
    ap.add_argument("--names", action="store_true")
    ap.add_argument("--example", action="store_true")
    a = ap.parse_args()
    if a.example:
        print(json.dumps(EXAMPLE, indent=2))
        return 0
    if not a.spec:
        ap.error("spec required")
    spec_path = ROOT / norm(a.spec)
    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    errors: list = []
    text = build(spec, errors)
    if errors:
        for e in errors:
            print("ERROR " + e)
        return 1
    out = (ROOT / (norm(a.out) if a.out else f"data/animations/{spec_path.stem}.tres")).resolve()
    if ROOT.resolve() not in out.parents:
        print("ERROR: --out must be inside the project")
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8", newline="\n")
    names = list(spec["animations"].keys())
    print(f"wrote {out.relative_to(ROOT.resolve()).as_posix()} ({len(names)} animations: {', '.join(names)})")
    if a.names:
        for n in names:
            print(f'const ANIM_{n.upper()}: StringName = &"{n}"')
    return 0


if __name__ == "__main__":
    sys.exit(main())
