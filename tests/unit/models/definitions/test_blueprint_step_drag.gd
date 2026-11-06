extends TestCase
## Tests for BlueprintStepDrag (scripts/models/definitions/BlueprintStepDrag.gd)


func test_defaults_are_a_single_step_to_the_right() -> void:
	var drag := BlueprintStepDrag.new()
	assert_eq(drag.from_cell, Vector2i(0, 0))
	assert_eq(drag.to_cell, Vector2i(1, 0))
	assert_almost_eq(drag.duration, 0.6)


func test_to_dictionary_carries_all_three_fields() -> void:
	var drag := BlueprintStepDrag.new()
	drag.from_cell = Vector2i(2, 3)
	drag.to_cell = Vector2i(2, 5)
	var dict := drag.to_dictionary()
	assert_eq(dict.size(), 3)
	assert_eq(dict["from_cell"], Vector2i(2, 3))
	assert_eq(dict["to_cell"], Vector2i(2, 5))
