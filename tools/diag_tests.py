"""Chạy test và in các DÒNG LỖI kèm ngữ cảnh (file:line) để soi nhanh.

Usage: python tools/diag_tests.py test_a test_b …
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


def run(name: str, timeout: float = 150.0, keep: int = 30) -> None:
    print(f"\n######## {name} ########")
    cmd = [GODOT, "--headless", "--path", str(ROOT), "--script", f"res://scripts/test_case/{name}.gd"]
    try:
        done = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True,
                              encoding="utf-8", errors="replace", timeout=timeout)
        out = (done.stdout or "") + "\n" + (done.stderr or "")
        print(f"[exit={done.returncode}]")
    except subprocess.TimeoutExpired as exc:
        out = str(exc.stdout or "") + "\n" + str(exc.stderr or "")
        print("[TIMEOUT]")
    lines = out.splitlines()
    shown = 0
    for i, line in enumerate(lines):
        if re.search(r"(SCRIPT ERROR|Parse Error|Assertion|\[FAIL\]|KET QUA)", line):
            if i and lines[i - 1].strip() and "SCRIPT ERROR" not in lines[i - 1]:
                print("   ↳ " + lines[i - 1].strip()[:170])
            print("  !! " + line.strip()[:200])
            if i + 1 < len(lines) and lines[i + 1].strip().startswith("at:"):
                print("       " + lines[i + 1].strip()[:170])
            shown += 1
            if shown >= keep:
                break


def main() -> None:
    for name in sys.argv[1:]:
        run(name)


if __name__ == "__main__":
    main()
