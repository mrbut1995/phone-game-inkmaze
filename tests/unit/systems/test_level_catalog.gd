extends TestCase
## Tests for LevelCatalog (scripts/systems/LevelCatalog.gd)


func test_mode_of_falls_back_to_play() -> void:
	assert_eq(LevelCatalog.mode_of(null), "play")
	var data := LevelData.new()
	data.mode_id = ""
	assert_eq(LevelCatalog.mode_of(data), "play", "màn không khai mode_id ⇒ play")
	data.mode_id = "dungeon"
	assert_eq(LevelCatalog.mode_of(data), "play", "dungeon là chế độ theo tầng, màn thường quy về play")
	data.mode_id = "khong_ton_tai"
	assert_eq(LevelCatalog.mode_of(data), "play", "id lạ ⇒ play")


func test_mode_of_keeps_known_mode() -> void:
	var data := LevelData.new()
	data.mode_id = " Blind_Memory "
	assert_eq(LevelCatalog.mode_of(data), "blind_memory", "id được trim + lowercase")


func test_difficulty_of_defaults_to_medium() -> void:
	var data := LevelData.new()
	data.difficulty = ""
	assert_eq(LevelCatalog.difficulty_of(data), "medium")
	data.difficulty = "hard"
	assert_eq(LevelCatalog.difficulty_of(data), "hard")


func test_is_known_mode() -> void:
	assert_true(LevelCatalog.is_known_mode("play"))
	assert_true(LevelCatalog.is_known_mode("challenge"))
	assert_false(LevelCatalog.is_known_mode("khong_ton_tai"))


func test_special_mode_ids_are_all_known() -> void:
	var ids := LevelCatalog.special_mode_ids()
	assert_true(ids.size() > 0, "phải có chế độ đặc biệt")
	for mode_id in ids:
		assert_true(LevelCatalog.is_known_mode(mode_id), mode_id)


func test_special_mode_ids_returns_copy() -> void:
	var ids := LevelCatalog.special_mode_ids()
	ids.clear()
	assert_true(LevelCatalog.special_mode_ids().size() > 0, "xoá bản sao không được làm hỏng danh sách gốc")
