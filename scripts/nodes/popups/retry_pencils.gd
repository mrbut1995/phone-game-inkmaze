class_name RetryPencils
extends VBoxContainer
## Hàng BÚT CHÌ + đồng hồ đếm ngược hồi bút của popup Retry.
##
## Script chỉ HIỂN THỊ. Số bút (= lượt chơi) và mốc hồi do GameManager giữ; retry.gd đọc
## rồi đẩy vào qua set_state(). Script không đọc/ghi tiến trình.
##
## retry.gd gọi:  pencils.set_state(lives, max_lives, unix_hồi_kế_tiếp, bỏ_qua_có_bị_trừ)
## và nối recover_finished (CONNECT_DEFERRED) để lấy lại số liệu mới.

## Đếm ngược chạm 0: chủ popup nên lấy lại số liệu từ manager và gọi set_state() lần nữa.
signal recover_finished

@export var tex_full: Texture2D
@export var tex_empty: Texture2D
@export var row: HBoxContainer
@export var recover_label: Label

var _current: int = 0
var _maximum: int = 0
var _next_recover_unix: float = 0.0
var _finished_emitted: bool = false


## current: số bút đang có. maximum: sức chứa tối đa (số slot hiện ra).
## next_recover_unix: mốc UNIX (giây) bút kế tiếp hồi xong; <= 0 nghĩa là không đếm.
## show_risk: đánh dấu bút sẽ gãy nếu bỏ qua (khung đỏ + nhãn −1) — bút CUỐI đang có.
## lost_index: slot bút VỪA GÃY (đã trừ rồi) — chỉ hiện nhãn −1, không khung; -1 = không có.
func set_state(current: int, maximum: int, next_recover_unix: float = 0.0, show_risk: bool = true, lost_index: int = -1) -> void:
	_maximum = clampi(maximum, 0, row.get_child_count())
	_current = clampi(current, 0, _maximum)
	_next_recover_unix = next_recover_unix
	_finished_emitted = false
	var risk_index: int = _current - 1 if show_risk else -1
	for i in row.get_child_count():
		var slot: Control = row.get_child(i)
		slot.visible = i < _maximum
		var pencil: TextureRect = slot.get_node("Pencil")
		pencil.texture = tex_full if i < _current else tex_empty
		slot.get_node("RiskFrame").visible = (i == risk_index)
		slot.get_node("Badge").visible = (i == risk_index) or (i == lost_index)
	_refresh_countdown()


func _refresh_countdown() -> void:
	var recovering: bool = _current < _maximum and _next_recover_unix > 0.0
	recover_label.visible = recovering
	if not recovering:
		return
	var remaining: float = maxf(0.0, _next_recover_unix - Time.get_unix_time_from_system())
	# Chuỗi dịch dạng "Bút mới sau {0}" (cùng kiểu {0} như STR_RESULT_STAMP_FLOOR).
	recover_label.text = tr("STR_RETRY_NEXT_PENCIL").format([format_duration(remaining)])
	if remaining <= 0.0 and not _finished_emitted:
		_finished_emitted = true
		recover_finished.emit()


## 83 giây -> "01:23"; 4 520 giây -> "1:15:20".
static func format_duration(seconds: float) -> String:
	var total: int = int(ceil(seconds))
	var h: int = floori(total / 3600.0)
	var m: int = floori((total % 3600) / 60.0)
	var s: int = total % 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s]
	return "%02d:%02d" % [m, s]


func _on_recover_timer_timeout() -> void:
	_refresh_countdown()
