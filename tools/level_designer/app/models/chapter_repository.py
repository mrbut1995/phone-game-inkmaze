"""Model: truy cập các file chương trong resources/chapters.

Chương gom màn theo trường `chapter` của LevelData, nên repository này làm việc
cặp với LevelRepository: muốn "thêm màn vào chương" thì ghi `chapter = N` cho màn đó.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from ..config import CHAPTERS_DIR, MAX_CHAPTER_ID, ensure_chapters_dir
from ..services import chapter_io
from .chapter import ChapterModel
from .repository import LevelRepository


@dataclass(frozen=True)
class ChapterSummary:
    chapter_id: int
    title: str
    star_cost: int
    levels: tuple[int, ...]
    path: Path
    icon: str = ""

    @property
    def level_count(self) -> int:
        return len(self.levels)

    @property
    def star_total(self) -> int:
        """Tổng Sao tối đa của chương (= số màn x 3)."""
        return self.level_count * 3

    def levels_text(self) -> str:
        """Danh sách màn dạng '1, 2, 3' (rỗng -> '(chưa có màn)')."""
        return ", ".join(str(level_id) for level_id in self.levels) or "(chưa có màn)"


class ChapterRepository:
    """Đọc/ghi chapter_*.tres + gán màn vào chương (sửa LevelData.chapter)."""

    def __init__(self, chapters_dir: Path | None = None, levels: LevelRepository | None = None) -> None:
        self.chapters_dir = Path(chapters_dir) if chapters_dir else CHAPTERS_DIR
        self.levels = levels or LevelRepository()

    # ------------------------------------------------------------------
    # Đường dẫn
    # ------------------------------------------------------------------
    def default_path(self, chapter_id: int) -> Path:
        return self.chapters_dir / ("chapter_%d.tres" % int(chapter_id))

    # ------------------------------------------------------------------
    # Danh sách
    # ------------------------------------------------------------------
    def list_summaries(self) -> list[ChapterSummary]:
        """Liệt kê toàn bộ chapter_*.tres, sắp xếp theo chapter_id."""
        if not self.chapters_dir.exists():
            return []
        summaries: list[ChapterSummary] = []
        for path in sorted(self.chapters_dir.glob("chapter_*.tres")):
            summary = self._summarize(path)
            if summary is not None:
                summaries.append(summary)
        summaries.sort(key=lambda s: s.chapter_id)
        return summaries

    def _summarize(self, path: Path) -> ChapterSummary | None:
        chapter_id = _id_from_filename(path)
        title = ""
        star_cost = 0
        icon = ""
        try:
            model = chapter_io.load_file(path)
            chapter_id = model.chapter_id
            title = model.title
            star_cost = model.star_cost
            icon = model.display_icon()
        except Exception:  # noqa: BLE001 - file hỏng vẫn phải hiện trong danh sách
            pass
        if chapter_id is None:
            return None
        return ChapterSummary(
            chapter_id=chapter_id,
            title=title or path.stem,
            star_cost=star_cost,
            levels=tuple(self.levels_in_chapter(chapter_id)),
            path=path,
            icon=icon,
        )

    def levels_in_chapter(self, chapter_id: int) -> list[int]:
        """Danh sách level_id có `chapter` = chapter_id (đọc từ file màn)."""
        out: list[int] = []
        for summary in self.levels.list_summaries():
            try:
                model = self.levels.load(summary.level_id)
            except Exception:  # noqa: BLE001 - bỏ qua file màn hỏng
                continue
            if int(model.chapter) == int(chapter_id):
                out.append(int(model.level_id))
        return sorted(out)

    def chapter_of_level(self, level_id: int) -> int:
        """Chương của 1 màn (1 nếu không đọc được file)."""
        try:
            return max(1, int(self.levels.load(level_id).chapter))
        except Exception:  # noqa: BLE001
            return 1

    # ------------------------------------------------------------------
    # Nạp / lưu / xoá
    # ------------------------------------------------------------------
    def load(self, chapter_id: int) -> ChapterModel:
        return chapter_io.load_file(self.default_path(chapter_id))

    def save(self, chapter: ChapterModel) -> Path:
        chapter.normalized()
        target = self.default_path(chapter.chapter_id)
        chapter_io.save_file(chapter, target)
        chapter.source_path = str(target)
        return target

    def delete(self, chapter_id: int) -> bool:
        """Xoá file chương. Màn trong chương KHÔNG bị xoá (chỉ mất nhãn chương)."""
        path = self.default_path(chapter_id)
        if path.exists():
            path.unlink()
            return True
        return False

    # ------------------------------------------------------------------
    # Tạo chương
    # ------------------------------------------------------------------
    def next_free_id(self) -> int:
        used = {summary.chapter_id for summary in self.list_summaries()}
        candidate = 1
        while candidate in used and candidate <= MAX_CHAPTER_ID:
            candidate += 1
        return min(candidate, MAX_CHAPTER_ID)

    def create_chapter(self, chapter_id: int | None = None) -> ChapterModel:
        """Tạo chương mới (chưa ghi file) với tiêu đề/phí sao gợi ý."""
        if chapter_id is None:
            chapter_id = self.next_free_id()
        return ChapterModel.suggested(int(chapter_id))

    def ensure_for_levels(self) -> list[ChapterModel]:
        """Tạo file chương cho mọi chương đang có màn nhưng chưa có file .tres."""
        ensure_chapters_dir()
        existing = {summary.chapter_id for summary in self.list_summaries()}
        needed = {self.chapter_of_level(summary.level_id) for summary in self.levels.list_summaries()}
        created: list[ChapterModel] = []
        for chapter_id in sorted(needed - existing):
            chapter = self.create_chapter(chapter_id)
            self.save(chapter)
            created.append(chapter)
        return created

    # ------------------------------------------------------------------
    # Gán màn vào chương (thêm / bớt màn khỏi chương)
    # ------------------------------------------------------------------
    def assign_levels(self, chapter_id: int, level_ids) -> list[int]:
        """Ghi `chapter = chapter_id` cho các màn được chỉ định.

        Trả về danh sách level_id đã gán THÀNH CÔNG (bỏ qua màn không có file).
        """
        chapter_id = max(1, min(MAX_CHAPTER_ID, int(chapter_id)))
        assigned: list[int] = []
        for level_id in level_ids:
            try:
                model = self.levels.load(int(level_id))
            except Exception:  # noqa: BLE001 - màn chưa tồn tại thì bỏ qua
                continue
            if int(model.chapter) == chapter_id:
                assigned.append(int(level_id))
                continue
            model.chapter = chapter_id
            self.levels.save(model)
            assigned.append(int(level_id))
        return assigned

    def assign_level(self, level_id: int, chapter_id: int) -> bool:
        """Gán 1 màn vào chương (dùng cho màn đang mở trong editor)."""
        return bool(self.assign_levels(chapter_id, [level_id]))

    def clear_levels(self, chapter_id: int) -> int:
        """Chuyển hết màn của chương này về chương 1 (không xoá file màn)."""
        if int(chapter_id) <= 1:
            return 0
        moved = 0
        for level_id in self.levels_in_chapter(chapter_id):
            model = self.levels.load(level_id)
            model.chapter = 1
            self.levels.save(model)
            moved += 1
        return moved

    # ------------------------------------------------------------------
    # Gợi ý nhãn kích thước (chip "KÍCH THƯỚC ..." trên thẻ chương)
    # ------------------------------------------------------------------
    def size_label_for(self, chapter_id: int) -> str:
        """Nhãn kích thước gợi ý từ bàn nhỏ nhất/lớn nhất của các màn trong chương."""
        sizes: list[tuple[int, int]] = []
        for level_id in self.levels_in_chapter(chapter_id):
            try:
                model = self.levels.load(level_id)
            except Exception:  # noqa: BLE001
                continue
            sizes.append((int(model.width), int(model.height)))
        if not sizes:
            return ""
        biggest = max(max(w, h) for w, h in sizes)
        smallest = min(min(w, h) for w, h in sizes)
        if smallest == biggest:
            return "%d×%d" % (smallest, biggest)
        return "%d×%d – %d×%d" % (smallest, smallest, biggest, biggest)


def _id_from_filename(path: Path) -> int | None:
    """Lấy số từ tên file chapter_<n>.tres."""
    stem = path.stem
    digits = "".join(ch for ch in stem if ch.isdigit())
    if not digits:
        return None
    try:
        return int(digits)
    except ValueError:
        return None
