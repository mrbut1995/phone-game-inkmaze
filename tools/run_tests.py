"""Chạy các test Godot headless KÈM TIMEOUT từng test (test lỗi assert thường treo vì không quit()).

Usage:
  python tools/run_tests.py                     # chạy bộ mặc định
  python tools/run_tests.py test_a test_b …     # chạy test chỉ định (tên không cần .gd)
  python tools/run_tests.py --timeout 60 …      # đổi timeout (giây/test, mặc định 120)
"""

from __future__ import annotations

import pathlib
import re
import subprocess
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

GODOT = r"D:\Godots\app dev\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe"
ROOT = pathlib.Path(__file__).resolve().parents[1]

DEFAULT = [
    "test_layout_bindings",
    "test_full_flow",
    "test_levels_paging",
    "test_main_layout",
    "test_daily",
    "test_shop",
    "test_archivement",
    "test_ranking",
    "test_chapters",
    "test_ui_scenes",
    "test_splash_title_shop_chapters",
    "test_game_scene_integration",
    "test_controllers_and_signals",
]


def run(name: str, timeout: float) -> tuple[str, str]:
    script = f"res://scripts/test_case/{name}.gd"
    cmd = [GODOT, "--headless", "--path", str(ROOT), "--script", script]
    try:
        done = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                              encoding="utf-8", errors="replace", timeout=timeout)
        out = (done.stdout or "") + (done.stderr or "")
        verdict = "PASS" if done.returncode == 0 else "FAIL"
    except subprocess.TimeoutExpired as exc:
        out = ((exc.stdout or "") if isinstance(exc.stdout, str) else "") + \
              ((exc.stderr or "") if isinstance(exc.stderr, str) else "")
        fails = [l.strip() for l in out.splitlines() if "FAIL" in l or "SCRIPT ERROR" in l]
        tail = " | ".join(fails[-3:]) if fails else "(không có dòng FAIL — có thể treo ở await)"
        return "TIMEOUT", tail
    summary = ""
    for line in out.splitlines():
        if re.search(r"KET QUA|CHECK PASS|CHECK FAIL|\[SUCCESS\]|\[FAIL\]", line):
            summary = line.strip()
    if not summary:
        errors = [l.strip() for l in out.splitlines() if "SCRIPT ERROR" in l or "Assertion failed" in l]
        summary = " | ".join(errors[-2:]) if errors else "(không thấy dòng KẾT QUẢ)"
    return verdict, summary


def main() -> None:
    argv = sys.argv[1:]
    names: list[str] = []
    timeout = 120.0
    i = 0
    while i < len(argv):
        if argv[i] == "--timeout":
            timeout = float(argv[i + 1])
            i += 2
            continue
        if not argv[i].startswith("--"):
            names.append(argv[i])
        i += 1
    names = names or DEFAULT
    worst = 0
    print(f"\n=== CHẠY {len(names)} TEST (timeout {timeout:.0f}s/test) ===")
    for name in names:
        verdict, summary = run(name, timeout)
        mark = {"PASS": "✔", "FAIL": "✘", "TIMEOUT": "⏱"}[verdict]
        print(f"  {mark} {name:<38} {verdict:<8} {summary}")
        if verdict != "PASS":
            worst = 1
    print("=== XONG ===\n")
    sys.exit(worst)


if __name__ == "__main__":
    main()
