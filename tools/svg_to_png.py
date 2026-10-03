"""Biến toàn bộ SVG của project thành PNG và xuất vào cây `png/` mirror.

QUY ƯỚC ĐƯỜNG DẪN (khớp đúng với tools/switch_refs_svg_to_png.py):
    assets/images/<rel>.svg             -> assets/images-png/<rel>.png
    assets/images-landscape/<rel>.svg   -> assets/images-landscape-png/<rel>.png
    <tên>.svg ở GỐC project (icon app)  -> assets/images-png/<tên>.png

ENGINE (rasterizer):
    edge     : KHUYẾN NGHỊ — chụp bằng Microsoft Edge/Chrome HEADLESS ⇒ giống hệt TRÌNH DUYỆT:
               đủ <pattern> (lưới ô vuông…), <text> (nhãn chữ), feDropShadow (ĐỔ BÓNG), gradient…
               (máy này có Edge sẵn — không cần cài gì thêm).
    cairosvg : pattern + text + gradient… nhưng KHÔNG vẽ feDropShadow (cần `pip install cairosvg`).
    godot    : ThorVG của Godot — KHÔNG vẽ <pattern>, <text>, feDropShadow ⇒ mất chi tiết.
    auto     : edge (nếu có Edge/Chrome) → cairosvg → godot — MẶC ĐỊNH.

    Kích thước PNG luôn được ép đúng bằng cỡ texture Godot đang dùng trước đây
    (width/height attr × svg/scale; dạng "50%" tính theo viewBox) — engine edge dùng
    cỡ đó cho cả cửa sổ chụp lẫn thẻ <img>, cairosvg nhận `output_width/output_height`.

SCALE (độ phân giải PNG so với kích thước thiết kế):
    Mặc định lấy `svg/scale` trong file `.import` của từng SVG (thường 1.0 — đúng
    bằng kích thước texture Godot đang import). `--scale N` ép tất cả về N (VD 2 = nét gấp đôi).

SAU KHI CHẠY:
    1. .venv\\Scripts\\python.exe tools/switch_refs_svg_to_png.py --apply   (đổi tham chiếu)
    2. Mở editor Godot 1 lần (hoặc chạy --import) để tạo `.import` cho PNG mới.

VÍ DỤ:
    .venv\\Scripts\\python.exe tools/svg_to_png.py --dry-run          # xem trước
    .venv\\Scripts\\python.exe tools/svg_to_png.py                    # chạy thật
    .venv\\Scripts\\python.exe tools/svg_to_png.py --only btn_header_cancel --out tmp_tools/png_probe
    .venv\\Scripts\\python.exe tools/svg_to_png.py --scale 2          # PNG nét gấp đôi
"""

from __future__ import annotations

import argparse
import json
import math
import queue
import re
import shutil
import subprocess
import sys
import threading
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

ROOT = Path(__file__).resolve().parents[1]
GODOT_DEFAULT = r"D:\Godots\app dev\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"

DEFAULT_ROOTS = ["assets/images", "assets/images-landscape"]
TMP_DIR = ROOT / "tmp_tools"
TMP_GD = TMP_DIR / "_svg_raster_tmp.gd"
TMP_JOBS = TMP_DIR / "_svg_raster_jobs.json"
TMP_RESULTS = TMP_DIR / "_svg_raster_results.json"

SVG_SCALE_RE = re.compile(r"svg/scale=([0-9.]+)")
WIDTH_RE = re.compile(r"<svg[^>]*?\bwidth=\"([0-9.]+)([%a-zA-Z]*)\"", re.S)
HEIGHT_RE = re.compile(r"<svg[^>]*?\bheight=\"([0-9.]+)([%a-zA-Z]*)\"", re.S)
VIEWBOX_RE = re.compile(r"<svg[^>]*?\bviewBox=\"([0-9.\s-]+)\"", re.S)

GD_TEMPLATE = """extends SceneTree
# Script tạm do tools/svg_to_png.py sinh ra — TỰ ĐỘNG XOÁ sau khi chạy, đừng commit.

const JOBS_PATH := "{jobs}"
const RESULTS_PATH := "{results}"

func _initialize() -> void:
	var jobs: Variant = JSON.parse_string(FileAccess.get_file_as_string(JOBS_PATH))
	var results: Array = []
	var ok := 0
	if jobs == null:
		push_error("Khong doc duoc jobs JSON: " + JOBS_PATH)
	else:
		for j in jobs:
			var res := {"src": j["src"], "out": j["out"], "ok": false, "err": "", "w": 0, "h": 0}
			var f := FileAccess.open(j["src"], FileAccess.READ)
			if f == null:
				res["err"] = "open_fail_%d" % FileAccess.get_open_error()
			else:
				var buf := f.get_buffer(f.get_length())
				f.close()
				var img := Image.new()
				var lerr := img.load_svg_from_buffer(buf, float(j["scale"]))
				if lerr != OK:
					res["err"] = "load_svg_error_%d" % lerr
				else:
					DirAccess.make_dir_recursive_absolute(j["out"].get_base_dir())
					var serr := img.save_png(j["out"])
					if serr != OK:
						res["err"] = "save_error_%d" % serr
					else:
						res["ok"] = true
						res["w"] = img.get_width()
						res["h"] = img.get_height()
						ok += 1
			results.append(res)
	var rf := FileAccess.open(RESULTS_PATH, FileAccess.WRITE)
	if rf != null:
		rf.store_string(JSON.stringify(results, "  "))
		rf.close()
	print("SVG_TO_PNG_GD: ok=%d fail=%d" % [ok, results.size() - ok])
	quit()
"""


# ---------------------------------------------------------------------------
# Quy ước đường dẫn
# ---------------------------------------------------------------------------
def out_for(svg: Path, roots: list[str], out_dir: Path | None) -> Path | None:
    """Trả đường dẫn PNG đích cho 1 file SVG (None nếu nằm ngoài mọi root)."""
    rel = svg.resolve().relative_to(ROOT)
    if out_dir is not None:  # chế độ test: giữ nguyên cây tính từ gốc project
        return out_dir / rel.with_suffix(".png")
    for r in roots:
        try:
            sub = rel.relative_to(r)
        except ValueError:
            continue
        return ROOT / (r + "-png") / sub.with_suffix(".png")
    if len(rel.parts) == 1:  # icon app nằm ngay gốc project
        return ROOT / "assets/images-png" / rel.with_suffix(".png")
    return None


def collect_svgs(roots: list[str], include_root_icons: bool) -> list[Path]:
    files: list[Path] = []
    for r in roots:
        base = (ROOT / r).resolve()
        if not base.is_dir():
            print(f"  [CẢNH BÁO] root không tồn tại: {r}")
            continue
        files += [p for p in sorted(base.rglob("*.svg")) if p.is_file()]
    if include_root_icons:
        files += [p for p in sorted(ROOT.glob("*.svg")) if p.is_file()]
    return files


def import_scale(svg: Path) -> float:
    imp = svg.with_name(svg.name + ".import")
    if imp.exists():
        m = SVG_SCALE_RE.search(imp.read_text(encoding="utf-8", errors="ignore"))
        if m:
            return float(m.group(1))
    return 1.0


def _round_half_up(x: float) -> int:
    return int(math.floor(x + 0.5))


def expected_size(svg: Path, scale: float) -> tuple[int, int] | None:
    head = svg.read_text(encoding="utf-8", errors="ignore")[:2000]
    vb: tuple[float, float] | None = None
    mv = VIEWBOX_RE.search(head)
    if mv:
        parts = mv.group(1).split()
        if len(parts) == 4:
            vb = (float(parts[2]), float(parts[3]))
    mw, mh = WIDTH_RE.search(head), HEIGHT_RE.search(head)
    if mw and mh:
        def _dim(m: re.Match, ref: float | None) -> float | None:
            v, unit = float(m.group(1)), m.group(2)
            if unit == "%":
                return ref * v / 100.0 if ref is not None else None
            if unit in ("", "px"):
                return v
            return None  # đơn vị lạ — không đoán
        w = _dim(mw, vb[0] if vb else None)
        h = _dim(mh, vb[1] if vb else None)
        if w is not None and h is not None:
            return _round_half_up(w * scale), _round_half_up(h * scale)
    if vb:
        return _round_half_up(vb[0] * scale), _round_half_up(vb[1] * scale)
    return None


def png_size(p: Path) -> tuple[int, int] | None:
    try:
        head = p.open("rb").read(24)
    except OSError:
        return None
    if len(head) < 24 or head[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return int.from_bytes(head[16:20], "big"), int.from_bytes(head[20:24], "big")


# ---------------------------------------------------------------------------
# Engine: godot / cairosvg
# ---------------------------------------------------------------------------
def raster_godot(jobs: list[dict], godot: str, timeout: float) -> list[dict]:
    TMP_DIR.mkdir(exist_ok=True)
    TMP_GD.write_text(GD_TEMPLATE.replace("{jobs}", TMP_JOBS.as_posix()).replace("{results}", TMP_RESULTS.as_posix()), encoding="utf-8")
    TMP_JOBS.write_text(json.dumps(jobs, ensure_ascii=False, indent=1), encoding="utf-8")
    if TMP_RESULTS.exists():
        TMP_RESULTS.unlink()
    cmd = [godot, "--headless", "--path", str(ROOT), "--script", "res://tmp_tools/_svg_raster_tmp.gd"]
    try:
        done = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                              encoding="utf-8", errors="replace", timeout=timeout)
        out = (done.stdout or "") + (done.stderr or "")
    except subprocess.TimeoutExpired:
        print(f"  [LỖI] Godot treo quá {timeout:.0f}s")
        return []
    finally:
        for f in (TMP_GD, TMP_JOBS):
            f.unlink(missing_ok=True)
    if not TMP_RESULTS.exists():
        print("  [LỖI] Không thấy file kết quả của Godot. 20 dòng cuối output:")
        for line in out.splitlines()[-20:]:
            print("    " + line)
        return []
    results = json.loads(TMP_RESULTS.read_text(encoding="utf-8"))
    TMP_RESULTS.unlink(missing_ok=True)
    return results


EDGE_CANDIDATES = [
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
]
EDGE_FLAGS = [
    "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
    "--default-background-color=00000000", "--virtual-time-budget=6000", "--no-first-run",
    "--no-default-browser-check", "--disable-extensions", "--disable-sync", "--mute-audio",
]


def find_edge(explicit: str | None) -> str | None:
    if explicit:
        return explicit if Path(explicit).exists() else None
    for c in EDGE_CANDIDATES:
        if Path(c).exists():
            return c
    for name in ("msedge", "chrome", "chromium"):
        w = shutil.which(name)
        if w:
            return w
    return None


def raster_edge(jobs: list[dict], edge: str, workers: int = 4) -> list[dict]:
    """Chụp SVG bằng Edge/Chrome headless — gom NHIỀU ảnh vào 'sheet' để chỉ mở Edge vài lần
    (mỗi lần mở Edge tốn 10–30s; chụp lẻ 622 lần là bất khả thi), rồi cắt từng ô bằng cairocffi.
    Giống TRÌNH DUYỆT: pattern + text + feDropShadow."""
    base = TMP_DIR / "_edge"
    base.mkdir(parents=True, exist_ok=True)
    results: list[dict] = [dict() for _ in jobs]
    try:
        import cairocffi as cairo  # đi kèm cairosvg
    except ImportError:
        for i, j in enumerate(jobs):
            results[i] = {"src": j["src"], "out": j["out"], "ok": False, "w": 0, "h": 0,
                          "err": "edge: cần cairocffi để cắt sheet (pip install cairosvg)"}
        return results

    # ---- Xếp ảnh vào các sheet (shelf packing) ----
    SHEET_W, SHEET_H = 6000, 6000
    sheets: list[dict] = []
    cur: dict = {"w": 0, "h": 0, "row_h": 0, "items": []}
    for i, j in enumerate(jobs):
        res = {"src": j["src"], "out": j["out"], "ok": False, "err": "", "w": 0, "h": 0}
        results[i] = res
        exp = expected_size(Path(j["src"]), float(j["scale"]))
        if exp is None:
            res["err"] = "edge: không xác định được cỡ (thiếu width/height/viewBox)"
            continue
        w, h = exp
        if cur["items"] and cur["w"] + w > SHEET_W:
            cur["h"] += cur["row_h"]
            cur["w"] = 0
            cur["row_h"] = 0
        if cur["items"] and cur["h"] + max(cur["row_h"], h) > SHEET_H:
            sheets.append(cur)
            cur = {"w": 0, "h": 0, "row_h": 0, "items": []}
        cur["items"].append((i, cur["w"], cur["h"], w, h))
        cur["w"] += w
        cur["row_h"] = max(cur["row_h"], h)
    if cur["items"]:
        sheets.append(cur)

    # ---- Chụp từng sheet (tuần tự, cùng 1 profile) ----
    profile = base / "prof"
    ok_sheets: list[Path | None] = []
    for k, s in enumerate(sheets):
        s_w = max(x + w for _, x, _, w, _ in s["items"])
        s_h = s["h"] + s["row_h"]
        wrap = base / f"sheet_{k:02d}.html"
        html = ["<!doctype html><meta charset='utf-8'>",
                "<style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}"
                "img{position:absolute;display:block}</style>"]
        for (i, x, y, w, h) in s["items"]:
            html.append(f"<img src=\"{Path(jobs[i]['src']).as_uri()}\" "
                        f"style=\"left:{x}px;top:{y}px;width:{w}px;height:{h}px\">")
        wrap.write_text("".join(html), encoding="utf-8")
        sheet_png = base / f"sheet_{k:02d}.png"
        cmd = [edge, *EDGE_FLAGS, f"--window-size={s_w},{s_h}", f"--user-data-dir={profile}",
               f"--screenshot={sheet_png}", wrap.as_uri()]
        shot: Path | None = None
        for _attempt in range(2):
            sheet_png.unlink(missing_ok=True)
            try:
                # KHÔNG capture pipe — process con của Edge giữ pipe ⇒ treo chờ EOF rất lâu
                subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=240)
            except subprocess.TimeoutExpired:
                pass
            if png_size(sheet_png) == (s_w, s_h):
                shot = sheet_png
                break
        ok_sheets.append(shot)
        print(f"    sheet {k + 1}/{len(sheets)}: {len(s['items'])} ảnh, {s_w}x{s_h}"
              + ("  [OK]" if shot else "  [LỖI]"), flush=True)

    # ---- Cắt từng ô từ sheet ----
    total_crop = sum(len(s["items"]) for s in sheets)
    done = 0
    for k, s in enumerate(sheets):
        if ok_sheets[k] is None:
            for (i, *_rest) in s["items"]:
                results[i]["err"] = "edge: sheet chụp lỗi"
            continue
        surf = cairo.ImageSurface.create_from_png(str(ok_sheets[k]))
        for (i, x, y, w, h) in s["items"]:
            out = Path(jobs[i]["out"])
            out.parent.mkdir(parents=True, exist_ok=True)
            sub = cairo.ImageSurface(cairo.FORMAT_ARGB32, w, h)
            ctx = cairo.Context(sub)
            ctx.set_source_surface(surf, -x, -y)
            ctx.paint()
            sub.write_to_png(str(out))
            size = png_size(out)
            res = results[i]
            if size == (w, h):
                res.update(ok=True, w=w, h=h, err="")
            elif size is None:
                res["err"] = "edge/crop: không ghi được PNG"
            else:
                res["err"] = f"edge/crop: sai cỡ {size[0]}x{size[1]} (mong {w}x{h})"
            done += 1
            if done % 100 == 0 or done == total_crop:
                print(f"    ... {done}/{len(jobs)} PNG", flush=True)

    shutil.rmtree(base, ignore_errors=True)
    return results


def raster_cairosvg(jobs: list[dict]) -> list[dict]:
    import cairosvg  # type: ignore
    results: list[dict] = []
    for j in jobs:
        res = {"src": j["src"], "out": j["out"], "ok": False, "err": "", "w": 0, "h": 0}
        try:
            Path(j["out"]).parent.mkdir(parents=True, exist_ok=True)
            exp = expected_size(Path(j["src"]), float(j["scale"]))
            kwargs: dict = {"url": j["src"], "write_to": j["out"]}
            if exp:
                # Ép đúng cỡ cũ (cairosvg xử lý width="%" khác ThorVG — không ép là lệch cỡ)
                kwargs["output_width"], kwargs["output_height"] = exp
            else:
                kwargs["scale"] = j["scale"]
            cairosvg.svg2png(**kwargs)
            size = png_size(Path(j["out"]))
            if size:
                res.update(ok=True, w=size[0], h=size[1])
            else:
                res["err"] = "png_invalid"
        except Exception as exc:  # noqa: BLE001
            res["err"] = f"cairosvg: {exc}"
        results.append(res)
    return results


def resolve_engine(engine: str, edge: str | None) -> str:
    if engine != "auto":
        return engine
    if find_edge(edge):
        return "edge"
    try:
        import cairosvg  # noqa: F401
        return "cairosvg"
    except ImportError:
        return "godot"


# ---------------------------------------------------------------------------
def main() -> int:
    ap = argparse.ArgumentParser(description="Rasterize SVG -> PNG (mirror cây png/).")
    ap.add_argument("--dry-run", action="store_true", help="chỉ in kế hoạch, không ghi gì")
    ap.add_argument("--only", action="append", default=[], metavar="SUBSTR",
                    help="chỉ xử lý file có đường dẫn chứa SUBSTR (lặp được nhiều lần)")
    ap.add_argument("--scale", type=float, default=None, help="ép scale cho tất cả (mặc định: theo từng .import)")
    ap.add_argument("--out", default=None, metavar="DIR", help="ghi vào DIR (giữ nguyên cây từ gốc project) — dùng để test")
    ap.add_argument("--engine", choices=["auto", "edge", "cairosvg", "godot"], default="auto")
    ap.add_argument("--godot", default=GODOT_DEFAULT, help="đường dẫn binary Godot để rasterize")
    ap.add_argument("--edge", default=None, help="đường dẫn msedge.exe/chrome.exe (mặc định: tự tìm)")
    ap.add_argument("--workers", type=int, default=4, help="dự phòng (engine edge chụp theo sheet, tuần tự)")
    ap.add_argument("--root", action="append", default=[], metavar="DIR", help="thêm root chứa SVG (mặc định: assets/images + assets/images-landscape)")
    ap.add_argument("--no-root-icons", action="store_true", help="bỏ qua các icon *.svg ở gốc project")
    ap.add_argument("--skip-existing", action="store_true", help="bỏ qua file PNG đã tồn tại")
    ap.add_argument("--verbose", action="store_true", help="in từng file")
    args = ap.parse_args()

    roots = DEFAULT_ROOTS + args.root
    out_dir = (ROOT / args.out).resolve() if args.out else None

    svgs = collect_svgs(roots, include_root_icons=not args.no_root_icons)
    if args.only:
        svgs = [p for p in svgs if any(s.lower() in p.as_posix().lower() for s in args.only)]
    if not svgs:
        print("Không tìm thấy SVG nào khớp.")
        return 0

    jobs: list[dict] = []
    skipped: list[tuple[Path, Path]] = []
    collision: dict[str, str] = {}
    for svg in svgs:
        out = out_for(svg, roots, out_dir)
        if out is None:
            print(f"  [BỎ QUA] ngoài root: {svg.relative_to(ROOT).as_posix()}")
            continue
        key = out.as_posix().lower()
        if key in collision:
            print(f"  [LỖI TRÙNG ĐÍCH] {collision[key]} và {svg} cùng ghi vào {out}")
            return 1
        collision[key] = svg.as_posix()
        if args.skip_existing and out.exists():
            skipped.append((svg, out))
            continue
        scale = args.scale if args.scale is not None else import_scale(svg)
        jobs.append({"src": svg.as_posix(), "out": out.as_posix(), "scale": scale})

    print(f"SVG tìm thấy   : {len(svgs)}")
    if skipped:
        print(f"Bỏ qua (đã có): {len(skipped)}")
    print(f"Sẽ rasterize   : {len(jobs)}  →  {out_dir if out_dir else 'assets/images-png + assets/images-landscape-png'}")
    if args.dry_run:
        for j in jobs[: (10 ** 9 if args.verbose else 12)]:
            print(f"    {Path(j['src']).relative_to(ROOT).as_posix():<62} -> {Path(j['out']).relative_to(ROOT).as_posix()}")
        if not args.verbose and len(jobs) > 12:
            print(f"    ... và {len(jobs) - 12} file nữa (thêm --verbose để in hết)")
        print("DRY-RUN — chưa ghi gì. Bỏ --dry-run để chạy thật.")
        return 0

    engine = resolve_engine(args.engine, args.edge)
    note = ""
    if engine == "edge":
        note = "  (giống TRÌNH DUYỆT: pattern + text + feDropShadow)"
    elif engine == "godot":
        note = "  ⚠ ThorVG KHÔNG vẽ <pattern>/<text>/feDropShadow — cài Edge/cairosvg để giữ đủ chi tiết"
    elif engine == "cairosvg":
        note = "  (giữ pattern/text; KHÔNG có feDropShadow — dùng engine edge nếu cần bóng)"
    print(f"Engine         : {engine}" + ("  (godot: " + args.godot + ")" if engine == "godot" else "") + note)
    print("Đang rasterize...")
    if engine == "edge":
        edge_bin = find_edge(args.edge)
        if edge_bin is None:
            print("  [LỖI] Không tìm thấy Edge/Chrome — dùng --edge <đường dẫn> hoặc --engine cairosvg/godot.")
            return 1
        results = raster_edge(jobs, edge_bin, workers=max(1, args.workers))
    elif engine == "godot":
        results = raster_godot(jobs, args.godot, timeout=900.0)
    else:
        results = raster_cairosvg(jobs)

    # Gộp kết quả theo src (ưu tiên bản OK) — và THỬ LẠI 1 lần cho file chưa OK
    def _merge(rs: list[dict]) -> dict[str, dict]:
        by: dict[str, dict] = {}
        for r in rs:
            prev = by.get(r["src"])
            if prev is None or (not prev.get("ok") and r.get("ok")):
                by[r["src"]] = r
        return by

    by_src = _merge(results)
    retry_jobs = [j for j in jobs if j["src"] not in by_src or not by_src[j["src"]].get("ok")]
    if retry_jobs:
        print(f"  [THỬ LẠI] {len(retry_jobs)}/{len(jobs)} file chưa có kết quả OK — chạy lại...")
        retry = raster_godot(retry_jobs, args.godot, timeout=900.0) if engine == "godot" else raster_cairosvg(retry_jobs)
        by_src = _merge(results + retry)

    ok: list[tuple[dict, dict]] = []
    fails: list[dict] = []
    lost: list[dict] = []
    for j in jobs:
        r = by_src.get(j["src"])
        if r is None:
            lost.append(j)
        elif r.get("ok"):
            ok.append((r, j))
        else:
            fails.append(r)

    # Kiểm tra chéo kích thước PNG với kích thước mong đợi (từ width/height/viewBox của SVG)
    mismatches: list[str] = []
    for r, j in ok:
        exp = expected_size(Path(r["src"]), float(j["scale"]))
        real = (r["w"], r["h"])
        if exp and (abs(exp[0] - real[0]) > 1 or abs(exp[1] - real[1]) > 1):
            mismatches.append(f"{Path(r['src']).relative_to(ROOT).as_posix()}: {real[0]}x{real[1]} (mong đợi {exp[0]}x{exp[1]})")
        if args.verbose:
            print(f"    [OK] {Path(r['src']).relative_to(ROOT).as_posix():<62} {real[0]}x{real[1]}")

    print(f"\nKẾT QUẢ: {len(ok)}/{len(jobs)} PNG tạo thành công")
    for r in fails[:15]:
        print(f"    [FAIL] {Path(r['src']).relative_to(ROOT).as_posix()} — {r.get('err')}")
    if len(fails) > 15:
        print(f"    ... và {len(fails) - 15} file lỗi nữa")
    for j in lost[:15]:
        print(f"    [MẤT KẾT QUẢ] {Path(j['src']).relative_to(ROOT).as_posix()} — engine không trả kết quả")
    if mismatches:
        print(f"  {len(mismatches)} file lệch kích thước (chỉ để biết, không chặn):")
        for m in mismatches[:8]:
            print(f"    [LỆCH] {m}")

    bad = len(fails) + len(lost)
    if not ok:
        print("\n[LỖI] KHÔNG tạo được PNG nào — xem lỗi phía trên rồi chạy lại tool.")
    if bad:
        print(f"\n[LỖI] {bad}/{len(jobs)} file không tạo được — chạy lại tool để thử tiếp (file đã OK ghi đè vô hại).")
        return 1
    print("\nBước tiếp theo: python tools/switch_refs_svg_to_png.py --apply  (rồi mở editor Godot 1 lần để import PNG)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
