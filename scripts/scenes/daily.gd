class_name DailyScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Daily Challenge (scenes/daily.tscn)
## Hiển thị lịch tháng và cho phép người chơi chọn ngày thử thách.
## Mỗi ngày tương ứng với một chế độ thử thách luân phiên trong 7 Challenge Modes.
## ============================================================================

@onready var btn_back: TextureButton = $TopBar/Back
@onready var calendar_days: GridContainer = $Calendar/Days
@onready var btn_prev_month: TextureButton = $Calendar/Months/Previous
@onready var btn_next_month: TextureButton = $Calendar/Months/Next


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_prev_month != null:
		btn_prev_month.pressed.connect(_on_month_switch_pressed)
	if btn_next_month != null:
		btn_next_month.pressed.connect(_on_month_switch_pressed)

	_setup_days()


func _setup_days() -> void:
	if calendar_days == null:
		return

	var daily: Variant = get_node_or_null("/root/DailyManager")
	var children := calendar_days.get_children()
	for i in children.size():
		var day_node: Control = children[i]
		var day_num := i + 1
		var is_done := false
		var is_today := day_num == 1
		if daily != null:
			is_done = bool(daily.call("is_completed", day_num))
			is_today = bool(daily.call("is_today", day_num))

		if day_node is DailyDayCell:
			day_node.setup(day_num, is_done, is_today)
			day_node.day_selected.connect(_on_day_selected)
		elif day_node.has_method("setup"):
			day_node.call("setup", day_num, is_done, is_today)
			if day_node.has_signal("day_selected"):
				day_node.connect("day_selected", _on_day_selected)


func _on_day_selected(day: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.start_daily(day)
	else:
		Nav.goto_game()


## Nút < > trên lịch: hiện phát SFX miết mép giấy (phần đổi tháng sẽ bổ sung sau)
func _on_month_switch_pressed() -> void:
	Sfx.play(Sfx.DAY_SWITCH)


func _on_back_pressed() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Back)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
	else:
		Nav.goto_main()
