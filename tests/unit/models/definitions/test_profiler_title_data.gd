extends TestCase
## Tests for ProfilerTitleData (scripts/models/definitions/ProfilerTitleData.gd)


func test_is_valid_only_needs_name_key() -> void:
	var data := ProfilerTitleData.new()
	assert_false(data.is_valid(), "thiếu khoá dịch")
	data.name_key = "STR_PROFILE_TIER_1"
	assert_true(data.is_valid())


func test_min_level_defaults_to_one() -> void:
	assert_eq(ProfilerTitleData.new().min_level, 1)
