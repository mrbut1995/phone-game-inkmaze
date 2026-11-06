extends TestCase
## Tests for BlueprintStep (scripts/models/definitions/BlueprintStep.gd)


func test_defaults_match_editor_expectations() -> void:
	var step := BlueprintStep.new()
	assert_eq(step.advance_mode, "MANUAL")
	assert_eq(step.title_key, "STR_TUT_COMMON_TITLE")
	assert_almost_eq(step.auto_delay, 0.0)


func test_to_dictionary_contains_required_keys() -> void:
	var step := BlueprintStep.new()
	step.message_key = "STR_TUT_STEP_1"
	step.fallback_text = "Bấm mũi tên"
	var dict := step.to_dictionary()
	assert_eq(str(dict["message_key"]), "STR_TUT_STEP_1")
	assert_eq(str(dict["fallback_text"]), "Bấm mũi tên")
	assert_eq(str(dict["title_key"]), "STR_TUT_COMMON_TITLE")
	assert_eq(str(dict["advance_mode"]), "MANUAL")


func test_to_dictionary_skips_unset_optional_fields() -> void:
	var step := BlueprintStep.new()
	var dict := step.to_dictionary()
	assert_false(dict.has("auto_delay"), "auto_delay = 0 thì không ghi vào dict")
	assert_false(dict.has("spotlight_cell"), "chưa set spotlight thì không ghi vào dict")
