class_name DailyScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Daily Challenge (scenes/daily.tscn)
## Hiển thị lịch tháng và cho phép người chơi chọn ngày thử thách.
## Mỗi ngày tương ứng với một chế độ thử thách luân phiên trong 7 Challenge Modes.
## ============================================================================

@onready var btn_back: TextureButton = $TopBar/Back
@onready var calendar_days: GridContainer = $Calendar/Days


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)

	_setup_days()


func _setup_days() -> void:
	if calendar_days == null:
		return

	var children := calendar_days.get_children()
	for i in children.size():
		var day_node: Control = children[i]
		var day_num := i + 1

		if day_node is DailyDayCell:
			day_node.setup(day_num, false, day_num == 1)
			day_node.day_selected.connect(_on_day_selected)
		elif day_node.has_method("setup"):
			day_node.call("setup", day_num, false, day_num == 1)
			if day_node.has_signal("day_selected"):
				day_node.connect("day_selected", _on_day_selected)


func _on_day_selected(day: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.start_daily(day)
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back_pressed() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
