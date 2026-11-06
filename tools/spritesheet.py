#!/usr/bin/env python3
"""Spritesheet + frame-animation helper (instruction R4/R5). Stdlib only; PNG work needs Pillow.

Pipeline (pick the line that matches what you have):
  NO ART YET   placeholder  -> sheet SVG with *moving* frames + spec           (python tools/spritesheet.py placeholder ...)
  FRAME FILES  pack-dir     -> sheet + spec from a folder of <anim>_<NN>.png    (python tools/spritesheet.py pack-dir ...)
  ASEPRITE     from-aseprite-> spec from the exported JSON (tags = animations)  (python tools/spritesheet.py from-aseprite ...)
  SHEET + GRID inspect      -> grid, blank cells; then write the spec by hand
  ALL          frames       -> spec -> SpriteFrames .tres   |   names -> StringName consts   |   preview -> contact sheet PNG

  placeholder characters/hero --frame 16x16 --cols 6 --role player --rows idle_down:2,walk_down:6,attack_down:4,death_down:4
  placeholder characters/hero --rows idle_down:2,walk_down:6,idle_side:2,walk_side:6,idle_up:2,walk_up:6 --shape rounded
  pack-dir characters/slime assets/images/characters/slime_frames/ [--frame 16x16] [--fps walk=10,attack=14] [--once attack,hit]
  from-aseprite assets/images/hero.json --texture assets/images/hero.png --name characters/hero
  inspect assets/images/hero_sheet.png [--frame 16x16 | --grid 4x7]      # size, grid, BLANK cells (PNG + Pillow)
  frames data/animations/specs/hero_frames.json                        # -> data/animations/hero_frames.tres
  names data/animations/specs/hero_frames.json                         # -> const ANIM_WALK_DOWN: StringName = &"walk_down" ...
  preview data/animations/specs/hero_frames.json                       # -> docs/reports/preview_hero_frames.png (PNG sheets, Pillow)
  example                                                              # print an example spec

Spec (grid mode):    {"texture": "assets/.../hero_sheet.png", "frame_size": [16,16] | "grid": [cols,rows], "margin": [0,0], "separation": [0,0],
                      "animations": {"idle_down": {"frames": [0], "fps": 4, "loop": true},
                                     "walk_down": {"row": 1, "start": 0, "count": 6, "fps": 8, "loop": true},
                                     "attack_down": {"frames": [12, 13, {"index": 14, "duration": 2}], "fps": 12, "loop": false}}}
Spec (regions mode): {"texture": "...", "regions": [[x,y,w,h], ...], "animations": {"walk": {"frames": [0,1,2], "fps": 8}}}   (irregular atlas, Aseprite)
Frame index = row * cols + col. Animation names: [a-z0-9_]+ ; use "<state>_<direction>" with direction in down|up|left|right|side
so the runtime blocks (FrameAnimUtils, BaseFrameAnimationController, FrameTextureRect) can pick and mirror them.
Placeholder -> real art: change "texture" in the spec to the real sheet and run `frames` again. Nothing else changes.
"""
from __future__ import annotations

import argparse
import json
import math
import re
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

from _common import ROOT, norm, setup_stdout

COLORS = {"player": "#4C99FF", "enemy": "#E64D4D", "neutral": "#B3B3B3", "collectible": "#FFD933", "obstacle": "#8C6640"}
SVG_NS = "http://www.w3.org/2000/svg"
DIRS = {"down": (0, 1), "up": (0, -1), "left": (-1, 0), "right": (1, 0), "side": (1, 0)}
ONE_SHOT = ("attack", "hit", "death", "die", "cast", "open", "close", "spawn", "land", "pop")
DEFAULT_FPS = {"idle": 4, "walk": 8, "run": 12, "attack": 12, "hit": 12, "death": 8, "die": 8, "jump": 8}
NAME_RX = re.compile(r"^[a-z0-9_]+$")
EXAMPLE = {
    "texture": "assets/images-placeholder/characters/hero_sheet.svg", "frame_size": [16, 16],
    "animations": {"idle_down": {"frames": [0], "fps": 4, "loop": True},
                   "walk_down": {"row": 1, "start": 0, "count": 4, "fps": 8, "loop": True}}}


# ------------------------------------------------------------------ small helpers
def pil():
    try:
        from PIL import Image  # type: ignore
        return Image
    except ImportError:
        return None


def image_size(path: Path):
    data = path.read_bytes()
    if data[:8] == b"\x89PNG\r\n\x1a\n":
        w, h = struct.unpack(">II", data[16:24])
        return int(w), int(h)
    if path.suffix.lower() == ".svg":
        root = ET.fromstring(data.decode("utf-8", errors="replace"))

        def num(v):
            m = re.match(r"^\s*([\d.]+)", v or "")
            return float(m.group(1)) if m else None
        w, h = num(root.get("width")), num(root.get("height"))
        if (w is None or h is None) and root.get("viewBox"):
            vb = [float(x) for x in re.split(r"[ ,]+", root.get("viewBox").strip())]
            w, h = vb[2], vb[3]
        if w is None or h is None:
            raise ValueError("SVG needs width/height or viewBox")
        return int(round(w)), int(round(h))
    raise ValueError(f"unsupported image type '{path.suffix}' (PNG and SVG are supported)")


def parse_pair(text: str, what: str, sep: str = "x"):
    m = re.match(r"^(\d+)" + sep + r"(\d+)$", text or "")
    if not m:
        raise SystemExit(f"ERROR: {what} must look like 16{sep}16")
    return int(m.group(1)), int(m.group(2))


def num(v: float) -> str:
    return f"{v:.2f}".rstrip("0").rstrip(".") if v != int(v) else str(int(v))


def split_name(anim: str):
    """'walk_down' -> ('walk', 'down'); 'idle' -> ('idle', '')."""
    head, _, tail = anim.rpartition("_")
    return (head, tail) if head and tail in DIRS else (anim, "")


def default_loop(anim: str) -> bool:
    return split_name(anim)[0] not in ONE_SHOT


def default_fps(anim: str, override=None) -> float:
    return float(override) if override else float(DEFAULT_FPS.get(split_name(anim)[0], 8))


def kv_list(text: str, what: str) -> dict:
    out = {}
    for part in [p for p in (text or "").split(",") if p.strip()]:
        k, _, v = part.partition("=")
        if not v:
            raise SystemExit(f"ERROR: {what} entries look like name=12")
        out[k.strip()] = float(v)
    return out


def add_manifest(rel_file: str, used_by: str, size: str, frames: int):
    manifest = ROOT / "assets" / "images-placeholder" / "MANIFEST.md"
    if not manifest.exists():
        manifest.parent.mkdir(parents=True, exist_ok=True)
        manifest.write_text("# Placeholder manifest\n\n| File | Used by (scene/resource + property) | Size | Pivot | Frames | Status | Final path |\n|---|---|---|---|---|---|---|\n", encoding="utf-8")
    text = manifest.read_text(encoding="utf-8")
    if f"| {rel_file} |" in text:
        return
    with manifest.open("a", encoding="utf-8", newline="\n") as f:
        f.write(f"| {rel_file} | {used_by} | {size} | center | {frames} | placeholder | - |\n")


def write_spec(spec_path: Path, spec: dict):
    spec_path.parent.mkdir(parents=True, exist_ok=True)
    spec_path.write_text(json.dumps(spec, indent=2) + "\n", encoding="utf-8", newline="\n")


# ------------------------------------------------------------------ geometry (grid or regions)
class Grid:
    def __init__(self, size, spec):
        w, h = size
        self.regions = None
        if "regions" in spec:
            self.regions = [tuple(int(v) for v in r) for r in spec["regions"]]
            for i, (x, y, rw, rh) in enumerate(self.regions):
                if x < 0 or y < 0 or rw <= 0 or rh <= 0 or x + rw > w or y + rh > h:
                    raise ValueError(f"region {i} {list(self.regions[i])} is outside the {w}x{h} texture")
            self.cols, self.rows, self.fw, self.fh = len(self.regions), 1, 0, 0
            self.count = len(self.regions)
            return
        mx, my = spec.get("margin", [0, 0])
        sx, sy = spec.get("separation", [0, 0])
        if "grid" in spec:
            self.cols, self.rows = spec["grid"]
            fw = (w - 2 * mx - (self.cols - 1) * sx) / self.cols
            fh = (h - 2 * my - (self.rows - 1) * sy) / self.rows
            if fw != int(fw) or fh != int(fh) or fw <= 0 or fh <= 0:
                raise ValueError(f"sheet {w}x{h} does not divide into a {self.cols}x{self.rows} grid (frame would be {fw}x{fh})")
            self.fw, self.fh = int(fw), int(fh)
        else:
            self.fw, self.fh = spec["frame_size"]
            self.cols = (w - 2 * mx + sx) // (self.fw + sx)
            self.rows = (h - 2 * my + sy) // (self.fh + sy)
            if self.cols < 1 or self.rows < 1:
                raise ValueError(f"frame {self.fw}x{self.fh} does not fit in sheet {w}x{h}")
        self.mx, self.my, self.sx, self.sy = mx, my, sx, sy
        self.count = self.cols * self.rows

    def rect(self, index: int):
        if self.regions is not None:
            return self.regions[index]
        col, row = index % self.cols, index // self.cols
        return (self.mx + col * (self.fw + self.sx), self.my + row * (self.fh + self.sy), self.fw, self.fh)


def expand_frames(name: str, anim: dict, grid: Grid, errors: list) -> list:
    """-> list of (index, relative duration)"""
    out = []
    if "frames" in anim:
        for f in anim["frames"]:
            out.append((int(f["index"]), float(f.get("duration", 1.0))) if isinstance(f, dict) else (int(f), 1.0))
    elif "row" in anim:
        if grid.regions is not None:
            errors.append(f"{name}: 'row' needs a grid spec, use 'frames' with regions")
            return out
        start, count = int(anim.get("start", 0)), int(anim.get("count", grid.cols))
        out = [(int(anim["row"]) * grid.cols + start + i, 1.0) for i in range(count)]
    else:
        errors.append(f"{name}: needs 'frames' or 'row'")
    for idx, _ in out:
        if not 0 <= idx < grid.count:
            errors.append(f"{name}: frame index {idx} is outside the sheet (0..{grid.count - 1})")
    if not out:
        errors.append(f"{name}: no frames")
    return out


# ------------------------------------------------------------------ placeholder frames with motion
def tint(hex_color: str, k: float) -> str:
    hx = hex_color.lstrip("#")
    rgb = [int(hx[i:i + 2], 16) for i in (0, 2, 4)]
    rgb = [max(0, min(255, int(c * k if k <= 1 else c + (255 - c) * (k - 1)))) for c in rgb]
    return "#%02X%02X%02X" % tuple(rgb)


def pose(state: str, direction: str, i: int, n: int, fw: int, fh: int):
    """Procedural pose of the placeholder body: (dx, dy, sx, sy, rot_deg, opacity, flash)."""
    p = i / max(n, 1)
    a = 2 * math.pi * p
    vx, vy = DIRS.get(direction, (0, 1))
    dx = dy = rot = 0.0
    sx = sy = 1.0
    op, flash = 1.0, False
    if state == "idle":
        dy, sy = -math.sin(a) * 0.04 * fh, 1 + 0.04 * math.sin(a)
    elif state in ("walk", "run"):
        k = 0.10 if state == "walk" else 0.14
        dy, sx, sy = -abs(math.sin(a)) * k * fh, 1 + 0.08 * math.sin(a), 1 - 0.08 * math.sin(a)
        rot = (8 if state == "run" else 0) * vx
    elif state in ("attack", "cast"):
        ext = math.sin(math.pi * p) * 0.22
        dx, dy = vx * ext * fw, vy * ext * fh
        sx = sy = 1 + 0.12 * math.sin(math.pi * p)
    elif state == "hit":
        dx, flash = (-1 if i % 2 else 1) * 0.06 * fw, i % 2 == 0
        op = 0.8 if i % 2 else 1.0
    elif state in ("death", "die"):
        s = max(0.15, 1 - 0.85 * p)
        sx = sy = s
        op, rot = max(0.1, 1 - p * 0.9), 90 * p
    elif state in ("jump", "fall"):
        dy = -math.sin(math.pi * p) * 0.25 * fh
    else:
        sx = sy = 1 + 0.1 * math.sin(a)
    return dx, dy, sx, sy, rot, op, flash


def frame_svg(ox: int, oy: int, fw: int, fh: int, anim: str, i: int, n: int, fill: str, shape: str, label: bool) -> str:
    state, direction = split_name(anim)
    dx, dy, sx, sy, rot, op, flash = pose(state, direction, i, n, fw, fh)
    cx, cy = ox + fw / 2, oy + fh / 2
    r = min(fw, fh) * 0.32
    color = tint(fill, 1.6) if flash else fill
    t = f'translate({num(cx + dx)} {num(cy + dy)})' + (f' rotate({num(rot)})' if rot else "") + f' scale({num(sx)} {num(sy)})'
    if shape == "rounded":
        body = f'<rect x="{num(-r)}" y="{num(-r)}" width="{num(2 * r)}" height="{num(2 * r)}" rx="{num(r * 0.35)}"'
    elif shape == "diamond":
        body = f'<polygon points="0,{num(-r)} {num(r)},0 0,{num(r)} {num(-r)},0"'
    else:
        body = f'<circle r="{num(r)}"'
    vx, vy = DIRS.get(direction, (0, 1))
    out = [f'<g transform="{t}" opacity="{num(op)}">{body} fill="{color}" stroke="#202020" stroke-width="{num(max(0.5, r / 8))}"/>',
           f'<circle cx="{num(vx * r * 0.7)}" cy="{num(vy * r * 0.7)}" r="{num(r * 0.25)}" fill="#FFF"/></g>']
    if label:
        fs = max(3, fh // 6)
        out.append(f'<text x="{ox + 1}" y="{oy + fs}" font-size="{fs}" fill="#FFF" opacity="0.7" font-family="sans-serif">{i}</text>')
    return "".join(out)


def sheet_svg(cols: int, rows: list, fw: int, fh: int, role: str, shape: str) -> str:
    parts = [f'<svg xmlns="{SVG_NS}" width="{cols * fw}" height="{len(rows) * fh}" viewBox="0 0 {cols * fw} {len(rows) * fh}">']
    for r, (anim, n) in enumerate(rows):
        for c in range(n):
            parts.append(frame_svg(c * fw, r * fh, fw, fh, anim, c, n, COLORS[role], shape, fw >= 16))
    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def parse_rows(text: str, cols: int):
    """cols = 0 -> auto (widest row). Returns [(name, frame_count)]; rows without a count use `cols` (or 4 when auto)."""
    rows = []
    for item in [p.strip() for p in (text or "").split(",") if p.strip()]:
        name, _, n = item.partition(":")
        if not NAME_RX.match(name):
            raise SystemExit(f"ERROR: bad animation name '{name}' (use [a-z0-9_])")
        count = int(n) if n else (cols or 4)
        if count < 1 or (cols and count > cols):
            raise SystemExit(f"ERROR: '{item}': frame count must be 1..{cols or 'N'} (--cols)")
        rows.append((name, count))
    return rows


def cmd_placeholder(a):
    fw, fh = parse_pair(a.frame, "--frame")
    rows = parse_rows(a.rows, a.cols) or [("default", a.cols or 4)]
    cols = a.cols or max(n for _, n in rows)
    rel = a.name.strip("/").replace("\\", "/")
    out = ROOT / "assets" / "images-placeholder" / f"{rel}_sheet.svg"
    spec_path = ROOT / "data" / "animations" / "specs" / f"{Path(rel).name}_frames.json"
    if (out.exists() or spec_path.exists()) and not a.force:
        print(f"ERROR: {out.relative_to(ROOT).as_posix()} or the spec exists (use --force)")
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(sheet_svg(cols, rows, fw, fh, a.role, a.shape), encoding="utf-8", newline="\n")
    anims = {n: {"row": r, "start": 0, "count": c, "fps": default_fps(n, a.fps), "loop": default_loop(n)} for r, (n, c) in enumerate(rows)}
    write_spec(spec_path, {"texture": out.relative_to(ROOT).as_posix(), "frame_size": [fw, fh], "animations": anims})
    add_manifest(f"{rel}_sheet.svg", f"data/animations/{Path(rel).name}_frames.tres", f"{cols * fw}x{len(rows) * fh}", sum(c for _, c in rows))
    print(f"created {out.relative_to(ROOT).as_posix()} ({cols}x{len(rows)} cells of {fw}x{fh}, frames move: bob/lunge/flash/fade by state)")
    print(f"created {spec_path.relative_to(ROOT).as_posix()}  -> next: python tools/spritesheet.py frames {spec_path.relative_to(ROOT).as_posix()}")
    return 0


# ------------------------------------------------------------------ pack-dir / pack
def natural_key(path: Path):
    return [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", path.name)]


def group_frames(files):
    """<anim>_<NN>.<ext> -> {anim: [files sorted by NN]} (a file with no number is a 1-frame animation)."""
    groups: dict = {}
    for f in sorted(files, key=natural_key):
        m = re.match(r"^(.*?)[_-]?(\d+)$", f.stem)
        anim = (m.group(1) if m and m.group(1) else f.stem).lower().replace("-", "_").replace(" ", "_")
        groups.setdefault(anim, []).append(f)
    return groups


def build_sheet(cells, fw: int, fh: int, cols: int, rel: str):
    """cells: list of rows (list of Path). Returns (out_path, is_svg)."""
    rows = len(cells)
    flat = [f for row in cells for f in row]
    if all(f.suffix.lower() == ".svg" for f in flat):
        ET.register_namespace("", SVG_NS)
        out = ROOT / "assets" / "images-placeholder" / f"{rel}_sheet.svg"
        root = ET.Element(f"{{{SVG_NS}}}svg", {"width": str(cols * fw), "height": str(rows * fh), "viewBox": f"0 0 {cols * fw} {rows * fh}"})
        for r, row in enumerate(cells):
            for c, f in enumerate(row):
                src = ET.fromstring(f.read_text(encoding="utf-8"))
                w, h = image_size(f)
                nested = ET.SubElement(root, f"{{{SVG_NS}}}svg", {"x": str(c * fw), "y": str(r * fh), "width": str(fw), "height": str(fh),
                                                                  "viewBox": src.get("viewBox") or f"0 0 {w} {h}"})
                for child in list(src):
                    nested.append(child)
        out.parent.mkdir(parents=True, exist_ok=True)
        ET.ElementTree(root).write(out, encoding="utf-8", xml_declaration=False)
        return out, True
    Image = pil()
    if Image is None:
        raise SystemExit("ERROR: packing PNG frames needs Pillow (pip install pillow)")
    sheet = Image.new("RGBA", (cols * fw, rows * fh), (0, 0, 0, 0))
    for r, row in enumerate(cells):
        for c, f in enumerate(row):
            img = Image.open(f).convert("RGBA")
            if img.size != (fw, fh):
                raise SystemExit(f"ERROR: {f.name} is {img.size[0]}x{img.size[1]}, expected {fw}x{fh} (all frames must be the same size; pad them)")
            sheet.paste(img, (c * fw, r * fh))
    out = ROOT / "assets" / "images" / f"{rel}_sheet.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(out)
    return out, False


def cmd_pack(a):
    """Legacy: explicit frame files in one row-major sheet (no spec)."""
    fw, fh = parse_pair(a.frame, "--frame")
    files = [ROOT / norm(f) for f in a.frames_files]
    missing = [f.name for f in files if not f.exists()]
    if missing:
        print("ERROR: not found: " + ", ".join(missing))
        return 1
    cols = a.cols or len(files)
    cells = [files[i:i + cols] for i in range(0, len(files), cols)]
    rel = a.name.strip("/").replace("\\", "/")
    out, svg = build_sheet(cells, fw, fh, cols, rel)
    if svg:
        add_manifest(f"{rel}_sheet.svg", "packed from " + ", ".join(f.name for f in files)[:60], f"{cols * fw}x{len(cells) * fh}", len(files))
    print(f"packed {len(files)} frames -> {out.relative_to(ROOT).as_posix()} ({cols}x{len(cells)} of {fw}x{fh})")
    return 0


def cmd_pack_dir(a):
    folder = ROOT / norm(a.folder)
    if not folder.is_dir():
        print(f"ERROR: {a.folder} is not a folder")
        return 1
    exts = {".png", ".svg"}
    files = [f for f in folder.iterdir() if f.suffix.lower() in exts]
    if not files:
        print("ERROR: no .png/.svg frames found")
        return 1
    groups = group_frames(files)
    bad = [k for k in groups if not NAME_RX.match(k)]
    if bad:
        print("ERROR: animation names from file names must be [a-z0-9_]: " + ", ".join(bad))
        return 1
    order = [s.strip() for s in a.order.split(",") if s.strip()] if a.order else sorted(groups)
    unknown = [o for o in order if o not in groups]
    if unknown:
        print("ERROR: --order names not found: " + ", ".join(unknown))
        return 1
    order += [k for k in sorted(groups) if k not in order]
    if a.frame:
        fw, fh = parse_pair(a.frame, "--frame")
    else:
        fw, fh = image_size(groups[order[0]][0])
    cols = max(len(g) for g in groups.values())
    rel = a.name.strip("/").replace("\\", "/")
    out, svg = build_sheet([groups[k] for k in order], fw, fh, cols, rel)
    fps, once = kv_list(a.fps, "--fps"), {s.strip() for s in a.once.split(",") if s.strip()}
    anims = {}
    for r, k in enumerate(order):
        loop = (k not in once) if once else default_loop(k)
        anims[k] = {"row": r, "start": 0, "count": len(groups[k]), "fps": fps.get(k, default_fps(k)), "loop": loop}
    spec_path = ROOT / "data" / "animations" / "specs" / f"{Path(rel).name}_frames.json"
    write_spec(spec_path, {"texture": out.relative_to(ROOT).as_posix(), "frame_size": [fw, fh], "animations": anims})
    if svg:
        add_manifest(f"{rel}_sheet.svg", f"data/animations/{Path(rel).name}_frames.tres", f"{cols * fw}x{len(order) * fh}", sum(len(g) for g in groups.values()))
    print(f"packed {sum(len(g) for g in groups.values())} frames in {len(order)} animations -> {out.relative_to(ROOT).as_posix()} ({cols}x{len(order)} of {fw}x{fh})")
    for k in order:
        print(f"  {k}: {len(groups[k])} frames @ {anims[k]['fps']:g} fps{' loop' if anims[k]['loop'] else ''}")
    print(f"created {spec_path.relative_to(ROOT).as_posix()}  -> next: python tools/spritesheet.py frames {spec_path.relative_to(ROOT).as_posix()}")
    return 0


# ------------------------------------------------------------------ Aseprite
def cmd_from_aseprite(a):
    jpath = ROOT / norm(a.json)
    data = json.loads(jpath.read_text(encoding="utf-8"))
    raw = data["frames"]
    frames = list(raw.values()) if isinstance(raw, dict) else list(raw)
    if not frames:
        print("ERROR: no frames in the JSON")
        return 1
    meta = data.get("meta", {})
    tex = norm(a.texture) if a.texture else norm(str(Path(a.json).with_name(meta.get("image", jpath.stem + ".png"))))
    if not (ROOT / tex).exists():
        print(f"ERROR: texture {tex} not found (use --texture)")
        return 1
    if any(f.get("trimmed") for f in frames):
        print("ERROR: frames are trimmed; export from Aseprite with 'Trim' off (frames must keep the full cell size)")
        return 1
    regions = [[f["frame"]["x"], f["frame"]["y"], f["frame"]["w"], f["frame"]["h"]] for f in frames]
    durations = [max(1, int(f.get("duration", 100))) for f in frames]
    base = min(durations)
    tags = meta.get("frameTags", [])
    anims = {}

    def add(name: str, idx: list):
        name = re.sub(r"[^a-z0-9_]+", "_", name.lower()).strip("_") or "default"
        item = [i if durations[i] == base else {"index": i, "duration": round(durations[i] / base, 3)} for i in idx]
        anims[name] = {"frames": item, "fps": round(1000 / base, 3), "loop": default_loop(name)}
    if tags:
        for t in tags:
            idx = list(range(t["from"], t["to"] + 1))
            d = t.get("direction", "forward")
            if d == "reverse":
                idx.reverse()
            elif d == "pingpong" and len(idx) > 2:
                idx = idx + idx[-2:0:-1]
            add(t["name"], idx)
    else:
        add("default", list(range(len(frames))))
    rel = a.name.strip("/").replace("\\", "/") if a.name else jpath.stem
    spec_path = ROOT / "data" / "animations" / "specs" / f"{Path(rel).name}_frames.json"
    write_spec(spec_path, {"texture": tex, "regions": regions, "animations": anims})
    print(f"created {spec_path.relative_to(ROOT).as_posix()}: {len(frames)} frames, {len(anims)} animations (base {base} ms -> {1000 / base:g} fps)")
    print("  loop flags are guessed from names (attack/hit/death = once); edit the spec if wrong")
    print(f"  next: python tools/spritesheet.py frames {spec_path.relative_to(ROOT).as_posix()}")
    return 0


# ------------------------------------------------------------------ inspect / frames / names / preview
def cmd_example(_):
    print(json.dumps(EXAMPLE, indent=2))
    return 0


def blank_cells(path: Path, grid: Grid):
    Image = pil()
    if Image is None or path.suffix.lower() != ".png":
        return None
    img = Image.open(path).convert("RGBA")
    alpha = img.getchannel("A")
    blank = []
    for i in range(grid.count):
        x, y, w, h = grid.rect(i)
        if alpha.crop((x, y, x + w, y + h)).getbbox() is None:
            blank.append(i)
    return blank


def cmd_inspect(a):
    path = ROOT / norm(a.image)
    w, h = image_size(path)
    print(f"{norm(a.image)}: {w}x{h}")
    spec = None
    if a.frame:
        fw, fh = parse_pair(a.frame, "--frame")
        print(f"frame {fw}x{fh}: {w // fw} cols x {h // fh} rows = {(w // fw) * (h // fh)} frames" + ("" if (w % fw == 0 and h % fh == 0) else "  (WARNING: size is not a multiple of the frame)"))
        spec = {"frame_size": [fw, fh]}
    elif a.grid:
        c, r = parse_pair(a.grid, "--grid")
        print(f"grid {c}x{r}: frame {w / c:g}x{h / r:g}" + ("" if (w % c == 0 and h % r == 0) else "  (WARNING: does not divide evenly)"))
        spec = {"grid": [c, r]}
    else:
        for s in (8, 16, 24, 32, 48, 64, 96, 128):
            if w % s == 0 and h % s == 0 and w >= s and h >= s:
                print(f"  frame {s}x{s}: {w // s} cols x {h // s} rows = {(w // s) * (h // s)} frames")
    if spec:
        try:
            grid = Grid((w, h), spec)
        except ValueError as exc:
            print(f"ERROR {exc}")
            return 1
        blank = blank_cells(path, grid)
        if blank is None:
            print("  blank-cell check skipped (needs a PNG and Pillow)")
        else:
            print(f"  blank cells: {blank if blank else 'none'}  (cells with no visible pixel: do not use them in an animation)")
    return 0


def load_spec(spec_arg: str):
    spec_path = ROOT / norm(spec_arg)
    return spec_path, json.loads(spec_path.read_text(encoding="utf-8"))


def cmd_frames(a):
    spec_path, spec = load_spec(a.spec)
    tex = norm(spec["texture"])
    errors: list = []
    if not (ROOT / tex).exists():
        print(f"ERROR texture {tex} not found")
        return 1
    try:
        grid = Grid(image_size(ROOT / tex), spec)
    except (ValueError, OSError, ET.ParseError, KeyError) as exc:
        print(f"ERROR {exc}")
        return 1
    regions: dict = {}
    anim_defs = []
    if not spec.get("animations"):
        print("ERROR spec has no animations")
        return 1
    for name, anim in spec["animations"].items():
        if not NAME_RX.match(name):
            errors.append(f"bad animation name '{name}' (use [a-z0-9_])")
        fps = float(anim.get("fps", 8))
        if fps <= 0:
            errors.append(f"{name}: fps must be > 0")
        frames = expand_frames(name, anim, grid, errors)
        for idx, _ in frames:
            regions.setdefault(idx, f"AtlasTexture_f{idx}")
        anim_defs.append((name, fps, bool(anim.get("loop", True)), frames))
    blank = blank_cells(ROOT / tex, grid) if not errors else None
    for name, _, _, frames in anim_defs:
        used_blank = [i for i, _ in frames if blank and i in blank]
        if used_blank:
            errors.append(f"{name}: uses blank cells {used_blank} (empty sheet cells; fix 'count' or the art)")
    if errors:
        for e in errors:
            print("ERROR " + e)
        return 1
    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(regions) + 2} format=3]', "",
             f'[ext_resource type="Texture2D" path="res://{tex}" id="1_sheet"]', ""]
    for idx in sorted(regions):
        x, y, w, h = grid.rect(idx)
        lines += [f'[sub_resource type="AtlasTexture" id="{regions[idx]}"]', 'atlas = ExtResource("1_sheet")', f"region = Rect2({x}, {y}, {w}, {h})", ""]
    blocks = []
    for name, fps, loop, frames in anim_defs:
        fr = ",\n".join('{\n"duration": %s,\n"texture": SubResource("%s")\n}' % (repr(float(d)), regions[i]) for i, d in frames)
        blocks.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % (fr, "true" if loop else "false", name, repr(float(fps))))
    lines += ["[resource]", "animations = [" + ", ".join(blocks) + "]"]
    out = (ROOT / (norm(a.out) if a.out else f"data/animations/{spec_path.stem}.tres")).resolve()
    if ROOT.resolve() not in out.parents:
        print("ERROR: --out must be inside the project")
        return 1
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")
    shape = f"{grid.cols}x{grid.rows} grid, frame {grid.fw}x{grid.fh}" if grid.regions is None else f"{grid.count} regions"
    print(f"wrote {out.relative_to(ROOT.resolve()).as_posix()}: {len(anim_defs)} animations, {len(regions)} frames used of {grid.count} ({shape})")
    for name, fps, loop, frames in anim_defs:
        print(f"  {name}: {len(frames)} frames @ {fps:g} fps{' loop' if loop else ''}")
    return 0


def cmd_names(a):
    _, spec = load_spec(a.spec)
    states: dict = {}
    for name in spec.get("animations", {}):
        print(f'const ANIM_{name.upper()}: StringName = &"{name}"')
        s, d = split_name(name)
        states.setdefault(s, []).append(d or "-")
    print("\n# states -> directions (for play_state(state, direction)):")
    for s, ds in states.items():
        print(f"#   {s}: {', '.join(ds)}")
    return 0


def cmd_preview(a):
    Image = pil()
    if Image is None:
        print("ERROR: preview needs Pillow (pip install pillow)")
        return 2
    spec_path, spec = load_spec(a.spec)
    tex = ROOT / norm(spec["texture"])
    if tex.suffix.lower() != ".png":
        print("ERROR: preview needs a PNG sheet (SVG sheets cannot be rasterised without extra libraries)")
        return 2
    grid = Grid(image_size(tex), spec)
    sheet = Image.open(tex).convert("RGBA")
    scale, pad = a.scale, 2
    rows = []
    for name, anim in spec["animations"].items():
        errs: list = []
        rows.append((name, expand_frames(name, anim, grid, errs)))
    cw = max(grid.rect(0)[2], max(grid.rect(i)[2] for i in range(grid.count))) * scale
    chh = max(grid.rect(i)[3] for i in range(grid.count)) * scale
    width = pad + max(len(f) for _, f in rows) * (cw + pad)
    img = Image.new("RGBA", (width, pad + len(rows) * (chh + pad)), (40, 40, 40, 255))
    for r, (_, frames) in enumerate(rows):
        for c, (idx, _) in enumerate(frames):
            x, y, w, h = grid.rect(idx)
            cell = sheet.crop((x, y, x + w, y + h)).resize((w * scale, h * scale), Image.NEAREST)
            img.paste(cell, (pad + c * (cw + pad), pad + r * (chh + pad)), cell)
    out = ROOT / "docs" / "reports" / f"preview_{spec_path.stem}.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"wrote {out.relative_to(ROOT).as_posix()} (one row per animation, in spec order: " + ", ".join(n for n, _ in rows) + ")")
    return 0


def main() -> int:
    setup_stdout()
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("example")
    p = sub.add_parser("inspect"); p.add_argument("image"); p.add_argument("--frame", default=""); p.add_argument("--grid", default="")
    p = sub.add_parser("placeholder"); p.add_argument("name"); p.add_argument("--frame", default="16x16"); p.add_argument("--cols", type=int, default=0, help="columns; default = widest row")
    p.add_argument("--rows", default="", help="animation names, one per row; optional frame count: walk_down:6,idle_down:2")
    p.add_argument("--role", choices=sorted(COLORS), default="neutral"); p.add_argument("--shape", choices=["circle", "rounded", "diamond"], default="circle")
    p.add_argument("--fps", type=float, default=0, help="override the per-state default fps"); p.add_argument("--force", action="store_true")
    p = sub.add_parser("pack"); p.add_argument("name"); p.add_argument("frames_files", nargs="+"); p.add_argument("--frame", required=True); p.add_argument("--cols", type=int, default=0)
    p = sub.add_parser("pack-dir"); p.add_argument("name"); p.add_argument("folder", help="folder of <anim>_<NN>.png|svg"); p.add_argument("--frame", default="", help="default: size of the first frame")
    p.add_argument("--fps", default="", help="name=fps,..."); p.add_argument("--once", default="", help="animations that do not loop (default: guessed from names)"); p.add_argument("--order", default="")
    p = sub.add_parser("from-aseprite"); p.add_argument("json"); p.add_argument("--texture", default=""); p.add_argument("--name", default="")
    p = sub.add_parser("frames"); p.add_argument("spec"); p.add_argument("--out", default="")
    p = sub.add_parser("names"); p.add_argument("spec")
    p = sub.add_parser("preview"); p.add_argument("spec"); p.add_argument("--scale", type=int, default=4)
    a = ap.parse_args()
    cmds = {"example": cmd_example, "inspect": cmd_inspect, "placeholder": cmd_placeholder, "pack": cmd_pack, "pack-dir": cmd_pack_dir,
            "from-aseprite": cmd_from_aseprite, "frames": cmd_frames, "names": cmd_names, "preview": cmd_preview}
    return cmds[a.cmd](a)


if __name__ == "__main__":
    sys.exit(main())
