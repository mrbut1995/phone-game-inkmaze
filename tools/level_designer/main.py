#!/usr/bin/env python3
"""InkMaze Level Designer - điểm khởi chạy.

Cách dùng:
    python main.py                 # mở giao diện
    python main.py --level 3       # mở sẵn level 3
    python main.py --project D:\\godot-phone-game\\phone-game-inkmaze
    python main.py --selftest      # tự kiểm tra (không cần màn hình)
    python main.py --export-example 3 --out out/level_3.tres
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

# Console Windows (khi bị pipe ra file) có thể không in được tiếng Việt -> ép UTF-8.
# Bản build --windowed không có console nên stdout/stderr là None -> gán vào devnull để print không lỗi.
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
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="LevelDesigner",
        description="Công cụ thiết kế màn chơi (resources/levels/*.tres) cho game InkMaze.",
    )
    parser.add_argument("--project", help="thư mục gốc dự án Godot (chứa project.godot)")
    parser.add_argument("--level", type=int, help="mở sẵn level_id này khi khởi động")
    parser.add_argument("--selftest", action="store_true",
                        help="chạy kiểm tra logic đọc/ghi .tres rồi thoát (không mở cửa sổ)")
    parser.add_argument("--export-example", type=int, metavar="N",
                        help="xuất level N ra file .tres rồi thoát (không mở cửa sổ)")
    parser.add_argument("--out", metavar="PATH", help="đường dẫn file cho --export-example")
    parser.add_argument("--version", action="store_true", help="in phiên bản rồi thoát")
    return parser


# ----------------------------------------------------------------------
# Các chế độ chạy không cần giao diện
# ----------------------------------------------------------------------
def run_selftest() -> int:
    """Kiểm tra nhanh: đọc 9 màn thật -> ghi lại -> đọc lại so sánh; thử solver/validator/undo."""
    import tempfile

    from app.controllers.app_controller import AppController
    from app.models.repository import LevelRepository
    from app.services import solver, tres_io, validator

    from app import config

    print("== InkMaze Level Designer self-test ==")
    print("Thư mục dự án :", config.PROJECT_ROOT)
    print("Thư mục levels:", config.LEVELS_DIR)

    failures: list[str] = []
    real_repo = LevelRepository()
    summaries = real_repo.list_summaries()
    print("Tìm thấy %d màn trong resources/levels" % len(summaries))

    for summary in summaries:
        try:
            level = real_repo.load(summary.level_id)
        except Exception as error:  # noqa: BLE001
            failures.append("Đọc level_%d thất bại: %s" % (summary.level_id, error))
            continue

        try:
            emitted = tres_io.dumps(level)
            again = tres_io.loads(emitted)
        except Exception as error:  # noqa: BLE001
            failures.append("Ghi lại level_%d thất bại: %s" % (summary.level_id, error))
            continue

        if level.snapshot() != again.snapshot():
            failures.append("Level %d: dữ liệu khác sau khi ghi/đọc lại" % summary.level_id)
        if not level.start_end_ok():
            failures.append("Level %d: S/F không hợp lệ" % summary.level_id)

        info = solver.analyze(level)
        issues = validator.validate(level)
        flag = "OK " if info["solved"] else "!! "
        print("  %slevel_%-2d %dx%d  đường ngắn nhất=%s bước  max_steps=%d  %s" % (
            flag, summary.level_id, level.width, level.height,
            info["path_length"] if info["solved"] else "-", level.max_steps,
            validator.summary_line(issues) or "không lỗi"))

    # Thử toàn bộ luồng của controller trên 1 thư mục tạm
    with tempfile.TemporaryDirectory() as tmp:
        app = AppController(repository=LevelRepository(Path(tmp)))
        app.create_level(42, 4, 4)
        editor = app.editor
        editor.set_property("level_title", "Self test")
        editor.begin_stroke()
        # Vẽ 1 hàng tường nhưng chừa 1 ô ở cột cuối -> vẫn phải còn đường đi
        for x in range(editor.level.width - 1):
            editor.apply_wall_tool(("h", x, 2), toggle=False)
        editor.end_stroke()
        drawn = editor.level.snapshot()

        if not solver.analyze(editor.level)["solved"]:
            failures.append("Sau khi vẽ tường vẫn phải còn đường đi (test 42)")

        if not app.save_current():
            failures.append("Lưu file test thất bại")
        else:
            reloaded = LevelRepository(Path(tmp)).load(42)
            if reloaded.snapshot() != drawn:
                failures.append("Dữ liệu khác sau khi lưu qua repository")

        editor.undo()
        if editor.level.snapshot() == drawn:
            failures.append("Undo không có tác dụng")
        editor.redo()
        if editor.level.wall_count((0, 1)) == 0:
            failures.append("Redo không phục hồi tường")
        if editor.level.snapshot() != drawn:
            failures.append("Redo không trả về đúng trạng thái trước khi undo")

    from app.models.chapter_repository import ChapterRepository

    # --- CHƯƠNG: liệt kê chương thật + thử tạo chương & gán màn (thư mục tạm) ---
    print("\n== CHƯƠNG (resources/chapters) ==")
    real_chapters = ChapterRepository(levels=real_repo).list_summaries()
    if not real_chapters:
        print("  (chưa có chương nào — mở menu 'Chương' > 'Tạo chương theo dữ liệu màn')")
    for summary in real_chapters:
        print("  chương %d · %-14s · %-8s · %s · %d màn · tối đa %d sao" % (
            summary.chapter_id, summary.title, summary.icon or "(auto)",
            "mở sẵn" if summary.star_cost <= 0 else "cần %d sao" % summary.star_cost,
            summary.level_count, summary.star_total))
    used = {ChapterRepository(levels=real_repo).chapter_of_level(s.level_id) for s in summaries}
    missing = sorted(n for n in used if n not in {c.chapter_id for c in real_chapters})
    if missing:
        failures.append("Thiếu file chapter cho chương: %s" % missing)

    with tempfile.TemporaryDirectory() as tmp:
        temp_levels = LevelRepository(Path(tmp) / "levels")
        chapters_repo = ChapterRepository(Path(tmp) / "chapters", levels=temp_levels)
        app = AppController(repository=temp_levels, chapters=chapters_repo)
        for level_id in range(1, 6):
            temp_levels.save(temp_levels.create_level(level_id, 3, 3))
        created = app.ensure_chapters_for_levels()
        if created != 1:
            failures.append("Phải tạo 1 chương từ dữ liệu màn (nhận %d)" % created)
        if app.assign_levels_to_chapter(1, [4, 5]) != 2:
            failures.append("Gán 2 màn vào chương 1 thất bại")
        chapter_summaries = app.chapter_summaries()
        if not chapter_summaries or chapter_summaries[0].level_count != 5:
            failures.append("Chương 1 phải gom đủ 5 màn sau khi gán")
        if chapter_summaries and chapter_summaries[0].star_cost != 0:
            failures.append("Chương 1 phải mở sẵn (star_cost = 0)")
        moved = chapters_repo.clear_levels(1)
        if moved != 0:
            failures.append("clear_levels(1) không được chuyển màn của chương 1")

    if failures:
        print("\nTHẤT BẠI:")
        for failure in failures:
            print(" -", failure)
        return 1

    print("\nTẤT CẢ KIỂM TRA ĐỀU ĐẠT ✔")
    return 0


def run_export_example(level_id: int, out_path: Path) -> int:
    """Đọc 1 màn thật rồi ghi ra đường dẫn khác (không sửa file gốc)."""
    from app.models.repository import LevelRepository
    from app.services import tres_io

    repo = LevelRepository()
    level = repo.load(level_id)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(tres_io.dumps(level), encoding="utf-8")
    print("Đã xuất level %d -> %s (%d bytes)" % (level_id, out_path, out_path.stat().st_size))
    return 0


def run_gui(level_id: int | None) -> int:
    """Mở giao diện Tkinter."""
    from app.views.main_window import MainWindow

    window = MainWindow(open_level_id=level_id)
    window.mainloop()
    return 0


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    # Phải đặt biến môi trường TRƯỚC khi import package app (config đọc lúc import)
    if args.project:
        os.environ["INKMAZE_PROJECT_ROOT"] = str(Path(args.project).expanduser())

    if args.version:
        from app import __version__

        print("InkMaze Level Designer %s" % __version__)
        return 0

    if args.selftest:
        return run_selftest()

    if args.export_example is not None:
        from app import config

        out = Path(args.out) if args.out else (config.default_output_dir() / ("level_%d.tres" % args.export_example))
        return run_export_example(args.export_example, out)

    try:
        return run_gui(args.level)
    except Exception as error:  # noqa: BLE001 - báo lỗi thân thiện khi khởi động
        print("Lỗi khởi động: %s" % error, file=sys.stderr)
        raise


if __name__ == "__main__":
    raise SystemExit(main())
