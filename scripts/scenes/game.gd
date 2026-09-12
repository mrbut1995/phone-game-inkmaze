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

var game_controller: GameController = null
var grid_controller: GridController = null
var anchor_controller: AnchorController = null
var floor_controller: FloorController = null
var timer_controller: TimerController = null
var ui_controller: UIController = null
var tool_controller: ToolController = null
var undo_controller: UndoController = null
var hint_controller: HintController = null

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
	anchor_controller = AnchorController.new()
	undo_controller = UndoController.new()
	hint_controller = HintController.new()

	var default_mode: BaseGameMode = DungeonGameMode.new()
	grid_controller = GridController.new(
		board_view,
		anchor_controller,
		default_mode,
		undo_controller,
		hint_controller
	)

	floor_controller = FloorController.new()
	timer_controller = TimerController.new()

	ui_controller = UIController.new()
	ui_controller.setup(
		level_label,
		step_val,
		step_max,
		time_val,
		score_val,
		popup_win,
		popup_gameover,
		popup_settings
	)

	tool_controller = ToolController.new()
	tool_controller.setup(tool_path_btn, tool_wall_btn)

	# Master GameController
	game_controller = GameController.new()
	add_child(game_controller)
	game_controller.setup(
		grid_controller,
		board_view,
		ui_controller,
		floor_controller,
		timer_controller,
		tool_controller,
		default_mode
	)

	# Kết nối signal từ BoardView sang GridController
	if board_view != null:
		board_view.connect("cell_pressed", Callable(grid_controller, "handle_cell_pressed"))
		board_view.connect("drag_updated", Callable(grid_controller, "handle_drag_updated"))
		board_view.connect("anchor_connected", Callable(grid_controller, "handle_anchor_connected"))


func _bind_buttons() -> void:
	if restart_btn != null:
		restart_btn.pressed.connect(_on_restart_pressed)
	if pause_btn != null:
		pause_btn.pressed.connect(_on_pause_pressed)
	if undo_btn != null:
		undo_btn.pressed.connect(_on_undo_pressed)
	if hint_btn != null:
		hint_btn.pressed.connect(_on_hint_pressed)


func _on_restart_pressed() -> void:
	if game_controller != null:
		game_controller.restart_run()


func _on_pause_pressed() -> void:
	if popup_settings != null:
		popup_settings.visible = not popup_settings.visible
		if timer_controller != null:
			if popup_settings.visible:
				timer_controller.pause()
			else:
				timer_controller.resume()


func _on_undo_pressed() -> void:
	if game_controller != null:
		game_controller.undo()


func _on_hint_pressed() -> void:
	if game_controller != null:
		game_controller.hint()


## API chuyển đổi chế độ chơi linh hoạt từ bên ngoài
func switch_mode(mode_name: String, difficulty := "medium") -> void:
	var new_mode: BaseGameMode = null
	match mode_name.to_lower():
		"play", "classic", "standard":
			new_mode = StandardGameMode.new(difficulty)
		"dungeon":
			new_mode = DungeonGameMode.new()
		"time_attack":
			new_mode = TimeAttackGameMode.new(difficulty)
		"minesweeper":
			new_mode = MinesweeperPathGameMode.new()
		"sum_path":
			new_mode = SumPathGameMode.new(difficulty)
		"countdown_cost":
			new_mode = CountdownCostGameMode.new(difficulty)
		"blind_memory":
			new_mode = BlindMemoryGameMode.new(difficulty)
		"fog_of_war":
			new_mode = FogOfWarGameMode.new(difficulty)
		"area":
			new_mode = AreaGameMode.new()
		_:
			new_mode = DungeonGameMode.new()

	if game_controller != null:
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
	if game_controller != null and game_controller.game_mode is DungeonGameMode:
		game_controller.next_floor()
	else:
		if gm != null:
			var stars: int = 3
			if game_controller != null and game_controller.game_state != null:
				stars = 3 if game_controller.game_state.wall_hits == 0 else 2
			var elapsed: float = game_controller.game_state.elapsed_time if game_controller != null and game_controller.game_state != null else 10.0
			gm.record_level_clear(gm.current_level, stars, elapsed)
			if gm.current_level < 9:
				gm.start_level(gm.current_level + 1)
			else:
				gm.go_to_levels()
		else:
			if game_controller != null:
				game_controller.restart_run()


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
