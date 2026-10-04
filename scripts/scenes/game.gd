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

## Nút CHƠI LẠI (reset) trên THANH HÀNH ĐỘNG của HUD — dời từ thanh trạng thái xuống (2026-09-26)
var restart_btn: BaseButton = null
## Nút GỬI BÀI của Wall Builder (các chế độ khác ẩn — xem `_apply_mode_buttons`)
var submit_btn: BaseButton = null
## Nút SKIP LEVEL — chỉ hiện khi ván này là ván chơi MÀN trong màn Chọn màn (`_apply_mode_buttons`)
var skip_btn: BaseButton = null
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
	# HintGuide nằm TRONG HUD (HUD bị thay bằng code khi đổi chế độ) ⇒ LUÔN hỏi HUD hiện tại
	hint_guide = _hud_hint_guide()
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
	_connect_once(board_view, "drag_updated", grid_controller, "handle_drag_updated")
	_connect_once(board_view, "anchor_connected", grid_controller, "handle_anchor_connected")
	# Bàn cờ → GameController (overlay retry)
	_connect_once(board_view, "no_moves_retry_pressed", game_controller, "_on_no_moves_retry_pressed")
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
	# Nút trên thanh Status — dây khai trong `scenes/game.tscn` (bản dọc);
	# guard chỉ nối lại nếu dây bị mất: nút Pause → script màn, nút "?" → GameController
	if layout != null and layout.pause_btn != null:
		ensure_signal(layout.pause_btn, &"pressed", &"_on_pause_pressed")
	if layout != null and layout.instruction_btn != null and game_controller != null:
		ensure_signal(layout.instruction_btn, &"pressed", &"open_instruction", [], game_controller)


## Mọi nút của màn chơi: 3 nút trên THANH TRẠNG THÁI (layout) + 5 nút trong THANH HÀNH ĐỘNG (HUD)
func _all_buttons() -> Array:
	return [
		layout.pause_btn if layout != null else null,
		layout.instruction_btn if layout != null else null,
		restart_btn, submit_btn, skip_btn, undo_btn, hint_btn, replay_btn,
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
	# Những nút trong Game Screen
	for btn in _all_buttons():
		if btn != null:
			UIAnim.attach_press_bounce(btn)

	if layout != null and layout.status_bar != null:
		UIAnim.play_slide_in(layout.status_bar, Vector2(0, -25), 0.0, 0.25)
	if layout != null and layout.hud_slot != null:
		UIAnim.play_slide_in(layout.hud_slot, Vector2(0, -15), 0.04, 0.25)
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
	# Nếu quay lại từ Tutorial (người chơi bấm “?”), đồng hồ đã dừng trước khi đổi scene — chạy lại.
	# (timer_controller.pause() gọi trong open_instruction() trước goto_tutorial())
	if timer_controller != null and game_controller != null:
		call_deferred("_resume_timer_if_paused")


func _on_restart_pressed() -> void:
	if game_controller != null:
		game_controller.restart_run()


## SKIP LEVEL: bỏ qua màn đang chơi (chỉ có ở ván chơi màn — xem `_apply_mode_buttons`)
func _on_skip_pressed() -> void:
	if game_controller != null:
		game_controller.skip_current_level()


func _on_pause_pressed() -> void:
	if ui_controller != null:
		ui_controller.toggle_settings()


func _resume_timer_if_paused() -> void:
	if timer_controller != null and game_controller != null:
		if game_controller.get("_run_active") == true:
			timer_controller.resume()


func _on_undo_pressed() -> void:
	if game_controller != null:
		game_controller.undo()


func _on_hint_pressed() -> void:
	if game_controller != null:
		game_controller.hint()


## Nút công cụ thứ 2 đã BỎ cùng nút Tool/Wall (2026-09-26) — chức năng GỬI BÀI của Wall Builder
## nay do nút `Submit` trên thanh hành động đảm nhiệm (xem `_wire_action_bar`).


## Bật/tắt nút đặc thù theo CHẾ ĐỘ trên thanh hành động:
##   · `Submit` — GỬI BÀI (chỉ Wall Builder)
##   · `Skip`   — SKIP LEVEL (chỉ khi chơi MÀN trong màn Chọn màn, KHÔNG có ở Dungeon/Daily/Debug)
func _apply_mode_buttons(mode_name: String) -> void:
	if submit_btn != null:
		submit_btn.visible = mode_name.to_lower() == "wall_builder"
	if skip_btn != null:
		skip_btn.visible = _is_level_run()
	# Dungeon: ẩn nút "?" (không có tutorial cho dungeon)
	if layout != null and layout.instruction_btn != null:
		layout.instruction_btn.visible = mode_name.to_lower() != "dungeon"


## Ván này có phải là ván chơi MÀN (màn Chọn màn) không — đọc cờ từ GameManager
func _is_level_run() -> bool:
	var gm: Node = get_node_or_null("/root/GameManager")
	return gm != null and bool(gm.get("level_run"))

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
##   · Ván chơi MÀN (màn Chọn màn — kể cả màn chạy chế độ Special): vào ĐÚNG màn đang chọn, và
##     ID màn cũng là "tầng" để chế độ biết đang ở màn nào (tường/mask nạp từ LevelData).
##   · Play (Classic): y như trên.
##   · Các chế độ khác (Dungeon/Daily/Debug): bắt đầu từ 1 (trừ khi Debug Console ép tầng).
func _start_floor_for(mode_name: String) -> int:
	var gm: Node = get_node_or_null("/root/GameManager")
	match mode_name.to_lower():
		"play", "classic", "standard":
			if gm != null:
				return maxi(int(gm.get("current_level")), 1)
			return 1
		"daily_classic":
			# Maze thường của Daily luôn bắt đầu ở tầng 1 (mê cung sinh tại chỗ)
			return 1
		_:
			if gm != null:
				if bool(gm.get("level_run")):
					return maxi(int(gm.get("current_level")), 1)
				var override := int(gm.get("start_floor_override"))
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


## Nhãn/art của 2 nút công cụ (VẼ ĐƯỜNG · GHI NHỚ) đã BỎ cùng nút (2026-09-26): bàn cờ tự nhận
## cả 2 thao tác (kéo nhân vật đi đường · kéo nối 2 Anchor để đánh dấu tường), GỬI BÀI của Wall
## Builder nằm ở nút `Submit` trên thanh hành động (xem `_apply_mode_buttons` / `_wire_action_bar`).

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
	# Tỉ lệ chia chỗ của CHA (VBox/HBox) — bản NGANG chia cột dọc: HUD nhỏ · bàn cờ lớn.
	# Thiếu dòng này thì HUD do code tạo giữ tỉ lệ MẶC ĐỊNH 1.0 → phình ra chiếm nửa cột.
	dst.size_flags_stretch_ratio = src.size_flags_stretch_ratio
	dst.custom_minimum_size = src.custom_minimum_size


## Khung Hướng dẫn nằm TRONG HUD (HUD đổi theo chế độ) ⇒ hỏi HUD hiện tại, không tự dò node con.
func _hud_hint_guide() -> HintGuide:
	var hud := hud_host as BaseHUD
	return hud.hint_guide() if hud != null else null


## Gắn HUD hiện tại cho UIController (vẽ nội dung) và ChallengeController (thẻ Thử thách).
## Đồng thời lấy thanh nút hành động NẰM TRONG HUD (phương án A) rồi nối lại tín hiệu — nhờ vậy
## mỗi HUD/chế độ tự bày nút theo bố cục dọc-ngang của mình, màn chơi không giữ nút nào.
## MỌI thứ thuộc HUD (nút · khung Hướng dẫn · nhường input) đều hỏi qua METHOD của HUD —
## màn chơi không tự lấy node con của HUD.
func _bind_hud_nodes() -> void:
	if hud_host == null or not is_instance_valid(hud_host):
		return
	var hud := hud_host as BaseHUD
	if hud == null:
		return
	# HUD phủ toàn khung nên phải NHƯỜNG chạm/kéo cho bàn cờ phía sau (nút bên trong vẫn ăn)
	# — HUD tự lo việc này, màn chơi không đụng node con của nó.
	hud.allow_board_input()
	restart_btn = hud.restart_btn()
	submit_btn = hud.submit_btn()
	skip_btn = hud.skip_btn()
	undo_btn = hud.undo_btn()
	hint_btn = hud.hint_btn()
	#replay_btn = hud.replay_btn()
	# HintGuide nằm TRONG HUD (đầu `ActionBar` bản dọc / `Content` bản ngang) ⇒ gắn lại theo HUD mới,
	# nếu không `hint_guide` sẽ trỏ vào node đã bị free khi đổi chế độ.
	hint_guide = _hud_hint_guide()
	_wire_action_bar()
	_apply_mode_buttons(_mode_id)
	hud.set_landscape(_layout_is_landscape())
	if ui_controller != null:
		ui_controller.set_hud(hud)
	if challenge_controller != null:
		challenge_controller.card = hud.challenge_card()
	hint_guide = _hud_hint_guide()
	_refresh_hint_guide()
	_fit_hud_scale.call_deferred()


## Nối tín hiệu cho các nút của thanh hành động (thay cho [connection] trong game.tscn)
func _wire_action_bar() -> void:
	for btn in _all_buttons():
		if btn != null and not btn.has_meta("bounce_attached"):
			btn.set_meta("bounce_attached", true)
			UIAnim.attach_press_bounce(btn)
	if game_controller != null:
		if restart_btn != null and not restart_btn.pressed.is_connected(_on_restart_pressed):
			restart_btn.pressed.connect(_on_restart_pressed)
		if skip_btn != null and not skip_btn.pressed.is_connected(_on_skip_pressed):
			skip_btn.pressed.connect(_on_skip_pressed)
		if submit_btn != null and not submit_btn.pressed.is_connected(game_controller.submit_build):
			submit_btn.pressed.connect(game_controller.submit_build)
		if undo_btn != null and not undo_btn.pressed.is_connected(game_controller.undo):
			undo_btn.pressed.connect(game_controller.undo)
		if hint_btn != null and not hint_btn.pressed.is_connected(game_controller.hint):
			hint_btn.pressed.connect(game_controller.hint)
		if replay_btn != null and not replay_btn.pressed.is_connected(game_controller.restart_run):
			replay_btn.pressed.connect(game_controller.restart_run)
	if ui_controller != null:
		ui_controller.undo_button = undo_btn
		ui_controller.replay_button = replay_btn
