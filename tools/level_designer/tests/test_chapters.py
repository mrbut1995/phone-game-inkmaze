"""Test: CHƯƠNG — đọc/ghi chapter_*.tres + gán màn vào chương (tính năng 2026-02)."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from app import config  # noqa: E402
from app.models.chapter import ChapterModel  # noqa: E402
from app.models.chapter_repository import ChapterRepository  # noqa: E402
from app.models.repository import LevelRepository  # noqa: E402
from app.services import chapter_io  # noqa: E402

REAL_CHAPTERS = sorted(config.CHAPTERS_DIR.glob("chapter_*.tres")) if config.CHAPTERS_DIR.exists() else []
REAL_LEVELS = sorted(config.LEVELS_DIR.glob("level_*.tres")) if config.LEVELS_DIR.exists() else []


class TestChapterFormat(unittest.TestCase):
    def test_emit_header_and_fields(self) -> None:
        chapter = ChapterModel(chapter_id=2, title="SUY LUẬN", subtitle="Mô tả",
                               size_label="4×4 – 11×11", star_cost=25)
        text = chapter_io.dumps(chapter)

        self.assertIn('[gd_resource type="Resource" script_class="ChapterData" load_steps=2 format=3', text)
        self.assertIn('[ext_resource type="Script" path="%s" id="%s"]' % (
            config.CHAPTER_SCRIPT_RES, config.CHAPTER_SCRIPT_ID), text)
        self.assertIn('script = ExtResource("%s")' % config.CHAPTER_SCRIPT_ID, text)
        self.assertIn("chapter_id = 2", text)
        self.assertIn('title = "SUY LUẬN"', text)
        self.assertIn('subtitle = "Mô tả"', text)
        self.assertIn('size_label = "4×4 – 11×11"', text)
        self.assertIn("star_cost = 25", text)
        self.assertTrue(text.endswith("\n"), "file .tres phải kết thúc bằng dòng trống")

    def test_roundtrip_text(self) -> None:
        chapter = ChapterModel(chapter_id=3, title='BẪY "ẨN"', subtitle="Dòng 1\nDòng 2",
                               size_label="8×8", star_cost=45, icon="trap")
        again = chapter_io.loads(chapter_io.dumps(chapter))
        self.assertEqual(again.chapter_id, 3)
        self.assertEqual(again.title, 'BẪY "ẨN"')
        self.assertEqual(again.subtitle, "Dòng 1\nDòng 2")
        self.assertEqual(again.size_label, "8×8")
        self.assertEqual(again.star_cost, 45)
        self.assertEqual(again.display_icon(), "trap")
        self.assertIn('icon = "trap"', chapter_io.dumps(chapter))

    def test_normalized_and_valid(self) -> None:
        chapter = ChapterModel(chapter_id=0, title="  NHẬP MÔN  ", subtitle=None,
                               size_label="  ", star_cost=-5).normalized()
        self.assertEqual(chapter.chapter_id, config.MIN_CHAPTER_ID)
        self.assertEqual(chapter.title, "NHẬP MÔN")
        self.assertEqual(chapter.subtitle, "")
        self.assertEqual(chapter.display_size(), "")
        self.assertEqual(chapter.star_cost, 0)
        self.assertTrue(chapter.is_valid())
        self.assertFalse(ChapterModel(title="   ").is_valid())
        self.assertEqual(ChapterModel(star_cost=0).cost_text(), "mở sẵn")
        self.assertEqual(ChapterModel(star_cost=45).cost_text(), "cần 45 sao")

    @unittest.skipUnless(bool(REAL_CHAPTERS), "chưa có resources/chapters")
    def test_real_files_match_game_format(self) -> None:
        for path in REAL_CHAPTERS:
            chapter = chapter_io.load_file(path)
            self.assertGreaterEqual(chapter.chapter_id, 1, path.name)
            self.assertTrue(chapter.is_valid(), "%s thiếu tiêu đề" % path.name)
            text = chapter_io.dumps(chapter)
            self.assertIn('script_class="ChapterData"', text)
            # ghi lại rồi đọc lại phải giữ nguyên nội dung
            again = chapter_io.loads(text)
            self.assertEqual((again.chapter_id, again.title, again.star_cost),
                             (chapter.chapter_id, chapter.title, chapter.star_cost))


class TestChapterRepository(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        self.levels_dir = root / "levels"
        self.chapters_dir = root / "chapters"
        self.levels_dir.mkdir(parents=True, exist_ok=True)
        self.levels = LevelRepository(self.levels_dir)
        self.chapters = ChapterRepository(self.chapters_dir, levels=self.levels)

    def tearDown(self) -> None:
        self.temp.cleanup()

    # ------------------------------------------------------------------
    def _make_levels(self, count: int, widths: int = 3) -> list[int]:
        ids = []
        for level_id in range(1, count + 1):
            model = self.levels.create_level(level_id, widths, widths)
            self.levels.save(model)
            ids.append(level_id)
        return ids

    def test_create_save_load_delete(self) -> None:
        self.assertEqual(self.chapters.list_summaries(), [])
        chapter = self.chapters.create_chapter()
        self.assertEqual(chapter.chapter_id, 1)
        self.assertEqual(chapter.display_icon(), "intro", "chương mới phải có icon gợi ý")
        path = self.chapters.save(chapter)
        self.assertTrue(path.exists(), "phải ghi ra chapter_1.tres")
        loaded = self.chapters.load(1)
        self.assertEqual(loaded.title, chapter.title)
        self.assertEqual(loaded.display_icon(), "intro", "icon phải được ghi/đọc lại đúng")
        summaries = self.chapters.list_summaries()
        self.assertEqual(len(summaries), 1)
        self.assertEqual(summaries[0].level_count, 0)
        self.assertEqual(summaries[0].levels_text(), "(chưa có màn)")
        self.assertEqual(self.chapters.next_free_id(), 2)
        self.assertTrue(self.chapters.delete(1))
        self.assertFalse(self.chapters.delete(1))
        self.assertEqual(self.chapters.list_summaries(), [])

    def test_ensure_for_levels_creates_missing_chapters(self) -> None:
        ids = self._make_levels(4)
        model = self.levels.load(ids[3])
        model.chapter = 2
        self.levels.save(model)
        created = self.chapters.ensure_for_levels()
        self.assertEqual([c.chapter_id for c in created], [1, 2])
        self.assertEqual(len(self.chapters.list_summaries()), 2)
        # gọi lại không tạo thêm
        self.assertEqual(self.chapters.ensure_for_levels(), [])

    def test_assign_levels_writes_chapter_field(self) -> None:
        ids = self._make_levels(5)
        assigned = self.chapters.assign_levels(2, [4, 5])
        self.assertEqual(sorted(assigned), [4, 5])
        self.assertEqual(self.chapters.levels_in_chapter(2), [4, 5])
        self.assertEqual(self.chapters.levels_in_chapter(1), [1, 2, 3])
        model = self.levels.load(4)
        self.assertEqual(model.chapter, 2)
        # gán màn không tồn tại thì bỏ qua (không lỗi)
        self.assertEqual(self.chapters.assign_levels(2, [99]), [])
        # gán lại vào chương 1 -> trả về chương 1
        self.chapters.assign_levels(1, [4])
        self.assertEqual(self.chapters.levels_in_chapter(2), [5])

    def test_assign_single_and_clear(self) -> None:
        ids = self._make_levels(3)
        self.assertTrue(self.chapters.assign_level(ids[0], 3))
        self.assertEqual(self.chapters.chapter_of_level(ids[0]), 3)
        self.assertEqual(self.chapters.clear_levels(3), 1)
        self.assertEqual(self.chapters.chapter_of_level(ids[0]), 1)
        self.assertEqual(self.chapters.clear_levels(1), 0, "chương 1 không cần chuyển")

    def test_size_label_from_levels(self) -> None:
        self._make_levels(2, widths=3)
        big = self.levels.create_level(3, 9, 9)
        self.levels.save(big)
        label = self.chapters.size_label_for(1)
        self.assertIn("3×3", label)
        self.assertIn("9×9", label)
        self.assertEqual(self.chapters.size_label_for(7), "")

    def test_summary_counts_levels_and_stars(self) -> None:
        self._make_levels(4)
        self.chapters.assign_levels(2, [1, 2])
        self.chapters.save(ChapterModel(chapter_id=2, title="SUY LUẬN", star_cost=25, icon="logic"))
        summary = [s for s in self.chapters.list_summaries() if s.chapter_id == 2][0]
        self.assertEqual(summary.level_count, 2)
        self.assertEqual(summary.star_total, 6)
        self.assertEqual(summary.levels_text(), "1, 2")
        self.assertEqual(summary.star_cost, 25)
        self.assertEqual(self.chapters.load(2).display_icon(), "logic")

    def test_icon_suggestion_cycles(self) -> None:
        """Icon gợi ý theo số chương: intro/logic/trap/master rồi lặp lại."""
        from app import config  # noqa: PLC0415 - chỉ dùng trong test này
        expected = ["intro", "logic", "trap", "master"]
        for index, icon in enumerate(expected, start=1):
            self.assertEqual(self.chapters.create_chapter(index).display_icon(), icon)
        self.assertEqual(self.chapters.create_chapter(len(expected) + 1).display_icon(),
                         config.chapter_icon_for(len(expected) + 1))


class TestLevelSummaryChapter(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.levels_dir = Path(self.temp.name) / "levels"
        self.repository = LevelRepository(self.levels_dir)

    def tearDown(self) -> None:
        self.temp.cleanup()

    def test_summary_reports_chapter(self) -> None:
        model = self.repository.create_level(1, 3, 3, chapter=2)
        self.repository.save(model)
        summary = self.repository.list_summaries()[0]
        self.assertEqual(summary.chapter, 2)
        # màn tạo mới mặc định thuộc chương 1
        default = self.repository.create_level(2, 3, 3)
        self.assertEqual(default.chapter, 1)
        self.assertEqual(default.level_title, "Level 1-2")
        self.assertEqual(model.level_title, "Level 2-1")


@unittest.skipUnless(bool(REAL_LEVELS), "chưa có resources/levels")
class TestRealDataConsistency(unittest.TestCase):
    def test_every_level_has_chapter_file(self) -> None:
        """Mọi chương đang có màn đều phải có file chapter_<n>.tres cho game đọc."""
        repository = LevelRepository()
        chapters = ChapterRepository(levels=repository)
        used = {chapters.chapter_of_level(s.level_id) for s in repository.list_summaries()}
        available = {s.chapter_id for s in chapters.list_summaries()}
        missing = sorted(used - available)
        self.assertEqual(missing, [], "thiếu file chương cho: %s" % missing)
        # chương 1 phải tồn tại (game cho mở sẵn)
        self.assertIn(1, available)
        # phí sao chương 1 = 0 (mở sẵn), các chương sau tăng dần
        costs = [c.star_cost for c in sorted(chapters.list_summaries(), key=lambda s: s.chapter_id)]
        self.assertEqual(costs[0], 0)
        self.assertEqual(costs, sorted(costs), "phí sao các chương phải tăng dần")


if __name__ == "__main__":
    unittest.main()
