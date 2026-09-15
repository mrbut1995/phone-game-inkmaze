"""Controller: điều phối toàn ứng dụng - quản lý file level + kết nối view.

View chỉ gọi các hàm ở đây (mở/lưu/tạo/xoá/kiểm tra), controller lo phần còn lại.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from ..config import ensure_levels_dir, project_root_hint
from ..models.chapter import ChapterModel
from ..models.chapter_repository import ChapterRepository, ChapterSummary
from ..models.level import LevelModel
from ..models.repository import LevelRepository, LevelSummary
from ..services import solver, validator
from .editor_controller import EditorController
from .events import (
    EV_LEVEL_CHANGED,
    EV_LEVELS_CHANGED,
    EV_STATUS,
    EventEmitter,
)


class AppController:
    """Bộ điều phối chính: thao tác file + trạng thái màn đang mở."""

    def __init__(
        self,
        repository: LevelRepository | None = None,
        editor: EditorController | None = None,
        chapters: ChapterRepository | None = None,
    ) -> None:
        self.events = EventEmitter()
        self.repository = repository or LevelRepository()
        self.editor = editor or EditorController(events=self.events)
        # editor dùng chung emitter với app controller để view chỉ cần nghe 1 chỗ
        self.editor.events = self.events
        # Chương gom màn theo LevelData.chapter -> dùng CHUNG repository level
        self.chapters = chapters or ChapterRepository(levels=self.repository)

    # ------------------------------------------------------------------
    # Danh sách level
    # ------------------------------------------------------------------
    def levels_dir(self) -> Path:
        return self.repository.levels_dir

    def level_summaries(self) -> list[LevelSummary]:
        return self.repository.list_summaries()

    def refresh_levels(self) -> None:
        self.events.emit(EV_LEVELS_CHANGED, self.level_summaries())

    # ------------------------------------------------------------------
    # Mở / tạo
    # ------------------------------------------------------------------
    def load_level(self, level_id: int) -> bool:
        try:
            model = self.repository.load(level_id)
        except Exception as error:  # noqa: BLE001 - file hỏng/không đọc được
            self.events.emit(EV_STATUS, "Không mở được level %d: %s" % (level_id, error))
            return False
        self.editor.replace_level(model)
        self.events.emit(EV_STATUS, "Đã mở level %d (%dx%d)" % (model.level_id, model.width, model.height))
        return True

    def create_level(self, level_id: int | None = None, width: int = 3, height: int = 3,
                     chapter: int | None = None) -> LevelModel:
        if chapter is None:
            # Màn mới nằm cùng chương với màn đang mở (tiện xếp chương theo nhóm)
            chapter = max(1, int(self.editor.level.chapter))
        model = self.repository.create_level(level_id, width, height, chapter)
        self.editor.replace_level(model)
        self.events.emit(EV_STATUS, "Tạo màn mới #%d (%dx%d) - chương %d - nhớ lưu để ghi ra file" % (
            model.level_id, model.width, model.height, model.chapter))
        return model

    # ------------------------------------------------------------------
    # Chương (CHỌN CHƯƠNG)
    # ------------------------------------------------------------------
    def chapters_dir(self) -> Path:
        return self.chapters.chapters_dir

    def chapter_summaries(self) -> list[ChapterSummary]:
        return self.chapters.list_summaries()

    def chapter_count(self) -> int:
        return len(self.chapters.list_summaries())

    def create_chapter(self, chapter_id: int | None = None) -> ChapterModel:
        return self.chapters.create_chapter(chapter_id)

    def save_chapter(self, chapter: ChapterModel) -> bool:
        try:
            path = self.chapters.save(chapter)
        except Exception as error:  # noqa: BLE001 - ghi file lỗi
            self.events.emit(EV_STATUS, "Lỗi khi ghi chương: %s" % error)
            return False
        self.events.emit(EV_STATUS, "Đã lưu chương %d: %s" % (chapter.chapter_id, chapter.title))
        return bool(path)

    def delete_chapter(self, chapter_id: int) -> bool:
        if not self.chapters.delete(chapter_id):
            self.events.emit(EV_STATUS, "Không tìm thấy file chapter_%d.tres" % chapter_id)
            return False
        self.events.emit(EV_STATUS, "Đã xoá chapter_%d.tres (màn trong chương vẫn còn)" % chapter_id)
        self.refresh_levels()
        return True

    def ensure_chapters_for_levels(self) -> int:
        """Tự tạo file chương cho mọi chương đang có màn nhưng chưa có .tres."""
        created = self.chapters.ensure_for_levels()
        if created:
            self.events.emit(EV_STATUS, "Đã tạo %d chương theo dữ liệu màn: %s" % (
                len(created), ", ".join(str(c.chapter_id) for c in created)))
        else:
            self.events.emit(EV_STATUS, "Mọi chương có màn đều đã có file .tres")
        return len(created)

    def assign_levels_to_chapter(self, chapter_id: int, level_ids) -> int:
        """Gán danh sách màn vào chương (ghi `chapter` cho từng file màn)."""
        assigned = self.chapters.assign_levels(chapter_id, level_ids)
        if assigned:
            self.refresh_levels()
            self.events.emit(EV_STATUS, "Đã gán %d màn vào chương %d: %s" % (
                len(assigned), chapter_id, ", ".join(str(i) for i in assigned)))
        else:
            self.events.emit(EV_STATUS, "Không có màn nào được gán (sai số hoặc thiếu file .tres)")
        return len(assigned)

    def assign_current_level_to_chapter(self, chapter_id: int) -> bool:
        """Gán màn ĐANG MỞ trong editor vào chương (tiện thao tác nhanh)."""
        level_id = int(self.editor.level.level_id)
        ok = self.chapters.assign_level(level_id, chapter_id)
        if ok:
            self.editor.level.chapter = int(chapter_id)
            self.refresh_levels()
            self.events.emit(EV_STATUS, "Màn #%d đã thuộc chương %d (nhớ Ctrl+S để lưu)" % (
                level_id, chapter_id))
        return ok

    def duplicate_current(self) -> LevelModel:
        clone = self.repository.duplicate(self.editor.level)
        self.editor.replace_level(clone)
        self.events.emit(EV_STATUS, "Đã nhân bản thành màn #%d (chưa ghi file)" % clone.level_id)
        return clone

    # ------------------------------------------------------------------
    # Lưu
    # ------------------------------------------------------------------
    def save_current(self) -> bool:
        model = self.editor.level
        issues = validator.validate(model)
        if validator.has_errors(issues):
            self.events.emit(
                EV_STATUS,
                "Không lưu: " + "; ".join(i.message for i in issues if i.is_error),
            )
            return False

        try:
            path = self.repository.save(model)
        except Exception as error:  # noqa: BLE001
            self.events.emit(EV_STATUS, "Lỗi khi ghi file: %s" % error)
            return False

        # Nạp lại để lấy uid Godot cấp cho file mới (nếu có)
        try:
            model = self.repository.load_path(path)
            self.editor.replace_level(model, reset_history=False)
        except Exception:  # noqa: BLE001 - không quan trọng, chỉ để đồng bộ uid
            pass

        self.editor._set_dirty(False)  # noqa: SLF001 - cờ dirty thuộc editor
        self.editor.events.emit(EV_LEVEL_CHANGED, self.editor.level)
        self.refresh_levels()
        self.events.emit(EV_STATUS, "Đã lưu %s" % path.name)
        return True

    def save_as(self, level_id: int) -> bool:
        self.editor.set_property("level_id", int(level_id))
        return self.save_current()

    def reload_current(self) -> bool:
        level_id = self.editor.level.level_id
        self.events.emit(EV_STATUS, "Nạp lại level %d từ đĩa" % level_id)
        return self.load_level(level_id)

    def delete_level(self, level_id: int) -> bool:
        if not self.repository.delete(level_id):
            self.events.emit(EV_STATUS, "Không tìm thấy file level_%d.tres" % level_id)
            return False
        self.refresh_levels()
        self.events.emit(EV_STATUS, "Đã xoá level_%d.tres" % level_id)
        return True

    # ------------------------------------------------------------------
    # Kiểm tra / phân tích
    # ------------------------------------------------------------------
    def validate_current(self) -> list[validator.Issue]:
        return validator.validate(self.editor.level)

    def analysis(self) -> dict:
        return solver.analyze(self.editor.level)

    def stats(self) -> dict:
        return self.editor.level.stats()

    # ------------------------------------------------------------------
    # Xuất thêm định dạng khác (tiện cho tool/debug)
    # ------------------------------------------------------------------
    def export_json(self, path: Path) -> bool:
        model = self.editor.level
        payload: dict[str, Any] = model.snapshot()
        payload["analysis"] = {
            key: value for key, value in self.analysis().items() if key != "path"
        }
        payload["issues"] = [issue.format() for issue in self.validate_current()]
        try:
            Path(path).write_text(json.dumps(payload, indent=2, ensure_ascii=False), encoding="utf-8")
        except Exception as error:  # noqa: BLE001
            self.events.emit(EV_STATUS, "Lỗi khi xuất JSON: %s" % error)
            return False
        self.events.emit(EV_STATUS, "Đã xuất JSON: %s" % Path(path).name)
        return True

    def project_root(self) -> str:
        return project_root_hint()

    def open_levels_dir(self) -> None:
        ensure_levels_dir()
