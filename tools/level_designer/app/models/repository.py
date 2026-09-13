"""Model: truy cập các file level trong resources/levels."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from ..config import LEVELS_DIR, ensure_levels_dir
from ..services import tres_io
from .level import LevelModel


@dataclass(frozen=True)
class LevelSummary:
    level_id: int
    title: str
    path: Path
    width: int
    height: int


class LevelRepository:
    """Đọc/ghi danh sách level .tres trong thư mục resources/levels của game."""

    def __init__(self, levels_dir: Path | None = None) -> None:
        self.levels_dir = Path(levels_dir) if levels_dir else LEVELS_DIR

    # ------------------------------------------------------------------
    # Đường dẫn
    # ------------------------------------------------------------------
    def default_path(self, level_id: int) -> Path:
        return self.levels_dir / ("level_%d.tres" % int(level_id))

    # ------------------------------------------------------------------
    # Danh sách
    # ------------------------------------------------------------------
    def list_summaries(self) -> list[LevelSummary]:
        """Liệt kê toàn bộ level_*.tres, sắp xếp theo level_id."""
        if not self.levels_dir.exists():
            return []
        summaries: list[LevelSummary] = []
        for path in sorted(self.levels_dir.glob("level_*.tres")):
            summary = self._summarize(path)
            if summary is not None:
                summaries.append(summary)
        summaries.sort(key=lambda s: s.level_id)
        return summaries

    def _summarize(self, path: Path) -> LevelSummary | None:
        level_id = _id_from_filename(path)
        title = ""
        width = height = 0
        try:
            model = tres_io.load_file(path)
            level_id = model.level_id
            title = model.level_title
            width, height = model.width, model.height
        except Exception:  # noqa: BLE001 - file hỏng vẫn phải hiện trong danh sách
            pass
        if level_id is None:
            return None
        return LevelSummary(level_id=level_id, title=title or path.stem, path=path, width=width, height=height)

    # ------------------------------------------------------------------
    # Nạp / lưu / xoá
    # ------------------------------------------------------------------
    def load(self, level_id: int) -> LevelModel:
        return self.load_path(self.default_path(level_id))

    def load_path(self, path: Path) -> LevelModel:
        return tres_io.load_file(Path(path))

    def save(self, level: LevelModel, path: Path | None = None) -> Path:
        target = Path(path) if path else self.default_path(level.level_id)
        target.parent.mkdir(parents=True, exist_ok=True)
        tres_io.save_file(level, target)
        level.source_path = str(target)
        return target

    def delete(self, level_id: int) -> bool:
        path = self.default_path(level_id)
        if path.exists():
            path.unlink()
            return True
        return False

    # ------------------------------------------------------------------
    # Tạo màn mới
    # ------------------------------------------------------------------
    def next_free_id(self) -> int:
        used = {summary.level_id for summary in self.list_summaries()}
        candidate = 1
        while candidate in used:
            candidate += 1
        return candidate

    def create_level(self, level_id: int | None = None, width: int = 3, height: int = 3) -> LevelModel:
        """Tạo màn trống: viền kín, S ở góc dưới-trái, F ở góc trên-phải."""
        if level_id is None:
            level_id = self.next_free_id()
        model = LevelModel(
            level_id=level_id,
            level_title="Level 1-%d" % level_id,
            width=width,
            height=height,
            start=(0, height - 1),
            end=(width - 1, 0),
            max_steps=max(4, width + height),
            par_time=30.0,
        )
        model.reset_walls()
        return model

    def duplicate(self, level: LevelModel, new_id: int | None = None) -> LevelModel:
        clone = tres_io.loads(tres_io.dumps(level))
        clone.level_id = new_id if new_id is not None else self.next_free_id()
        clone.level_title = "%s (copy)" % level.level_title
        clone.source_uid = ""
        clone.source_path = ""
        return clone


def _id_from_filename(path: Path) -> int | None:
    stem = path.stem
    if not stem.startswith("level_"):
        return None
    try:
        return int(stem.split("_", 1)[1])
    except (IndexError, ValueError):
        return None
