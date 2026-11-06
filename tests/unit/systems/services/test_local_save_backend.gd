extends TestCase
## Tests for LocalSaveBackend — CHỈ test metadata; KHÔNG đọc/ghi file save thật của người chơi.


func test_metadata() -> void:
	var backend := LocalSaveBackend.new()
	assert_eq(backend.id(), "local")
	assert_eq(backend.display_name(), "Local")
	assert_true(backend.is_available(), "lưu file luôn dùng được")
	assert_false(backend.supports_cloud(), "lưu file không phải cloud")


func test_storage_key_is_stable() -> void:
	assert_eq(LocalSaveBackend.DATA_MANAGER_KEY, "player_progress", "đổi khoá này là mất tiến trình người chơi")
