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

## Bật/tắt để test luồng UI khi chưa có SDK.
## ĐANG ĐỂ true: giả lập xem quảng cáo xong thành công để nút HỒI SINH chạy được
## trong bản chưa gắn SDK (khi gắn SDK thật thì thay thân hàm show_rewarded bên dưới).
var enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_rewarded_ready() -> bool:
	return enabled


func is_interstitial_ready() -> bool:
	return enabled


## Trả về true nếu quảng cáo được hiển thị (và người chơi đã xem xong)
func show_rewarded(reward_id := "default") -> bool:
	if not enabled:
		_debug_log("show_rewarded bị bỏ qua (chưa gắn SDK quảng cáo)")
		return false
	_debug_log("show_rewarded: giả lập xem xong quảng cáo '%s'" % reward_id)
	rewarded_completed.emit(reward_id)
	return true


func show_interstitial() -> bool:
	if not enabled:
		_debug_log("show_interstitial bị bỏ qua (chưa gắn SDK quảng cáo)")
		return false
	interstitial_closed.emit()
	return true


func _debug_log(message: String) -> void:
	var dbg: Variant = get_node_or_null("/root/DebugManager")
	if dbg != null and dbg.has_method("log"):
		dbg.call("log", "ads", message)
	else:
		print("[ADS] " + message)
