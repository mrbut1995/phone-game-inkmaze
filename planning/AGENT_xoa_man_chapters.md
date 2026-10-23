# Việc cho AI agent: xoá màn "Chọn chương" cũ (đã được tab + khung khoá thay thế)

KHÔNG xoá: `nodes/chapters/chest_chip.tscn`, `chapter_progress*.tscn`, `chapter_rail.tscn`, `scripts/nodes/chapters/chest_chip.gd`, `chapter_progress.gd` (màn Level đang dùng).

Xoá / dọn:
1. `scenes/chapters.tscn`, `scripts/scenes/chapters.gd`, `scripts/scenes/layout/chapters_layout.gd`, các layout `scenes/layout/{portrait,landscape}/chapters.tscn`.
2. `nodes/chapters/chapter_card.tscn` + `scripts/nodes/chapters/chapter_card.gd` (chỉ nếu không nơi nào khác dùng).
3. `Nav.goto_chapters()`, `GameManager.go_to_chapters()` và mọi nơi gọi chúng (tìm bằng grep `goto_chapters`, `go_to_chapters`, `chapters.tscn`); đăng ký route trong `ScreenManager`/`SceneManager` nếu có.
4. Test liên quan màn Chapters; chuỗi dịch chỉ dùng cho màn đó (kiểm tra bằng grep trước khi xoá).
5. Chạy lại toàn bộ test, báo kết quả.
