class_name GameHUD
extends BaseHUD
## ============================================================================
## Base: HUD thẻ thông tin của màn chơi — khung "Information" trong scenes/game.tscn
## được thay bằng scene HUD ứng với từng chế độ (GameScene._apply_hud_for_mode).
##
## Mỗi chế độ có 1 HUD riêng (nodes/hud/*.tscn) — GameScene tự đổi HUD theo mode:
##   level_mode.tscn    (LevelHUD)     : THỜI GIAN + THỬ THÁCH   — Play + mọi mode không có HUD riêng
##   dungeon_mode.tscn  (DungeonHUD)   : THỜI GIAN + SỐ BƯỚC + TẦNG — Dungeon (endless)
##   minesweep_hud.tscn (MinesweepHUD) : THỜI GIAN + BOMB CÒN LẠI — Minesweeper Maze
##   sum_path_hud.tscn  (SumPathHUD)   : THỜI GIAN + TỔNG HIỆN TẠI + MỤC TIÊU — Sum Path
##   fog_of_war_hud.tscn (FogOfWarHUD) : THỜI GIAN + BẢNG SƯƠNG MÙ (lượt thử lại · tầm nhìn) — Fog of War
##
## UIController KHÔNG tự biết từng thẻ: nó chỉ gọi `update_hud(ctx)`, HUD con tự vẽ.
## Mọi HUD đều có thẻ THỜI GIAN tên node "Time/Value" (xem set_time()).
## ============================================================================

@export var time_value_node : Label

## Gọi mỗi khi HUD cần vẽ lại (GameController._update_hud). ctx gồm:
##   title:String · subtitle:String · steps_remaining:int · elapsed_time:float
##   floor_number:int · extra:String · mode:BaseGameMode
func update_hud(ctx: Dictionary) -> void:
	set_time(float(ctx.get("elapsed_time", 0.0)))
	_sync_instruction(ctx.get("mode"))
	_on_update(ctx)


## HUD con override để vẽ các thẻ riêng của chế độ mình
func _on_update(_ctx: Dictionary) -> void:
	pass


## Thẻ THỬ THÁCH nếu HUD có (chỉ HUD của các chế độ dùng hệ thống Thử thách).
## ChallengeController gọi hàm này để biết thẻ cần vẽ 3 dải thử thách.
func challenge_card() -> Control:
	return null


## Đồng hồ của ván: giây -> "m:ss"
func set_time(seconds: float) -> void:
	set_label_text(time_value_node, format_time(seconds))

func get_time_node() -> Control :
	return get_node_or_null("Content/ModeInformation/Time")

## Gán text cho Label (bỏ qua nếu trùng -> không redraw mỗi frame)
func set_label_text(node: Node, text: String) -> void:
	var label := node as Label
	if label != null and label.text != text:
		label.text = text


static func format_time(seconds: float) -> String:
	var total := maxi(int(seconds), 0)
	return "%d:%02d" % [total / 60, total % 60]


## ---------------------------------------------------------------------------
## THANH NÚT HÀNH ĐỘNG (phương án A): mỗi HUD đều instance `nodes/hud/action_bar.tscn`
## ngay trong scene của mình ⇒ nút VẼ ĐƯỜNG/GHI NHỚ/UNDO/HINT/REPLAY nằm TRONG HUD,
## màn chơi chỉ việc lấy ra để nối tín hiệu (không còn nút nào trong game.tscn).
## ---------------------------------------------------------------------------
func action_bar() -> ActionBar:
	return get_node_or_null("Content/ActionBar") as ActionBar


## Bật bố cục NGANG cho thanh nút (hàng trên: Vẽ đường · Ghi nhớ — hàng dưới: Undo · Hint)
func set_landscape(on: bool) -> void:
	var bar := action_bar()
	if bar != null:
		bar.set_landscape(on)


func tool_path_btn() -> BaseButton:
	var bar := action_bar()
	return bar.tool_path_btn() if bar != null else null


func tool_wall_btn() -> BaseButton:
	var bar := action_bar()
	return bar.tool_wall_btn() if bar != null else null


func undo_btn() -> BaseButton:
	var bar := action_bar()
	return bar.undo_btn() if bar != null else null


func hint_btn() -> BaseButton:
	var bar := action_bar()
	return bar.hint_btn() if bar != null else null


func replay_btn() -> BaseButton:
	var bar := action_bar()
	return bar.replay_btn() if bar != null else null


## ---------------------------------------------------------------------------
## KHUNG HƯỚNG DẪN NHÚNG — `Content/InstructionSection` (bản NGANG: giữa HintGuide và ActionBar)
##
##   · Khung ĐỦ chỗ → nhúng NỘI DUNG hướng dẫn của chế độ (`nodes/popups/instruction/<mode>` —
##     kế thừa `content_instruction.tscn`) vào `Panel/GuideHost`; nội dung tự dàn theo khung
##     (bằng anchors + `page.gd` đổi bố cục rộng/cao) nên TRÀN kín GuideHost.
##   · Khung QUÁ NHỎ (hoặc chế độ chưa có scene) → hiện nút "XEM HƯỚNG DẪN" trong Panel;
##     bấm thì phát `instruction_requested` → GameScene mở popup hướng dẫn (toàn màn hình).
## ---------------------------------------------------------------------------
signal instruction_requested

## Khung nhỏ hơn mức này thì nội dung hướng dẫn không còn đọc được ⇒ chuyển sang nút dự phòng
const GUIDE_MIN_W := 300.0
const GUIDE_MIN_H := 220.0

## Cache scene nội dung theo đường dẫn — nhiều HUD/chế độ dùng chung 1 PackedScene
static var _guide_scene_cache: Dictionary = {}

var _instruction_mode := ""
var _instruction_content: InstructionContent = null
var _instruction_fallback: Button = null


## Khung chứa hướng dẫn — CHỈ bản NGANG có (khung `InstructionSection`); bản dọc trả null.
func instruction_section() -> Control:
	return get_node_or_null("Content/InstructionSection") as Control


## Nội dung hướng dẫn đang NHÚNG trong khung (null = không nhúng)
func instruction_view() -> InstructionContent:
	return _instruction_content


## Nút dự phòng "XEM HƯỚNG DẪN" trong khung
func instruction_fallback() -> Button:
	return _instruction_fallback


func _sync_instruction(mode: Variant) -> void:
	var section := instruction_section()
	if section == null:
		return
	_ensure_instruction_nodes(section)
	var mode_id := ""
	var game_mode := mode as BaseGameMode
	if game_mode != null:
		mode_id = game_mode.mode_id
	if mode_id == _instruction_mode:
		return
	show_instruction_for(mode_id)


## Dựng lại khung hướng dẫn cho chế độ `mode_id` (chuỗi rỗng = chưa biết chế độ ⇒ chỉ nút dự phòng)
func show_instruction_for(mode_id: String) -> void:
	var section := instruction_section()
	if section == null:
		return
	_ensure_instruction_nodes(section)
	_instruction_mode = mode_id
	if _instruction_content != null and is_instance_valid(_instruction_content):
		_instruction_content.queue_free()
	_instruction_content = null
	var host := section.get_node_or_null("Panel/GuideHost") as Control
	if host != null and not mode_id.is_empty():
		var packed := _instruction_scene(mode_id)
		if packed != null:
			var content := packed.instantiate() as InstructionContent
			if content != null:
				host.add_child(content)
				content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				content.set_embedded(true)
				_instruction_content = content
	_fit_instruction_view()


## Nút dự phòng + tín hiệu `resized` của khung — nối đúng 1 lần
func _ensure_instruction_nodes(section: Control) -> void:
	if _instruction_fallback == null:
		_instruction_fallback = section.get_node_or_null("Panel/Fallback") as Button
		if _instruction_fallback != null and not _instruction_fallback.pressed.is_connected(_on_instruction_pressed):
			_instruction_fallback.pressed.connect(_on_instruction_pressed)
		if _instruction_fallback != null and not _instruction_fallback.has_meta("bounce_attached"):
			_instruction_fallback.set_meta("bounce_attached", true)
			UIAnim.attach_press_bounce(_instruction_fallback)
	if not section.resized.is_connected(_fit_instruction_view):
		section.resized.connect(_fit_instruction_view)


## Scene nội dung hướng dẫn của chế độ (load 1 lần, dùng lại cho mọi HUD)
static func _instruction_scene(mode_id: String) -> PackedScene:
	var path := GameController.instruction_scene_path(mode_id)
	if not _guide_scene_cache.has(path):
		_guide_scene_cache[path] = load(path)
	return _guide_scene_cache[path] as PackedScene


## Nội dung TRÀN kín khung (full-rect) khi khung đủ chỗ; quá nhỏ ⇒ đổi sang nút dự phòng.
## Chạy khi khung đổi cỡ (tín hiệu `resized`) và ngay sau khi dựng lại (`show_instruction_for`).
func _fit_instruction_view() -> void:
	var section := instruction_section()
	if section == null:
		return
	var fits := _instruction_content != null and is_instance_valid(_instruction_content) \
			and section.size.x >= GUIDE_MIN_W and section.size.y >= GUIDE_MIN_H
	if _instruction_fallback != null:
		_instruction_fallback.visible = not fits
	if _instruction_content != null and is_instance_valid(_instruction_content):
		_instruction_content.visible = fits


func _on_instruction_pressed() -> void:
	instruction_requested.emit()
