class_name GameScene
extends BaseScene
## ============================================================================
## View Controller: Quản lý Scene chính của Game Screen (scenes/game.tscn).
## Khởi tạo và liên kết các Controller theo chuẩn MVC & Component.
## ============================================================================
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Bố cục đang hiển thị (Portrait / Landscape). Node UI của màn chơi (nút thanh trạng thái ·
## nhãn Tên màn/Phụ đề · khung HUD · BoardSlot) đã BIND SẴN bằng `@export` trong
## `scenes/layout/<hướng>/game.tscn` ⇒ code đọc `layout.<tên>`, KHÔNG tra đường dẫn.
var layout: GameSceneLayout = null
## Bàn cờ — node DÙNG CHUNG nằm NGOÀI layout (trong `scenes/game.tscn`)
var board_view: Control = null
## Khung chứa HUD của chế độ đang chơi: ban đầu = `layout.hud_slot`, thay bằng code khi đổi chế độ
## hoặc đổi hướng màn hình (xem `_apply_hud_for_mode`)
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

## HUD theo chế độ chơi — mỗi chế độ có 1 scene HUD DỌC (nodes/hud/portrait/game/<mode>.tscn,
## kế thừa portrait/portrait.tscn). Xem scripts/nodes/hud/base.gd
const HUD_LEVEL := preload("res://nodes/hud/portrait/game/level_mode.tscn")
const HUD_DUNGEON := preload("res://nodes/hud/portrait/game/dungeon_mode.tscn")
const HUD_MINESWEEP := preload("res://nodes/hud/portrait/game/minesweep_hud.tscn")
const HUD_SUM_PATH := preload("res://nodes/hud/portrait/game/sum_path_hud.tscn")
const HUD_BLIND_MEMORY := preload("res://nodes/hud/portrait/game/blind_memory_hud.tscn")
const HUD_COUNTDOWN := preload("res://nodes/hud/portrait/game/countdown_hud.tscn")
const HUD_FADING_INK := preload("res://nodes/hud/portrait/game/fading_ink_hud.tscn")
## Fog of War: THỜI GIAN + BẢNG SƯƠNG MÙ (lượt thử lại · tầm nhìn · cảnh báo) — không có thẻ Thử thách
const HUD_FOG_OF_WAR := preload("res://nodes/hud/portrait/game/fog_of_war_hud.tscn")
## One Stroke: THỜI GIAN + BẢNG TIẾN ĐỘ PHỦ KÍN (số ô đã đi · thanh tiến độ) — không có thẻ Thử thách
const HUD_ONE_STROKE := preload("res://nodes/hud/portrait/game/one_stroke_hud.tscn")
## Wall Builder: THỜI GIAN + BẢNG TƯỜNG ĐÃ VẼ (đoạn đã dựng · lượt gửi) — không có thẻ Thử thách
const HUD_WALL_BUILDER := preload("res://nodes/hud/portrait/game/wall_builder_hud.tscn")

#@export var game_mode : BaseGameMode


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
	# UI của bố cục đang hiển thị — đã BIND SẴN trong scenes/layout/<hướng>/game.tscn
	layout = active_layout() as GameSceneLayout
	if layout == null:
		push_warning("GameScene: bố cục chưa gắn GameSceneLayout — thiếu binding trong scenes/layout/<hướng>/game.tscn")
	# HUD hiện tại là instance do code tạo (đổi theo chế độ/biến thể) ⇒ GIỮ NGUYÊN nếu còn hợp lệ.
	# Chỉ khi chưa có (hoặc node đã bị xoá) mới lấy khung gốc của layout — khung này KHÔNG bị xoá
	# nữa (xem `_apply_hud_for_mode`) nên `layout.hud_slot` luôn còn dùng được sau nhiều lần xoay.
	if hud_host == null or not is_instance_valid(hud_host):
		hud_host = layout.hud_slot if layout != null else null
	# HintGuide nằm TRONG HUD (HUD bị thay bằng code khi đổi chế độ) nên vẫn tra theo TÊN
	hint_guide = ui("HintGuide") as HintGuide
	# Bàn cờ + nhãn Status là node RIÊNG của bố cục ⇒ gắn lại vào bộ controller dùng chung
	if board_view != null:
		if game_controller != null:
			game_controller.grid_view = board_view
		if grid_controller != null:
			grid_controller.board_view = board_view
	if ui_controller != null and layout != null:
		ui_controller.level_label = layout.level_label
		ui_controller.subtitle_label = layout.subtitle_label
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
	# ToolController → Board (đổi công cụ VẼ ĐƯỜNG ⇄ VẼ TƯỜNG)
	_connect_once(tool_controller, "tool_changed", board_view, "set_tool_mode")
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
	if layout != null and layout.pause_btn != null and not layout.pause_btn.has_meta("wired"):
		layout.pause_btn.set_meta("wired", true)
		layout.pause_btn.pressed.connect(_on_pause_pressed)
	if layout != null and layout.restart_btn != null and not layout.restart_btn.has_meta("wired"):
		layout.restart_btn.set_meta("wired", true)
		layout.restart_btn.pressed.connect(_on_restart_pressed)
	if layout != null and layout.instruction_btn != null and game_controller != null \
			and not layout.instruction_btn.has_meta("wired"):
		layout.instruction_btn.set_meta("wired", true)
		layout.instruction_btn.pressed.connect(game_controller.open_instruction)


## Mọi nút của màn chơi: 3 nút trên THANH TRẠNG THÁI (layout) + 5 nút trong THANH HÀNH ĐỘNG (HUD)
func _all_buttons() -> Array:
	return [
		layout.pause_btn if layout != null else null,
		layout.instruction_btn if layout != null else null,
		layout.restart_btn if layout != null else null,
		tool_path_btn, tool_wall_btn, undo_btn, hint_btn, replay_btn,
	]


## Nối `source.signal_name` → `target.method` đúng 1 lần (bỏ qua nếu thiếu node/tín hiệu)
func _connect_once(source: Object, signal_name: String, target: Object, method: String) -> void:
	if source == null or target == null or not source.has_signal(signal_name):
		return
	if not target.has_method(method):
		return
	var cb := Callable(target, method)
	if not source.is_connected(signal_name, cb):
		source.connect(signal_name, cb)


## Khởi động (và đổi bố cục nếu có): gắn lại refs rồi gắn lại HUD + thanh nút.
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	for btn in _all_buttons():
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


## Gọi hàm của SCRIPT BỐ CỤC đang hiển thị (gắn bàn cờ · cỡ HUD · nút công cụ —
## xem `scripts/layout/portrait/game.gd`).
func _layout_call(method: String, args: Array = []) -> Variant:
	var holder: Node = active_layout()
	if holder == null or not holder.has_method(method):
		return null
	return holder.callv(method, args)


## (PORTRAIT-ONLY) Giữ hàm cho tương thích — không còn bố cục ngang.
func _layout_is_landscape() -> bool:
	return false


## Cỡ HUD do BỐ CỤC quyết định — dọc giữ nguyên 980 thiết kế, ngang co theo bề rộng sidebar
## (xem `scripts/orientation/<hướng>/game.gd::fit_hud`).
func _fit_hud_scale() -> void:
	# HUD có thể đã bị thay/xoá (đổi chế độ hoặc xoay màn hình) ⇒ kiểm tra TRƯỚC khi cast,
	# nếu không sẽ lỗi "Trying to cast a freed object" mỗi lần resize.
	if hud_host == null or not is_instance_valid(hud_host):
		return
	var hud := hud_host as Control
	if hud == null:
		return
	_layout_call("fit_hud", [hud])


func _ready() -> void:
	_bind_refs()
	orientation_changed.connect(_on_orientation_changed)
	resized.connect(_fit_hud_scale)
	# Gắn hiệu ứng nảy xúc giác cho các nút trong Game Screen
	for btn in _all_buttons():
		if btn != null:
			UIAnim.attach_press_bounce(btn)

	if layout != null and layout.status_bar != null:
		UIAnim.play_slide_in(layout.status_bar, Vector2(0, -25), 0.0, 0.25)
	if layout != null and layout.hud_slot != null:
		UIAnim.play_slide_in(layout.hud_slot, Vector2(0, -15), 0.04, 0.25)
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
## Scene HUD ứng với từng chế độ (bản portrait-only: dùng thẳng scene HUD dọc)
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
		"fog_of_war":
			return HUD_FOG_OF_WAR
		"one_stroke":
			return HUD_ONE_STROKE
		"wall_builder":
			return HUD_WALL_BUILDER
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
	if not is_inside_tree():
		return
	var slot: Control = layout.hud_slot if layout != null and is_instance_valid(layout) else null
	if slot == null or not is_instance_valid(slot):
		return
	# Đủ chỗ khi HUD hiện tại THUỘC layout đang hiển thị và ĐÚNG chế độ
	if hud_host != null and is_instance_valid(hud_host) \
			and layout.is_ancestor_of(hud_host) \
			and hud_host.get_script() == _hud_class_for(mode_name):
		_bind_hud_nodes()
		return
	var scene := _hud_scene_for(mode_name)
	if scene == null:
		return
	var parent := slot.get_parent()
	if parent == null:
		return
	var new_hud := scene.instantiate() as BaseHUD
	if new_hud == null:
		return
	parent.add_child(new_hud)
	parent.move_child(new_hud, slot.get_index())
	# HUD scene chỉ khai khung theo thiết kế (bản dọc 980×249 ở mốc (50,175) — bản ngang là khung
	# trong sidebar do layout dàn) ⇒ chép khung của KHUNG GỐC sang HUD mới, nếu không HUD sẽ nhảy
	# về góc trái canvas.
	_copy_layout_from(slot, new_hud)
	# ⚠️ KHÔNG xoá khung gốc (`layout.hud_slot`): mỗi lần xoay màn hình `_bind_refs()` cần nó làm
	# mốc để đặt HUD mới. Trước đây xoá nó ⇒ `layout.hud_slot` thành node đã free ⇒ xoay/resize
	# tiếp theo là lỗi "Trying to cast a freed object" (tái hiện: xoay dọc→ngang ở mode Minesweeper).
	if hud_host != null and is_instance_valid(hud_host) and hud_host != slot:
		hud_host.queue_free()
	slot.visible = false
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
	if hud_host == null or not is_instance_valid(hud_host):
		return
	var hud := hud_host as BaseHUD
	if hud == null:
		return
	# HUD được bao phủ toàn khung (để dễ căn vị trí) nên nó nằm TRÊN bàn cờ. Control mặc định
	# `mouse_filter = STOP` ⇒ sẽ NUỐT hết chạm/kéo khiến BoardSlot phía sau không nhận input.
	# Đặt IGNORE cho khung HUD + khối `Content`: bản thân khung không nhận input nữa nhưng
	# các NÚT BÊN TRONG (ActionBar, Status…) vẫn nhận bình thường.
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hud_content := hud.get_node_or_null("Content") as Control
	if hud_content != null:
		hud_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tool_path_btn = hud.tool_path_btn()
	tool_wall_btn = hud.tool_wall_btn()
	undo_btn = hud.undo_btn()
	hint_btn = hud.hint_btn()
	replay_btn = hud.replay_btn()
	# HintGuide nằm TRONG HUD (đầu `ActionBar/Portrait`) ⇒ HUD nào gắn sau cùng thì gắn lại,
	# nếu không `hint_guide` sẽ trỏ vào node đã bị free khi đổi chế độ.
	hint_guide = ui("HintGuide") as HintGuide
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
	for btn in _all_buttons():
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
