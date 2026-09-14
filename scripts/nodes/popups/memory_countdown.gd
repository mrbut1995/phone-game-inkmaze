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

@onready var _number: Label = piece("Number") as Label
@onready var _title: Label = piece("Title") as Label

var _seconds := 3
var _tw: Tween = null


func _on_open() -> void:
	_seconds = maxi(int(data.get("seconds", 3)), 1)
	if _number != null:
		_number.text = str(_seconds)
	if _title != null and _title.text.is_empty():
		_title.text = "STR_MEMORIZE_TITLE"
	# Mở xong mới bắt đầu đếm để người chơi kịp thấy mẩu giấy
	if not opened.is_connected(_start_countdown):
		opened.connect(_start_countdown, CONNECT_ONE_SHOT)


func _on_close() -> void:
	if _tw != null and _tw.is_valid():
		_tw.kill()
		_tw = null


func _start_countdown() -> void:
	_tw = create_tween()
	for s in range(_seconds, 0, -1):
		_tw.tween_callback(_show_step.bind(str(s)))
		_tw.tween_interval(STEP_SECONDS)
	_tw.tween_callback(_show_step.bind("GO!"))
	_tw.tween_interval(GO_SECONDS)
	_tw.tween_callback(_finish)


## Đổi số trên mẩu giấy + nảy nhẹ cho dễ nhìn
func _show_step(text: String) -> void:
	if _number == null or not is_instance_valid(_number):
		return
	_number.text = text
	_number.modulate = Color(0.847, 0.267, 0.267, 1) if text != "GO!" else Color(0.180, 0.490, 0.196, 1)
	_number.pivot_offset = _number.size * 0.5
	_number.scale = Vector2(1.35, 1.35)
	var tw := create_tween()
	tw.tween_property(_number, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
