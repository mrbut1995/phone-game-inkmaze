# -*- coding: utf-8 -*-
"""Soát bản dịch (localization audit):

  1. CHUỖI CỨNG trong UI  — literal còn nằm thẳng trong `.gd` / `.tscn` / `.tres`
     (thay vì dùng khoá `STR_*`). Bỏ qua vùng dev-only: `scripts/test_case/**`
     (test) và bảng dịch `resources/localization/**`.
  2. KEY STR_ KHÔNG DÙNG   — khoá có trong `string.csv` / `string_extra.csv` nhưng
     KHÔNG xuất hiện ở bất kỳ mã/scene/dữ liệu nào. Khoá dựng ĐỘNG (ví dụ
     `"STR_MONTH_%02d"`, `f"STR_GI_{mode}_…"`) được nhận theo "họ tiền tố" nên
     không bị báo oan.

Chạy:
  python tools/content/audit_localization.py                  # báo cáo
  python tools/content/audit_localization.py --check          # thêm: exit 1 nếu có vấn đề
  python tools/content/audit_localization.py --drop-unused    # xoá row key không dùng khỏi CSV
  python tools/content/audit_localization.py --hardcoded      # chỉ in danh sách chuỗi cứng
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSV_FILES = [
    ROOT / "resources" / "localization" / "string.csv",
    ROOT / "resources" / "localization" / "string_extra.csv",
]
SCAN_DIRS = ["scripts", "scenes", "nodes", "resources", "tools"]
SKIP_PARTS = ("scripts/test_case", "resources/localization", "__pycache__")
## Vùng DEV-ONLY: chữ trong Debug Console là chữ dev (cố ý không dịch) — không tính là chuỗi cứng
SKIP_SOURCES = ("scripts/scenes/debug.gd", "scripts/scenes/layout/debug_layout.gd")
SCAN_SUFFIXES = (".gd", ".tscn", ".tres", ".json", ".py")

KEY_TOKEN = re.compile(r"STR_[A-Z0-9_]+")
# Khoá dựng động: "STR_MONTH_%02d" · f"STR_GI_{m}" · "STR_X_" + …
DYNAMIC_TOKEN = re.compile(r"STR_[A-Z0-9_]*[%{]")
HAS_LETTER = re.compile(r"[^\W\d_]", re.UNICODE)
## Chuỗi cần TỪ 2 KÝ TỰ CHỮ trở lên mới coi là chữ hiển thị (bỏ qua format kiểu "/%d ✓")
VI_CHARS = re.compile(r"[ăâđêôơưĂÂĐÊÔƠƯáàảãạấầẩẫậắằẳẵặéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵ]", re.UNICODE)

# Properties hay mang chữ hiển thị cho người chơi
PROP_RE = re.compile(
    r"(?:^|[\s\.\(,])(text|title|subtitle|body|message|label_text|placeholder_text|tooltip_text)"
    r"\s*[:=]\s*\"([^\"\\]*)\"",
    re.MULTILINE,
)
CALL_RE = re.compile(
    r"\b(?:tr|translate)\s*\(\s*\"([^\"\\]*)\"",
)
SET_TEXT_RE = re.compile(r"\b_set_text\s*\([^,]+,\s*\"([^\"\\]*)\"")
SET_LABEL_RE = re.compile(r"\bset_label_text\s*\(\s*\"([^\"\\]*)\"")

## VÙNG GÁC (production UI đã dọn sạch): `--check` chỉ ĐỎ khi literal rơi vào đây.
## Ngoài vùng này (component demo · bố cục mockup · popup mẫu) vẫn in ra để soi nhưng không gác.
GATED_PREFIXES = (
    "scripts/nodes/tutorial/",
    "scripts/nodes/hud/",
    "nodes/hud/",
    "nodes/tutorials/",
    "nodes/game/cell.tscn",
)
## Ngoại lệ ĐÃ BIẾT trong vùng gác: chữ MẪU cho editor (bị code ghi đè lúc chạy)
PLACEHOLDER_ALLOWLIST = {
    ("nodes/tutorials/how_to_play_sum_path.tscn", "Tổng: 2  |  Mục tiêu: = 8"),
    ("nodes/tutorials/how_to_play_wall_builder.tscn", "Đã vẽ: 0 / 2 đoạn"),
    ("nodes/game/cell.tscn", "ĐÃ ĐI"),
}


def scan_files() -> list[Path]:
    out: list[Path] = []
    for folder in SCAN_DIRS:
        base = ROOT / folder
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix not in SCAN_SUFFIXES:
                continue
            rel = path.relative_to(ROOT).as_posix()
            if any(skip in rel for skip in SKIP_PARTS):
                continue
            out.append(path)
    return sorted(out)


def test_only_keys(all_keys: set[str]) -> set[str]:
    """Khoá CHỈ được nhắc trong `scripts/test_case/**` (test cũ) — không dùng ở game thật."""
    base = ROOT / "scripts" / "test_case"
    if not base.exists():
        return set()
    mentioned: set[str] = set()
    for path in base.rglob("*.gd"):
        mentioned.update(KEY_TOKEN.findall(read_text(path)))
    return {key for key in all_keys if key in mentioned}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="replace")


def hardcoded_hits(files: list[Path]) -> list[tuple[str, int, str, str]]:
    """-> [(rel, dòng, literal, nguồn)] cho literal còn cứng trong UI"""
    hits: list[tuple[str, int, str, str]] = []
    for path in files:
        rel = path.relative_to(ROOT).as_posix()
        if rel in SKIP_SOURCES:
            continue
        text = read_text(path)
        # `.tres` có khoá dịch đi kèm (`title_key`/`desc_key`/`subtitle_key`) ⇒ literal chỉ là
        # DỰ PHÒNG (code ưu tiên khoá) — không tính là chuỗi cứng.
        if path.suffix == ".tres" and re.search(r"\w+_key = \"STR_", text):
            continue
        lines = text.split("\n")
        found: list[tuple[int, str, str]] = []
        for match in PROP_RE.finditer(text):
            found.append((text[: match.start()].count("\n") + 1, match.group(2), match.group(1)))
        for match in CALL_RE.finditer(text):
            found.append((text[: match.start()].count("\n") + 1, match.group(1), "tr()"))
        if path.suffix == ".gd":
            for match in SET_TEXT_RE.finditer(text):
                found.append((text[: match.start()].count("\n") + 1, match.group(1), "_set_text()"))
            for match in SET_LABEL_RE.finditer(text):
                found.append((text[: match.start()].count("\n") + 1, match.group(1), "set_label_text()"))
        for line_no, literal, source in found:
            value = literal.strip()
            if not value or value.startswith("STR_") or not HAS_LETTER.search(value):
                continue
            # Chuỗi 1–2 ký tự (S · F · ✓ · ×) là ký hiệu bàn cờ, không cần dịch
            if len(value) <= 2:
                continue
            # Chuỗi CHỈ có 1 ký tự chữ ("0 PTS" thì 3 chữ ✓ · "/%d ✓" thì 1 chữ ✗) = format thuần
            if len(re.findall(r"[^\W\d_]", value)) < 2:
                continue
            if line_no - 1 < len(lines) and lines[line_no - 1].lstrip().startswith("#"):
                continue
            hits.append((rel, line_no, value, source))
    return hits


def node_name_at(path: Path, line_no: int) -> str:
    """Tên node bao quanh 1 dòng trong `.tscn` ([node name="X" …] gần nhất phía trên)"""
    if path.suffix != ".tscn":
        return ""
    lines = read_text(path).split("\n")
    for index in range(min(line_no, len(lines)) - 1, -1, -1):
        match = re.match(r'\[node name="([^"]+)"', lines[index])
        if match:
            return match.group(1)
    return ""


def defined_keys() -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for csv_path in CSV_FILES:
        if not csv_path.exists():
            continue
        with csv_path.open(encoding="utf-8", newline="") as handle:
            for row in csv.reader(handle):
                if not row or not row[0].startswith("STR_"):
                    continue
                out.setdefault(row[0], []).append(csv_path.name)
    return out


def used_keys(files: list[Path]) -> tuple[set[str], set[str]]:
    """-> (khoá dùng TRỰC TIẾP, họ tiền tố dựng động)"""
    used: set[str] = set()
    families: set[str] = set()
    for path in files:
        text = read_text(path)
        used.update(KEY_TOKEN.findall(text))
        # Họ tiền tố chỉ suy từ MÃ/SCENE/DỮ LIỆU game — bỏ `tools/` (script sinh key cũng có
        # dạng "STR_X_%s" nên sẽ tự "hợp thức hoá" mọi khoá cùng tiền tố)
        if path.relative_to(ROOT).parts[0] == "tools":
            continue
        for token in DYNAMIC_TOKEN.findall(text):
            families.add(token.rstrip("%{"))
        for token in re.findall(r"\"(STR_[A-Z0-9_]+_)\"", text):
            families.add(token)
    # Họ tiền tố: chỉ cần khớp phần tên trước dấu cuối cùng
    return used, {name for name in families if name.endswith("_")}


def is_used(key: str, used: set[str], families: set[str]) -> bool:
    if key in used:
        return True
    return any(key.startswith(family) for family in families)


def drop_unused(unused: set[str]) -> int:
    """Xoá theo DÒNG (giữ nguyên mọi dòng khác) — an toàn với encoding/quoting."""
    removed = 0
    for csv_path in CSV_FILES:
        if not csv_path.exists():
            continue
        text = read_text(csv_path)
        lines = text.split("\n")
        keep: list[str] = []
        for index, line in enumerate(lines):
            if index > 0 and line and not line.startswith('"'):
                key = line.split(",", 1)[0].strip()
                if key in unused:
                    removed += 1
                    continue
            keep.append(line)
        csv_path.write_text("\n".join(keep), encoding="utf-8", newline="")
    return removed


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    args = set(sys.argv[1:])
    files = scan_files()
    keys = defined_keys()
    used, families = used_keys(files)
    hits = hardcoded_hits(files)
    unused = {key for key in keys if not is_used(key, used, families)}
    test_only = test_only_keys(set(keys))
    dead = unused - test_only
    # Tên node của mọi literal trong .gd — dùng để biết chỗ nào bị code GHI ĐÈ lúc chạy
    gd_text = "\n".join(read_text(p) for p in files if p.suffix == ".gd")

    lines_out: list[str] = []

    def emit(text: str = "") -> None:
        lines_out.append(text)
        print(text)

    emit(f"[INFO] quét {len(files)} file · {len(keys)} khoá định nghĩa · "
         f"{len(used)} khoá dùng trực tiếp · {len(families)} họ tiền tố: {sorted(families)}")

    if "--unused" not in args:
        emit(f"\n=== CHUỖI CỨNG TRONG UI ({len(hits)}) ===")
        current = ""
        for rel, line_no, value, source in hits:
            if rel != current:
                current = rel
                emit(f"\n-- {rel}")
            node = node_name_at(ROOT / rel, line_no)
            runtime = " ~runtime" if node and re.search(rf"\b{re.escape(node)}\b", gd_text) else ""
            flag = "VI" if VI_CHARS.search(value) else "  "
            emit(f"   [{flag}] {line_no:>4}  {source}{runtime}  {value!r}")

    emit(f"\n=== KEY CHẾT HẮN ({len(dead)}) — xoá được ==")
    for key in sorted(dead):
        emit(f"  - {key}   ({', '.join(keys[key])})")

    # ---- Vùng GÁC: literal rơi vào production UI (không nằm trong allowlist) là LỖI ----
    gated = [h for h in hits
             if h[0].startswith(GATED_PREFIXES) and (h[0], h[2]) not in PLACEHOLDER_ALLOWLIST]
    emit(f"\n=== VÙNG GÁC (production UI) — {len(gated)} chuỗi cứng ==")
    for rel, line_no, value, source in gated:
        emit(f"  [FAIL] {rel}:{line_no}  {source}  {value!r}")

    emit(f"\n=== KEY CHỈ DÙNG TRONG TEST ({len(test_only & unused)}) — giữ, dọn test rồi hãy xoá ===")
    for key in sorted(test_only & unused):
        emit(f"  - {key}   ({', '.join(keys[key])})")

    if "--drop-unused" in args and dead:
        removed = drop_unused(dead)
        emit(f"\n[OK] đã xoá {removed} dòng khỏi CSV (chạy lại: godot --headless --path . --editor --quit)")

    for arg in args:
        if arg.startswith("--out="):
            Path(arg.split("=", 1)[1]).write_text("\n".join(lines_out), encoding="utf-8")

    if "--check" in args and (gated or dead):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
