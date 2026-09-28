# -*- coding: utf-8 -*-
"""Chuyển CHUỖI CỨNG trong UI sang KHOÁ DỊCH (chạy 1 lần, idempotent).

 - Scene/script: thay `text = "<literal>"` → `text = "STR_…"` theo bảng bên dưới.
 - `.tres` danh hiệu: điền `title_key` / `desc_key` (ArchivementData đã hỗ trợ sẵn).
 - `.tres` chương: điền `title_key` / `subtitle_key` (ChapterData vừa thêm hỗ trợ).
 - Khoá MỚI ghi vào `resources/localization/string_extra.csv` (en + vi; ngôn ngữ khác
   dùng bản EN qua fallback).

Chạy: python tools/content/migrate_hardcoded_text.py            # thực hiện
      python tools/content/migrate_hardcoded_text.py --dry-run  # chỉ in việc sẽ làm
"""

from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CSV_EXTRA = ROOT / "resources" / "localization" / "string_extra.csv"

# ---------------------------------------------------------------------------
# 1. Scene/script: literal -> khoá (literal phải khớp CHÍNH XÁC trong file)
# ---------------------------------------------------------------------------
SCENE_REPLACEMENTS: dict[str, list[tuple[str, str]]] = {
    "nodes/hud/portrait/game/sum_path_hud.tscn": [
        ("Tổng số", "STR_HUD_SUM"),
        ("Mục Tiêu", "STR_HUD_TARGET"),
    ],
    "nodes/hud/landscape/game/dungeon_mode.tscn": [
        ("BƯỚC CÒN LẠI", "STR_HUD_STEPS_LEFT"),
        ("HẦM NGỤC", "STR_HUD_DUNGEON_SUB"),
    ],
    "nodes/hud/landscape/game/level_mode.tscn": [
        ("TỐC ĐỘ: TIÊU CHUẨN", "STR_HUD_SPEED_STANDARD"),
    ],
    "nodes/hud/landscape/game/minesweep_hud.tscn": [
        ("ĐANG DÒ MÌN", "STR_HUD_MINE_TIME_SUB"),
    ],
    "nodes/hud/landscape/game/blind_memory_hud.tscn": [
        ("⏸ ĐỒNG HỒ ĐỨNG YÊN", "STR_HUD_BLIND_TIME_PAUSED"),
    ],
    "nodes/game/cell.tscn": [
        ("SẮP PHAI", "STR_CELL_ALMOST_FADED"),
        ("CẠN", "STR_CELL_DRY"),
    ],
    "nodes/hud/portrait/game/action_bar.tscn": [
        ("Submit", "STR_TOOL_SUBMIT"),
        ("UNDO", "STR_TOOL_UNDO"),
        ("HINT", "STR_TOOL_HINT"),
    ],
    "nodes/hud/landscape/game/action_bar.tscn": [
        ("SUBMIT", "STR_TOOL_SUBMIT"),
        ("RESTART", "STR_TOOL_RESTART"),
        ("UNDO", "STR_TOOL_UNDO"),
        ("HINT", "STR_TOOL_HINT"),
    ],
    "nodes/tutorials/how_to_play_wall_builder.tscn": [
        ("GỬI BÀI", "STR_TOOL_SUBMIT"),
    ],
}

# ---------------------------------------------------------------------------
# 2. Khoá MỚI (chưa có trong CSV) — (khoá, EN, VI)
# ---------------------------------------------------------------------------
NEW_KEYS: list[tuple[str, str, str]] = [
    ("STR_HUD_DUNGEON_SUB", "DUNGEON", "HẦM NGỤC"),
    ("STR_HUD_SPEED_STANDARD", "SPEED: STANDARD", "TỐC ĐỘ: TIÊU CHUẨN"),
    ("STR_HUD_MINE_TIME_SUB", "SCANNING MINES", "ĐANG DÒ MÌN"),
    ("STR_HUD_BLIND_TIME_PAUSED", "⏸ TIMER PAUSED", "⏸ ĐỒNG HỒ ĐỨNG YÊN"),
    ("STR_CELL_ALMOST_FADED", "ALMOST FADED", "SẮP PHAI"),
    ("STR_CELL_DRY", "DRY", "CẠN"),
    ("STR_TOOL_RESTART", "RESTART", "CHƠI LẠI"),
    ("STR_TUT_SUM_HUD_FORMAT", "Sum: {0}  |  Target: = {1}", "Tổng: {0}  |  Mục tiêu: = {1}"),
    ("STR_TUT_WB_COUNTER_FORMAT", "Drawn: {0} / {1} segments", "Đã vẽ: {0} / {1} đoạn"),
]

# ---------------------------------------------------------------------------
# 3. Danh hiệu: id -> bản EN (bản VI giữ nguyên trong .tres làm dự phòng)
# ---------------------------------------------------------------------------
ACH_EN: dict[str, tuple[str, str]] = {
    "dl_days_30": ("A Month of Discipline", "Complete 30 days of Daily Challenge"),
    "dl_days_7": ("Diligent Week", "Complete 7 days of Daily Challenge"),
    "dl_first_day": ("First Day", "Complete your first Daily Challenge day"),
    "dl_stars_30": ("Daily Star Vault", "Collect 30 stars from Daily Challenge days"),
    "dl_streak_14": ("14-Day Streak", "Keep a 14-day streak"),
    "dl_streak_3": ("Disciplined Streak", "Keep a 3-day streak"),
    "dl_streak_7": ("7-Day Streak", "Keep a 7-day streak"),
    "dn_floor_15": ("Lord of the Dungeon", "Reach Floor 15 in Dungeon Mode"),
    "dn_floor_30": ("Bottomless Abyss", "Reach Floor 30 in Dungeon Mode"),
    "dn_floor_5": ("Dungeon Conqueror", "Reach Floor 5 in Dungeon Mode"),
    "dn_floors_100": ("Dungeon Bulldozer", "Clear 100 floors total in Dungeon Mode"),
    "dn_floors_25": ("Floor Sweeper", "Clear 25 floors total in Dungeon Mode"),
    "dn_score_20000": ("Dungeon Legend", "Score 20,000 in a single Dungeon run"),
    "dn_score_5000": ("Point Hunter", "Score 5,000 in a single Dungeon run"),
    "lv_clear_10": ("Path Drawer", "Clear 10 levels"),
    "lv_clear_25": ("Maze Master", "Clear 25 levels"),
    "lv_first_step": ("Rookie Explorer", "Clear your first level in Play Mode"),
    "lv_perfect_10": ("Flawless Ten", "Earn 3 stars in 10 levels"),
    "lv_perfect_3": ("Perfect Thrice", "Earn 3 stars in 3 levels"),
    "lv_stars_15": ("Star Collection", "Collect 15 stars from levels"),
    "lv_stars_45": ("Starry Sky", "Collect 45 stars from levels"),
    "sp_claimed_10": ("Badge Collector", "Claim 10 achievements"),
    "sp_hardcore_3": ("Daredevil", "Win 3 levels in Hardcore modes (Blind / Fog of War)"),
    "sp_no_hint_5": ("Self-Reliant", "Win 5 levels/floors without using hints"),
    "sp_no_undo_10": ("No Turning Back", "Win 10 levels/floors without undo"),
    "sp_secret_dungeon_50": ("Secret • Oath of the Dungeon", "Clear 50 floors total in Dungeon Mode"),
    "sp_secret_star_60": ("Secret • Sky Keeper", "Collect 60 stars across all modes"),
    "sp_wins_50": ("Veteran", "Win 50 levels/floors across all modes"),
}

# ---------------------------------------------------------------------------
# 4. Chương: số chương -> bản EN (VI giữ trong .tres làm dự phòng)
# ---------------------------------------------------------------------------
CHAPTER_EN: dict[int, tuple[str, str]] = {
    1: ("INTRO", "Get familiar with step & wall rules"),
    2: ("DEDUCTION", "Bigger mazes with denser walls"),
    3: ("HIDDEN TRAPS", "Test your memory and wall-free drawing"),
    4: ("GRANDMASTER", "Huge mazes for deduction masters"),
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_text(path: Path, text: str) -> None:
    path.write_text(text, encoding="utf-8", newline="")


def load_csv_keys() -> set[str]:
    keys: set[str] = set()
    for name in ("string.csv", "string_extra.csv"):
        path = ROOT / "resources" / "localization" / name
        if not path.exists():
            continue
        with path.open(encoding="utf-8", newline="") as handle:
            for row in csv.reader(handle):
                if row and row[0].startswith("STR_"):
                    keys.add(row[0])
    return keys


def append_keys(keys: list[tuple[str, str, str]], dry: bool) -> int:
    """Ghi khoá mới vào cuối `string_extra.csv` (đúng dạng `id,en,vi` có quote khi cần)"""
    existing = load_csv_keys()
    rows = [(k, en, vi) for k, en, vi in keys if k not in existing]
    if not rows or dry:
        return len(rows)
    text = read_text(CSV_EXTRA)
    if not text.endswith("\n"):
        text += "\n"
    lines = []
    for key, en, vi in rows:
        quote = ("," in en or "," in vi or '"' in en or '"' in vi
                 or "\n" in en or "\n" in vi)
        cell_en = '"%s"' % en.replace('"', '""') if '"' in en else ('"%s"' % en if quote else en)
        cell_vi = '"%s"' % vi.replace('"', '""') if '"' in vi else ('"%s"' % vi if quote else vi)
        # Chỉ quote ô nào cần (khớp cách file đang ghi)
        if "," in en or '"' in en:
            cell_en = '"%s"' % en.replace('"', '""')
        if "," in vi or '"' in vi:
            cell_vi = '"%s"' % vi.replace('"', '""')
        lines.append("%s,%s,%s" % (key, cell_en, cell_vi))
    write_text(CSV_EXTRA, text + "\n".join(lines) + "\n")
    return len(rows)


def replace_in_file(rel: str, pairs: list[tuple[str, str]], dry: bool, report: list[str]) -> None:
    path = ROOT / rel
    if not path.exists():
        report.append("  [BO QUA] %s (không thấy file)" % rel)
        return
    text = read_text(path)
    for literal, key in pairs:
        needle = '"%s"' % literal
        if needle in text:
            text = text.replace(needle, '"%s"' % key)
            report.append("  [DOI] %s: %r -> %s" % (rel, literal, key))
        elif '"%s"' % key in text:
            report.append("  [DA ROI] %s: %s" % (rel, key))
        else:
            report.append("  [KHONG THAY] %s: %r" % (rel, literal))
    if not dry:
        write_text(path, text)


def migrate_achievements(dry: bool, report: list[str]) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    for path in sorted((ROOT / "resources" / "archivements").glob("*.tres")):
        text = read_text(path)
        ach_id = path.stem
        if "title_key" in text:
            report.append("  [DA ROI] %s: đã có title_key" % path.name)
            continue
        en_title, en_desc = ACH_EN.get(ach_id, ("", ""))
        title_key = "STR_ACH_%s_TITLE" % ach_id.upper()
        desc_key = "STR_ACH_%s_DESC" % ach_id.upper()
        vi_title = re.search(r'title = "([^"]*)"', text)
        vi_desc = re.search(r'description = "([^"]*)"', text)
        # chèn ngay sau dòng description để .tres gọn gàng
        text = re.sub(
            r'(\ndescription = "[^"]*"\n)',
            r'\1title_key = "%s"\ndesc_key = "%s"\n' % (title_key, desc_key),
            text,
            count=1,
        )
        rows.append((title_key, en_title, vi_title.group(1) if vi_title else en_title))
        rows.append((desc_key, en_desc, vi_desc.group(1) if vi_desc else en_desc))
        report.append("  [THEM KEY] %s: %s + %s" % (path.name, title_key, desc_key))
        if not dry:
            write_text(path, text)
    return rows


def migrate_chapters(dry: bool, report: list[str]) -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    for path in sorted((ROOT / "resources" / "chapters").glob("chapter_*.tres")):
        text = read_text(path)
        number = int(re.search(r"chapter_id = (\d+)", text).group(1))
        if "title_key" in text:
            report.append("  [DA ROI] %s: đã có title_key" % path.name)
            continue
        en_title, en_sub = CHAPTER_EN.get(number, ("", ""))
        title_key = "STR_CHAPTER_%d_NAME" % number
        sub_key = "STR_CHAPTER_%d_SUB" % number
        vi_title = re.search(r'title = "([^"]*)"', text)
        vi_sub = re.search(r'subtitle = "([^"]*)"', text)
        text = re.sub(
            r'(\nsubtitle = "[^"]*"\n)',
            r'\1title_key = "%s"\nsubtitle_key = "%s"\n' % (title_key, sub_key),
            text,
            count=1,
        )
        rows.append((title_key, en_title, vi_title.group(1) if vi_title else en_title))
        rows.append((sub_key, en_sub, vi_sub.group(1) if vi_sub else en_sub))
        report.append("  [THEM KEY] %s: %s + %s" % (path.name, title_key, sub_key))
        if not dry:
            write_text(path, text)
    return rows


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    dry = "--dry-run" in sys.argv
    report: list[str] = []
    print("[1] Scene/script: thay literal bằng khoá")
    for rel, pairs in SCENE_REPLACEMENTS.items():
        replace_in_file(rel, pairs, dry, report)
    print("\n".join(report) or "  (không có)")

    print("\n[2] Danh hiệu (.tres) — điền title_key/desc_key")
    mark = len(report)
    ach_rows = migrate_achievements(dry, report)
    print("\n".join(report[mark:]) or "  (không có)")

    print("\n[3] Chương (.tres) — điền title_key/subtitle_key")
    mark = len(report)
    chapter_rows = migrate_chapters(dry, report)
    print("\n".join(report[mark:]) or "  (không có)")

    print("\n[4] Ghi khoá mới vào string_extra.csv")
    added = append_keys(NEW_KEYS + ach_rows + chapter_rows, dry)
    print("  [%s] %d khoá" % ("dry-run" if dry else "OK", added))
    if not dry:
        print("\nTIẾP: chạy  godot --headless --path . --editor --quit  rồi test lại.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
