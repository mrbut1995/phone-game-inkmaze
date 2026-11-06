extends TestCase
## Tests for AvatarData (scripts/models/definitions/AvatarData.gd)


func test_is_valid_requires_id_name_key_and_icon() -> void:
	var data := AvatarData.new()
	assert_false(data.is_valid(), "mặc định chưa đủ dữ liệu")
	data.id = "avatar_boy_kid"
	data.name_key = "STR_AVATAR_BOY_KID"
	assert_false(data.is_valid(), "thiếu icon")
	data.icon = ImageTexture.new()
	assert_true(data.is_valid())
