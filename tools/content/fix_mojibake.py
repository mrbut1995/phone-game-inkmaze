# -*- coding: utf-8 -*-
"""SỬA CHUỖI BỊ MOJIBAKE trong file text (chữ Việt/CJK bị mã hoá nhầm nhiều lớp).

Nguyên nhân: file UTF-8 bị đọc bằng CP1252/"Windows-1252 châm chước" rồi ghi lại UTF-8
⇒ "NHIỆM VỤ" → "THá»¬ THÃCH" (có thể bị chồng 2–3 lớp).

  python tools/content/fix_mojibake.py               # chỉ báo cáo file nào đang lỗi
  python tools/content/fix_mojibake.py --apply       # sửa tại chỗ (chỉ file trong SCAN_DIRS)
  python tools/content/fix_mojibake.py --apply --all # sửa cả file ngoài vùng quét mặc định

Sau khi sửa CSV: chạy `godot --headless --path . --editor --quit` để sinh lại `.translation`.

Lưu ý kỹ thuật:
  • `.translation` là file NHỊ PHÂN (Godot sinh từ CSV) ⇒ không quét.
  • Python không mã hoá ngược được một số ký tự CP1252 (U+0081/0x81, U+20AC/0x80…)
    ⇒ phải tự dựng bảng đảo 256 byte (xem `_build_cp1252_table`).
  • Sửa theo TỪNG Ô của CSV (1 ô lạnh không làm hỏng cả file); các file khác theo TỪNG DÒNG.
  • Ô lành (tiếng Việt/CJK/thật) không đổi được về CP1252 ⇒ tự động giữ nguyên.
"""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCAN_DIRS = ["resources", "scripts", "scenes", "nodes", "planning", "mockup"]
## `.translation` là file NHỊ PHÂN do Godot sinh từ CSV ⇒ bỏ qua (đọc bằng UTF-8 sẽ ra rác giả)
SUFFIXES = (".csv", ".gd", ".tscn", ".tres", ".json", ".md", ".txt", ".cfg")
SKIP_PARTS = ("tools/", "__pycache__", "optimizing_clean")
## Dấu hiệu mojibake tiếng Việt: cụm chỉ sinh ra khi UTF-8 bị đọc bằng CP1252
## (á» = ộ/ớ/ợ, áº = ế/ề/ể, Ä‘ = đ, Æ° = ư, Æ¡ = ơ, â€ = nháy cong)
MARKERS = ("á»", "áº", "Ä‘", "Æ°", "Æ¡", "â€", "Ã¢â‚¬", "ÃƒÂ")
## File tự chứa dấu hiệu (tool/docs nói VỀ mojibake) — không sửa
SKIP_FILES = {"tools/content/fix_mojibake.py", "tools/content/audit_localization.py",
              "tools/content/migrate_hardcoded_text.py"}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def markers(text: str) -> int:
    return sum(text.count(marker) for marker in MARKERS)


def _build_cp1252_table() -> dict[str, int]:
    """Bảng ĐẢO CP1252 đủ 256 byte: Python giải mã 0x81/0x8D/0x8F/0x90/0x9D ra ký tự C1
    (U+0081…) nhưng KHÔNG mã hoá ngược được ⇒ phải tự dựng bảng."""
    table: dict[str, int] = {}
    for byte in range(256):
        try:
            table[bytes([byte]).decode("cp1252")] = byte
        except UnicodeDecodeError:
            pass
        # 5 ô trống bị bộ giải mã "châm chước" trả về đúng ký tự C1 tương ứng
        table.setdefault(chr(byte), byte)
    return table


CP1252_TO_BYTE = _build_cp1252_table()


def to_cp1252_bytes(text: str) -> bytes:
    """Mã hoá ngược về byte CP1252 (dùng bảng đảo, chịu được cả U+0081 lẫn U+20AC)"""
    out = bytearray()
    for char in text:
        byte = CP1252_TO_BYTE.get(char)
        if byte is None:
            raise UnicodeEncodeError("cp1252", text, 0, len(text), "không đổi được")
        out.append(byte)
    return bytes(out)


def score(text: str) -> int:
    """Điểm "bẩn": dấu hiệu mojibake tiếng Việt ×2 + số ký tự điều khiển C1 (U+0080–U+009F).
    Bảng JP/KO/TH khi lỗi sinh nhiều ký tự C1 nên vẫn bắt được dù không có dấu hiệu Việt."""
    c1 = sum(1 for char in text if 0x80 <= ord(char) <= 0x9F)
    return markers(text) * 2 + c1


def looks_clean(text: str) -> bool:
    return markers(text) == 0 and not any(0x80 <= ord(char) <= 0x9F for char in text)


def repair_unit(unit: str) -> str:
    """Sửa 1 ĐƠN VỊ nhỏ (1 ô CSV hoặc 1 dòng): byte CP1252 → UTF-8, lặp tới khi ổn định (≤4 lớp).

    Ô lành (tiếng Việt/CJK thật) sẽ không đổi vì không mã hoá ngược được về CP1252."""
    if unit.isascii():
        return unit
    current = unit
    for _round in range(4):
        candidate = None
        for encoder in (to_cp1252_bytes, lambda text: text.encode("latin-1")):
            try:
                candidate = encoder(current).decode("utf-8")
            except (UnicodeEncodeError, UnicodeDecodeError):
                continue
            break
        if candidate is None or candidate == current:
            break
        current = candidate
    return current if looks_clean(current) else unit


def repair(text: str) -> str:
    """Sửa text: đơn vị là TỪNG Ô trong ngoặc kép của CSV, còn lại theo TỪNG DÒNG"""
    if '","' in text or text.lstrip().startswith("id,"):
        return "\n".join(repair_row(line) for line in text.split("\n"))
    return "\n".join(repair_unit(line) for line in text.split("\n"))


def repair_row(line: str) -> str:
    """CSV: tách theo dấu ngoặc kép, sửa từng ô, phần ngoài ngoặc giữ nguyên"""
    parts = line.split('"')
    for index in range(1, len(parts), 2):
        parts[index] = repair_unit(parts[index])
    return '"'.join(parts)


def scan_targets(scan_all: bool) -> list[Path]:
    targets: list[Path] = []
    for folder in (SCAN_DIRS if not scan_all else ["."]):
        base = ROOT / folder
        if not base.exists():
            continue
        for path in base.rglob("*"):
            if not path.is_file() or path.suffix not in SUFFIXES:
                continue
            rel = path.relative_to(ROOT).as_posix()
            if any(skip in rel for skip in SKIP_PARTS) or rel in SKIP_FILES:
                continue
            targets.append(path)
    return sorted(set(targets))


def sample_line(text: str) -> str:
    """Dòng đầu tiên sửa được (để in ví dụ sau khi sửa)"""
    for line in text.split("\n"):
        if repair(line) != line or markers(line) > 0:
            return repair(line)[:70]
    return ""


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    apply_fix = "--apply" in sys.argv
    scan_all = "--all" in sys.argv

    broken: list[tuple[Path, int]] = []
    for path in scan_targets(scan_all):
        text = read_text(path)
        fixed_text = repair(text)
        if fixed_text == text and score(text) < 3:
            continue
        broken.append((path, len(text) - len(fixed_text)))

    if not broken:
        print("[OK] Không thấy file nào bị mojibake.")
        return 0

    print("[!] %d file bị mojibake:" % len(broken))
    for path, delta in broken:
        rel = path.relative_to(ROOT).as_posix()
        print("  - %s   (byte lệch %d)\n      ví dụ sau khi sửa: %s"
              % (rel, delta, sample_line(read_text(path))))

    if not apply_fix:
        print("\n(chạy lại với --apply để sửa)")
        return 1

    fixed_count = 0
    for path, _delta in broken:
        text = read_text(path)
        fixed = repair(text)
        if fixed != text:
            path.write_text(fixed, encoding="utf-8", newline="")
            fixed_count += 1
    print("\n[OK] đã sửa %d file." % fixed_count)
    print("TIẾP: godot --headless --path . --editor --quit   (sinh lại .translation)")
    print("KIỂM: python tools/content/fix_mojibake.py   → phải báo không còn file lỗi")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
