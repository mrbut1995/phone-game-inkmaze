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


static func safe_area() -> SafeAreaClass:
	return node(&"SafeArea") as SafeAreaClass


static func loading() -> LoadingManagerClass:
	return node(&"LoadingManager") as LoadingManagerClass


static func level() -> LevelManagerClass:
	return node(&"LevelManager") as LevelManagerClass


static func game() -> GameManagerClass:
	return node(&"GameManager") as GameManagerClass


static func app() -> AppManagerClass:
	return node(&"AppManager") as AppManagerClass


static func setting() -> SettingManagerClass:
	return node(&"SettingManager") as SettingManagerClass


static func scene() -> SceneManagerClass:
	return node(&"SceneManager") as SceneManagerClass


static func screen() -> ScreenManagerClass:
	return node(&"ScreenManager") as ScreenManagerClass


static func popup() -> PopupManagerClass:
	return node(&"PopupManager") as PopupManagerClass


static func sfx() -> SfxManagerClass:
	return node(&"SfxManager") as SfxManagerClass


static func music() -> MusicManagerClass:
	return node(&"MusicManager") as MusicManagerClass


static func data() -> DataManagerClass:
	return node(&"DataManager") as DataManagerClass


static func daily() -> DailyManagerClass:
	return node(&"DailyManager") as DailyManagerClass


static func debug() -> DebugManagerClass:
	return node(&"DebugManager") as DebugManagerClass


static func ads() -> AdsManagerClass:
	return node(&"AdsManager") as AdsManagerClass


static func loc() -> LocalizationManagerClass:
	return node(&"LocalizationManager") as LocalizationManagerClass


static func save() -> SaveManagerClass:
	return node(&"SaveManager") as SaveManagerClass


static func shop() -> ShopManagerClass:
	return node(&"ShopManager") as ShopManagerClass


static func archivement() -> ArchivementManagerClass:
	return node(&"ArchivementManager") as ArchivementManagerClass


static func profile() -> PlayerProfileManagerClass:
	return node(&"PlayerProfileManager") as PlayerProfileManagerClass


static func ranking() -> RankingManagerClass:
	return node(&"RankingManager") as RankingManagerClass


static func theme() -> ThemeManagerClass:
	return node(&"ThemeManager") as ThemeManagerClass


static func tutorial() -> TutorialManagerClass:
	return node(&"TutorialManager") as TutorialManagerClass


static func event() -> EventManagerClass:
	return node(&"EventManager") as EventManagerClass
