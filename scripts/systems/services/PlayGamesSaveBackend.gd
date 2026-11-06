class_name PlayGamesSaveBackend
extends SaveBackend
## ============================================================================
## Backend: Google Play Games - Saved Games (Snapshots).  [CHƯA CÀI ĐẶT]
##
## Hiện tại backend này LUÔN chưa sẵn sàng: game vẫn lưu local (LocalSaveBackend).
## Khi phát hành lên Google Play, chỉ cần:
##   1. Cài plugin Play Games Services cho Godot 4 Android (xem TODO.txt mục
##      "GOOGLE PLAY"): plugin cung cấp singleton "GodotPlayGamesServices"
##      (hoặc "PlayGamesServices" tuỳ bản plugin).
##   2. Bật Play Games Services trong Google Play Console + tạo OAuth client,
##      khai báo app_id trong plugin.
##   3. Điền phần TODO(google-play) bên dưới - KHÔNG phải sửa chỗ nào khác
##      trong game (SaveManager/Save facade đã tách sẵn).
##
## Ghi chú kỹ thuật cho phần cài đặt sau:
##  - Snapshots API là bất đồng bộ: mở snapshot -> đọc/ghi byte[] -> commit.
##  - Dữ liệu lưu dạng JSON UTF-8 (giống blob local) để merge được với local.
##  - Cần xử lý xung đột: so sánh `saved_at` (SaveManager.collect() đã ghi kèm)
##    và ưu tiên bản có tiến trình cao hơn, không ghi đè mù quáng.
##  - Nên gọi Save.use_play_games() sau khi người chơi đăng nhập thành công.
## ============================================================================

const SNAPSHOT_NAME := "inkmaze_player_progress"
const SINGLETON_CANDIDATES: Array[String] = ["GodotPlayGamesServices", "PlayGamesServices"]


func id() -> String:
	return "play_games"


func display_name() -> String:
	return "Google Play Games"


func is_available() -> bool:
	# TODO(google-play): chỉ trả true khi plugin đã cài VÀ người chơi đã đăng nhập.
	var plugin := _plugin()
	if plugin == null:
		return false
	if plugin.has_method("is_authenticated"):
		return bool(plugin.call("is_authenticated"))
	return true


func supports_cloud() -> bool:
	return true


func load_data() -> Dictionary:
	# TODO(google-play): mở snapshot SNAPSHOT_NAME, đọc byte[], JSON.parse_string.
	var plugin := _plugin()
	if plugin == null:
		return {}
	push_warning("[PlayGamesSaveBackend] Chua ho tro doc snapshot - xem TODO.txt (GOOGLE PLAY).")
	return {}


func save_data(_data: Dictionary) -> bool:
	# TODO(google-play): ghi byte[] JSON vào snapshot SNAPSHOT_NAME rồi commit.
	var plugin := _plugin()
	if plugin == null:
		return false
	push_warning("[PlayGamesSaveBackend] Chua ho tro ghi snapshot - xem TODO.txt (GOOGLE PLAY).")
	return false


func clear_data() -> bool:
	# TODO(google-play): xoá/ghi đè snapshot bằng dữ liệu rỗng.
	return false


## Singleton của plugin Play Games nếu đã cài (null khi chưa cài)
func _plugin() -> Object:
	for name in SINGLETON_CANDIDATES:
		if Engine.has_singleton(name):
			return Engine.get_singleton(name)
	return null
