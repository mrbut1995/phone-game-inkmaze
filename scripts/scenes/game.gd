class_name GameScene
extends BaseScene
## ============================================================================
## View Controller: Quản lý Scene chính của Game Screen (scenes/game.tscn).
## Khởi tạo và liên kết các Controller theo chuẩn MVC & Component.
## ============================================================================
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Node UI gắn lại mỗi lần ĐỔI HƯỚNG (2 layout giữ CÙNG đường dẫn node — các `@export NodePath`
## của Controllers vẫn trỏ đúng vì cấu trúc cây không đổi)
var board_view: Control = null
var pause_btn: BaseButton = null
var instruction_btn: BaseButton = null
var restart_btn: BaseButton = null
var level_label: Label = null
var subtitle_label: Label = null
## Khung chứa HUD của chế độ đang chơi (HUD được đổi bằng code — xem _apply_hud_for_mode)
var hud_host: Control = null

var tool_path_btn: NinePatchButton = null
var tool_wall_btn: NinePatchButton = null
var undo_btn: BaseButton = null
var hint_btn: BaseButton = null
## Nút CHƠI LẠI ẩn sẵn DƯỚI thanh nút — UIController hiện khi ván không còn thắng được nữa (Sum Path)
var replay_btn: BaseButton = null
## Panel HƯỚNG DẪN LUẬT CHƠI TÓM TẮT dưới bàn cờ (đổi nội dung theo chế độ)
var hint_guide: HintGuide = null
## Mã chế độ đang chơi (để ghi lại nhãn nút công cụ mỗi khi gắn lại HUD)
var _mode_id := "level"

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

## HUD theo chế độ chơi — mỗi chế độ có 2 scene HUD: bản DỌC (nodes/hud/<mode>.tscn, kế thừa
## portrait/portrait.tscn) và bản NGANG (nodes/hud/landscape/<mode>.tscn). Xem scripts/nodes/hud/base.gd
const HUD_LEVEL := preload("res://nodes/hud/level_mode.tscn")
const HUD_DUNGEON := preload("res://nodes/hud/dungeon_mode.tscn")
const HUD_MINESWEEP := preload("res://nodes/hud/minesweep_hud.tscn")
const HUD_SUM_PATH := preload("res://nodes/hud/sum_path_hud.tscn")
const HUD_BLIND_MEMORY := preload("res://nodes/hud/blind_memory_hud.tscn")
const HUD_COUNTDOWN := preload("res://nodes/hud/countdown_hud.tscn")
const HUD_FADING_INK := preload("res://nodes/hud/fading_ink_hud.tscn")
## Fog of War: THỜI GIAN + BẢNG SƯƠNG MÙ (lượt thử lại · tầm nhìn · cảnh báo) — không có thẻ Thử thách
const HUD_FOG_OF_WAR := preload("res://nodes/hud/fog_of_war_hud.tscn")
## One Stroke: THỜI GIAN + BẢNG TIẾN ĐỘ PHỦ KÍN (số ô đã đi · thanh tiến độ) — không có thẻ Thử thách
const HUD_ONE_STROKE := preload("res://nodes/hud/one_stroke_hud.tscn")
## Wall Builder: THỜI GIAN + BẢNG TƯỜNG ĐÃ VẼ (đoạn đã dựng · lượt gửi) — không có thẻ Thử thách
const HUD_WALL_BUILDER := preload("res://nodes/hud/wall_builder_hud.tscn")

## Bản NGANG của từng chế độ (thẻ nằm trên · action bar 2 hàng nằm dưới, trong cùng HUD)
const HUD_LAND_LEVEL := preload("res://nodes/hud/landscape/level_mode.tscn")
const HUD_LAND_DUNGEON := preload("res://nodes/hud/landscape/dungeon_mode.tscn")
const HUD_LAND_MINESWEEP := preload("res://nodes/hud/landscape/minesweep_hud.tscn")
const HUD_LAND_SUM_PATH := preload("res://nodes/hud/landscape/sum_path_hud.tscn")
const HUD_LAND_BLIND_MEMORY := preload("res://nodes/hud/landscape/blind_memory_hud.tscn")
const HUD_LAND_COUNTDOWN := preload("res://nodes/hud/landscape/countdown_hud.tscn")
const HUD_LAND_FADING_INK := preload("res://nodes/hud/landscape/fading_ink_hud.tscn")
const HUD_LAND_FOG_OF_WAR := preload("res://nodes/hud/landscape/fog_of_war_hud.tscn")
const HUD_LAND_ONE_STROKE := preload("res://nodes/hud/landscape/one_stroke_hud.tscn")
const HUD_LAND_WALL_BUILDER := preload("res://nodes/hud/landscape/wall_builder_hud.tscn")
#@export var game_mode : BaseGameMode
## HUD đang gắn thuộc bản NGANG hay bản DỌC (đổi hướng màn hình là phải đổi cả biến thể HUD)
var _hud_variant_landscape := false


## Gắn node UI của BỐ CỤC ĐANG HIỂN THỊ.
## Controllers + Board là DÙNG CHUNG: chúng nằm NGOÀI layout (scenes/game.tscn) nên chỉ tra 1 lần;
## mỗi bố cục chỉ khai UI riêng (thanh trạng thái · HUD · HintGuide · BoardSlot).
func _bind_refs() -> void:
	if game_controller == null:
		game_controller = get_node_or_null("Controllers/GameController") as GameController
	if grid_controller == null:
		grid_controller = get_node_or_null("Controllers/GridController") as GridController
	if anchor_controller == null:
		anchor_controller = get_node_or_null("Controllers/AnchorController") as AnchorController
	if floor_controller == null:
		floor_controller = get_node_or_null("Controllers/FloorController") as FloorController
	if timer_controller == null:
		timer_controller = get_node_or_null("Controllers/TimerController") as TimerController
	if ui_controller == null:
		ui_controller = get_node_or_null("Controllers/UIController") as UIController
	if tool_controller == null:
		tool_controller = get_node_or_null("Controllers/ToolController") as ToolController
	if undo_controller == null:
		undo_controller = get_node_or_null("Controllers/UndoController") as UndoController
	if hint_controller == null:
		hint_controller = get_node_or_null("Controllers/HintController") as HintController
	if game_mode_controller == null:
		game_mode_controller = get_node_or_null("Controllers/GameModeController") as GameModeController
	if challenge_controller == null:
		challenge_controller = get_node_or_null("Controllers/ChallengeController") as ChallengeController
	if board_view == null:
		board_view = get_node_or_null("Board") as Control
	# UI của bố cục đang hiển thị (Portrait/Landscape là 2 instance riêng)
	pause_btn = ui("Pause") as BaseButton
	instruction_btn = ui("Instruction") as BaseButton
	restart_btn = ui("Restart") as BaseButton
	level_label = ui_child("Title", "LevelLabel") as Label
	subtitle_label = ui_child("Title", "Subtitle") as Label
	hud_host = ui("Information") as Control
	hint_guide = ui("HintGuide") as HintGuide
	# Bàn cờ + nhãn Status là node RIÊNG của bố cục ⇒ gắn lại vào bộ controller dùng chung
	if board_view != null:
		if game_controller != null:
			game_controller.grid_view = board_view
		if grid_controller != null:
			grid_controller.board_view = board_view
	if ui_controller != null:
		ui_controller.level_label = level_label
		ui_controller.subtitle_label = subtitle_label
	_wire_controllers()
	_mount_board()


## ============================================================================
## NỐI DÂY GIỮA CONTROLLER VÀ VIEW
## Trước đây các dây này khai bằng `[connection]` trong `scenes/orientation/*/game.tscn`,
## nhưng khi tách layout / dọn node thì phần `[connection]` bị mất ⇒ bàn cờ kéo không đi được,
## nút bấm không ăn. Nối lại bằng code (có guard `is_connected` nên gọi lại nhiều lần vẫn an toàn).
## LƯU Ý: mỗi layout có BỘ controller riêng ⇒ phải gọi lại mỗi lần `_bind_refs()` (đổi hướng màn hình).
## ============================================================================
func _wire_controllers() -> void:
	# Bàn cờ → GridController
	_connect_once(board_view, "cell_pressed", grid_controller, "handle_cell_pressed")
	_connect_once(board_view, "drag_updated", grid_controller, "handle_drag_updated")
	_connect_once(board_view, "anchor_connected", grid_controller, "handle_anchor_connected")
	# GridController → GameController (đếm bước · đâm tường · tới đích · hết đường)
	_connect_once(grid_controller, "step_consumed", game_controller, "_on_step_consumed")
	_connect_once(grid_controller, "wall_hit", game_controller, "_on_wall_hit")
	_connect_once(grid_controller, "reached_end", game_controller, "_on_reached_end")
	_connect_once(grid_controller, "dead_end", game_controller, "_on_dead_end")
	# Đồng hồ → GameController
	_connect_once(timer_controller, "time_updated", game_controller, "_on_time_updated")
	_connect_once(timer_controller, "timeout", game_controller, "_on_timer_timeout")
	# Popup/HUD → GameController
	_connect_once(ui_controller, "continue_requested", game_controller, "_on_continue_requested")
	_connect_once(ui_controller, "retry_requested", game_controller, "_on_retry_requested")
	_connect_once(ui_controller, "revive_requested", game_controller, "_on_revive_requested")
	_connect_once(ui_controller, "home_requested", game_controller, "_on_home_requested")
	_connect_once(ui_controller, "daily_requested", game_controller, "_on_daily_requested")
	_connect_once(ui_controller, "pause_toggled", game_controller, "_on_pause_toggled")
	_connect_once(ui_controller, "memorize_finished", game_controller, "_on_memorize_finished")
	# Nút trên thanh Status
	if pause_btn != null and not pause_btn.has_meta("wired"):
		pause_btn.set_meta("wired", true)
		pause_btn.pressed.connect(_on_pause_pressed)
	if restart_btn != null and not restart_btn.has_meta("wired"):
		restart_btn.set_meta("wired", true)
		restart_btn.pressed.connect(_on_restart_pressed)
	if instruction_btn != null and game_controller != null and not instruction_btn.has_meta("wired"):
		instruction_btn.set_meta("wired", true)
		instruction_btn.pressed.connect(game_controller.open_instruction)


## Nối `source.signal_name` → `target.method` đúng 1 lần (bỏ qua nếu thiếu node/tín hiệu)
func _connect_once(source: Object, signal_name: String, target: Object, method: String) -> void:
	if source == null or target == null or not source.has_signal(signal_name):
		return
	if not target.has_method(method):
		return
	var cb := Callable(target, method)
	if not source.is_connected(signal_name, cb):
		source.connect(signal_name, cb)


## Xoay màn hình: chuyển bàn cờ sang `BoardSlot` của bố cục mới rồi gắn lại HUD + thanh nút.
## Controllers + Board DÙNG CHUNG (ngoài layout) nên ván đang chơi KHÔNG bị mất khi xoay.
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	for btn in [pause_btn, instruction_btn, restart_btn, tool_path_btn, tool_wall_btn, undo_btn, hint_btn, replay_btn]:
		if btn != null and not btn.has_meta("bounce_attached"):
			btn.set_meta("bounce_attached", true)
			UIAnim.attach_press_bounce(btn)
	# HUD (và thanh nút bên trong nó) là instance RIÊNG của mỗi bố cục ⇒ đổi cả BIẾN THỂ HUD
	# (dọc ↔ ngang) rồi gắn lại nút từ HUD mới
	_apply_hud_for_mode(_mode_id)


## Gắn bàn cờ (instance DÙNG CHUNG) vào chỗ mà BỐ CỤC ĐANG HIỂN THỊ dành cho nó. Việc đổi chỗ +
## chốt lại bố cục bên trong do CHÍNH SCRIPT BỐ CỤC làm (`scripts/orientation/<hướng>/game.gd`).
func _mount_board() -> void:
	if board_view == null:
		return
	_layout_call("mount_board", [board_view])


## Gọi hàm của SCRIPT BỐ CỤC đang hiển thị — mỗi hướng tự lo phần khác biệt của mình
## (gắn bàn cờ · cỡ HUD · nút công cụ · chọn biến thể HUD: xem scripts/orientation/*/game.gd).
func _layout_call(method: String, args: Array = []) -> Variant:
	var holder: Node = active_layout()
	if holder == null or not holder.has_method(method):
		return null
	return holder.callv(method, args)


## Bố cục đang hiển thị có phải bản NGANG không (do chính script bố cục trả lời)
func _layout_is_landscape() -> bool:
	var answer: Variant = _layout_call("is_landscape_layout")
	return bool(answer) if answer != null else is_landscape


## Chọn biến thể HUD (dọc/ngang) theo bố cục đang hiển thị
func _hud_variant(portrait_scene: PackedScene, landscape_scene: PackedScene) -> PackedScene:
	var picked: Variant = _layout_call("hud_variant", [portrait_scene, landscape_scene])
	return picked as PackedScene if picked != null else portrait_scene


## Cỡ HUD do BỐ CỤC quyết định — dọc giữ nguyên 980 thiết kế, ngang co theo bề rộng sidebar
## (xem `scripts/orientation/<hướng>/game.gd::fit_hud`).
func _fit_hud_scale() -> void:
	var hud := hud_host as Control
	if hud == null:
		return
	_layout_call("fit_hud", [hud])


func _ready() -> void:
	_bind_refs()
	orientation_changed.connect(_on_orientation_changed)
	resized.connect(_fit_hud_scale)
	# Gắn hiệu ứng nảy xúc giác cho các nút trong Game Screen
	for btn in [pause_btn, instruction_btn, restart_btn, tool_path_btn, tool_wall_btn, undo_btn, hint_btn, replay_btn]:
		if btn != null:
			UIAnim.attach_press_bounce(btn)

	var status_bar := ui("Status") as Control
	if status_bar != null:
		UIAnim.play_slide_in(status_bar, Vector2(0, -25), 0.0, 0.25)
	var info_bar := ui("Information") as Control
	if info_bar != null:
		UIAnim.play_slide_in(info_bar, Vector2(0, -15), 0.04, 0.25)
	var button_bar := tool_path_btn.get_parent() as Control if tool_path_btn != null else null
	if button_bar != null:
		UIAnim.play_slide_in(button_bar, Vector2(0, 30), 0.08, 0.25)

	# Wall Builder: nút thứ 2 trên thanh công cụ được đổi công dụng thành GỬI BÀI
	if tool_wall_btn != null and not tool_wall_btn.pressed.is_connected(_on_secondary_tool_pressed):
		tool_wall_btn.pressed.connect(_on_secondary_tool_pressed)

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


## Nút công cụ thứ 2: bình thường là GHI NHỚ, riêng Wall Builder là GỬI BÀI
func _on_secondary_tool_pressed() -> void:
	var mode: BaseGameMode = null
	if game_mode_controller != null:
		mode = game_mode_controller.game_mode
	if mode != null and mode.mode_id == "wall_builder" and game_controller != null:
		game_controller.submit_build()


## API chuyển đổi chế độ chơi linh hoạt từ bên ngoài
func switch_mode(mode_name: String, difficulty := "medium") -> void:
	_mode_id = mode_name
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
## Scene HUD ứng với từng chế độ — biến thể (dọc/ngang) do BỐ CỤC quyết định qua `hud_variant()`
## (xem nodes/hud/*.tscn + nodes/hud/landscape/*.tscn + scripts/orientation/*/game.gd)
func _hud_scene_for(mode_name: String) -> PackedScene:
	match mode_name.to_lower():
		"dungeon":
			return _hud_variant(HUD_DUNGEON, HUD_LAND_DUNGEON)
		"daily_classic":
			return _hud_variant(HUD_LEVEL, HUD_LAND_LEVEL)
		"minesweeper":
			return _hud_variant(HUD_MINESWEEP, HUD_LAND_MINESWEEP)
		"sum_path":
			return _hud_variant(HUD_SUM_PATH, HUD_LAND_SUM_PATH)
		"blind_memory":
			return _hud_variant(HUD_BLIND_MEMORY, HUD_LAND_BLIND_MEMORY)
		"countdown_cost":
			return _hud_variant(HUD_COUNTDOWN, HUD_LAND_COUNTDOWN)
		"fading_ink":
			return _hud_variant(HUD_FADING_INK, HUD_LAND_FADING_INK)
		"fog_of_war":
			return _hud_variant(HUD_FOG_OF_WAR, HUD_LAND_FOG_OF_WAR)
		"one_stroke":
			return _hud_variant(HUD_ONE_STROKE, HUD_LAND_ONE_STROKE)
		"wall_builder":
			return _hud_variant(HUD_WALL_BUILDER, HUD_LAND_WALL_BUILDER)
		_:
			return _hud_variant(HUD_LEVEL, HUD_LAND_LEVEL)


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
		"fog_of_war":
			return FogOfWarHUD
		"one_stroke":
			return OneStrokeHUD
		"wall_builder":
			return WallBuilderHUD
		_:
			return LevelHUD


## Nhãn PHỤ của 2 nút công cụ theo CHẾ ĐỘ (mockup matchup_<mode>.svg — vd Fog of War: "Dò trong sương" · "Cắm cờ mép ô")
const TOOL_SUB_KEYS := {
	"fog_of_war": ["STR_TOOL_DRAW_PATH_FOG", "STR_TOOL_MARK_WALL_FOG"],
	"one_stroke": ["STR_TOOL_DRAW_PATH_STROKE", "STR_TOOL_MARK_WALL_STROKE"],
}
const TOOL_SUB_DEFAULT := ["STR_TOOL_DRAW_PATH_DESC", "STR_TOOL_MARK_WALL_DESC"]
const TOOL_TITLE_DEFAULT := ["STR_TOOL_DRAW_PATH", "STR_TOOL_MARK_WALL"]
## Chế độ đổi HẲN công dụng 2 nút công cụ (Wall Builder: VẼ TƯỜNG + GỬI BÀI)
const TOOL_FULL_KEYS := {
	"wall_builder": [
		["STR_TOOL_DRAW_WALL", "STR_TOOL_DRAW_WALL_DESC"],
		["STR_TOOL_SUBMIT", "STR_TOOL_SUBMIT_DESC"],
	],
}
const TOOL_TEX_STROKE_PATH := preload("res://assets/images/game/btn_tool_path_stroke_active.svg")
const TOOL_TEX_SUBMIT := preload("res://assets/images/game/btn_tool_submit_normal.svg")
const TOOL_TEX_SUBMIT_PRESSED := preload("res://assets/images/game/btn_tool_submit_pressed.svg")
const TOOL_LAND_PATH_ACTIVE := preload("res://assets/images-landscape/game/btn_tool_path_hero_active.svg")
const TOOL_LAND_PATH_INACTIVE := preload("res://assets/images-landscape/game/btn_tool_path_hero_inactive.svg")
const TOOL_LAND_PATH_PRESSED := preload("res://assets/images-landscape/game/btn_tool_path_hero_pressed.svg")
const TOOL_LAND_WALL_NORMAL := preload("res://assets/images-landscape/game/btn_tool_wall_land_normal.svg")
const TOOL_LAND_WALL_PRESSED := preload("res://assets/images-landscape/game/btn_tool_wall_land_pressed.svg")
## Chế độ ẩn hẳn nút GHI NHỚ (tường hiện rõ 100% nên không cần đánh dấu) — mockup
## matchup_one_stroke.svg: "ẨN NÚT GHI NHỚ THEO §5.12", thanh công cụ chỉ còn VẼ ĐƯỜNG ĐI + UNDO + GỢI Ý.
const TOOL_HIDE_WALL_MODES := ["one_stroke"]


## Đổi nhãn 2 nút công cụ cho khớp chế độ đang chơi (VẼ ĐƯỜNG/GHI NHỚ ↔ VẼ TƯỜNG/GỬI BÀI)
func _apply_tool_labels_for_mode(mode_name: String) -> void:
	var id := mode_name.to_lower()
	# Nút nằm trong HUD (action_bar) ⇒ chỉ ghi nhãn khi HUD đã gắn xong
	if tool_path_btn == null or tool_wall_btn == null:
		return
	var full: Array = TOOL_FULL_KEYS.get(id, [])
	if not full.is_empty():
		var path_keys: Array = full[0]
		var wall_keys: Array = full[1]
		_set_tool_label(tool_path_btn, str(path_keys[0]), str(path_keys[1]))
		_set_tool_label(tool_wall_btn, str(wall_keys[0]), str(wall_keys[1]))
	else:
		var subs: Array = TOOL_SUB_KEYS.get(id, TOOL_SUB_DEFAULT)
		_set_tool_label(tool_path_btn, TOOL_TITLE_DEFAULT[0], str(subs[0]))
		_set_tool_label(tool_wall_btn, TOOL_TITLE_DEFAULT[1], str(subs[1]))
	# Ẩn nút GHI NHỚ ở chế độ không có tường ẩn (One Stroke). Nút VẼ ĐƯỜNG ĐI giữ
	# nguyên kích thước gốc (SHRINK) để icon không bị kéo giãn theo bề ngang còn lại.
	var hide_wall: bool = TOOL_HIDE_WALL_MODES.has(id)
	tool_wall_btn.visible = not hide_wall
	# Mỗi bố cục tự quyết định (dọc: ghim nút VẼ ĐƯỜNG khi ẩn nút GHI NHỚ · ngang: action_bar tự dàn)
	_layout_call("configure_tool_path_button", [tool_path_btn, hide_wall])
	_apply_tool_textures_for_mode(id)


## Art 2 nút công cụ theo chế độ (mockup): One Stroke có nút VẼ ĐƯỜNG ĐI bè ngang 680px,
## Wall Builder có nút GỬI BÀI xanh ở vị trí nút GHI NHỚ.
func _apply_tool_textures_for_mode(mode_id: String) -> void:
	if tool_controller == null:
		return
	if _layout_is_landscape():
		match mode_id:
			"one_stroke":
				tool_controller.set_mode_textures(TOOL_LAND_PATH_ACTIVE, TOOL_LAND_PATH_PRESSED,
					TOOL_LAND_PATH_ACTIVE, null, null, null)
			"wall_builder":
				tool_controller.set_mode_textures(TOOL_LAND_PATH_ACTIVE, TOOL_LAND_PATH_PRESSED,
					TOOL_LAND_PATH_INACTIVE, TOOL_TEX_SUBMIT, TOOL_TEX_SUBMIT_PRESSED, TOOL_TEX_SUBMIT)
			_:
				tool_controller.set_mode_textures(TOOL_LAND_PATH_ACTIVE, TOOL_LAND_PATH_PRESSED,
					TOOL_LAND_PATH_INACTIVE, TOOL_LAND_WALL_NORMAL, TOOL_LAND_WALL_PRESSED, TOOL_LAND_WALL_NORMAL)
		return
	match mode_id:
		"one_stroke":
			tool_controller.set_mode_textures(TOOL_TEX_STROKE_PATH, TOOL_TEX_STROKE_PATH,
				TOOL_TEX_STROKE_PATH, null, null, null)
		"wall_builder":
			tool_controller.set_mode_textures(null, null, null,
				TOOL_TEX_SUBMIT, TOOL_TEX_SUBMIT_PRESSED, TOOL_TEX_SUBMIT)
		_:
			tool_controller.set_mode_textures(null, null, null, null, null, null)


func _set_tool_label(btn: NinePatchButton, title_key: String, sub_key: String) -> void:
	if btn == null:
		return
	var title := btn.get_node_or_null("Label") as Label
	if title != null:
		title.text = title_key
	var sub := btn.get_node_or_null("Sub") as Label
	if sub != null:
		sub.text = sub_key


## Thay khung Information bằng HUD của chế độ đang chơi rồi gắn lại cho UIController /
## ChallengeController (thẻ Thử thách nằm trong HUD nên phải trỏ lại node mới).
func _apply_hud_for_mode(mode_name: String) -> void:
	_mode_id = mode_name
	if hud_host == null or not is_inside_tree():
		return
	# Đủ chỗ khi HUD hiện tại ĐÚNG chế độ VÀ đúng biến thể (bản dọc ↔ bản ngang)
	if hud_host.get_script() == _hud_class_for(mode_name) \
			and _hud_variant_landscape == _layout_is_landscape():
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
	# HUD scene chỉ khai khung theo thiết kế (bản dọc 980×249 ở mốc (50,175) — bản ngang là khung
	# trong sidebar do layout dàn) ⇒ chép khung của HUD cũ sang HUD mới, nếu không HUD sẽ nhảy
	# về góc trái canvas.
	_copy_layout_from(old_hud, new_hud)
	_hud_variant_landscape = _layout_is_landscape()
	old_hud.queue_free()
	hud_host = new_hud
	UIAnim.play_slide_in(new_hud, Vector2(0, -15), 0.0, 0.25)
	_bind_hud_nodes()


## Chép anchors/offsets từ node này sang node kia (giữ HUD đúng khung mà layout quy định)
func _copy_layout_from(src: Control, dst: Control) -> void:
	if src == null or dst == null:
		return
	dst.anchor_left = src.anchor_left
	dst.anchor_top = src.anchor_top
	dst.anchor_right = src.anchor_right
	dst.anchor_bottom = src.anchor_bottom
	dst.offset_left = src.offset_left
	dst.offset_top = src.offset_top
	dst.offset_right = src.offset_right
	dst.offset_bottom = src.offset_bottom
	dst.grow_horizontal = src.grow_horizontal
	dst.grow_vertical = src.grow_vertical
	dst.size_flags_horizontal = src.size_flags_horizontal
	dst.size_flags_vertical = src.size_flags_vertical
	dst.custom_minimum_size = src.custom_minimum_size


## Gắn HUD hiện tại cho UIController (vẽ nội dung) và ChallengeController (thẻ Thử thách).
## Đồng thời lấy thanh nút hành động NẰM TRONG HUD (phương án A) rồi nối lại tín hiệu — nhờ vậy
## mỗi HUD/chế độ tự bày nút theo bố cục dọc-ngang của mình, màn chơi không giữ nút nào.
func _bind_hud_nodes() -> void:
	var hud := hud_host as BaseHUD
	if hud == null:
		return
	tool_path_btn = hud.tool_path_btn()
	tool_wall_btn = hud.tool_wall_btn()
	undo_btn = hud.undo_btn()
	hint_btn = hud.hint_btn()
	replay_btn = hud.replay_btn()
	_wire_action_bar()
	_apply_tool_labels_for_mode(_mode_id)
	hud.set_landscape(_layout_is_landscape())
	if ui_controller != null:
		ui_controller.set_hud(hud)
	if challenge_controller != null:
		challenge_controller.card = hud.challenge_card()
	hint_guide = ui("HintGuide") as HintGuide
	_refresh_hint_guide()
	_fit_hud_scale.call_deferred()


## Nối tín hiệu cho các nút của thanh hành động (thay cho [connection] trong game.tscn)
func _wire_action_bar() -> void:
	for btn in [pause_btn, instruction_btn, restart_btn, tool_path_btn, tool_wall_btn, undo_btn, hint_btn, replay_btn]:
		if btn != null and not btn.has_meta("bounce_attached"):
			btn.set_meta("bounce_attached", true)
			UIAnim.attach_press_bounce(btn)
	if tool_controller != null:
		var ctrl := tool_controller
		if tool_path_btn != null and not tool_path_btn.pressed.is_connected(ctrl._on_tool_pressed):
			tool_path_btn.pressed.connect(ctrl._on_tool_pressed.bind("path"))
		if tool_wall_btn != null and not tool_wall_btn.pressed.is_connected(ctrl._on_wall_pressed):
			tool_wall_btn.pressed.connect(ctrl._on_wall_pressed.bind("wall"))
		ctrl.tool_path_btn = tool_path_btn
		ctrl.tool_wall_btn = tool_wall_btn
	if game_controller != null:
		if undo_btn != null and not undo_btn.pressed.is_connected(game_controller.undo):
			undo_btn.pressed.connect(game_controller.undo)
		if hint_btn != null and not hint_btn.pressed.is_connected(game_controller.hint):
			hint_btn.pressed.connect(game_controller.hint)
		if replay_btn != null and not replay_btn.pressed.is_connected(game_controller.restart_run):
			replay_btn.pressed.connect(game_controller.restart_run)
	if ui_controller != null:
		ui_controller.undo_button = undo_btn
		ui_controller.replay_button = replay_btn
