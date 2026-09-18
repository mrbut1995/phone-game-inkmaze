"""Phương án A: thanh nút hành động của màn chơi thành `nodes/hud/action_bar.tscn` (2 bố cục
dọc/ngang) rồi GẮN vào MỌI HUD chế độ — GameScene chỉ lấy nút ra từ HUD đang chơi.

- `Portrait/Row`  : 1 hàng ngang (VẼ ĐƯỜNG · GHI NHỚ · UNDO · HINT · CHƠI LẠI) — nằm NGAY DƯỚI HUD
- `Landscape/MainRow` (2 nút chính) + `Landscape/SubRow` (Undo · Hint · Replay) — 2 hàng dưới HUD
- `scripts/nodes/hud/action_bar.gd` CHUYỂN nút giữa 2 bố cục theo hướng màn hình.

Usage: python tools/ui/make_action_bar.py            # tạo lại thanh nút + gắn vào HUD
"""

from __future__ import annotations

import pathlib
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]
BAR_SCENE = ROOT / "nodes" / "hud" / "action_bar.tscn"
BAR_SCRIPT = "res://scripts/nodes/hud/action_bar.gd"
ASSETS = "res://assets/images/game"
HUD_DIR = ROOT / "nodes" / "hud"
HUD_SCENES = [
    "level_mode.tscn", "dungeon_mode.tscn", "minesweep_hud.tscn", "sum_path_hud.tscn",
    "blind_memory_hud.tscn", "countdown_hud.tscn", "fading_ink_hud.tscn",
    "fog_of_war_hud.tscn", "one_stroke_hud.tscn", "wall_builder_hud.tscn",
]

# (id, loại, đường dẫn) — art nút dùng đúng như thanh nút cũ trong game.tscn
EXTS = [
    ("bar_tool_n", "Texture2D", f"{ASSETS}/btn_tool_path_inactive.svg"),
    ("bar_tool_p", "Texture2D", f"{ASSETS}/btn_tool_path_pressed.svg"),
    ("bar_wall_n", "Texture2D", f"{ASSETS}/btn_tool_wall_inactive.svg"),
    ("bar_wall_p", "Texture2D", f"{ASSETS}/btn_tool_wall_pressed.svg"),
    ("bar_undo_n", "Texture2D", f"{ASSETS}/btn_undo_normal.svg"),
    ("bar_undo_p", "Texture2D", f"{ASSETS}/btn_undo_pressed.svg"),
    ("bar_undo_d", "Texture2D", f"{ASSETS}/btn_undo_disabled.svg"),
    ("bar_undo_f", "Texture2D", f"{ASSETS}/btn_undo_focus.svg"),
    ("bar_hint_n", "Texture2D", f"{ASSETS}/btn_hint_normal.svg"),
    ("bar_hint_p", "Texture2D", f"{ASSETS}/btn_hint_pressed.svg"),
    ("bar_hint_d", "Texture2D", f"{ASSETS}/btn_hint_disabled.svg"),
    ("bar_replay", "Texture2D", "res://assets/images/popups/icon_replay.svg"),
    ("bar_lbl", "LabelSettings", "res://resources/settings/text/text_game_button_label.tres"),
    ("bar_sub", "LabelSettings", "res://resources/settings/text/text_game_button_sub.tres"),
]


def tool_button(name: str, ext_n: str, ext_p: str, title: str, sub: str) -> str:
    return (
        f'[node name="{name}" type="TextureButton" parent="Portrait/Row"]\n'
        f'layout_mode = 2\nsize_flags_horizontal = 3\nsize_flags_vertical = 4\n'
        f'texture_normal = ExtResource("{ext_n}")\ntexture_pressed = ExtResource("{ext_p}")\n\n'
        f'[node name="Label" type="Label" parent="Portrait/Row/{name}" index="0"]\n'
        f'layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\n'
        f'offset_bottom = -40.0\nlabel_settings = ExtResource("bar_lbl")\n'
        f'horizontal_alignment = 1\nvertical_alignment = 1\ntext = "{title}"\n\n'
        f'[node name="Sub" type="Label" parent="Portrait/Row/{name}" index="1"]\n'
        f'layout_mode = 1\nanchors_preset = 12\nanchor_top = 1.0\nanchor_right = 1.0\n'
        f'anchor_bottom = 1.0\noffset_top = -46.0\nlabel_settings = ExtResource("bar_sub")\n'
        f'horizontal_alignment = 1\nvertical_alignment = 1\ntext = "{sub}"\n\n'
    )


def icon_button(name: str, ext_n: str, title: str, ext_p: str = "", ext_d: str = "") -> str:
    extra = f'texture_pressed = ExtResource("{ext_p}")\n' if ext_p else ""
    extra += f'texture_disabled = ExtResource("{ext_d}")\n' if ext_d else ""
    return (
        f'[node name="{name}" type="TextureButton" parent="Portrait/Row"]\n'
        f'layout_mode = 2\nsize_flags_horizontal = 4\nsize_flags_vertical = 4\n'
        f'tooltip_text = "{title}"\n'
        f'texture_normal = ExtResource("{ext_n}")\n{extra}\n'
    )


def replay_button() -> str:
    return (
        '[node name="Replay" type="TextureButton" parent="Portrait/Row"]\n'
        'custom_minimum_size = Vector2(192, 108)\nlayout_mode = 2\nsize_flags_horizontal = 4\n'
        'size_flags_vertical = 4\nvisible = false\ntexture_normal = ExtResource("bar_replay")\n'
        'ignore_texture_size = true\nstretch_mode = 5\n\n'
        '[node name="Label" type="Label" parent="Portrait/Row/Replay" index="0"]\n'
        'layout_mode = 1\nanchors_preset = 12\nanchor_top = 1.0\nanchor_right = 1.0\n'
        'anchor_bottom = 1.0\noffset_top = -34.0\nlabel_settings = ExtResource("bar_sub")\n'
        'horizontal_alignment = 1\nvertical_alignment = 1\n'
    )


def build_bar() -> None:
    out = "[gd_scene format=3]\n\n"
    out += f'[ext_resource type="Script" path="{BAR_SCRIPT}" id="bar_script"]\n'
    for eid, etype, path in EXTS:
        out += f'[ext_resource type="{etype}" path="{path}" id="{eid}"]\n'
    out += "\n"
    out += ('[node name="ActionBar" type="Control"]\n'
            'layout_mode = 3\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\n'
            'script = ExtResource("bar_script")\n\n')
    # Bản DỌC: 1 hàng, nằm ngay dưới khung HUD (như thanh nút cũ ở đáy màn chơi)
    out += ('[node name="Portrait" type="Control" parent="."]\n'
            'layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\n'
            'mouse_filter = 2\n\n')
    out += ('[node name="Row" type="HBoxContainer" parent="Portrait"]\n'
            'layout_mode = 1\nanchors_preset = -1\nanchor_top = 1.0\nanchor_right = 1.0\n'
            'anchor_bottom = 1.0\noffset_top = 20.0\noffset_bottom = 182.0\n'
            'theme_override_constants/separation = 20\nalignment = 1\n\n')
    out += tool_button("Tool", "bar_tool_n", "bar_tool_p", "STR_TOOL_DRAW_PATH",
                       "STR_TOOL_DRAW_PATH_DESC")
    out += tool_button("Wall", "bar_wall_n", "bar_wall_p", "STR_TOOL_MARK_WALL",
                       "STR_TOOL_MARK_WALL_DESC")
    out += icon_button("Undo", "bar_undo_n", "UNDO", "bar_undo_p", "bar_undo_d")
    out += icon_button("Hint", "bar_hint_n", "HINT", "bar_hint_p", "bar_hint_d")
    out += replay_button()
    # Bản NGANG: 2 hàng rộng 980 (hàng trên: 2 nút chính — hàng dưới: Undo · Hint · Chơi lại)
    out += ('[node name="Landscape" type="Control" parent="."]\n'
            'layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\n'
            'mouse_filter = 2\nvisible = false\n\n')
    out += ('[node name="MainRow" type="HBoxContainer" parent="Landscape"]\n'
            'layout_mode = 1\nanchors_preset = -1\nanchor_left = 0.5\nanchor_right = 0.5\n'
            'offset_left = -490.0\noffset_right = 490.0\noffset_top = 18.0\noffset_bottom = 180.0\n'
            'theme_override_constants/separation = 18\nalignment = 1\n\n')
    out += ('[node name="SubRow" type="HBoxContainer" parent="Landscape"]\n'
            'layout_mode = 1\nanchors_preset = -1\nanchor_left = 0.5\nanchor_right = 0.5\n'
            'offset_left = -490.0\noffset_right = 490.0\noffset_top = 190.0\noffset_bottom = 352.0\n'
            'theme_override_constants/separation = 18\nalignment = 1\n')
    BAR_SCENE.write_text(out, encoding="utf-8")
    print(f"  OK {BAR_SCENE.relative_to(ROOT)}")


def attach_to_huds() -> None:
    """Gắn ActionBar vào `nodes/hud/base.tscn` — MỌI HUD (level_mode, dungeon_mode…) đều kế thừa
    root của scene này nên chỉ cần 1 chỗ: mọi chế độ đều có thanh nút, kể cả HUD giữ chỗ ban đầu."""
    base = HUD_DIR / "base.tscn"
    text = base.read_text(encoding="utf-8")
    if 'name="ActionBar"' in text:
        print("  (base.tscn đã có ActionBar)")
        return
    ext = ('[ext_resource type="PackedScene" path="res://nodes/hud/action_bar.tscn" '
           'id="L_action_bar"]\n')
    lines = text.splitlines(keepends=True)
    first = next((i for i, l in enumerate(lines) if l.startswith("[node ")), len(lines))
    text = "".join(lines[:first]) + ext + "\n" + "".join(lines[first:])
    text = text.rstrip("\n") + \
        '\n\n[node name="ActionBar" parent="." instance=ExtResource("L_action_bar")]\n'
    base.write_text(text, encoding="utf-8")
    print("  OK gắn ActionBar vào nodes/hud/base.tscn")
    # dọn bản cũ đã gắn rời vào từng HUD (tránh 2 thanh nút)
    for name in HUD_SCENES:
        path = HUD_DIR / name
        if not path.exists():
            continue
        t = path.read_text(encoding="utf-8")
        if 'name="ActionBar"' not in t:
            continue
        t = "".join(l for l in t.splitlines(keepends=True)
                    if 'name="ActionBar"' not in l and 'res://nodes/hud/action_bar.tscn' not in l)
        path.write_text(t, encoding="utf-8")
        print(f"  dọn ActionBar rời khỏi {name}")


if __name__ == "__main__":
    build_bar()
    attach_to_huds()
