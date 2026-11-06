class_name Svc
extends RefCounted
## ============================================================================
## Helper tĩnh: ĐIỂM TRUY CẬP AUTOLOAD DUY NHẤT của toàn project.
##
## Vì sao không gọi thẳng tên autoload (`GameManager.xxx`)? Vì test/harness chạy bằng
## `godot --script` (xem `tools/run_tests.py`) KHÔNG có autoload ⇒ gọi tên trực tiếp
## sẽ lỗi PARSE. `Svc` lấy node theo `Engine.get_main_loop().root` nên trả `null` an toàn
## trong môi trường đó (mọi chỗ dùng đều đã/null-check sẵn).
##
## Quy ước: KHÔNG còn chuỗi `"/root/…"` nào ngoài file này (§8.2 REFACTOR_INSTRUCTIONS).
## Ai gọi: toàn bộ `scripts/` (trực tiếp hoặc qua facade `Loc`/`Nav`/`Shop`/`Save`…).
## ============================================================================


## Node autoload theo tên (null nếu chưa có trong cây — ví dụ khi chạy `--script`)
static func node(singleton: StringName) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null(NodePath(String(singleton)))


static func safe_area() -> Node:
	return node(&"SafeArea")


static func loading() -> Node:
	return node(&"LoadingManager")


static func level() -> Node:
	return node(&"LevelManager")


static func game() -> Node:
	return node(&"GameManager")


static func app() -> Node:
	return node(&"AppManager")


static func setting() -> Node:
	return node(&"SettingManager")


static func scene() -> Node:
	return node(&"SceneManager")


static func screen() -> Node:
	return node(&"ScreenManager")


static func popup() -> Node:
	return node(&"PopupManager")


static func sfx() -> Node:
	return node(&"SfxManager")


static func music() -> Node:
	return node(&"MusicManager")


static func data() -> Node:
	return node(&"DataManager")


static func daily() -> Node:
	return node(&"DailyManager")


static func debug() -> Node:
	return node(&"DebugManager")


static func ads() -> Node:
	return node(&"AdsManager")


static func loc() -> Node:
	return node(&"LocalizationManager")


static func save() -> Node:
	return node(&"SaveManager")


static func shop() -> Node:
	return node(&"ShopManager")


static func achievement() -> Node:
	return node(&"AchievementManager")


static func profile() -> Node:
	return node(&"PlayerProfileManager")


static func ranking() -> Node:
	return node(&"RankingManager")


static func theme() -> Node:
	return node(&"ThemeManager")


static func tutorial() -> Node:
	return node(&"TutorialManager")


static func event() -> Node:
	return node(&"EventManager")
