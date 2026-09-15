class_name Nav
extends RefCounted
## ============================================================================
## Helper tĩnh: điều hướng scene qua autoload SceneManager (có SFX lật trang
## + ghi lịch sử cho nút Back).
##
## Lý do tồn tại: test runner chạy bằng `godot --script ...` không resolve
## được identifier autoload lúc parse, nên script khác không được tham chiếu
## thẳng `SceneManager`. Ở đây lấy node động qua /root/SceneManager.
## ============================================================================

const SCENE_MAIN := "res://scenes/main.tscn"
const SCENE_LEVELS := "res://scenes/levels.tscn"
const SCENE_GAME := "res://scenes/game.tscn"
const SCENE_DAILY := "res://scenes/daily.tscn"
const SCENE_SETTINGS := "res://scenes/settings.tscn"
const SCENE_DEBUG := "res://scenes/debug.tscn"
const SCENE_ARCHIVEMENT := "res://scenes/archivement.tscn"
const SCENE_RANKING := "res://scenes/ranking.tscn"
## Màn CHỌN CHƯƠNG — xem scripts/scenes/chapters.gd
const SCENE_CHAPTERS := "res://scenes/chapters.tscn"


static func change_scene(path: String) -> void:
	var manager := _manager()
	if manager != null and manager.has_method("change_scene"):
		manager.call("change_scene", path)
		return
	var tree := _tree()
	if tree != null:
		tree.change_scene_to_file(path)


static func goto_main() -> void:
	change_scene(SCENE_MAIN)


static func goto_levels() -> void:
	change_scene(SCENE_LEVELS)


static func goto_game() -> void:
	change_scene(SCENE_GAME)


static func goto_daily() -> void:
	change_scene(SCENE_DAILY)


static func goto_settings() -> void:
	change_scene(SCENE_SETTINGS)


## Sổ tay thành tựu (danh hiệu)
static func goto_archivement() -> void:
	change_scene(SCENE_ARCHIVEMENT)


## Bảng xếp hạng (Dungeon · Play · Daily)
static func goto_ranking() -> void:
	change_scene(SCENE_RANKING)


## Màn CHỌN CHƯƠNG (xem tiến độ + mở khóa chương bằng Sao)
static func goto_chapters() -> void:
	change_scene(SCENE_CHAPTERS)


## Màn hình debug (chỉ dùng khi phát triển)
static func goto_debug() -> void:
	change_scene(SCENE_DEBUG)


static func _manager() -> Node:
	var tree := _tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("SceneManager")
	return null


static func _tree() -> SceneTree:
	var main_loop := Engine.get_main_loop()
	return main_loop as SceneTree if main_loop is SceneTree else null
