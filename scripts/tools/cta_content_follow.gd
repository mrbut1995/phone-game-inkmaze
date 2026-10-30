class_name CtaContentFollow
extends TextureButton
## Nút CTA kiểu gờ đáy: art nút tự vẽ độ chìm khi nhấn, script này kéo NỘI DUNG (icon + chữ)
## chìm theo đúng chừng đó để chữ dính vào mặt nút.

## Node nội dung (Control đã neo kín nút) — gán trong .tscn
@export var content: Control = null
## Độ chìm (px hiển thị). Art: 4px thiết kế × scale 0.5 = 2px
@export_range(0.0, 8.0, 0.5) var press_sink := 2.0
@export_range(0.01, 0.3, 0.01) var follow_sec := 0.05

var _base_top := 0.0
var _base_bottom := 0.0
var _tween: Tween = null


func _ready() -> void:
	if content != null:
		_base_top = content.offset_top
		_base_bottom = content.offset_bottom
	button_down.connect(_on_down)
	button_up.connect(_on_up)


func _on_down() -> void:
	_move(press_sink)


func _on_up() -> void:
	_move(0.0)


func _move(sink: float) -> void:
	if content == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(content, "offset_top", _base_top + sink, follow_sec)
	_tween.tween_property(content, "offset_bottom", _base_bottom + sink, follow_sec)
