extends TestCase
## Tests for PlayGamesSaveBackend — khi chưa cài plugin (desktop) mọi thao tác phải an toàn.


func test_metadata() -> void:
	var backend := PlayGamesSaveBackend.new()
	assert_eq(backend.id(), "play_games")
	assert_eq(backend.display_name(), "Google Play Games")
	assert_true(backend.supports_cloud(), "lưu qua Play Games là lưu đám mây")


func test_without_plugin_nothing_works_and_nothing_crashes() -> void:
	var backend := PlayGamesSaveBackend.new()
	if backend.is_available():
		return  # máy Android đã có plugin — bỏ qua nhánh kiểm này
	assert_eq(backend.load_data().size(), 0, "chưa có plugin thì không có dữ liệu")
	assert_false(backend.save_data({"a": 1}), "chưa có plugin thì không ghi được")
	assert_false(backend.clear_data())
