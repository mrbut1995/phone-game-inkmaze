class_name GameScene
extends BaseScene
## ============================================================================
## View Controller: Quản lý Scene chính của Game Screen (scenes/game.tscn).
## Khởi tạo và liên kết các Controller theo chuẩn MVC & Component.
## ============================================================================
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

@onready var board_view: Control = $Board
@onready var pause_btn: TextureButton = $Status/Pause
@onready var restart_btn: TextureButton = $Status/Restart
@onready var level_label: Label = $Status/Title/LevelLabel
@onready var subtitle_label: Label = $Status/Title/Subtitle
## Khung chứa HUD của chế độ đang chơi (HUD được đổi bằng code — xem _apply_hud_for_mode)
@onready var hud_host: Control = $Information

@onready var tool_path_btn: TextureButton = $Button/Tool
@onready var tool_wall_btn: TextureButton = $Button/Wall
@onready var undo_btn: TextureButton = $Button/Undo
@onready var hint_btn: TextureButton = $Button/Hint
## Panel HƯỚNG DẪN LUẬT CHƠI TÓM TẮT dưới bàn cờ (đổi nội dung theo chế độ)
@onready var hint_guide: HintGuide = $HintGuide

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
@export var challenge_controller : ChallengeController = null

## HUD theo chế độ chơi — mỗi chế độ 1 scene HUD riêng, GameScene tự đổi (xem scripts/nodes/hud/base.gd)
const HUD_LEVEL := preload("res://nodes/hud/level_mode.tscn")
const HUD_DUNGEON := preload("res://nodes/hud/dungeon_mode.tscn")
const HUD_MINESWEEP := preload("res://nodes/hud/minesweep_hud.tscn")
const HUD_SUM_PATH := preload("res://nodes/hud/sum_path_hud.tscn")
const HUD_BLIND_MEMORY := preload("res://nodes/hud/blind_memory_hud.tscn")
const HUD_COUNTDOWN := preload("res://nodes/hud/countdown_hud.tscn")
const HUD_FADING_INK := preload("res://nodes/hud/fading_ink_hud.tscn")

#@export var game_mode : BaseGameMode


func _ready() -> void:
	# Gắn hiệu ứng nảy xúc giác cho các nút trong Game Screen
	for btn in [pause_btn, restart_btn, tool_path_btn, tool_wall_btn, undo_btn, hint_btn]:
		if btn != null:
			UIAnim.attach_press_bounce(btn)

	var status_bar := get_node_or_null("Status") as Control
	if status_bar != null:
		UIAnim.play_slide_in(status_bar, Vector2(0, -25), 0.0, 0.25)
	var info_bar := get_node_or_null("Information") as Control
	if info_bar != null:
		UIAnim.play_slide_in(info_bar, Vector2(0, -15), 0.04, 0.25)
	var button_bar := get_node_or_null("Button") as Control
	if button_bar != null:
		UIAnim.play_slide_in(button_bar, Vector2(0, 30), 0.08, 0.25)

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
	# Đổi khung HUD (Information) cho đúng chế độ trước khi ván mới bắt đầu
	_apply_hud_for_mode(mode_name)
	if game_mode_controller != null:
		game_mode_controller.set_mode_by_name(mode_name, difficulty)
		_refresh_hint_guide()
		if game_controller != null:
			game_controller.start_new_run(_start_floor_for(mode_name))
	elif game_controller != null:
		var new_mode: BaseGameMode = StandardGameMode.new(difficulty) if mode_name.to_lower() == "play" else DungeonGameMode.new()
		game_controller.set_game_mode(new_mode)
		_refresh_hint_guide()
		game_controller.start_new_run(_start_floor_for(mode_name))


## Panel gợi ý luật chơi dưới bàn cờ: đổi nội dung theo chế độ vừa chọn
func _refresh_hint_guide() -> void:
	if hint_guide == null:
		return
	var mode: BaseGameMode = null
	if game_mode_controller != null:
		mode = game_mode_controller.game_mode
	elif game_controller != null:
		mode = game_controller.game_mode
	hint_guide.show_mode(mode)


## Màn/tầng xuất phát của ván mới.
## Play (Classic) luôn vào đúng màn đang chọn trong GameManager, các mode khác bắt đầu từ 1
## (trừ khi Debug Console ép tầng bắt đầu qua `start_floor_override`).
func _start_floor_for(mode_name: String) -> int:
	match mode_name.to_lower():
		"play", "classic", "standard":
			var gm: Node = get_node_or_null("/root/GameManager")
			if gm != null:
				return maxi(int(gm.get("current_level")), 1)
			return 1
		"daily_classic":
			# Maze thường của Daily luôn bắt đầu ở tầng 1 (mê cung sinh tại chỗ)
			return 1
		_:
			var debug_gm: Node = get_node_or_null("/root/GameManager")
			if debug_gm != null:
				var override := int(debug_gm.get("start_floor_override"))
				if override > 0:
					return override
			return 1


# ---------------------------------------------------------------------------
# HUD theo chế độ chơi
# ---------------------------------------------------------------------------
## Scene HUD ứng với từng chế độ (xem nodes/hud/*.tscn + scripts/nodes/hud/*.gd)
func _hud_scene_for(mode_name: String) -> PackedScene:
	match mode_name.to_lower():
		"dungeon":
			return HUD_DUNGEON
		"daily_classic":
			return HUD_LEVEL
		"minesweeper":
			return HUD_MINESWEEP
		"sum_path":
			return HUD_SUM_PATH
		"blind_memory":
			return HUD_BLIND_MEMORY
		"countdown_cost":
			return HUD_COUNTDOWN
		"fading_ink":
			return HUD_FADING_INK
		_:
			return HUD_LEVEL


func _hud_class_for(mode_name: String) -> GDScript:
	match mode_name.to_lower():
		"dungeon":
			return DungeonHUD
		"daily_classic":
			return LevelHUD
		"minesweeper":
			return MinesweepHUD
		"sum_path":
			return SumPathHUD
		"blind_memory":
			return BlindMemoryHUD
		"countdown_cost":
			return CountdownHUD
		"fading_ink":
			return FadingInkHUD
		_:
			return LevelHUD


## Thay khung Information bằng HUD của chế độ đang chơi rồi gắn lại cho UIController /
## ChallengeController (thẻ Thử thách nằm trong HUD nên phải trỏ lại node mới).
func _apply_hud_for_mode(mode_name: String) -> void:
	if hud_host == null or not is_inside_tree():
		return
	if hud_host.get_script() == _hud_class_for(mode_name):
		_bind_hud_nodes()
		return
	var scene := _hud_scene_for(mode_name)
	if scene == null:
		return
	var parent := hud_host.get_parent()
	if parent == null:
		return
	var old_hud := hud_host
	var new_hud := scene.instantiate() as BaseHUD
	if new_hud == null:
		return
	parent.add_child(new_hud)
	parent.move_child(new_hud, old_hud.get_index())
	old_hud.queue_free()
	hud_host = new_hud
	# Khung (50,175)-(1030,424) đã được định nghĩa sẵn trong nodes/hud/base.tscn
	UIAnim.play_slide_in(new_hud, Vector2(0, -15), 0.0, 0.25)
	_bind_hud_nodes()


## Gắn HUD hiện tại cho UIController (vẽ nội dung) và ChallengeController (thẻ Thử thách).
func _bind_hud_nodes() -> void:
	var hud := hud_host as BaseHUD
	if hud == null:
		return
	if ui_controller != null:
		ui_controller.set_hud(hud)
	if challenge_controller != null:
		challenge_controller.card = hud.challenge_card()
