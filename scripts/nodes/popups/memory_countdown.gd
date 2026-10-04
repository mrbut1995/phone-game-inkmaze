class_name MemoryCountdownPopup
extends BasePopup
## ============================================================================
## Popup đếm ngược pha GHI NHỚ của Blind Memory Maze.
## - Không có nền mờ (Dim ẩn) để người chơi VẪN NHÌN THẤY toàn bộ tường bên dưới.
## - Chạy 3 → 2 → 1 → GO! rồi phát signal `finished` để GameController ẩn tường.
## - Không đóng bằng nút Back (close_on_back = false trong scene).
## ============================================================================

signal finished

const STEP_SECONDS := 0.85
const GO_SECONDS := 0.5

## Node binding: khai `node_paths` + `NodePath` trong `memory_countdown.tscn`
@export var number_label: Label = null
@export var title_label: Label = null
## Hiệu ứng riêng của popup (animation "number_pop") — node tên `FxAnim` vì popup đã có
## `AnimationPlayer` của base.tscn (mở/đóng popup) — không được trùng tên.
@export var fx_anim: AnimationPlayer = null

var _seconds := 3
var _tw: Tween = null


func _on_open() -> void:
	_seconds = maxi(int(data.get("seconds", 3)), 1)
	number_label.text = str(_seconds)
	if title_label.text.is_empty():
		title_label.text = "STR_MEMORIZE_TITLE"
	# Mở xong mới bắt đầu đếm để người chơi kịp thấy mẩu giấy —
	# dây `opened → _start_countdown` khai trong `memory_countdown.tscn` (cùng scene)


func _on_close() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
		_tw = null


func _start_countdown() -> void:
	# Nhịp đếm (chờ theo giây rồi đổi số) là LỊCH TRÌNH, không phải hiệu ứng hình — giữ tween
	if _tw != null and _tw.is_valid():
		_tw.kill()
	_tw = create_tween()
	for s in range(_seconds, 0, -1):
		_tw.tween_callback(_show_step.bind(str(s)))
		_tw.tween_interval(STEP_SECONDS)
	_tw.tween_callback(_show_step.bind("GO!"))
	_tw.tween_interval(GO_SECONDS)
	_tw.tween_callback(_finish)


## Đổi số trên mẩu giấy + nảy nhẹ cho dễ nhìn (animation "number_pop" trong scene)
func _show_step(text: String) -> void:
	if not is_instance_valid(number_label):
		return
	number_label.text = text
	number_label.modulate = Color(0.847, 0.267, 0.267, 1) if text != "GO!" else Color(0.180, 0.490, 0.196, 1)
	number_label.pivot_offset = number_label.size * 0.5
	number_label.scale = Vector2(1.35, 1.35)
	if fx_anim == null or not fx_anim.has_animation(&"number_pop"):
		# Fallback khi scene thiếu FxAnim
		var tw := create_tween()
		tw.tween_property(number_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		fx_anim.play(&"number_pop")
	if text == "GO!":
		Sfx.play(Sfx.LEVEL_WIN)
	else:
		Sfx.play(Sfx.STAR_POP)


## Hết đếm ngược: báo cho GameController (ẩn tường + chạy đồng hồ) rồi tự đóng
func _finish() -> void:
	if is_closing():
		return
	finished.emit()
	close()
