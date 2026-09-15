"""Model: dữ liệu 1 CHƯƠNG (tương ứng 1-1 với resource ChapterData của Godot).

Chương KHÔNG chứa danh sách màn — quan hệ là ngược lại: mỗi màn có trường
`chapter` (LevelData.chapter) trỏ tới chương của nó. Ngoài ra chương còn có:
    - tiêu đề + mô tả + nhãn kích thước (hiện trên thẻ chương)
    - phí sao để MỞ KHÓA (0 = chương mở sẵn, ví dụ chương 1)
"""

from __future__ import annotations

from dataclasses import dataclass

from ..config import MAX_CHAPTER_ID, MIN_CHAPTER_ID, chapter_icon_for, default_chapter_meta


@dataclass
class ChapterModel:
    """Dữ liệu tương ứng 1-1 với resource ChapterData của Godot."""

    chapter_id: int = 1
    title: str = "NHẬP MÔN"
    subtitle: str = "Làm quen với các quy luật bước & tường"
    size_label: str = ""          # ví dụ "3×3 – 5×5" (rỗng = ẩn chip trên thẻ)
    star_cost: int = 0            # số Sao cần để mở khóa (0 = mở sẵn)
    icon: str = ""                # tên icon riêng (intro/logic/trap/master — xem config.CHAPTER_ICONS)

    ## Đường dẫn file gốc (để ghi lại đúng chỗ khi đã từng đọc từ đĩa)
    source_uid: str = ""
    source_path: str = ""

    # ------------------------------------------------------------------
    @staticmethod
    def suggested(chapter_id: int) -> "ChapterModel":
        """Chương mới với tiêu đề/mô tả/phí sao/icon gợi ý theo số thứ tự."""
        title, subtitle, cost = default_chapter_meta(chapter_id)
        return ChapterModel(chapter_id=chapter_id, title=title, subtitle=subtitle,
                            star_cost=cost, icon=chapter_icon_for(chapter_id))

    def display_icon(self) -> str:
        """Tên icon đã cắt khoảng trắng (rỗng = game tự chọn theo số chương)."""
        return (self.icon or "").strip()

    def display_size(self) -> str:
        """Nhãn kích thước đã cắt khoảng trắng (rỗng = không hiện chip)."""
        return (self.size_label or "").strip()

    def normalized(self) -> "ChapterModel":
        """Chuẩn hóa dữ liệu trước khi ghi file (id trong khoảng, phí sao >= 0...)."""
        self.chapter_id = max(MIN_CHAPTER_ID, min(MAX_CHAPTER_ID, int(self.chapter_id)))
        self.title = (self.title or "").strip()
        self.subtitle = (self.subtitle or "").strip()
        self.size_label = (self.size_label or "").strip()
        self.star_cost = max(0, int(self.star_cost))
        self.icon = (self.icon or "").strip()
        return self

    def is_valid(self) -> bool:
        """Hợp lệ khi có tiêu đề (game hiện tiêu đề lên thẻ chương)."""
        return bool((self.title or "").strip())

    def cost_text(self) -> str:
        """Chuỗi hiển thị phí sao cho danh sách trong tool."""
        return "mở sẵn" if self.star_cost <= 0 else "cần %d sao" % self.star_cost
