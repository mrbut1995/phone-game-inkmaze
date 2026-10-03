"""Đổi TOÀN BỘ tham chiếu asset SVG -> PNG trong project (scene / script / resource / cfg).

QUY ƯỚC ĐƯỜNG DẪN (khớp đúng tools/svg_to_png.py):
    res://assets/images/<rel>.svg            -> res://assets/images-png/<rel>.png
    res://<tên>.svg (icon app ở gốc project) -> res://assets/images-png/<tên>.png
    (ref theo quy ước CŨ `assets/images/png/…` được tự đổi sang `assets/images-png/…`)

CÁCH LÀM:
    - Quét mặc định: *.tscn, *.tres, *.gd, project.godot, *.cfg (đổi bằng --ext).
    - Bỏ qua: .godot/, android/, mockup/, optimizing_clean/, tmp_*/ … (xem EXCLUDE_DIRS).
    - KHÔNG đụng file *.import — Godot tự quản, sửa tay là hỏng mapping import.
    - Dòng `[ext_resource ...]` đổi path thì đổi LUÔN uid cho khớp:
        + PNG đích đã có .import  -> thay uid mới (lấy từ .import)
        + chưa có .import         -> BỎ uid (Godot tự điền khi mở editor)
      (tránh uid cũ còn trỏ về SVG — editor sẽ tự "sửa" path ngược lại).
    - Chạy lại nhiều lần vô hại (idempotent). Ref không map được sẽ được báo, không sửa.
    - Đổi CẢ literal đuôi RỜI (không có res://) — kiểu `ICON_DIR + "avatar.svg"`, `"day_cell_empty.svg"`,
      `ends_with("icon_coin_t1.svg")`: nếu tên file (bỏ đuôi) khớp một asset của cây `assets/**`
      thì đổi đuôi; tự bỏ qua chuỗi chứa `mockup`, `*`, `%` hay bắt đầu bằng `res://`.
    - Đổi CẢ hằng THƯ MỤC trỏ vào cây ảnh — kiểu `const CURSOR_DIR := "res://assets/images/game/player_cursor/"`
      (không có tên file nên regex .svg không bắt được): `assets/images/<sub>/` ⇄ `assets/images-png/<sub>/`
      (chiều đi nhận luôn hằng thư mục quy ước CŨ `assets/images/png/<sub>/`).

CHẠY:
    .venv\\Scripts\\python.exe tools/switch_refs_svg_to_png.py            # xem trước (dry-run)
    .venv\\Scripts\\python.exe tools/switch_refs_svg_to_png.py --apply    # ghi thật
    .venv\\Scripts\\python.exe tools/switch_refs_svg_to_png.py --only nodes/popups/base.tscn --apply

NGƯỢC LẠI: tools/switch_refs_png_to_svg.py   (hoàn tác từng bước một)
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]

SCAN_EXTS = {".tscn", ".tres", ".gd", ".godot", ".cfg"}
EXCLUDE_DIRS = {
    ".godot", ".git", ".venv", "__pycache__", "android", "mockup", "optimizing_clean",
    "bug", "Memorizing", "planning", "Errow When Resize",
}

REF_SVG = re.compile(r'res://[^"\'\s\)\]]*\.svg(?![.\w])')
REF_PNG = re.compile(r'res://[^"\'\s\)\]]*\.png(?![.\w])')
REF_PNG_OLD = re.compile(r'res://assets/images/png/[^"\'\s\)\]]*\.png(?![.\w])')
UID_RE = re.compile(r'uid="(uid://[^"]+)"')


# ---------------------------------------------------------------------------
# Mapping 2 chiều (fwd = svg -> png, rev = png -> svg)
# ---------------------------------------------------------------------------
def map_svg(rel: str, root: Path) -> str | None:
    if rel.startswith("assets/images-png/"):
        return None  # đã ở cây png rồi
    if rel.startswith("assets/images/"):
        return "assets/images-png/" + rel[len("assets/images/"):-4] + ".png"
    if "/" not in rel:  # icon app ở gốc project
        return "assets/images-png/" + rel[:-4] + ".png"
    return None


def map_png(rel: str, root: Path) -> str | None:
    if rel.startswith("assets/images-png/"):
        rest = rel[len("assets/images-png/"):-4]
        src = "assets/images/" + rest + ".svg"
        # Icon app: hồi về gốc project nếu SVG gốc chỉ tồn tại ở đó
        if "/" not in rest and not (root / src).exists() and (root / (rest + ".svg")).exists():
            return rest + ".svg"
        return src
    # Tương thích quy ước CŨ (assets/images/png/…) — vẫn revert được
    if rel.startswith("assets/images/png/"):
        return "assets/images/" + rel[len("assets/images/png/"):-4] + ".svg"
    return None


def map_old_png(rel: str) -> str | None:
    """Quy ước CŨ assets/<tree>/png/<rel>.png -> quy ước MỚI assets/<tree>-png/<rel>.png."""
    for tree in ("images",):
        prefix = f"assets/{tree}/png/"
        if rel.startswith(prefix):
            return f"assets/{tree}-png/" + rel[len(prefix):]
    return None


def _migrate_old_png(text: str) -> tuple[str, list[tuple[str, str]]]:
    found: list[tuple[str, str]] = []

    def repl(m: re.Match) -> str:
        new = map_old_png(m.group(0)[len("res://"):])
        if new is None:
            return m.group(0)
        found.append((m.group(0), "res://" + new))
        return "res://" + new

    return REF_PNG_OLD.sub(repl, text), found


def build_stem_registry(direction: str, root: Path) -> set[str]:
    """Tên file (không đuôi) của cây asset — để đổi literal đuôi rời kiểu ICON_DIR + "x.svg"."""
    stems: set[str] = set()
    if direction == "png":
        for pat in ("assets/images/**/*.svg",):
            stems.update(p.stem for p in root.glob(pat) if p.is_file())
    else:
        for pat in ("assets/images-png/**/*.png", "assets/images/png/**/*.png"):
            stems.update(p.stem for p in root.glob(pat) if p.is_file())
    return stems


def convert_suffix_literals(text: str, direction: str, stems: set[str]) -> tuple[str, list[tuple[str, str]]]:
    """Đổi đuôi trong chuỗi kiểu "…x.svg" (KHÔNG có res://) nếu tên file khớp registry."""
    src_ext = "svg" if direction == "png" else "png"
    dst = ".png" if direction == "png" else ".svg"
    pat = re.compile(r'"([^"\n]{1,160}\.' + src_ext + r')"')
    found: list[tuple[str, str]] = []

    def repl(m: re.Match) -> str:
        s = m.group(1)
        if s.startswith("res://") or "mockup" in s.lower() or "*" in s or "%" in s:
            return m.group(0)
        if s.rsplit("/", 1)[-1][:-4] in stems:
            out = s[:-4] + dst
            found.append((s, out))
            return '"' + out + '"'
        return m.group(0)

    return pat.sub(repl, text), found


def convert_dir_refs(text: str, direction: str) -> tuple[str, list[tuple[str, str]]]:
    """Đổi hằng THƯ MỤC trỏ vào cây ảnh — kiểu "res://assets/images/game/player_cursor/"."""
    found: list[tuple[str, str]] = []
    if direction == "png":
        pat = re.compile(r'"(res://assets/images/([^"]*?)/)"')

        def repl(m: re.Match) -> str:
            full, rest = m.group(1), m.group(2)
            if rest == "png" or rest.startswith("png/"):  # quy ước CŨ: images/png/<sub>/
                sub = rest[3:].lstrip("/")
                new = f"res://assets/images-png/{sub}/" if sub else "res://assets/images-png/"
            else:
                new = f"res://assets/images-png/{rest}/" if rest else "res://assets/images-png/"
            found.append((full, new))
            return '"' + new + '"'

        return pat.sub(repl, text), found

    pat = re.compile(r'"(res://assets/images(?:/png|-png)/([^"]*?)/)"')

    def repl_rev(m: re.Match) -> str:
        full, rest = m.group(1), m.group(2)
        new = f"res://assets/images/{rest}/" if rest else "res://assets/images/"
        found.append((full, new))
        return '"' + new + '"'

    return pat.sub(repl_rev, text), found


# ---------------------------------------------------------------------------
def lookup_uid(asset: Path) -> str | None:
    """uid khai trong <asset>.import (nếu có) — dùng để giữ uid khớp asset mới."""
    imp = asset.with_name(asset.name + ".import")
    if imp.exists():
        m = UID_RE.search(imp.read_text(encoding="utf-8", errors="ignore"))
        if m:
            return m.group(1)
    return None


def read_text_raw(p: Path) -> str:
    # newline="" : giữ nguyên CRLF/LF như file gốc (không đổi kiểu xuống dòng)
    with p.open("r", encoding="utf-8", errors="ignore", newline="") as fh:
        return fh.read()


def write_text_raw(p: Path, s: str) -> None:
    with p.open("w", encoding="utf-8", newline="") as fh:
        fh.write(s)


def convert_text(text: str, ref_re: re.Pattern, mapping, root: Path) -> tuple[str, list[tuple[str, str]], list[str]]:
    hits: list[tuple[str, str]] = []
    unmapped: list[str] = []

    def repl(m: re.Match) -> str:
        url = m.group(0)
        new = mapping(url[len("res://"):], root)
        if new is None:
            unmapped.append(url)
            return url
        hits.append((url, "res://" + new))
        return "res://" + new

    return ref_re.sub(repl, text), hits, unmapped


def fix_uids(orig: str, new: str, mapping, root: Path, target_ext: str) -> str:
    """Cập nhật uid trên các dòng [ext_resource] vừa được đổi path (theo target_ext)."""
    o_lines = orig.split("\n")
    n_lines = new.split("\n")
    if len(o_lines) != len(n_lines):
        return new
    pat_new = re.compile(r'path="(res://[^"]+\.' + re.escape(target_ext) + r')"')
    pat_old = re.compile(r'path="(res://[^"]+)"')
    for i, nl in enumerate(n_lines):
        if "[ext_resource" not in nl:
            continue
        m = pat_new.search(nl)
        if m is None:
            continue
        o = pat_old.search(o_lines[i])
        if o is None:
            continue
        new_rel = m.group(1)[len("res://"):]
        mapped = mapping(o.group(1)[len("res://"):], root)
        if mapped is None or mapped != new_rel:
            continue  # dòng này không do mình đổi
        uid = lookup_uid(root / new_rel)
        if uid:
            if 'uid="uid://' in nl:
                nl = re.sub(r'uid="uid://[^"]*"', f'uid="{uid}"', nl, count=1)
            else:
                nl = nl.replace("[ext_resource type=", f'[ext_resource uid="{uid}" type=', 1)
        else:
            nl = re.sub(r'\s*uid="uid://[^"]*"', "", nl, count=1)
        n_lines[i] = nl
    return "\n".join(n_lines)


def iter_files(root: Path, exts: set[str], only: list[str]) -> list[Path]:
    found: list[Path] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = sorted(n for n in dirnames if n not in EXCLUDE_DIRS and not n.startswith("tmp_"))
        for fn in sorted(filenames):
            p = Path(dirpath) / fn
            if p.suffix.lower() not in exts:
                continue
            rel = p.relative_to(root).as_posix()
            if only and not any(s.lower() in rel.lower() for s in only):
                continue
            found.append(p)
    return found


def main(argv: list[str] | None = None, direction: str = "png") -> int:
    is_fwd = direction == "png"
    arrow = "SVG -> PNG" if is_fwd else "PNG -> SVG"
    ap = argparse.ArgumentParser(description=f"Đổi tham chiếu asset {arrow} trong project.")
    ap.add_argument("--apply", action="store_true", help="ghi thật (mặc định: chỉ xem trước)")
    ap.add_argument("--only", action="append", default=[], metavar="SUBSTR",
                    help="chỉ xử lý file có đường dẫn chứa SUBSTR (lặp được nhiều lần)")
    ap.add_argument("--ext", default="", help="đuôi file, phẩy phân cách (mặc định: tscn,tres,gd,godot,cfg)")
    ap.add_argument("--root", default=str(ROOT), help="gốc project (chủ yếu để test)")
    ap.add_argument("--verbose", action="store_true", help="in từng ref cũ -> mới")
    args = ap.parse_args(argv)

    root = Path(args.root).resolve()
    exts = SCAN_EXTS if not args.ext else {"." + e.strip().lstrip(".").lower() for e in args.ext.split(",") if e.strip()}
    mapping = map_svg if is_fwd else map_png
    ref_re = REF_SVG if is_fwd else REF_PNG
    target_ext = "png" if is_fwd else "svg"
    stems = build_stem_registry(direction, root)

    print(f"== Đổi tham chiếu asset {arrow} ==")
    print(f"Gốc project: {root}")
    files = iter_files(root, exts, args.only)
    print(f"File quét  : {len(files)}  ({', '.join(sorted(e.lstrip('.') for e in exts))})")
    print(f"Stem asset : {len(stems)}  (đổi cả literal đuôi rời không có res:// nếu khớp tên file)")

    total_hits = 0
    changed: list[tuple[Path, int]] = []
    all_hits: list[tuple[str, str]] = []
    unmapped_report: list[tuple[Path, list[str]]] = []
    for p in files:
        orig = read_text_raw(p)
        new, hits, unmapped = convert_text(orig, ref_re, mapping, root)
        hits_old: list[tuple[str, str]] = []
        if is_fwd and REF_PNG_OLD.search(new):
            new, hits_old = _migrate_old_png(new)
        new, suffixes = convert_suffix_literals(new, direction, stems)
        new, dirs = convert_dir_refs(new, direction)
        if unmapped:
            unmapped_report.append((p, unmapped))
        n_changes = len(hits) + len(hits_old) + len(suffixes) + len(dirs)
        if not n_changes:
            continue
        new = fix_uids(orig, new, mapping, root, target_ext)
        total_hits += n_changes
        changed.append((p, n_changes))
        if args.verbose:
            for old, newu in hits:
                print(f"    {p.relative_to(root).as_posix()}: {old}  ->  {newu}")
            for old, newu in hits_old:
                print(f"    {p.relative_to(root).as_posix()}: {old}  ->  {newu}  (QUY ƯỚC CŨ)")
            for old, newu in suffixes:
                print(f"    {p.relative_to(root).as_posix()}: \"{old}\"  ->  \"{newu}\"")
            for old, newu in dirs:
                print(f"    {p.relative_to(root).as_posix()}: \"{old}\"  ->  \"{newu}\" (THƯ MỤC)")
        if args.apply:
            write_text_raw(p, new)
        all_hits += hits + hits_old

    if not args.verbose:
        for p, n in changed[:40]:
            print(f"  {p.relative_to(root).as_posix()}: {n} tham chiếu")
        if len(changed) > 40:
            print(f"  ... và {len(changed) - 40} file nữa")

    missing: dict[str, str] = {}
    for old, newu in all_hits:
        if "%" in newu:  # ref động kiểu "…/icon_%s.png" — không kiểm tra tồn tại literal được
            continue
        t = root / newu[len("res://"):]
        if not t.exists():
            missing.setdefault(newu, old)

    if unmapped_report:
        n_un = sum(len(set(u)) for _, u in unmapped_report)
        print(f"\nRef KHÔNG map được ({n_un} — giữ nguyên, không sửa):")
        shown = 0
        for p, urls in unmapped_report:
            for u in sorted(set(urls)):
                if shown >= 15:
                    break
                print(f"    {p.relative_to(root).as_posix()}: {u}")
                shown += 1
        if n_un > shown:
            print(f"    ... và {n_un - shown} ref nữa")

    if missing:
        print(f"\n[CẢNH BÁO] {len(missing)} đích chưa tồn tại trên đĩa (10 cái đầu):")
        for u, src in list(missing.items())[:10]:
            print(f"    {u}   (đang dùng ở {src})")
        if is_fwd:
            print("    → chạy tools/svg_to_png.py trước, rồi mở editor Godot 1 lần để import PNG.")
        else:
            print("    → kiểm tra asset SVG nguồn có bị xoá không.")
    elif changed:
        print("\nMọi đích tham chiếu đều tồn tại trên đĩa: OK")

    state = "ĐÃ GHI" if args.apply else "DRY-RUN (thêm --apply để ghi)"
    print(f"\nTỔNG: {total_hits} tham chiếu trong {len(changed)} file — {state}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(direction="png"))
