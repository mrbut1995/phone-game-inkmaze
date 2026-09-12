extends Node
## ============================================================================
## Manager: AdsManager - Cầu nối quảng cáo (PLACEHOLDER).
##
## Hiện dự án chưa gắn SDK quảng cáo (AdMob/Unity Ads...). Manager này cung cấp
## API an toàn để game gọi trước, khi gắn SDK thật chỉ cần thay phần thân.
##
## TODO: Gắn plugin AdMob (Android) và hiện thực các hàm bên dưới.
## ============================================================================

signal rewarded_available_changed(available: bool)
signal rewarded_completed(reward_id: String)
signal interstitial_closed

## Bật/tắt để test luồng UI khi chưa có SDK
var enabled := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_rewarded_ready() -> bool:
	return false


func is_interstitial_ready() -> bool:
	return false


## Trả về true nếu quảng cáo được hiển thị
func show_rewarded(_reward_id := "default") -> bool:
	_debug_log("show_rewarded bị bỏ qua (chưa gắn SDK quảng cáo)")
	return false


func show_interstitial() -> bool:
	_debug_log("show_interstitial bị bỏ qua (chưa gắn SDK quảng cáo)")
	return false


func _debug_log(message: String) -> void:
	var dbg: Variant = get_node_or_null("/root/DebugManager")
	if dbg != null and dbg.has_method("log"):
		dbg.call("log", "ads", message)
	else:
		print("[ADS] " + message)
