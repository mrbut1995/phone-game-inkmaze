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
## Màn CHỌN MÀN đã GỘP vào Main (bản đồ nằm ngay trong Main) — giữ tên hằng để code cũ
## không vỡ, nhưng trỏ về Main.
const SCENE_LEVELS := "res://scenes/main.tscn"
const SCENE_GAME := "res://scenes/game.tscn"
const SCENE_DAILY := "res://scenes/daily.tscn"
const SCENE_SETTINGS := "res://scenes/settings.tscn"
const SCENE_DEBUG := "res://scenes/debug.tscn"
const SCENE_ARCHIVEMENT := "res://scenes/archivement.tscn"
const SCENE_RANKING := "res://scenes/ranking.tscn"
## Màn CỬA HÀNG — xem scripts/scenes/shop.gd
const SCENE_SHOP := "res://scenes/shop.tscn"
## Màn CREDIT — soundtrack + ghi công
const SCENE_CREDIT := "res://scenes/credit.tscn"
## Màn TUTORIAL — CHI TIẾT bài hướng dẫn (mount đúng bài được yêu cầu)
const SCENE_TUTORIAL := "res://scenes/tutorial.tscn"
## Màn DANH SÁCH bài hướng dẫn — bấm 1 bài mới mở `SCENE_TUTORIAL`
const SCENE_TUTORIAL_LIST := "res://scenes/tutorial_list.tscn"
## Màn CHI TIẾT SỰ KIỆN — xem scripts/scenes/event.gd
const SCENE_EVENT := "res://scenes/event.tscn"
## (HỒ SƠ CÁ NHÂN nay là POPUP — mở bằng `Popups.open(Popups.PROFILER)`)



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


## DEPRECATED — Levels đã GỘP vào Main: bản đồ màn chơi nằm ngay trong Main.
## Giữ tên hàm để không phải sửa mọi nơi gọi.
static func goto_levels() -> void:
	back_to_main()


## Điều hướng KHÔNG ghi lịch sử — dùng cho nút BACK (về màn CHA).
## Vì `ScreenManager` lùi theo LỊCH SỬ, nếu Back có ghi lịch sử thì Back ở màn cha sẽ nhảy
## NGƯỢC về màn con ⇒ vòng lặp điều hướng (lỗi đã gặp: Chọn màn ⇄ Chọn chương).
static func back_to(path: String) -> void:
	var manager := _manager()
	if manager != null and manager.has_method("change_scene"):
		manager.call("change_scene", path, false)
		return
	var tree := _tree()
	if tree != null:
		tree.change_scene_to_file(path)


## Back về MÀN HÌNH CHÍNH (không ghi lịch sử)
static func back_to_main() -> void:
	back_to(SCENE_MAIN)


## Back về màn CÓ BẢN ĐỒ ĐỒ (nay là Main) — không ghi lịch sử
static func back_to_levels() -> void:
	back_to_main()


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


## Màn CỬA HÀNG (bút · giấy vở · dụng cụ · nạp xu)
static func goto_shop() -> void:
	change_scene(SCENE_SHOP)


## Màn CREDIT (thông tin soundtrack và ghi công đội ngũ)
static func goto_credit() -> void:
	change_scene(SCENE_CREDIT)


## Màn hình debug (chỉ dùng khi phát triển)
static func goto_debug() -> void:
	change_scene(SCENE_DEBUG)


## Màn TUTORIAL — CHI TIẾT (màn mount bài học). Yêu cầu bài đặt TRƯỚC qua
## `GameManager.request_tutorial(id)`; mở từ danh sách thì dùng `request_tutorial(id, true)`.
static func goto_tutorial() -> void:
	change_scene(SCENE_TUTORIAL)


## Màn DANH SÁCH bài hướng dẫn (nút LUẬT CHƠI ở Main)
static func goto_tutorial_list() -> void:
	change_scene(SCENE_TUTORIAL_LIST)


## Lùi về MÀN TRƯỚC theo lịch sử `ScreenManager` (hết lịch sử ⇒ về Main).
## Dùng cho màn mở được từ NHIỀU nơi khác nhau — vd DANH SÁCH hướng dẫn mở từ Main
## hoặc từ Cài đặt ⇒ Back phải về đúng màn đã mở nó, không phải luôn về Main.
static func go_back() -> void:
	var manager := _manager()
	var screen := _screen()
	# Bỏ các mục lịch sử TRÙNG màn hiện tại (đi tới rồi lùi trong CÙNG một màn, vd Danh sách
	# ⇄ Chi tiết bài) — nếu để nguyên, Back sẽ "quay lại chính nó" và người chơi thấy như nút hỏng.
	if manager != null and screen != null and manager.has_method("current_scene_path") \
			and screen.has_method("drop_history"):
		var current := str(manager.call("current_scene_path"))
		while bool(screen.call("drop_history", current)):
			pass
	if manager != null and manager.has_method("go_back"):
		manager.call("go_back")
		return
	back_to_main()


## Back từ màn CHI TIẾT về DANH SÁCH (không ghi lịch sử)
static func back_to_tutorial_list() -> void:
	back_to(SCENE_TUTORIAL_LIST)


## Màn CHI TIẾT SỰ KIỆN — truyền event_id qua SceneManager trước khi chuyển cảnh
static func goto_event(event_id: StringName) -> void:
	var manager := _manager()
	if manager != null and manager.has_method("goto_event"):
		manager.call("goto_event", event_id)
		return
	change_scene(SCENE_EVENT)


static func _manager() -> Node:
	var tree := _tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("SceneManager")
	return null


static func _screen() -> Node:
	var tree := _tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("ScreenManager")
	return null


static func _tree() -> SceneTree:
	var main_loop := Engine.get_main_loop()
	return main_loop as SceneTree if main_loop is SceneTree else null
