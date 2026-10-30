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

import os

_DEFAULT_GODOT_CANDIDATES = [
    # Engine THẬT của game (bản dev 4.8 đã build riêng). LƯU Ý: file `.console.exe`
    # nằm cùng thư mục bin là bản 4.4-stable cũ ⇒ KHÔNG dùng để chạy test (kết quả lệch).
    r"D:\Godots\app dev\Godot Source Code\godot\bin\godot.windows.editor.x86_64.exe",
    r"D:\Godots\app dev\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe",
]
GODOT = next((p for p in _DEFAULT_GODOT_CANDIDATES if os.path.exists(p)), _DEFAULT_GODOT_CANDIDATES[0])
ROOT = pathlib.Path(__file__).resolve().parents[1]

DEFAULT = [
    "test_layout_bindings",
    "test_popup_bindings",
    "test_full_flow",
    "test_levels_map",
    "test_main_layout",
    "test_daily",
    "test_shop",
    "test_achievement",
    "test_profiler",
    "test_ranking",
    "test_chapters",
    "test_ui_scenes",
    "test_splash_title_shop_chapters",
    "test_game_scene_integration",
    "test_tutorial_flow",
    "test_controllers_and_signals",
    "test_level_special_modes",
    "test_challenge_mode",
    "test_event_manager",
    "test_localization",
]


def _project_name() -> str:
    """Tên project trong `project.godot` (config/name) — dùng để tìm thư mục user://."""
    try:
        for line in (ROOT / "project.godot").read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("config/name="):
                return line.split("=", 1)[1].strip().strip('"')
    except OSError:
        pass
    return ROOT.name


def _user_save_path() -> pathlib.Path | None:
    """Đường dẫn file save người chơi (`user://inkmaze_data.json`) nếu tìm thấy thư mục user://."""
    name = _project_name()
    dirs: list[pathlib.Path] = []
    appdata = os.environ.get("APPDATA")
    if appdata:
        dirs.append(pathlib.Path(appdata) / "Godot" / "app_userdata" / name)
    home = pathlib.Path(os.path.expanduser("~"))
    dirs.append(home / ".local" / "share" / "godot" / "app_userdata" / name)
    dirs.append(home / "Library" / "Application Support" / "Godot" / "app_userdata" / name)
    for d in dirs:
        if d.is_dir():
            return d / "inkmaze_data.json"
    return None


def run(name: str, timeout: float) -> tuple[str, str]:
    script = f"res://scripts/test_case/{name}.gd"
    cmd = [GODOT, "--headless", "--path", str(ROOT), "--script", script]
    # ☠️ LƯỚI AN TOÀN cho SAVE NGƯỜI CHƠI: nhiều test đổi tiến trình (sao/màn/cửa hàng…),
    # thay đổi đó phát tín hiệu "changed" ⇒ SaveManager GHI NGAY vào `user://…/inkmaze_data.json`.
    # Test nào quên khôi phục file (hoặc chỉ khôi phục RAM) sẽ XOÁ TIẾN TRÌNH THẬT của người chơi.
    # ⇒ Chụp file TRƯỚC mỗi test và trả lại NGUYÊN VĂN sau khi test xong.
    save_path = _user_save_path()
    snapshot: bytes | None = None
    if save_path is not None and save_path.exists():
        snapshot = save_path.read_bytes()
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
        verdict, out = "TIMEOUT", out
        return verdict, tail
    finally:
        if save_path is not None:
            try:
                if snapshot is not None:
                    save_path.write_bytes(snapshot)
                elif save_path.exists():
                    save_path.unlink()
            except OSError:
                print(f"  ⚠ không khôi phục được save người chơi: {save_path}")
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
