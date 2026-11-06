extends TestCase
## Tests for AchievementData (scripts/models/definitions/AchievementData.gd)


func test_is_valid_needs_id_stat_and_target() -> void:
	var data := AchievementData.new()
	assert_false(data.is_valid(), "mặc định chưa đủ dữ liệu")
	data.id = "lv_clear_10"
	assert_false(data.is_valid(), "thiếu stat")
	data.stat = "levels_cleared"
	assert_true(data.is_valid())
	data.target = 0
	assert_false(data.is_valid(), "mốc 0 là vô nghĩa")


func test_display_title_prefers_translation_key() -> void:
	var data := AchievementData.new()
	data.title = "Tiêu đề tiếng Việt"
	assert_eq(data.display_title(), "Tiêu đề tiếng Việt")
	data.title_key = "STR_ACH_TEST_TITLE"
	assert_ne(data.display_title(), "Tiêu đề tiếng Việt", "có khoá dịch thì dùng khoá")


func test_display_description_prefers_translation_key() -> void:
	var data := AchievementData.new()
	data.description = "Mô tả tiếng Việt"
	assert_eq(data.display_description(), "Mô tả tiếng Việt")
	data.desc_key = "STR_ACH_TEST_DESC"
	assert_ne(data.display_description(), "Mô tả tiếng Việt")


func test_defaults_are_safe_for_new_asset() -> void:
	var data := AchievementData.new()
	assert_eq(data.category, "levels")
	assert_eq(data.target, 1)
	assert_false(data.secret)
