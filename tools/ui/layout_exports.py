"""Tool: quản lý binding `@export` node giữa SCENE MÀN ⇄ SCENE LAYOUT theo hướng.

Mục đích: mỗi màn (settings/ranking/daily/…) có 2 scene bố cục
`scenes/layout/portrait/<màn>.tscn` + `scenes/layout/landscape/<màn>.tscn`, mỗi scene gắn
script `scripts/scenes/layout/<màn>_layout.gd`. Tool này:
  · dump   — in CÂY NODE đầy đủ của scene layout (đã trộn scene cha + mở node instance con)
  · check  — đối chiếu SPEC (danh sách node cần bind) với cây node CẢ 2 hướng, báo thiếu/sai kiểu
  · apply  — ghi `node_paths=PackedStringArray(...)` + binding vào đúng 2 scene layout
             + ghi danh sách `@export` vào script layout
  · script — chuyển script màn sang dùng `layout.<tên>` (bỏ khai báo local, rút gọn _bind_refs)

Cách dùng:
  python tools/ui/layout_exports.py dump [màn ...]
  python tools/ui/layout_exports.py check [màn ...]
  python tools/ui/layout_exports.py apply [màn ...]     (thêm --dry-run để chỉ xem)
  python tools/ui/layout_exports.py script [màn ...]    (mặc định --dry-run)
"""

from __future__ import annotations

import pathlib
import re
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ROOT = pathlib.Path(__file__).resolve().parents[2]

ATTR_RE = re.compile(r'([\w_]+)="((?:[^"\\]|\\.)*)"')
INST_RE = re.compile(r'instance=ExtResource\("([^"]+)"\)')
NODEPATHS_RE = re.compile(r"node_paths=PackedStringArray\(([^)]*)\)")
SCRIPT_LINE_RE = re.compile(r'^script = ExtResource\("([^"]+)"\)$', re.M)

# ---------------------------------------------------------------------------
# Chuỗi kế thừa của các lớp dựng sẵn hay dùng (để kiểm tra kiểu cho đúng)
# ---------------------------------------------------------------------------
BUILTIN_CHAIN: dict[str, list[str]] = {
    "Button": ["BaseButton", "Control", "CanvasItem", "Node"],
    "TextureButton": ["BaseButton", "Control", "CanvasItem", "Node"],
    "CheckBox": ["Button", "BaseButton", "Control", "CanvasItem", "Node"],
    "Label": ["Control", "CanvasItem", "Node"],
    "RichTextLabel": ["Control", "CanvasItem", "Node"],
    "TextureRect": ["Control", "CanvasItem", "Node"],
    "ColorRect": ["Control", "CanvasItem", "Node"],
    "NinePatchRect": ["Control", "CanvasItem", "Node"],
    "TextureProgressBar": ["Range", "Control", "CanvasItem", "Node"],
    "HSlider": ["Slider", "Range", "Control", "CanvasItem", "Node"],
    "VSlider": ["Slider", "Range", "Control", "CanvasItem", "Node"],
    "ProgressBar": ["Range", "Control", "CanvasItem", "Node"],
    "HBoxContainer": ["BoxContainer", "Container", "Control", "CanvasItem", "Node"],
    "VBoxContainer": ["BoxContainer", "Container", "Control", "CanvasItem", "Node"],
    "GridContainer": ["Container", "Control", "CanvasItem", "Node"],
    "MarginContainer": ["Container", "Control", "CanvasItem", "Node"],
    "PanelContainer": ["Container", "Control", "CanvasItem", "Node"],
    "CenterContainer": ["Container", "Control", "CanvasItem", "Node"],
    "ScrollContainer": ["Container", "Control", "CanvasItem", "Node"],
    "Panel": ["Control", "CanvasItem", "Node"],
    "HFlowContainer": ["FlowContainer", "Container", "Control", "CanvasItem", "Node"],
    "VFlowContainer": ["FlowContainer", "Container", "Control", "CanvasItem", "Node"],
}


def unquote(value: str) -> str:
    return value.replace('\\"', '"')


def read_text(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8").lstrip("\ufeff")


def parse(scene_rel: str) -> tuple[dict[str, tuple[str, str]], list[str]]:
    """→ (ext_resources: id→(type, path), các block [node ...])"""
    text = read_text(ROOT / scene_rel)
    ext: dict[str, tuple[str, str]] = {}
    for line in text.splitlines():
        if line.startswith("[ext_resource"):
            attrs = dict(ATTR_RE.findall(line))
            if "id" in attrs and "path" in attrs:
                ext[attrs["id"]] = (attrs.get("type", ""), attrs["path"])
    blocks = [b for b in re.split(r"(?=^\[node )", text, flags=re.M) if b.startswith("[node ")]
    return ext, blocks


def node_tree(scene_rel: str, seen: set[str] | None = None) -> dict[str, dict]:
    """Cây node ĐẦY ĐỦ của scene (đã trộn scene cha kế thừa + mở các node instance con).

    Khoá = đường dẫn TƯƠNG ĐỐI từ root (root = ""), đúng như NodePath ghi trong .tscn.
    """
    seen = seen if seen is not None else set()
    if scene_rel in seen:
        return {}
    seen.add(scene_rel)
    ext, blocks = parse(scene_rel)

    def make_rec(block: str) -> dict:
        head = block.splitlines()[0]
        attrs = dict(ATTR_RE.findall(head))
        inst = INST_RE.search(head)
        script = SCRIPT_LINE_RE.search(block)
        return {
            "name": unquote(attrs["name"]) if "name" in attrs else "",
            "parent": unquote(attrs["parent"]) if "parent" in attrs else None,
            "type": attrs.get("type"),
            "inst": ext[inst.group(1)][1] if inst else None,
            "script": ext[script.group(1)][1] if script else None,
        }

    recs = [make_rec(b) for b in blocks]
    if not recs:
        return {}
    root = recs[0]
    root_key = root["name"]
    nodes: dict[str, dict] = {}

    def add(path: str, rec: dict) -> None:
        nodes[path] = dict(rec, path=path)

    if root["inst"]:
        base = node_tree(root["inst"].replace("res://", ""), seen)
        for path, rec in base.items():
            if path == "":
                continue
            add(path, rec)

    def expand(prefix: str, scene: str) -> None:
        sub = node_tree(scene.replace("res://", ""), seen)
        for path, rec in sub.items():
            if path == "":
                continue
            full = f"{prefix}/{path}" if prefix else path
            add(full, dict(rec, name=path.split("/")[-1]))

    for rec in recs:
        if rec["parent"] is None:
            full = ""
        elif rec["parent"] == ".":
            full = rec["name"]
        else:
            full = f"{rec['parent']}/{rec['name']}"
        add(full, rec)
        if rec["inst"]:
            expand(full, rec["inst"])
    if root_key and "" in nodes:
        nodes[""] = dict(nodes[""], name=root_key)
    return nodes


# ---------------------------------------------------------------------------
# Tra node theo SPEC: ["path", "A/B"] · ["name", "Nút"] · ["child", "Cha", "Con"]
# hoặc {"portrait": spec, "landscape": spec} khi 2 hướng khác nhau.
# ---------------------------------------------------------------------------
def find_nodes(nodes: dict[str, dict], spec) -> list[str]:
    kind = spec[0]
    if kind == "path":
        return [spec[1]] if spec[1] in nodes else []
    if kind == "name":
        return [p for p in nodes if nodes[p]["name"] == spec[1]]
    if kind == "child":
        hits = []
        for path in find_nodes(nodes, ["name", spec[1]]):
            cand = f"{path}/{spec[2]}" if path else spec[2]
            if cand in nodes:
                hits.append(cand)
        return hits
    raise ValueError(f"spec lạ: {spec!r}")


# ---------------------------------------------------------------------------
# Kiểu của node (đọc script class_name/extends + scene instance tiếp)
# ---------------------------------------------------------------------------
_CLASS_CACHE: dict[str, dict[str, tuple[str, str]]] = {}


def project_classes() -> dict[str, tuple[str, str]]:
    """class_name → (file .gd, lớp cha ghi trong `extends`)"""
    if "all" in _CLASS_CACHE:
        return _CLASS_CACHE["all"]
    found: dict[str, tuple[str, str]] = {}
    for folder in ("scripts", "nodes"):
        for path in (ROOT / folder).rglob("*.gd"):
            text = read_text(path)
            m_cls = re.search(r"^class_name (\w+)", text, re.M)
            if not m_cls:
                continue
            m_ext = re.search(r"^extends ([\w\.]+)", text, re.M)
            rel = path.relative_to(ROOT).as_posix()
            found[m_cls.group(1)] = (rel, m_ext.group(1) if m_ext else "")
    _CLASS_CACHE["all"] = found
    return found


def type_chain(nodes: dict[str, dict], rec: dict, depth: int = 0) -> list[str]:
    """Chuỗi kiểu của node: [lớp cụ thể, …, lớp dựng sẵn]."""
    if depth > 6:
        return []
    classes = project_classes()
    script = rec.get("script")
    if script is None and rec.get("inst"):
        sub = node_tree(rec["inst"].replace("res://", ""))
        root_rec = sub.get("")
        if root_rec:
            return type_chain(sub, root_rec, depth + 1)
    if script:
        rel = script.replace("res://", "")
        text = read_text(ROOT / rel)
        m_cls = re.search(r"^class_name (\w+)", text, re.M)
        m_ext = re.search(r"^extends ([\w\.]+)", text, re.M)
        chain: list[str] = [m_cls.group(1)] if m_cls else []
        parent = m_ext.group(1) if m_ext else ""
        while parent and parent in classes:
            chain.append(parent)
            parent = classes[parent][1]
        if parent:
            chain.append(parent)
            chain.extend(BUILTIN_CHAIN.get(parent, []))
        return chain
    if rec.get("type"):
        return [rec["type"]] + BUILTIN_CHAIN.get(rec["type"], [])
    return []


def type_ok(chain: list[str], expected: str) -> bool:
    if not chain:
        return True  # không xác định được → bỏ qua
    return expected in chain or expected == chain[0]


# ---------------------------------------------------------------------------
# SPEC: per-màn danh sách node cần bind
#   (tên_export, "Kiểu", spec_hoặc_{portrait,landscape})
# ---------------------------------------------------------------------------
SPECS: dict[str, dict] = {
    "settings": {
        "layout_class": "SettingsLayout",
        "layout_script": "scripts/scenes/layout/settings_layout.gd",
        "items": [
            ("btn_back", "TextureButton", ["path", "TopBar/Back"]),
            ("content_root", "Control", ["name", "Content"]),
            ("bgm_slider", "HSlider", ["child", "BgmRow", "Slider"]),
            ("bgm_value", "Label", ["child", "BgmRow", "Value"]),
            ("sfx_slider", "HSlider", ["child", "SfxRow", "Slider"]),
            ("sfx_value", "Label", ["child", "SfxRow", "Value"]),
            ("chk_haptic", "TextureButton", ["child", "HapticRow", "Check"]),
            ("chk_auto_mark", "TextureButton", ["child", "AutoMarkRow", "Check"]),
            ("chk_glow", "TextureButton", ["child", "GlowRow", "Check"]),
            ("btn_language", "TextureButton", ["child", "LangRow", "LangButton"]),
            ("lbl_language", "Label", ["child", "LangButton", "LangValue"]),
            ("lbl_player_id", "Label", ["child", "PlayerRow", "PlayerIdValue"]),
            ("btn_guide", "TextureButton", ["name", "Guide"]),
            ("btn_credits", "TextureButton", ["name", "Credits"]),
            ("btn_reset", "TextureButton", ["name", "Reset"]),
            ("lbl_version", "Label", ["child", "Stamp", "Label"]),
        ],
    },
    "main": {
        "layout_class": "MainLayout",
        "layout_script": "scripts/scenes/layout/main_layout.gd",
        "bind_func": "_bind_layout",
        "items": [
            ("logo", "TextureRect", ["name", "Logo"]),
            ("btn_play", "BaseButton", ["name", "Play"]),
            ("btn_dungeon", "BaseButton", ["name", "Dungeon"]),
            ("btn_daily", "BaseButton", ["name", "DailyChallenge"]),
            ("btn_leaderboard", "BaseButton", ["name", "Leaderboard"]),
            ("btn_shop", "BaseButton", ["name", "Shop"]),
            ("btn_settings", "BaseButton", ["name", "Settings"]),
            ("btn_archivement", "BaseButton", ["name", "Archivement"]),
            ("badge_count_label", "Label", ["child", "Archivement", "Count"]),
            ("badge_play", "Label", ["child", "Play", "Badge"]),
            ("badge_dungeon", "Label", ["child", "Dungeon", "Badge"]),
            ("badge_daily", "Label", ["child", "DailyChallenge", "Badge"]),
            ("stamp_panel", "Control", ["name", "Stamp"]),
            ("stamp_label", "Label", ["child", "Stamp", "Label"]),
            ("game_mode_box", "Control", {"portrait": ["name", "GameMode"], "landscape": ["name", "Menu"]}),
            ("other_box", "Control", {"portrait": ["name", "Other"], "landscape": ["name", "Utils"]}),
        ],
    },
    "ranking": {
        "layout_class": "RankingLayout",
        "layout_script": "scripts/scenes/layout/ranking_layout.gd",
        "items": [
            ("btn_back", "BaseButton", ["path", "TopBar/Back"]),
            ("tabs_box", "HBoxContainer", ["path", "Sheet/Tabs"]),
            ("podium", "Control", ["path", "Sheet/Podium"]),
            ("scroll", "ScrollContainer", ["path", "Sheet/Scroll"]),
            ("rows_box", "VBoxContainer", ["path", "Sheet/Scroll/Rows"]),
            ("my_rank_bar", "TextureRect", ["path", "Sheet/MyRank"]),
        ],
    },
    "chapters": {
        "layout_class": "ChaptersLayout",
        "layout_script": "scripts/scenes/layout/chapters_layout.gd",
        "items": [
            ("btn_back", "BaseButton", ["name", "Back"]),
            ("cards_box", "Container", ["name", "Cards"]),
            ("lbl_wallet", "Label", ["child", "Wallet", "Count"]),
            ("btn_continue", "BaseButton", ["name", "ContinueButton"]),
            ("lbl_continue", "Label", ["child", "ContinueButton", "Label"]),
            ("list", "Control", ["name", "List"]),
            ("top_bar", "Control", ["name", "TopBar"]),
            ("wallet_bar", "Control", ["name", "Wallet"]),
            ("banner", "Control", ["name", "Banner"]),
        ],
    },
    "daily": {
        "layout_class": "DailyLayout",
        "layout_script": "scripts/scenes/layout/daily_layout.gd",
        "items": [
            ("btn_back", "BaseButton", ["path", "Panel/HUD/Content/Information/TopBar/Back"]),
            ("calendar", "DailyCalendar", ["name", "Calendar"]),
            ("missions", "Control", ["name", "Missions"]),
            ("lbl_streak", "Label",
                ["path", "Panel/HUD/Content/Information/TopBar/StreakBadge/StreakContainer/Streak"]),
            ("lbl_date", "Label", ["child", "DateTag", "Label"]),
            ("lbl_mode", "Label", ["name", "Mode"]),
            ("lbl_reward", "Label", ["child", "Reward", "Label"]),
            ("rows_host", "Control", ["name", "Rows"]),
            ("lbl_progress", "Label", ["name", "ProgressLabel"]),
            ("bar_progress", "TextureProgressBar", ["name", "ProgressBar"]),
            ("lbl_claim", "Label", ["name", "Claim"]),
            ("btn_play", "BaseButton", ["name", "Play"]),
            ("lbl_play", "Label", ["child", "Play", "Label"]),
            ("icon_play", "TextureRect", ["child", "Play", "Icon"]),
            ("streak_badge", "Control", ["name", "StreakBadge"]),
        ],
    },
    "shop": {
        "layout_class": "ShopLayout",
        "layout_script": "scripts/scenes/layout/shop_layout.gd",
        "items": [
            ("btn_back", "BaseButton", ["path", "TopBar/Back"]),
            ("tabs_box", "HBoxContainer", ["path", "Tabs"]),
            ("list_box", "VBoxContainer", ["path", "Content/List"]),
            ("scroll", "ScrollContainer", ["path", "Content"]),
            ("wallet_count", "Label", ["child", "Wallet", "Count"]),
            ("wallet_plus", "BaseButton", ["child", "Wallet", "Plus"]),
            ("pager", "Control", ["name", "Pager"]),
            ("page_label", "Label", ["child", "Pager", "PageLabel"]),
            ("btn_prev", "BaseButton", ["child", "Pager", "Prev"]),
            ("btn_next", "BaseButton", ["child", "Pager", "Next"]),
            ("dots_box", "HBoxContainer", ["child", "Pager", "Dots"]),
            ("btn_gift", "BaseButton", ["child", "GiftBanner", "GiftBtn"]),
            ("top_bar", "Control", ["name", "TopBar"]),
            ("wallet_bar", "Control", ["name", "Wallet"]),
            ("gift_banner", "Control", ["name", "GiftBanner"]),
            ("tab_line", "ColorRect", ["name", "TabLine"]),
        ],
    },
    "archivement": {
        "layout_class": "ArchivementLayout",
        "layout_script": "scripts/scenes/layout/archivement_layout.gd",
        "items": [
            ("btn_back", "BaseButton", ["path", "TopBar/Back"]),
            ("overview_bar", "Control", ["path", "Sheet/Overview/Bar"]),
            ("overview_fill", "TextureRect", ["path", "Sheet/Overview/Bar/Fill"]),
            ("overview_pct", "Label", ["path", "Sheet/Overview/Percent"]),
            ("overview_summary", "Label", ["path", "Sheet/Overview/Summary"]),
            ("tabs_box", "HBoxContainer", ["path", "Sheet/Tabs"]),
            ("card_area", "Control", ["path", "Sheet/CardArea"]),
            ("scroll", "ScrollContainer", ["path", "Sheet/CardArea/Scroll"]),
            ("pages_host", "HBoxContainer", ["path", "Sheet/CardArea/Scroll/Pages"]),
            ("dots_box", "HBoxContainer", ["path", "Sheet/Dots"]),
            ("empty_label", "Label", ["path", "Sheet/EmptyLabel"]),
            ("stamp_label", "Label", ["path", "Sheet/Footer/Stamp/Label"]),
        ],
    },
    "credit": {
        "layout_class": "CreditLayout",
        "layout_script": "scripts/scenes/layout/credit_layout.gd",
        "items": [
            ("btn_back", "TextureButton", ["path", "TopBar/Back"]),
            ("theme_value", "Label", ["path", "Panel/Content/VBox/MusicSection/ThemeRow/Value"]),
            ("track_value", "Label", ["path", "Panel/Content/VBox/MusicSection/TrackRow/Value"]),
            ("version_label", "Label", ["path", "Panel/Content/VBox/Footer/Stamp/VersionLabel"]),
            ("content_root", "Control", ["path", "Panel/Content"]),
        ],
    },
    "debug": {
        "layout_class": "DebugLayout",
        "layout_script": "scripts/scenes/layout/debug_layout.gd",
        "items": [
            ("btn_back", "TextureButton", ["path", "TopBar/Back"], "_btn_back"),
            ("lbl_title", "Label", ["path", "TopBar/Title"], "_lbl_title"),
            ("rows_box", "VBoxContainer", ["path", "Panel/Content/Scroll/Rows"], "_rows"),
            ("lbl_stats", "Label", ["path", "Panel/Content/Stats"], "_lbl_stats"),
            ("lbl_footer", "Label", ["path", "Panel/Content/Footer"], "_lbl_footer"),
        ],
    },
    "splash": {
        "layout_class": "SplashLayout",
        "layout_script": "scripts/scenes/layout/splash_layout.gd",
        "items": [
            ("studio_label", "Label", ["path", "Panel/StudioLabel"]),
            ("logo_container", "Control", ["path", "Panel/LogoContainer"]),
            ("logo", "TextureRect", ["path", "Panel/LogoContainer/Logo"]),
            ("pencil", "TextureRect", ["path", "Panel/LogoContainer/Pencil"]),
            ("title_label", "Label", ["path", "Panel/Title"]),
            ("tagline_label", "Label", ["path", "Panel/Tagline"]),
            ("stamp_label", "Label", ["path", "Panel/Stamp/Label"]),
            ("touch_button", "TextureButton", ["path", "TouchButton"]),
            ("fade_overlay", "ColorRect", ["path", "FadeOverlay"], None, "optional"),
        ],
    },
    "title": {
        "layout_class": "TitleLayout",
        "layout_script": "scripts/scenes/layout/title_layout.gd",
        "items": [
            ("logo_container", "Control", ["path", "Panel/LogoContainer"]),
            ("logo", "TextureRect", ["path", "Panel/LogoContainer/Logo"]),
            ("pencil", "TextureRect", ["path", "Panel/LogoContainer/Pencil"]),
            ("title_label", "Label", ["path", "Panel/Title"]),
            ("subtitle_label", "Label", ["path", "Panel/Subtitle"]),
            ("tap_container", "Control", ["path", "Panel/TapContainer"]),
            ("play_icon", "TextureRect", ["path", "Panel/TapContainer/PlayIcon"]),
            ("tap_label", "Label", ["path", "Panel/TapContainer/TapLabel"]),
            ("stamp_label", "Label", ["path", "Panel/Stamp/Label"]),
            ("touch_button", "TextureButton", ["path", "TouchButton"], None, "optional"),
            ("fade_overlay", "ColorRect", ["path", "FadeOverlay"], None, "optional"),
        ],
    },
    # Màn CHƠI: 2 hướng dùng 2 script KHÁC NHAU (đều kế thừa GameSceneLayout) ⇒ không ghi script.
    "game": {
        "layout_class": "GameSceneLayout",
        "layout_script": {
            "portrait": "scripts/layout/portrait/game.gd",
            "landscape": "scripts/layout/landscape/game_layout.gd",
        },
        "skip_script": True,
        "items": [
            ("status_bar", "Control", ["name", "Status"]),
            ("hud_slot", "Control", ["name", "Information"]),
            ("board_holder", "Control", ["name", "BoardSlot"]),
            ("pause_btn", "BaseButton", ["name", "Pause"]),
            ("instruction_btn", "BaseButton", ["name", "Instruction"]),
            ("level_label", "Label", ["child", "Title", "LevelLabel"]),
            ("subtitle_label", "Label", ["child", "Title", "Subtitle"]),
        ],
    },
}


def item_name(item) -> str:
    return item[0]


def item_old(item) -> str:
    return item[3] if len(item) > 3 and item[3] else item[0]


def item_optional(item) -> bool:
    return bool(item[4]) if len(item) > 4 else False


def render_layout_script(spec: dict) -> str:
    lines = [f"class_name {spec['layout_class']}", "extends BaseLayout", ""]
    for item in spec["items"]:
        lines.append(f"@export var {item_name(item)}: {item[1]} = null")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Ghi binding vào .tscn: cập nhật header root + thêm `script = ExtResource(...)`
# ---------------------------------------------------------------------------
def patch_scene(scene_rel: str, bindings: dict[str, str], script_rel: str, dry: bool) -> None:
    path = ROOT / scene_rel
    text = read_text(path)
    nl = "\r\n" if "\r\n" in text else "\n"
    script_res = "res://" + script_rel

    # 1) ext_resource cho script layout (thêm nếu chưa có)
    ext_lines = [l for l in text.splitlines() if l.startswith("[ext_resource")]
    ext_id = ""
    for line in ext_lines:
        if f'path="{script_res}"' in line:
            ext_id = dict(ATTR_RE.findall(line)).get("id", "")
    added_ext = False
    if not ext_id:
        used = {dict(ATTR_RE.findall(l)).get("id", "") for l in ext_lines}
        ext_id, i = "2_layout", 1
        while ext_id in used:
            i += 1
            ext_id = f"2_layout{i}"
        lines = text.splitlines(keepends=True)
        last_ext = max(i for i, l in enumerate(lines) if l.startswith("[ext_resource"))
        lines.insert(last_ext + 1, f'[ext_resource type="Script" path="{script_res}" id="{ext_id}"]{nl}')
        text = "".join(lines)
        added_ext = True

    lines = text.splitlines(keepends=True)
    hdr = next(i for i, l in enumerate(lines) if l.startswith("[node "))
    ends = [i for i in range(hdr + 1, len(lines)) if lines[i].startswith("[node ")]
    block_end = ends[0] if ends else len(lines)

    # 2) `script = ExtResource(...)` trong block root (cảnh báo nếu là script KHÁC)
    script_at = None
    for i in range(hdr + 1, block_end):
        if lines[i].startswith("script = ExtResource("):
            script_at = i
            cur_id = re.search(r'"([^"]+)"', lines[i]).group(1)
            cur = next((l for l in ext_lines if f'id="{cur_id}"' in l), "?")
            if script_res not in cur:
                print(f"  !! {scene_rel}: root đang gắn script KHÁC → {cur.strip()}")
                return
    if script_at is None:
        lines.insert(hdr + 1, f'script = ExtResource("{ext_id}"){nl}')

    # 3) node_paths= trong header root (giữ tên cũ, thêm tên mới)
    hdr = next(i for i, l in enumerate(lines) if l.startswith("[node "))
    ends = [i for i in range(hdr + 1, len(lines)) if lines[i].startswith("[node ")]
    block_end = ends[0] if ends else len(lines)
    header = lines[hdr]
    names = list(bindings)
    m = NODEPATHS_RE.search(header)
    if m:
        existing = re.findall(r'"([^"]+)"', m.group(1))
        names = existing + [n for n in names if n not in existing]
    attr = "node_paths=PackedStringArray(" + ", ".join(f'"{n}"' for n in names) + ")"
    if m:
        header = header[: m.start()] + attr + header[m.end():]
    elif " instance=" in header:
        header = header.replace(" instance=", f" {attr} instance=", 1)
    else:
        body = header.rstrip("\r\n")
        header = body[:-1] + f" {attr}]" + nl
    lines[hdr] = header

    # 4) xoá dòng binding cũ cùng tên rồi chèn lại sau dòng `script =`
    lines = [l for i, l in enumerate(lines)
             if not (hdr < i < block_end and re.match(r"^\w+ = NodePath\(", l))]
    ends = [i for i in range(hdr + 1, len(lines)) if lines[i].startswith("[node ")]
    block_end = ends[0] if ends else len(lines)
    script_at = next(i for i in range(hdr + 1, block_end) if lines[i].startswith("script = ExtResource("))
    lines[script_at + 1: script_at + 1] = [f'{n} = NodePath("{p}"){nl}' for n, p in bindings.items()]

    print(f"  {'(dry) ' if dry else ''}{scene_rel}: {len(bindings)} binding"
          + (" (+ ext script mới)" if added_ext else ""))
    if not dry:
        path.write_text("".join(lines), encoding="utf-8")


def write_layout_script(spec: dict, dry: bool) -> None:
    if spec.get("skip_script"):
        print(f"  . {spec['layout_script'] if isinstance(spec['layout_script'], str) else 'script riêng theo hướng'} (giữ nguyên, không ghi)")
        return
    path = ROOT / spec["layout_script"]
    new_text = render_layout_script(spec)
    old_text = read_text(path) if path.exists() else ""
    if old_text.strip() == new_text.strip():
        print(f"  = {spec['layout_script']} (đã đúng)")
        return
    tag = "+" if not old_text.strip() else "~"
    print(f"  {'(dry) ' if dry else ''}{tag} {spec['layout_script']} ({len(spec['items'])} export)")
    if not dry:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(new_text, encoding="utf-8")


def cmd_apply(screens: list[str], dry: bool) -> int:
    bad = 0
    for screen in screens:
        spec = SPECS.get(screen)
        if spec is None:
            print(f"!! chưa có SPEC cho màn '{screen}'")
            bad += 1
            continue
        print(f"\n=== {screen} ===")
        ok = True
        for orientation in ("portrait", "landscape"):
            scene_rel = f"scenes/layout/{orientation}/{screen}.tscn"
            tree = node_tree(scene_rel)
            bindings: dict[str, str] = {}
            for item in spec["items"]:
                name, expected, target = item_name(item), item[1], item[2]
                one = target[orientation] if isinstance(target, dict) else target
                hits = find_nodes(tree, one)
                chain = type_chain(tree, tree[hits[0]]) if len(hits) == 1 else []
                if len(hits) != 1:
                    if item_optional(item):
                        print(f"  (bỏ trống) {orientation}: '{name}' — layout không có node (optional)")
                        continue
                    print(f"  !! {orientation}: '{name}' → {len(hits)} kết quả cho {one}")
                    ok = False
                elif not type_ok(chain, expected):
                    print(f"  !! {orientation}: '{name}' khai {expected} nhưng node là {'/'.join(chain[:3])}")
                    ok = False
                else:
                    bindings[name] = hits[0]
            script_rel = spec["layout_script"]
            if isinstance(script_rel, dict):
                script_rel = script_rel[orientation]
            if ok:
                patch_scene(scene_rel, bindings, script_rel, dry)
        if ok:
            write_layout_script(spec, dry)
        bad += 0 if ok else 1
    print(f"\n>>> {'OK' if bad == 0 else str(bad) + ' màn lỗi'}")
    return bad


# ---------------------------------------------------------------------------
# Chuyển script màn sang dùng `layout.<tên>`
# ---------------------------------------------------------------------------
def mask_code(text: str) -> str:
    """Bản sao CÙNG ĐỘ DÀI, mọi ký tự trong chuỗi/ghi chú đổi thành khoảng trắng."""
    out = list(text)
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if ch == "#":
            j = text.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
        elif ch in "\"'":
            quote = ch
            triple = text[i: i + 3] == quote * 3
            j = i + (3 if triple else 1)
            while j < n:
                if not triple and text[j] == "\\":
                    j += 2
                    continue
                if triple and text[j: j + 3] == quote * 3:
                    j += 3
                    break
                if not triple and text[j] in (quote, "\n"):
                    j += 1
                    break
                j += 1
            for k in range(i, min(j, n)):
                if out[k] != "\n":
                    out[k] = " "
            i = j
        else:
            i += 1
    return "".join(out)


DECL_RE = re.compile(r"^\s*(?:#\s*)?(?:@export\s+)?(?:static\s+)?var (\w+)\s*(?::\s*[\w\[\]\. ]+)?\s*=\s*null\s*$")


def convert_screen(screen: str, write: bool) -> None:
    spec = SPECS[screen]
    path = ROOT / "scripts/scenes" / (screen + ".gd")
    text = read_text(path)
    olds = [item_old(i) for i in spec["items"]]

    # 1) rút gọn thân hàm bind → chỉ còn lấy layout đang hiển thị
    bind_func = spec.get("bind_func", "_bind_refs")
    m_func = re.search(r"(?m)^func " + re.escape(bind_func) + r"\(\)\s*->\s*void:\s*\n", text)
    if not m_func:
        print(f"  !! {screen}: không thấy func {bind_func}()")
        return
    lines = text.splitlines(keepends=True)
    start = text[: m_func.start()].count("\n")
    idx, last_body = start + 1, start
    while idx < len(lines):
        line = lines[idx]
        if line.startswith("\t"):
            last_body = idx
            idx += 1
            continue
        if line.strip() == "":
            idx += 1
            continue
        break
    new_body = (
        f"func {bind_func}() -> void:\n"
        f"\tlayout = active_layout() as {spec['layout_class']}\n"
        f"\tif layout == null:\n"
        f"\t\tpush_warning(\"{spec.get('scene_class', screen)}: bố cục chưa gắn {spec['layout_class']}"
        f" — thiếu binding trong scenes/layout/<hướng>/{screen}.tscn\")\n"
    )
    lines[start: last_body + 1] = [new_body]

    # 2) gộp vùng khai báo node thành 1 dòng `var layout`
    decl_idx = [i for i, l in enumerate(lines) if DECL_RE.match(l) and DECL_RE.match(l).group(1) in olds]
    if decl_idx:
        first, last = decl_idx[0], decl_idx[-1]
        for i in range(first, last + 1):
            line = lines[i]
            m_decl = DECL_RE.match(line)
            if line.strip() == "" or line.lstrip().startswith("#") or (m_decl and m_decl.group(1) in olds):
                continue
            print(f"  !! {screen}: dòng {i + 1} xen giữa vùng khai báo — dừng, chưa chuyển: {line.strip()}")
            return
        start_cmt = first
        while start_cmt > 0 and lines[start_cmt - 1].lstrip().startswith("#"):
            start_cmt -= 1
        comment = (
            f"## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng\n"
            f"## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/{screen}.tscn`\n"
            f"## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.\n"
            f"var layout: {spec['layout_class']} = null\n"
        )
        lines[start_cmt: last + 1] = [comment]
    else:
        print(f"  !! {screen}: không thấy vùng khai báo node cũ")

    text = "".join(lines)

    # 3) đổi mọi chỗ dùng tên cũ → `layout.<tên mới>` (bỏ qua chuỗi/ghi chú)
    count = 0
    for _ in range(10):
        changed = 0
        for item in spec["items"]:
            old, new = item_old(item), item_name(item)
            # PHẢI tính lại mask SAU MỖI tên: mỗi lần thay đổi độ dài chuỗi nên vị trí cũ hết hiệu lực
            masked = mask_code(text)
            pat = re.compile(r"(?<![\w.])" + re.escape(old) + r"\b")
            hits = list(pat.finditer(masked))
            for m in reversed(hits):  # thay từ cuối lên để vị trí phía trước còn nguyên
                text = text[: m.start()] + f"layout.{new}" + text[m.end():]
            changed += len(hits)
        count += changed
        if changed == 0:
            break

    # chốt chặn: nếu thấy dấu hiệu chèn sai vị trí thì KHÔNG ghi
    for bad_pat in ("layout.layout", "var layout.", "func layout.", "= layout.layout"):
        if bad_pat in text:
            print(f"  !! {screen}.gd: nghi vấn hỏng ({bad_pat}) — không ghi, cần xem lại SPEC")
            return

    print(f"  {'(dry) ' if not write else ''}{screen}.gd: {len(spec['items'])} node"
          f" · {count} chỗ dùng đổi sang layout.<tên>" + ("" if write else "   (--write để ghi)"))
    if write:
        path.write_text(text, encoding="utf-8")


def cmd_dump(screens: list[str]) -> None:
    for screen in screens:
        for orientation in ("portrait", "landscape"):
            scene = f"scenes/layout/{orientation}/{screen}.tscn"
            if not (ROOT / scene).exists():
                print(f"!! thiếu {scene}")
                continue
            nodes = node_tree(scene)
            print(f"\n=== {scene}  ({len(nodes) - 1} node) ===")
            for path in sorted(nodes):
                if path == "":
                    continue
                rec = nodes[path]
                chain = type_chain(nodes, rec)
                extra = f"  ← {'/'.join(chain[:3])}" if chain else ""
                inst = f"  [inst {rec['inst'].split('/')[-1]}]" if rec["inst"] else ""
                print(f"  {path}{inst}{extra}")


def cmd_check(screens: list[str]) -> int:
    bad = 0
    for screen in screens:
        spec = SPECS.get(screen)
        if spec is None:
            print(f"!! chưa có SPEC cho màn '{screen}'")
            bad += 1
            continue
        print(f"\n=== {screen} ===")
        trees = {o: node_tree(f"scenes/layout/{o}/{screen}.tscn") for o in ("portrait", "landscape")}
        for item in spec["items"]:
            name, expected, target = item_name(item), item[1], item[2]
            row: list[str] = []
            for orientation in ("portrait", "landscape"):
                one = target.get(orientation, target) if isinstance(target, dict) else target
                hits = find_nodes(trees[orientation], one)
                if len(hits) == 1:
                    chain = type_chain(trees[orientation], trees[orientation][hits[0]])
                    mark = "OK" if type_ok(chain, expected) else f"KIỂU? ({'/'.join(chain[:3])})"
                    if not type_ok(chain, expected):
                        bad += 1
                    row.append(f"{orientation}: {hits[0]} [{mark}]")
                elif item_optional(item):
                    row.append(f"{orientation}: (không có — optional)")
            print(f"  {name:<18} " + " | ".join(row))
    print(f"\n>>> {'OK' if bad == 0 else str(bad) + ' vấn đề'}")
    return bad


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return
    cmd = sys.argv[1]
    args = [a for a in sys.argv[2:] if not a.startswith("--")]
    dry = "--dry-run" in sys.argv
    write = "--write" in sys.argv
    screens = args or list(SPECS)
    if cmd == "dump":
        cmd_dump(args or sorted({p.stem for p in (ROOT / "scenes/layout/portrait").glob("*.tscn")}))
    elif cmd == "check":
        sys.exit(1 if cmd_check(screens) else 0)
    elif cmd == "apply":
        sys.exit(1 if cmd_apply(screens, dry) else 0)
    elif cmd == "script":
        for screen in screens:
            convert_screen(screen, write)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
