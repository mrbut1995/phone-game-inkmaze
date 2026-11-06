#!/usr/bin/env python3
"""Scaffold a scene + its mirror script in the correct folders (instruction sections 2.1-2.2, R1-R4).

  python tools/new_scene.py screen shop --inherits scenes/base/base_scene.tscn
  python tools/new_scene.py object world/coin --root Node2D --animated
  python tools/new_scene.py component actor/health_bar --root Control
  python tools/new_scene.py variant bird/seagull --inherits scenes/objects/world/bird.tscn
  python tools/new_scene.py autoload analytics --root Node
  python tools/new_scene.py object world/slime --frames                 # AnimatedSprite2D %Sprite + AnimationController (frames only)
  python tools/new_scene.py component ui/coin_icon --root Control --frames   # FrameTextureRect %Sprite (Control-only projects)
Kinds -> folders: screen=screens | object=objects/<domain> | component=components/<domain> | variant=variants/<family> | base=base | autoload=autoload
Creates: scenes/<kind>/.../<name>.tscn, scripts/<kind>/.../<ClassName>.gd (with `## Scene contract`), and with --animated an
AnimationController node + AnimationPlayer + data/animations/<name>_animations(.json/.tres) with a RESET animation.
--frames = frame animation only (no AnimationPlayer): Node2D root -> AnimatedSprite2D + BaseFrameAnimationController (+ signal wired);
Control root -> FrameTextureRect (play_state() on it directly). Use --animated for effect tracks (flash, shake) and --frames for sprite cycles;
a scene may take both flags only with a Node2D root (see instruction R4 'hybrid').
Never overwrites. Runs validate_scenes on the result.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys

from _common import ROOT, norm, parse_gd, read_text, resolve_scene, setup_stdout

KIND_DIR = {"screen": "screens", "object": "objects", "component": "components", "variant": "variants", "base": "base", "autoload": "autoload"}
ROOTS_2D = {"Node2D", "Control", "Node", "CanvasLayer", "Node3D"}


def pascal(name: str) -> str:
    return "".join(p.capitalize() for p in re.split(r"[_\-]", name) if p)


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("kind", choices=sorted(KIND_DIR))
    ap.add_argument("path", help="<domain>/<name> (screen/base/autoload: just <name>)")
    ap.add_argument("--root", default="Node2D", choices=sorted(ROOTS_2D))
    ap.add_argument("--inherits", default="", help="base scene (required for variant)")
    ap.add_argument("--animated", action="store_true")
    ap.add_argument("--frames", action="store_true", help="frame animation (SpriteFrames): AnimatedSprite2D, or FrameTextureRect for a Control root")
    ap.add_argument("--no-validate", action="store_true")
    a = ap.parse_args()

    parts = a.path.replace("\\", "/").strip("/").split("/")
    name = parts[-1]
    if not re.match(r"^[a-z][a-z0-9_]*$", name) or not all(re.match(r"^[a-z][a-z0-9_]*$", p) for p in parts):
        print("ERROR: path segments must be snake_case")
        return 1
    if a.kind in ("object", "component", "variant") and len(parts) < 2:
        print(f"ERROR: {a.kind} needs <domain>/<name>")
        return 1
    if a.kind in ("screen", "base", "autoload") and len(parts) != 1:
        print(f"ERROR: {a.kind} takes just <name>")
        return 1
    if a.kind == "variant" and not a.inherits:
        print("ERROR: variant requires --inherits <base scene>")
        return 1
    if a.kind == "variant" and (a.animated or a.frames):
        print("ERROR: a variant keeps the base node tree; it cannot add an AnimationController or a sprite")
        return 1
    if a.animated and a.frames:
        print("ERROR: choose one: --frames (sprite cycles only) or --animated (AnimationPlayer; drive frames from its AnimatedSprite2D via FrameAnimUtils)")
        return 1
    if a.frames and a.root not in ("Node2D", "Control"):
        print("ERROR: --frames needs --root Node2D (AnimatedSprite2D) or --root Control (FrameTextureRect)")
        return 1

    sub = "/".join(parts[:-1])
    kind_dir = KIND_DIR[a.kind]
    scene_rel = f"scenes/{kind_dir}/{sub + '/' if sub else ''}{name}.tscn"
    script_dir = f"scripts/{kind_dir}/{sub + '/' if sub else ''}".rstrip("/")
    cls = pascal(name)
    if a.kind == "screen" and not cls.endswith("Scene"):
        cls += "Scene"
    script_rel = f"{script_dir}/{cls}.gd"

    base_scene = norm(a.inherits) if a.inherits else ""
    if base_scene and not (ROOT / base_scene).exists():
        print(f"ERROR: base scene {base_scene} not found")
        return 1
    for rel in (scene_rel, script_rel):
        if (ROOT / rel).exists():
            print(f"ERROR: {rel} already exists")
            return 1

    extends = a.root
    if base_scene:
        base_script = resolve_scene(base_scene).get("", {}).get("script", "")
        if base_script:
            g = parse_gd(read_text(ROOT / base_script))
            extends = g["class_name"] or f'"res://{base_script}"'
        else:
            extends = resolve_scene(base_scene).get("", {}).get("type", a.root)

    # ---------------- script
    class_line = "" if a.kind == "autoload" else f"class_name {cls}\n"
    body = f"""extends {extends}
{class_line}## <one line: what this scene is>
##
## Scene contract
## Exports:  (none yet)
## Emits:    (none yet)
## Handlers wired in scene: (none yet)
## Subscribes in code (EventBus/Model): (none yet)

# @export_group("Tuning")
# ## <unit and effect>
# @export_range(0.0, 10.0, 0.1, "suffix:s") var example_duration: float = 1.0

func _ready() -> void:
\tpass
"""
    if a.kind == "screen" and "BaseScene" in extends:
        body = body.replace("func _ready() -> void:\n\tpass\n", "func _on_scene_ready() -> void:\n\tpass\n")
    sp = ROOT / script_rel
    sp.parent.mkdir(parents=True, exist_ok=True)
    sp.write_text(body, encoding="utf-8", newline="\n")
    created = [script_rel]

    # ---------------- scene
    ext = []
    nodes = []
    if base_scene:
        ext.append(f'[ext_resource type="PackedScene" path="res://{base_scene}" id="1_base"]')
        ext.append(f'[ext_resource type="Script" path="res://{script_rel}" id="2_script"]')
        nodes.append(f'[node name="{cls.replace("Scene", "") if a.kind == "screen" else cls}" instance=ExtResource("1_base")]\nscript = ExtResource("2_script")')
    else:
        ext.append(f'[ext_resource type="Script" path="res://{script_rel}" id="1_script"]')
        nodes.append(f'[node name="{cls}" type="{a.root}"]\nscript = ExtResource("1_script")')
    conns = []
    if a.animated:
        ctrl_cls = f"{cls}AnimationController"
        ctrl_rel = f"{script_dir}/{ctrl_cls}.gd"
        spec_rel = f"data/animations/specs/{name}_animations.json"
        lib_rel = f"data/animations/{name}_animations.tres"
        (ROOT / ctrl_rel).write_text(f"""extends BaseAnimationController
class_name {ctrl_cls}
## Scene contract
## Exports:  speed_scale (inherited)
## Emits:    animation_finished (inherited)
## Handlers wired in scene: _on_animation_player_animation_finished (inherited)
## Subscribes in code (EventBus/Model): (none)

# const ANIM_EXAMPLE: StringName = &"example"

func _required_animations() -> Array[StringName]:
\treturn [&"RESET"]

# func play_example() -> void:
# \t_play(ANIM_EXAMPLE)
""", encoding="utf-8", newline="\n")
        (ROOT / spec_rel).parent.mkdir(parents=True, exist_ok=True)
        (ROOT / spec_rel).write_text(json.dumps({"animations": {"RESET": {"length": 0.001, "tracks": [
            {"path": ".:modulate", "keys": [[0, "Color(1, 1, 1, 1)"]]}]}}}, indent=2) + "\n", encoding="utf-8")
        subprocess.run([sys.executable, str(ROOT / "tools" / "gen_animation.py"), spec_rel], cwd=str(ROOT), check=True, capture_output=True)
        ext.append(f'[ext_resource type="Script" path="res://{ctrl_rel}" id="3_anim"]')
        ext.append(f'[ext_resource type="AnimationLibrary" path="res://{lib_rel}" id="4_lib"]')
        nodes.append('[node name="AnimationController" type="Node" parent="."]\nunique_name_in_owner = true\nscript = ExtResource("3_anim")')
        nodes.append('[node name="AnimationPlayer" type="AnimationPlayer" parent="AnimationController"]\nunique_name_in_owner = true\nroot_node = NodePath("../..")\nlibraries = {\n&"": ExtResource("4_lib")\n}')
        conns.append('[connection signal="animation_finished" from="AnimationController/AnimationPlayer" to="AnimationController" method="_on_animation_player_animation_finished"]')
        created += [ctrl_rel, spec_rel, lib_rel]

    if a.frames:
        if a.root == "Control":
            ext.append('[ext_resource type="Script" path="res://scripts/editor/FrameTextureRect.gd" id="3_frames"]')
            nodes.append('[node name="Sprite" type="TextureRect" parent="."]\nunique_name_in_owner = true\nlayout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\nexpand_mode = 1\nstretch_mode = 5\nscript = ExtResource("3_frames")')
            print("note: FrameTextureRect is the whole API: play_state(&\"walk\", &\"left\"), play(), stop(), animation_finished; call it from the View.")
        else:
            ctrl_cls = f"{cls}AnimationController"
            ctrl_rel = f"{script_dir}/{ctrl_cls}.gd"
            (ROOT / ctrl_rel).write_text(f"""extends BaseFrameAnimationController
class_name {ctrl_cls}
## Frame animation of {cls} (names from tools/spritesheet.py: <state>_<direction>).
##
## Scene contract
## Exports:  speed_scale, default_state, default_direction (inherited)
## Emits:    animation_finished (inherited)
## Handlers wired in scene: _on_sprite_animation_finished (inherited)
## Subscribes in code (EventBus/Model): (none)

# Semantic API for the Controller/View, e.g.:
# func play_walk() -> void:
# \tplay_state(&"walk")
# func play_attack() -> void:
# \tplay_state(&"attack", AnimDirections.NONE, true)

func _required_states() -> Array[StringName]:
\treturn [default_state]
""", encoding="utf-8", newline="\n")
            ext.append(f'[ext_resource type="Script" path="res://{ctrl_rel}" id="3_anim"]')
            nodes.append('[node name="Sprite" type="AnimatedSprite2D" parent="."]\nunique_name_in_owner = true')
            nodes.append('[node name="AnimationController" type="Node" parent="."]\nunique_name_in_owner = true\nscript = ExtResource("3_anim")')
            conns.append('[connection signal="animation_finished" from="Sprite" to="AnimationController" method="_on_sprite_animation_finished"]')
            created.append(ctrl_rel)

    header = f"[gd_scene load_steps={len(ext) + 1} format=3]\n\n"
    text = header + "\n".join(ext) + "\n\n" + "\n\n".join(nodes) + ("\n\n" + "\n".join(conns) if conns else "") + "\n"
    scp = ROOT / scene_rel
    scp.parent.mkdir(parents=True, exist_ok=True)
    scp.write_text(text, encoding="utf-8", newline="\n")
    created.insert(0, scene_rel)

    print("created:\n  " + "\n  ".join(created))
    if a.kind == "autoload":
        print(f'next: register in project.godot [autoload]: {cls}="*res://{scene_rel}"')
    if not a.no_validate:
        rc = subprocess.run([sys.executable, str(ROOT / "tools" / "validate_scenes.py"), scene_rel], cwd=str(ROOT)).returncode
        if rc:
            return rc
    if a.frames:
        print("next: python tools/spritesheet.py placeholder <cat/name> --rows idle_down:2,walk_down:6 (or pack-dir / from-aseprite), then `frames <spec>`, then assign the .tres to Sprite.sprite_frames in the .tscn.")
    print("next: add nodes/exports/connections in the .tscn, logic in the script, then `python tools/new_test.py <Class>` for logic classes.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
