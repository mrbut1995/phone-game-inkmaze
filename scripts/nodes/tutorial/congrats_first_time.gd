class_name CongratsFirstTimeTutorial
extends BaseTutorial
## Bài CHÚC MỪNG cuối luồng học lần đầu (xem `TutorialManager.FLOW`):
## chúc mừng người chơi đã xong 3 bài học + 4 màn thử sức, rồi cho CHỌN:
##   · CHƠI BÀN TIẾP THEO → vào luôn màn kế tiếp trong chương
##   · VỀ MÀN HÌNH CHÍNH  → về Main
## Màn này dùng 2 nút riêng ở đáy nên ẩn thanh điều hướng mặc định (nút Tiếp tục · chấm bước).

const TITLE_KEY := "STR_TUT_CONGRATS_TITLE"

## Con dấu "HOÀN THÀNH" trang trí giữa màn + 2 nút lựa chọn (bind trong .tscn)
@export var stamp: TextureRect = null
@export var btn_continue: BaseButton = null
@export var btn_main: BaseButton = null


func _init_tutorial() -> void:
	tutorial_id = "congrats_first_time"


func _get_default_steps() -> Array:
	return [{
		"title_key": TITLE_KEY,
		"message_key": "STR_TUT_CONGRATS_BODY",
		"fallback_text": "Bạn đã hoàn thành 3 bài học đầu tiên và 4 màn thử sức. Giờ bạn đã sẵn sàng cho hành trình tiếp theo!",
		"advance_mode": "AUTO",
	}]


## Ẩn thanh điều hướng mặc định + chấm bước; đóng dấu "nở" ra khi vào bài
func _on_step_entered(_index: int, _data: Dictionary) -> void:
	if btn_continue != null:
		btn_continue.text = _tr_key("STR_TUT_CONGRATS_CONTINUE", "CHƠI BÀN TIẾP THEO")
	if btn_main != null:
		btn_main.text = _tr_key("STR_TUT_CONGRATS_MAIN", "VỀ MÀN HÌNH CHÍNH")
	nav_bar.visible = false
	btn_skip.visible = false
	if dots_container != null:
		dots_container.visible = false
	# Ẩn nút lựa chọn — sẽ pop vào sau khi con dấu đóng
	if btn_continue != null:
		btn_continue.modulate.a = 0.0
	if btn_main != null:
		btn_main.modulate.a = 0.0
	if stamp != null:
		stamp.pivot_offset = stamp.size * 0.5
		stamp.scale = Vector2(1.6, 1.6)
		stamp.modulate.a = 0.0
		stamp.rotation = deg_to_rad(-5.0)
		var tw := stamp.create_tween()
		# Phase 1: con dấu rơi nhanh + squash nhẹ khi chạm
		tw.set_parallel(true)
		tw.tween_property(stamp, "scale", Vector2(0.88, 0.88), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(stamp, "modulate:a", 1.0, 0.14)
		tw.tween_property(stamp, "rotation", 0.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		# Phase 2: nảy lại về kích thước thật
		tw.set_parallel(false)
		tw.tween_callback(func() -> void: Sfx.play(Sfx.STAMP_IMPACT))
		tw.tween_property(stamp, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		# Phase 3: nhạc chiến thắng + nút xuất hiện
		tw.tween_callback(func() -> void: Sfx.play(Sfx.LEVEL_WIN))
		tw.tween_callback(func() -> void: _reveal_choice_buttons())
	else:
		Sfx.play(Sfx.LEVEL_WIN)
		_reveal_choice_buttons()


## Nút xuất hiện có stagger sau khi con dấu đóng xong
func _reveal_choice_buttons() -> void:
	var btns := [btn_continue, btn_main]
	for i in btns.size():
		var btn := btns[i] as BaseButton
		if btn != null:
			UIAnim.play_pop_in(btn, i * 0.12, 0.88, 0.28)


## "CHƠI BÀN TIẾP THEO": học xong luồng sẽ mở luôn màn kế trong chương
func _on_continue_pressed() -> void:
	var tm := get_node_or_null("/root/TutorialManager")
	if tm != null and tm.has_method("request_continue_after_flow"):
		tm.call("request_continue_after_flow")
	Sfx.play(Sfx.BTN_CLICK)
	complete_tutorial()


## "VỀ MÀN HÌNH CHÍNH": học xong luồng về Main
func _on_main_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	complete_tutorial()


## Dịch khoá chữ (chưa có khoá trong bảng dịch thì dùng chữ dự phòng)
func _tr_key(key: String, fallback: String) -> String:
	var text := tr(key)
	return fallback if text == key else text
