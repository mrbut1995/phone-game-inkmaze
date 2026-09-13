class_name Save
extends RefCounted
## ============================================================================
## Helper tĩnh: lưu/đọc dữ liệu người chơi qua autoload SaveManager.
##
## Vì sao không gọi thẳng `SaveManager.flush()`?
##   Test runner chạy bằng `godot --script ...` -> identifier autoload không
##   resolve được lúc parse. Vì vậy mọi nơi chỉ tham chiếu class `Save` này,
##   node autoload được lấy động qua /root/SaveManager (giống Sfx/Nav/Loc/Popups).
##
## Cách dùng:
##   Save.queue_save()                 # hẹn lưu (debounce) sau khi tiến trình đổi
##   Save.flush()                      # lưu ngay
##   Save.use_play_games()             # chuyển sang lưu Google Play (khi có plugin)
## ============================================================================

const LOCAL := "local"
const PLAY_GAMES := "play_games"


static func _mgr() -> Node:
	var main_loop := Engine.get_main_loop()
	var tree := main_loop as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("SaveManager")
	return null


## Hẹn lưu sau một nhịp (gộp nhiều thay đổi liên tiếp)
static func queue_save() -> void:
	var mgr := _mgr()
	if mgr != null:
		mgr.call("queue_save")


## Lưu ngay
static func flush() -> bool:
	var mgr := _mgr()
	return bool(mgr.call("save_now")) if mgr != null else false


## Nạp lại dữ liệu từ backend và áp vào các manager.
## LƯU Ý: KHÔNG đặt tên là `reload()` vì GDScript sẽ gọi vào API native
## `Script.reload()` (lỗi "Cannot reload script while instances exist") thay vì hàm này.
static func reload_all() -> void:
	var mgr := _mgr()
	if mgr != null:
		mgr.call("load_all")


## Đổi nơi lưu: Save.LOCAL hoặc Save.PLAY_GAMES
static func set_backend(kind: String) -> bool:
	var mgr := _mgr()
	return bool(mgr.call("set_backend", kind)) if mgr != null else false


static func use_local() -> bool:
	return set_backend(LOCAL)


## Bật lưu trên Google Play Games (chỉ thành công khi đã cài plugin + đăng nhập)
static func use_play_games() -> bool:
	return set_backend(PLAY_GAMES)


static func backend_id() -> String:
	var mgr := _mgr()
	if mgr == null:
		return LOCAL
	var backend: Variant = mgr.get("backend")
	return str(backend.call("id")) if backend != null else LOCAL


static func is_cloud() -> bool:
	var mgr := _mgr()
	return bool(mgr.call("is_cloud")) if mgr != null else false


static func cloud_available() -> bool:
	var mgr := _mgr()
	return bool(mgr.call("cloud_available")) if mgr != null else false


static func reset_all() -> void:
	var mgr := _mgr()
	if mgr != null:
		mgr.call("reset_all")
