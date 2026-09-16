# -*- coding: utf-8 -*-
"""Đối chiếu bảng dịch guide_text_en.EN với toàn bộ chuỗi thật lấy từ mockup.

 - "MISSING": chuỗi có chữ cái nhưng chưa có bản dịch  -> phải bổ sung.
 - "EXTRA"  : khoá trong EN không còn được dùng        -> nên xoá.
Chuỗi chỉ gồm số/ký hiệu (S, F, =, <, 03, 00:45...) được builder tự dùng lại VI.

Chạy: python tools/content/check_text_en.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "mockup"))
sys.path.insert(0, str(ROOT / "tools" / "content"))

import instruction_mockup as im   # noqa: E402
from guide_text_en import EN      # noqa: E402

HAS_LETTER = re.compile(r"[^\W\d_]", re.UNICODE)


def collect_strings() -> dict[str, list[str]]:
    """-> {chuỗi VI: [ngữ cảnh...]}"""
    out: dict[str, list[str]] = {}
    data = im.load_all()
    for mode, pages in data.items():
        for p, d in pages.items():
            ctx = f"{mode}.p{p}"
            for field in ("chip", "title", "section", "cta_text", "link_text"):
                t = d.get(field, "")
                if t:
                    out.setdefault(t, []).append(f"{ctx}.{field}")
            for i, tab in enumerate(d["tabs"], 1):
                out.setdefault(tab, []).append(f"{ctx}.tab{i}")
            for i, row in enumerate(d["rows"], 1):
                for f in ("title", "desc"):
                    t = row.get(f, "")
                    if t:
                        out.setdefault(t, []).append(f"{ctx}.row{i}{f[0].upper()}")
            for t in d["panel_texts"]:
                out.setdefault(t["text"], []).append(f"{ctx}.panel")
    return out


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    strings = collect_strings()
    missing = {t: c for t, c in strings.items() if HAS_LETTER.search(t) and t not in EN}
    extra = [k for k in EN if k not in strings]
    print(f"[INFO] {len(strings)} chuoi duy nhat | da dich {len(EN)}")
    if missing:
        print(f"[MISSING] {len(missing)} chuoi chua dich:")
        for t, ctx in sorted(missing.items()):
            print(f"  - {t!r}   ({ctx[0]})")
    else:
        print("[OK] khong thieu chuoi nao")
    if extra:
        print(f"[EXTRA] {len(extra)} khoa thua trong EN:")
        for k in sorted(extra):
            print(f"  + {k!r}")
    return 1 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
