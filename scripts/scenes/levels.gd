class_name LevelScenes
extends BaseScene
## ============================================================================
## View Controller: Màn hình Chọn Màn chơi (Level Selection)
## Hiển thị lưới 9 level card tương ứng chương 1.
## Cập nhật trạng thái khóa/mở và số sao đã tích lũy từ GameManager.
## ============================================================================

@onready var btn_back: TextureButton = $TopBar/Back
@onready var grid_container: GridContainer = $GridContainer


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)

	_setup_level_cards()


func _setup_level_cards() -> void:
	if grid_container == null:
		return

	var gm: Node = get_node_or_null("/root/GameManager")
	var unlocked: int = gm.unlocked_levels if gm != null else 1
	var stars_dict: Dictionary = gm.level_stars if gm != null else {}

	var cards := grid_container.get_children()
	for i in cards.size():
		var card: Control = cards[i]
		var level_id := i + 1
		var is_locked := level_id > unlocked
		var rating: int = stars_dict.get(level_id, 0)
		var is_done := rating > 0

		if card is LevelCard:
			card.setup(level_id, is_locked, rating, is_done)
			card.selected.connect(_on_level_selected)
		elif card.has_method("setup"):
			card.call("setup", level_id, is_locked, rating, is_done)
			if card.has_signal("selected"):
				card.connect("selected", _on_level_selected)


func _on_level_selected(level_id: int) -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.start_level(level_id)
	else:
		get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back_pressed() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
