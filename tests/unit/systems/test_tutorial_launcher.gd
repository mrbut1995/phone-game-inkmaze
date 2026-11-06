extends TestCase
## Tests for TutorialLauncher (scripts/systems/TutorialLauncher.gd)
## CHỈ test `ids_for()` — `launch()` đổi state của GameManager nên không chạy trong unit test.
## Dùng tầng 999 (không tồn tại) để luồng học lần đầu không ghi đè danh sách bài của chế độ.


func test_dungeon_has_no_question_mark_button() -> void:
	assert_eq(TutorialLauncher.ids_for("dungeon", 999).size(), 0, "Dungeon không có nút '?'")


func test_blind_memory_opens_its_own_lesson() -> void:
	var ids := TutorialLauncher.ids_for("blind_memory", 999)
	assert_eq(ids.size(), 1)
	assert_eq(str(ids[0]), "how_to_play_blind_memory")


func test_wall_builder_opens_its_own_lesson() -> void:
	var ids := TutorialLauncher.ids_for("wall_builder", 999)
	assert_eq(ids.size(), 1)
	assert_eq(str(ids[0]), "how_to_play_wall_builder")


func test_unknown_mode_returns_nothing() -> void:
	assert_eq(TutorialLauncher.ids_for("khong_ton_tai", 999).size(), 0)
