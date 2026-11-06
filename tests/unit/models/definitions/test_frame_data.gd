extends TestCase
## Tests for FrameData (scripts/models/definitions/FrameData.gd)


func test_is_valid_requires_id_name_key_and_icon() -> void:
	var data := FrameData.new()
	assert_false(data.is_valid(), "mặc định chưa đủ dữ liệu")
	data.id = "frame_gold"
	data.name_key = "STR_FRAME_GOLD"
	assert_false(data.is_valid(), "thiếu icon")
	data.icon = ImageTexture.new()
	assert_true(data.is_valid())
