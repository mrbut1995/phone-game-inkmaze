"""Chuyển THẺ CHẾ ĐỘ + NÚT CÔNG CỤ màn Main sang 9-SLICE (guide/GUIDE.MD §3.1).

Vì `TextureButton` KHÔNG hỗ trợ 9-slice, tool này:
  1. Sinh `StyleBoxTexture` (9-slice) cho từng ART dùng trong màn Main → `resources/settings/styles/menu/`
     · Thẻ chế độ: `card_mode_*.svg` (804×310; thân thẻ 780×260 tại (12,30); tag ở góc trên-trái tới x=277,
       badge ở góc dưới-phải từ x=577 ⇒ patch trái 277 · phải 227 · trên/dưới 60 — art KHÔNG bị kéo méo).
     · Nút công cụ: `btn_menu_*.svg` (230×130; thân 210×110 tại (10,10), rx 20) ⇒ patch 40 mọi phía.
  2. Đổi node `TextureButton` → `Button` + gán `theme_override_styles/{normal,hover,pressed,focus,disabled}`
     trong 2 layout `scenes/orientation/{portrait,landscape}/main.tscn`.
  3. Thêm `custom_minimum_size` để giữ đúng cỡ cũ (thẻ cao 310, nút công cụ 230×130).

Usage: python tools/ui/menu_buttons_9slice.py
"""

from __future__ import annotations

import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
STYLE_DIR = ROOT / "resources" / "settings" / "styles" / "menu"
ART_DIR = "res://assets/images/main"

CARD_MARGINS = (277, 60, 227, 60)  # trái · trên · phải · dưới (px trong texture 804×310)
UTIL_MARGINS = (40, 40, 40, 40)  # texture 230×130

# art -> (tên file stylebox, patch margins)
STYLEBOXES: dict[str, tuple[str, tuple[int, int, int, int]]] = {
    "card_mode_level_normal": ("card_level_normal", CARD_MARGINS),
    "card_mode_level_pressed": ("card_level_pressed", CARD_MARGINS),
    "card_mode_level_focus": ("card_level_focus", CARD_MARGINS),
    "card_mode_level_disabled": ("card_level_disabled", CARD_MARGINS),
    "card_mode_dungeon_normal": ("card_dungeon_normal", CARD_MARGINS),
    "card_mode_dungeon_pressed": ("card_dungeon_pressed", CARD_MARGINS),
    "card_mode_dungeon_focus": ("card_dungeon_focus", CARD_MARGINS),
    "card_mode_daily_normal": ("card_daily_normal", CARD_MARGINS),
    "card_mode_daily_pressed": ("card_daily_pressed", CARD_MARGINS),
    "card_mode_disabled": ("card_disabled", CARD_MARGINS),
    "btn_menu_leaderboard": ("util_leaderboard", UTIL_MARGINS),
    "btn_menu_utility_normal": ("util_normal", UTIL_MARGINS),
    "btn_menu_utility_pressed": ("util_pressed", UTIL_MARGINS),
    "btn_menu_utility_focus": ("util_focus", UTIL_MARGINS),
    "btn_menu_settings": ("util_settings", UTIL_MARGINS),
}

# node -> {state: art}  (state = normal/hover/pressed/focus/disabled)
BUTTONS: dict[str, dict[str, str]] = {
    "Play": {
        "normal": "card_mode_level_normal", "hover": "card_mode_level_normal",
        "pressed": "card_mode_level_pressed", "focus": "card_mode_level_focus",
        "disabled": "card_mode_level_disabled",
    },
    "Dungeon": {
        "normal": "card_mode_dungeon_normal", "hover": "card_mode_dungeon_normal",
        "pressed": "card_mode_dungeon_pressed", "focus": "card_mode_dungeon_focus",
        "disabled": "card_mode_disabled",
    },
    "DailyChallenge": {
        "normal": "card_mode_daily_normal", "hover": "card_mode_daily_normal",
        "pressed": "card_mode_daily_pressed", "focus": "card_mode_dungeon_focus",
        "disabled": "card_mode_disabled",
    },
    "Leaderboard": {
        "normal": "btn_menu_leaderboard", "hover": "btn_menu_leaderboard",
        "pressed": "btn_menu_leaderboard", "focus": "btn_menu_leaderboard",
        "disabled": "btn_menu_leaderboard",
    },
    "Shop": {
        "normal": "btn_menu_utility_normal", "hover": "btn_menu_utility_normal",
        "pressed": "btn_menu_utility_pressed", "focus": "btn_menu_utility_focus",
        "disabled": "btn_menu_utility_normal",
    },
    "Settings": {
        "normal": "btn_menu_settings", "hover": "btn_menu_settings",
        "pressed": "btn_menu_settings", "focus": "btn_menu_settings",
        "disabled": "btn_menu_settings",
    },
}

CARD_NAMES = {"Play", "Dungeon", "DailyChallenge"}
UTIL_NAMES = {"Leaderboard", "Shop", "Settings"}

SCENES = [
    ROOT / "scenes" / "orientation" / "portrait" / "main.tscn",
    ROOT / "scenes" / "orientation" / "landscape" / "main.tscn",
]


def write_styleboxes() -> None:
    STYLE_DIR.mkdir(parents=True, exist_ok=True)
    for art, (name, margins) in STYLEBOXES.items():
        text = (
            '[gd_resource type="StyleBoxTexture" format=3]\n\n'
            f'[ext_resource type="Texture2D" path="{ART_DIR}/{art}.svg" id="1_tex"]\n\n'
            "[resource]\n"
            'texture = ExtResource("1_tex")\n'
            f"texture_margin_left = {float(margins[0])}\n"
            f"texture_margin_top = {float(margins[1])}\n"
            f"texture_margin_right = {float(margins[2])}\n"
            f"texture_margin_bottom = {float(margins[3])}\n"
            "axis_stretch_horizontal = 0\n"
            "axis_stretch_vertical = 0\n"
        )
        (STYLE_DIR / f"{name}.tres").write_text(text, encoding="utf-8")


def _stylebox_path(art: str) -> str:
    name = STYLEBOXES[art][0]
    return f"res://resources/settings/styles/menu/{name}.tres"


def _ensure_ext_resources(header: str, arts: set[str]) -> str:
    for art in sorted(arts):
        sid = f"S_{STYLEBOXES[art][0]}"
        if f'id="{sid}"' in header:
            continue
        header += f'[ext_resource type="StyleBoxTexture" path="{_stylebox_path(art)}" id="{sid}"]\n'
    return header


def _convert_button(block: str, name: str) -> str:
    lines = block.splitlines(keepends=True)
    out: list[str] = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("texture_") or stripped.startswith("ignore_texture_size") or stripped.startswith("stretch_mode"):
            continue  # TextureButton-only props (đã thay bằng stylebox)
        if line.startswith("[node ") and 'type="TextureButton"' in line:
            line = line.replace('type="TextureButton"', 'type="Button"')
        out.append(line)
    block = "".join(out)
    states = BUTTONS[name]
    extra = ""
    if name in CARD_NAMES and "custom_minimum_size" not in block:
        extra += "custom_minimum_size = Vector2(0, 310)\n"
    if name in UTIL_NAMES and 'parent="Panel/Other"' in block and "custom_minimum_size" not in block:
        extra += "custom_minimum_size = Vector2(230, 130)\n"
    if extra and not block.endswith("\n"):
        block += "\n"
    block += extra
    for state in ["normal", "hover", "pressed", "focus", "disabled"]:
        art = states[state]
        sid = f"S_{STYLEBOXES[art][0]}"
        block += f'theme_override_styles/{state} = ExtResource("{sid}")\n'
    return block


def patch_scene(path: pathlib.Path) -> int:
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    first = next(i for i, l in enumerate(lines) if l.startswith("[node "))
    header = "".join(lines[:first])
    blocks = [b for b in re.split(r"(?=^\[node )", "".join(lines[first:]), flags=re.M) if b.strip()]

    used_arts: set[str] = set()
    changed = 0
    result: list[str] = []
    for block in blocks:
        m = re.match(r'\[node name="([^"]+)"', block)
        name = m.group(1) if m else ""
        if name in BUTTONS:
            used_arts.update(BUTTONS[name].values())
            block = _convert_button(block, name)
            changed += 1
        result.append(block)

    header = _ensure_ext_resources(header, used_arts)
    path.write_text(header + "\n" + "".join(result), encoding="utf-8")
    return changed


def main() -> None:
    write_styleboxes()
    print(f"OK: sinh {len(STYLEBOXES)} StyleBoxTexture trong {STYLE_DIR.relative_to(ROOT)}")
    for scene in SCENES:
        if not scene.exists():
            print(f"  (bỏ qua, không có) {scene.relative_to(ROOT)}")
            continue
        n = patch_scene(scene)
        print(f"OK: {scene.relative_to(ROOT)} — đổi {n} nút sang Button + 9-slice")


if __name__ == "__main__":
    main()
