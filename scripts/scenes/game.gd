class_name GameScene
extends BaseScene
## ============================================================================
## View Controller: Quản lý Scene chính của Game Screen (scenes/game.tscn).
## Khởi tạo và liên kết các Controller theo chuẩn MVC & Component.
## ============================================================================

const GAME_OVER_SCENE := preload("res://nodes/popups/gameover.tscn")
const WIN_SCENE := preload("res://nodes/popups/winning.tscn")
const SETTINGS_SCENE := preload("res://nodes/popups/settings.tscn")

@onready var board_view: Control = $Board
@onready var pause_btn: TextureButton = $Status/Pause
@onready var restart_btn: TextureButton = $Status/Restart
@onready var level_label: Label = $Status/LevelLabel

@onready var step_val: Label = $Information/Step/ValueContainer/Value
@onready var step_max: Label = $Information/Step/ValueContainer/MaxValue
@onready var time_val: Label = $Information/Time/Value
@onready var score_val: Label = $Information/Score/Value

@onready var tool_path_btn: TextureButton = $Button/Tool
@onready var tool_wall_btn: TextureButton = $Button/Wall
@onready var undo_btn: TextureButton = $Button/Undo
@onready var hint_btn: TextureButton = $Button/Hint

@export var game_controller: GameController = null
@export var grid_controller: GridController = null
@export var anchor_controller: AnchorController = null
@export var floor_controller: FloorController = null
@export var timer_controller: TimerController = null
@export var ui_controller: UIController = null
@export var tool_controller: ToolController = null
@export var undo_controller: UndoController = null
@export var hint_controller: HintController = null
@export var game_mode_controller : GameModeController = null

#@export var game_mode : BaseGameMode

var popup_win: Control = null
var popup_gameover: Control = null
var popup_settings: Control = null


func _ready() -> void:
	_setup_popups()
	_setup_mvc()
	_bind_buttons()

	# Khởi động ván chơi dựa trên GameManager hoặc mặc định
	var gm: Node = get_node_or_null("/root/GameManager")
	var initial_mode: String = "dungeon"
	var initial_diff: String = "medium"
	if gm != null:
		var m: Variant = gm.get("current_mode")
		if m != null and str(m) != "":
			initial_mode = str(m)
		var d: Variant = gm.get("current_difficulty")
		if d != null and str(d) != "":
			initial_diff = str(d)
	switch_mode(initial_mode, initial_diff)


func _setup_popups() -> void:
	popup_win = WIN_SCENE.instantiate()
	popup_win.visible = false
	add_child(popup_win)
	var win_replay := popup_win.get_node_or_null("Panel/Buttons/Replay") as TextureButton
	if win_replay != null:
		win_replay.pressed.connect(_on_win_replay_pressed)
	var win_next := popup_win.get_node_or_null("Panel/Buttons/Next") as TextureButton
	if win_next != null:
		win_next.pressed.connect(_on_win_next_pressed)

	popup_gameover = GAME_OVER_SCENE.instantiate()
	popup_gameover.visible = false
	add_child(popup_gameover)
	var go_replay := popup_gameover.get_node_or_null("Panel/Buttons/Replay") as TextureButton
	if go_replay != null:
		go_replay.pressed.connect(_on_gameover_replay_pressed)
	var go_menu := popup_gameover.get_node_or_null("Panel/Buttons/Menu") as TextureButton
	if go_menu != null:
		go_menu.pressed.connect(_on_menu_pressed)

	popup_settings = SETTINGS_SCENE.instantiate()
	popup_settings.visible = false
	add_child(popup_settings)


func _setup_mvc() -> void:
	ui_controller.setup(
		popup_win,
		popup_gameover,
		popup_settings
	)

func _bind_buttons() -> void:
	# Cac button chinh da duoc bind truc tiep bang signal trong scenes/game.tscn
	pass


func _on_restart_pressed() -> void:
	if game_controller != null:
		game_controller.restart_run()


func _on_pause_pressed() -> void:
	if ui_controller != null:
		ui_controller.toggle_settings()


func _on_undo_pressed() -> void:
	if game_controller != null:
		game_controller.undo()


func _on_hint_pressed() -> void:
	if game_controller != null:
		game_controller.hint()


## API chuyển đổi chế độ chơi linh hoạt từ bên ngoài
func switch_mode(mode_name: String, difficulty := "medium") -> void:
	if game_mode_controller != null:
		game_mode_controller.set_mode_by_name(mode_name, difficulty)
		if game_controller != null:
			game_controller.start_new_run()
	elif game_controller != null:
		var new_mode: BaseGameMode = StandardGameMode.new(difficulty) if mode_name.to_lower() == "play" else DungeonGameMode.new()
		game_controller.set_game_mode(new_mode)
		game_controller.start_new_run()


func _on_win_replay_pressed() -> void:
	if popup_win != null:
		popup_win.visible = false
	if game_controller != null:
		game_controller.restart_run()


func _on_win_next_pressed() -> void:
	if popup_win != null:
		popup_win.visible = false

	var gm: Node = get_node_or_null("/root/GameManager")

	# Dungeon Mode: chuyển sang floor tiếp theo không cần GameManager
	if game_controller != null and game_mode_controller != null \
			and game_mode_controller.game_mode is DungeonGameMode:
		_on_continue_next_floor()
		return

	# Play Mode / Standard: báo cáo level clear rồi chuyển qua level kế tiếp
	if gm != null:
		var stars: int = 3
		if game_controller != null and game_controller.game_state != null:
			stars = 3 if game_controller.game_state.floor_wall_hits == 0 else 2
		var elapsed: float = game_controller.game_state.elapsed_time \
				if game_controller != null and game_controller.game_state != null else 10.0
		gm.call("record_level_clear", gm.get("current_level"), stars, elapsed)
		var next_lvl: int = int(gm.get("current_level")) + 1
		if next_lvl <= 9:
			gm.call("start_level", next_lvl)
		else:
			gm.call("go_to_levels")
	else:
		# Fallback không có GameManager: restart lại run
		if game_controller != null:
			game_controller.restart_run()


## Chuyển sang floor kế tiếp trong Dungeon Mode (không cần GameManager)
func _on_continue_next_floor() -> void:
	if game_controller == null or game_controller.game_state == null:
		return
	# Dùng lại _on_continue_requested bên trong GameController
	# (signal continue_requested → GameController._on_continue_requested)
	game_controller._on_continue_requested()


func _on_gameover_replay_pressed() -> void:
	if popup_gameover != null:
		popup_gameover.visible = false
	if game_controller != null:
		game_controller.restart_run()


func _on_menu_pressed() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null:
		gm.go_to_main_menu()
	else:
		get_tree().change_scene_to_file("res://scenes/main.tscn")
