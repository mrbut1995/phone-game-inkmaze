# -*- coding: utf-8 -*-
"""Sinh bộ key dịch STR_GI_* từ mockup + bảng dịch EN, rồi ghi vào string_extra.csv.

Kết quả phụ: tools/content/_guide_keys.json — bản đồ "chuỗi VI -> key" để
tools/mockup/gen_instruction_popups.py dùng lại (tránh trùng logic).

  - STR_GI_<MODE>_CHIP             : chip nhỏ góc trên (1 key / chế độ)
  - STR_GI_<MODE>_P<n>_TITLE/…     : tiêu đề, mục, CTA, link, tab, 3 hàng luật
  - STR_GI_PAGE_INDEX              : "TRANG {0} / {1}"
  - STR_GI_X###                    : mọi chữ nằm trên khung minh hoạ (dedupe)

Chạy: python tools/content/build_instruction_data.py
"""

from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "mockup"))
sys.path.insert(0, str(ROOT / "tools" / "content"))

import instruction_mockup as im          # noqa: E402
from guide_text_en import EN              # noqa: E402

CSV_PATH = ROOT / "resources" / "localization" / "string_extra.csv"
KEYS_PATH = ROOT / "tools" / "content" / "_guide_keys.json"
DROP_PREFIXES = ("STR_GI_", "STR_INSTRUCTION_")
PAGE_INDEX_KEY = ("STR_GI_PAGE_INDEX", "PAGE {0} / {1}", "TRANG {0} / {1}")


def en_of(vi: str) -> str:
    return EN.get(vi, vi)


def build() -> tuple[list[tuple[str, str, str]], dict]:
    data = im.load_all()
    rows: list[tuple[str, str, str]] = []
    keymap: dict = {"modes": {}, "panel_texts": {}}

    for mode, pages in data.items():
        m = mode.upper()
        entry: dict = {"pages": {}}
        keymap["modes"][mode] = entry

        chip = next((d["chip"] for d in pages.values() if d["chip"]), "")
        if chip:
            rows.append((f"STR_GI_{m}_CHIP", en_of(chip), chip))
            entry["chip"] = [f"STR_GI_{m}_CHIP", chip]

        for p, d in pages.items():
            base = f"STR_GI_{m}_P{p}"
            pe: dict = {}
            entry["pages"][str(p)] = pe

            def chrome(field: str, suffix: str) -> None:
                txt = d.get(field, "")
                if txt:
                    rows.append((f"{base}_{suffix}", en_of(txt), txt))
                    pe[suffix.lower()] = [f"{base}_{suffix}", txt]

            chrome("title", "TITLE")
            chrome("section", "SECTION")
            chrome("cta_text", "CTA")
            chrome("link_text", "LINK")
            tabs = []
            for i, tab in enumerate(d["tabs"], 1):
                rows.append((f"{base}_TAB{i}", en_of(tab), tab))
                tabs.append([f"{base}_TAB{i}", tab])
            pe["tabs"] = tabs
            rules = []
            for i, row in enumerate(d["rows"], 1):
                rt = row["title"]
                rd = row["desc"]
                item = {"title": None, "desc": None}
                if rt:
                    rows.append((f"{base}_R{i}T", en_of(rt), rt))
                    item["title"] = [f"{base}_R{i}T", rt]
                if rd:
                    rows.append((f"{base}_R{i}D", en_of(rd), rd))
                    item["desc"] = [f"{base}_R{i}D", rd]
                rules.append(item)
            pe["rules"] = rules

    for mode, pages in data.items():
        for p, d in pages.items():
            for t in d["panel_texts"]:
                txt = t["text"]
                if txt in keymap["panel_texts"]:
                    continue
                if im.is_literal_text(txt):
                    continue    # số/ký hiệu trên grid -> ghi thẳng, không cần khoá dịch
                key = f"STR_GI_X{len(keymap['panel_texts']) + 1:03d}"
                keymap["panel_texts"][txt] = key

    xrows = [(key, en_of(txt), txt) for txt, key in keymap["panel_texts"].items()]
    rows.append(PAGE_INDEX_KEY)
    rows.sort(key=lambda r: r[0])
    xrows.sort(key=lambda r: r[0])
    return rows + xrows, keymap


def update_csv(new_rows: list[tuple[str, str, str]]) -> tuple[int, int]:
    with CSV_PATH.open("r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f)
        all_rows = list(reader)
    header, body = all_rows[0], all_rows[1:]
    kept = [r for r in body if r and not r[0].startswith(DROP_PREFIXES)]
    dropped = len(body) - len(kept)
    ids = {r[0] for r in new_rows}
    dupe = len(new_rows) - len(ids)
    assert dupe == 0, f"key trung lap: {dupe}"
    with CSV_PATH.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        writer.writerows(kept)
        writer.writerows(new_rows)
    return dropped, len(new_rows)


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    rows, keymap = build()
    KEYS_PATH.write_text(json.dumps(keymap, ensure_ascii=False, indent=1), encoding="utf-8")
    dropped, added = update_csv(rows)
    print(f"[OK] xoa {dropped} dong cu (STR_INSTRUCTION_/STR_GI_), them {added} dong moi")
    print(f"[OK] keymap -> {KEYS_PATH.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
