class_name TutorialScene
extends BaseScene

## ============================================================================
## View Controller: Màn hình Tutorial (hướng dẫn tương tác)
## Kế thừa BaseScene, điều phối chạy các màn tutorial độc lập hoặc theo chuỗi onboarding.
## ============================================================================

const NavHelper := preload("res://scripts/utils/nav.gd")

@export var tutorial_controller: TutorialController = null

var layout: TutorialLayout = null
## Mở 1 bài LẺ (Debug Console) hoặc Test mode ⇒ học xong Ở LẠI màn Tutorial để thử bài khác
var _stay_after_finish := false


func _ready() -> void:
	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)

	# `tutorial_controller` bind trong `scenes/tutorial.tscn` (không dò đường dẫn trong code)
	if tutorial_controller != null and layout != null:
		tutorial_controller.set_container(layout.tutorial_container)
		tutorial_controller.sequence_finished.connect(_on_sequence_finished)
		_start_requested()


## Debug Console có thể yêu cầu mở THẲNG 1 bài (hoặc chạy lại chuỗi CORE) trước khi vào màn
func _start_requested() -> void:
	var requested := _take_tutorial_request()
	_stay_after_finish = _is_test_mode()
	if requested.is_empty() or requested == TutorialController.REQUEST_CORE:
		tutorial_controller.start_sequence()
	else:
		_stay_after_finish = true
		tutorial_controller.play_single_tutorial(requested)


## Ván TEST (Debug Console bật “Test mode”): không ghi tiến trình, không tự nhảy màn
func _is_test_mode() -> bool:
	var gm := get_node_or_null("/root/GameManager")
	return bool(gm.get("debug_run")) if gm != null else false


## Đọc yêu cầu từ GameManager (lấy động qua /root — xem chú thích ở `utils/nav.gd`)
func _take_tutorial_request() -> String:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("take_tutorial_request"):
		return str(gm.call("take_tutorial_request"))
	return ""


func _bind_refs() -> void:
	layout = active_layout() as TutorialLayout
	if layout == null:
		push_warning("tutorial: active_layout chua phai TutorialLayout")


func _wire_buttons() -> void:
	if layout == null:
		return

	if layout.btn_back != null and not layout.btn_back.is_connected("pressed", _on_back_pressed):
		layout.btn_back.pressed.connect(_on_back_pressed)

	var btn_map := {
		layout.btn_first_time: "first_time",
		layout.btn_move: "how_to_play_move",
		layout.btn_checking_wall: "how_to_play_checking_wall",
		layout.btn_minesweeper: "how_to_play_minesweeper",
		layout.btn_one_stroke: "how_to_play_one_stroke",
		layout.btn_sum_path: "how_to_play_sum_path",
		layout.btn_wall_builder: "how_to_play_wall_builder",
		layout.btn_countdown_cost: "how_to_play_countdown_cost",
		layout.btn_fading_ink: "how_to_play_fading_ink",
		layout.btn_fog_of_war: "how_to_play_fog_of_war",
		layout.btn_blind_memory: "how_to_play_blind_memory",
		layout.btn_use_tool: "how_to_use_tool",
	}

	for btn in btn_map:
		if btn != null:
			var tid: String = btn_map[btn]
			if not btn.is_connected("pressed", _on_select_tutorial.bind(tid)):
				btn.pressed.connect(_on_select_tutorial.bind(tid))


func _on_select_tutorial(tid: String) -> void:
	_stay_after_finish = true
	if tutorial_controller != null:
		tutorial_controller.play_single_tutorial(tid)


func _on_back_pressed() -> void:
	NavHelper.goto_main()


func _on_sequence_finished() -> void:
	# Thử bài từ Debug Console (bài lẻ / Test mode): ở lại màn Tutorial để chọn bài khác
	if _stay_after_finish:
		return
	# Hoàn thành chuỗi: chuyển sang Màn 1 hoặc về Menu chính
	var gm := get_tree().root.get_node_or_null("GameManager") if get_tree() != null and get_tree().root != null else null
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", 1)
	else:
		NavHelper.goto_main()


func _on_orientation_changed(_is_land: bool) -> void:
	_bind_refs()
	_wire_buttons()
	if tutorial_controller != null and layout != null:
		tutorial_controller.set_container(layout.tutorial_container)
