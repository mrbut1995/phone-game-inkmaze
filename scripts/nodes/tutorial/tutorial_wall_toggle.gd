class_name TutorialWallToggle
extends Button
## ============================================================================
## Nút bật/tắt 1 đoạn TƯỜNG của tutorial Wall Builder.
##
## Hình đoạn tường (`Wall` — NinePatchRect) khai SẴN trong scene; nút chỉ bật/tắt nó rồi phát
## `wall_toggled` để tutorial xử lý luật. Dây `pressed → _on_pressed` nằm trong `.tscn`.
## Đoạn tường NỞ RA khi bật / CO LẠI khi tắt (kèm SFX) — hiệu ứng nằm gọn trong component này.
## ============================================================================

signal wall_toggled(wall_id: String, active: bool)

## Mã đoạn tường (tutorial so với đáp án) — ghi trong .tscn
@export var wall_id: String = ""
## Node hình đoạn tường — bind trong .tscn
@export var wall_visual: Control = null

## Cỡ lúc bắt đầu nở / lúc kết thúc co (nhỏ & dẹt ⇒ trông như nét mực vừa vẽ ra)
const GROW_FROM := Vector2(0.35, 0.12)

var _active := false


func _ready() -> void:
	if wall_visual != null:
		wall_visual.pivot_offset = wall_visual.size * 0.5
		wall_visual.resized.connect(_on_visual_resized)


func _on_visual_resized() -> void:
	if wall_visual != null:
		wall_visual.pivot_offset = wall_visual.size * 0.5


func is_active() -> bool:
	return _active


func set_active(on: bool, animate := true) -> void:
	_active = on
	if wall_visual == null:
		return
	if not animate or not is_inside_tree():
		wall_visual.visible = on
		wall_visual.scale = Vector2.ONE
		wall_visual.modulate.a = 1.0
		return
	_animate_visual(on)


## Bật: nở từ giữa + hiện dần · Tắt: co lại + mờ đi rồi ẩn
func _animate_visual(on: bool) -> void:
	wall_visual.pivot_offset = wall_visual.size * 0.5
	wall_visual.visible = true
	if on:
		wall_visual.scale = GROW_FROM
		wall_visual.modulate.a = 0.0
	else:
		wall_visual.scale = Vector2.ONE
		wall_visual.modulate.a = 1.0

	var tw := wall_visual.create_tween()
	tw.set_parallel(true)
	if on:
		tw.tween_property(wall_visual, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(wall_visual, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tw.tween_property(wall_visual, "scale", GROW_FROM, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(wall_visual, "modulate:a", 0.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		if not is_instance_valid(wall_visual):
			return
		wall_visual.scale = Vector2.ONE
		if not _active:
			wall_visual.visible = false
	)


## Nối với tín hiệu `pressed` NGAY TRONG `.tscn` (`[connection signal="pressed" …]`)
func _on_pressed() -> void:
	set_active(not _active)
	Sfx.play(Sfx.WALL_MARK if _active else Sfx.BTN_WOOD_TAP)
	wall_toggled.emit(wall_id, _active)
