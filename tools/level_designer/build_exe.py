#!/usr/bin/env python3
"""Build file .exe cho Level Designer bằng PyInstaller.

Cách dùng:
    python build_exe.py            # build bình thường
    python build_exe.py --console  # build kèm cửa sổ console (để xem log/lỗi)
    python build_exe.py --keep     # giữ lại thư mục build/ trung gian

Kết quả: tools/level_designer/dist/LevelDesigner.exe
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

# Khi bị chuyển hướng ra file/pipe, console Windows có thể dùng cp1252 -> in tiếng Việt lỗi.
for name in ("stdout", "stderr"):
    stream = getattr(sys, name, None)
    if stream is None:
        setattr(sys, name, open(os.devnull, "w", encoding="utf-8"))
    elif hasattr(stream, "reconfigure"):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:  # noqa: BLE001
            pass

APP_DIR = Path(__file__).resolve().parent
APP_NAME = "LevelDesigner"
DIST_DIR = APP_DIR / "dist"
WORK_DIR = APP_DIR / "build"


def check_pyinstaller() -> None:
    try:
        import PyInstaller  # noqa: F401
    except ImportError:
        print("Chưa có PyInstaller. Cài bằng lệnh:")
        print("    %s -m pip install -r requirements-dev.txt" % sys.executable)
        raise SystemExit(2)


def build(console: bool, clean: bool) -> int:
    check_pyinstaller()
    command = [
        sys.executable, "-m", "PyInstaller",
        "--noconfirm",
        "--onefile",
        "--name", APP_NAME,
        "--distpath", str(DIST_DIR),
        "--workpath", str(WORK_DIR),
        "--specpath", str(WORK_DIR),
        "--windowed" if not console else "--console",
        "main.py",
    ]
    if clean:
        command.insert(3, "--clean")

    print("Chạy:", " ".join(command))
    started = time.time()
    result = subprocess.run(command, cwd=str(APP_DIR), check=False)
    if result.returncode != 0:
        print("Build thất bại (mã %d)" % result.returncode)
        return result.returncode

    exe = DIST_DIR / ("%s.exe" % APP_NAME if sys.platform == "win32" else APP_NAME)
    print("\nBuild xong sau %.1f giây" % (time.time() - started))
    print("File chạy:", exe)
    print("Kiểm tra nhanh:", '"%s" --selftest' % exe)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Build LevelDesigner.exe bằng PyInstaller")
    parser.add_argument("--console", action="store_true", help="giữ cửa sổ console khi chạy")
    parser.add_argument("--keep", action="store_true", help="giữ thư mục build/ trung gian")
    args = parser.parse_args()
    return build(console=args.console, clean=not args.keep)


if __name__ == "__main__":
    raise SystemExit(main())
