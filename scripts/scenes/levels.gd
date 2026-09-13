class_name LevelScenes
extends BaseScene
## ============================================================================
## View Controller: Màn hình Chọn Màn chơi (Level Selection)
## Hiển thị lưới 9 level card tương ứng chương 1.
## Cập nhật trạng thái khóa/mở và số sao đã tích lũy từ GameManager.
## ============================================================================

@onready var btn_back: TextureButton = $TopBar/Back
@onready var grid_container: GridContainer = $GridContainer
@onready var btn_continue: TextureButton = $ContinueButton
@onready var lbl_continue: Label = $ContinueButton/Label
@onready var lbl_stars: Label = $StarsCounter/Count


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
	if btn_continue != null:
		btn_continue.pressed.connect(_on_continue_pressed)

	_setup_level_cards()
	_refresh_header()


## Cap nhat so sao tich luy + nhan nut "Tiep tuc man {0}" theo String key
func _refresh_header() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	var unlocked: int = 1
	var total_stars := 0
	if gm != null:
		unlocked = int(gm.get("unlocked_levels")) if gm.get("unlocked_levels") != null else 1
		var stars_dict: Dictionary = gm.get("level_stars") if gm.get("level_stars") != null else {}
		for value in stars_dict.values():
			total_stars += int(value)
	if lbl_stars != null:
		lbl_stars.text = "%d/%d" % [total_stars, unlocked * 3]
	if lbl_continue != null:
		lbl_continue.text = tr("STR_BTN_CONTINUE_LEVEL").format([maxi(unlocked, 1)])


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


func _on_continue_pressed() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	var unlocked: int = 1
	if gm != null and gm.get("unlocked_levels") != null:
		unlocked = maxi(int(gm.get("unlocked_levels")), 1)
	Sfx.play(Sfx.BTN_CLICK)
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", unlocked)
	else:
		Nav.goto_game()


func _on_back_pressed() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Back)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
	else:
		Nav.goto_main()
