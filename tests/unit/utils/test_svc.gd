extends TestCase
## Tests for Svc (scripts/utils/Svc.gd) — chỉ ĐỌC: autoload phải resolve được từ cây scene.


func test_core_autoloads_resolve() -> void:
	assert_not_null(Svc.game(), "GameManager")
	assert_not_null(Svc.level(), "LevelManager")
	assert_not_null(Svc.daily(), "DailyManager")
	assert_not_null(Svc.loc(), "LocalizationManager")


func test_unknown_singleton_returns_null() -> void:
	assert_null(Svc.node(&"KhongTonTai123"), "tên lạ phải trả null, không được crash")
