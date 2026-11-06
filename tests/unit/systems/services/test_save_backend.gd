extends TestCase
## Tests for SaveBackend (scripts/systems/services/SaveBackend.gd) — lớp cơ sở phải "trơ".


func test_base_backend_is_inert() -> void:
	var backend := SaveBackend.new()
	assert_eq(backend.id(), "base")
	assert_eq(backend.display_name(), "Base")
	assert_false(backend.is_available(), "lớp cơ sở không dùng được")
	assert_false(backend.supports_cloud())
	assert_eq(backend.load_data().size(), 0)
	assert_false(backend.save_data({"a": 1}))
	assert_false(backend.clear_data())
