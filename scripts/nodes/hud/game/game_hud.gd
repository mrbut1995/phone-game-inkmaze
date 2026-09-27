class_name GameHUD
extends BaseHUD
## ============================================================================
## HUD của MÀN CHƠI — mỗi chế độ có 1 HUD riêng (nodes/hud/<hướng>/game/*.tscn) và GameScene
## tự đổi HUD theo chế độ (`GameScene._apply_hud_for_mode`):
##   level_mode.tscn     (LevelHUD)      : THỜI GIAN + THỬ THÁCH — Play + mọi mode không có HUD riêng
##   dungeon_mode.tscn   (DungeonHUD)    : THỜI GIAN + SỐ BƯỚC + TẦNG — Dungeon (endless)
##   minesweep_hud.tscn  (MinesweepHUD)  : THỜI GIAN + BOMB CÒN LẠI — Minesweeper Maze
##   sum_path_hud.tscn   (SumPathHUD)    : THỜI GIAN + TỔNG HIỆN TẠI + MỤC TIÊU — Sum Path
##   fog_of_war_hud.tscn (FogOfWarHUD)   : THỜI GIAN + BẢNG SƯƠNG MÙ — Fog of War
##
## PHẦN DÙNG CHUNG nằm ở lớp cơ sở `BaseHUD` (đồng hồ · thanh nút hành động · thẻ THỬ THÁCH ·
## nhường input cho bàn cờ · khung HintGuide) — ai đang giữ HUD chỉ cần biết `BaseHUD`.
##
## Lớp này lo RIÊNG phần của màn chơi: KHUNG HƯỚNG DẪN NHÚNG + hook `_on_update()` để HUD con
## vẽ các thẻ của chế độ mình (UIController chỉ gọi `update_hud(ctx)`, không biết từng thẻ).
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")

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


## ---------------------------------------------------------------------------
## NODE CON — SCENE TỰ BIND qua `@export` (script KHÔNG dò đường dẫn "A/B/C")
## ---------------------------------------------------------------------------
## Khung hướng dẫn NHÚNG (`Content/InstructionSection`) — CHỈ bản NGANG khai node này
@export var instruction_section_node : Control
## Nơi nhúng nội dung hướng dẫn (`…/InstructionSection/Panel/GuideHost`)
@export var instruction_host : Control
## Nút dự phòng "XEM HƯỚNG DẪN" (`…/InstructionSection/Panel/Fallback`)
@export var instruction_fallback_btn : Button


## Khung chứa hướng dẫn — CHỈ bản NGANG có (khung `InstructionSection`); bản dọc trả null.
func instruction_section() -> Control:
	return instruction_section_node


## Nội dung hướng dẫn đang NHÚNG trong khung (null = không nhúng)
func instruction_view() -> InstructionContent:
	return _instruction_content


## Nút dự phòng "XEM HƯỚNG DẪN" trong khung
func instruction_fallback() -> Button:
	return instruction_fallback_btn


## Ghi đè hook ở `BaseHUD`: đổi chế độ ⇒ nhúng lại nội dung hướng dẫn (bản NGANG mới có khung)
func _sync_instruction(mode: Variant) -> void:
	var section := instruction_section()
	if section == null:
		return
	_ensure_instruction_nodes()
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
	_ensure_instruction_nodes()
	_instruction_mode = mode_id
	if _instruction_content != null and is_instance_valid(_instruction_content):
		_instruction_content.queue_free()
	_instruction_content = null
	var host := instruction_host
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
func _ensure_instruction_nodes() -> void:
	if instruction_fallback_btn != null \
			and not instruction_fallback_btn.pressed.is_connected(_on_instruction_pressed):
		instruction_fallback_btn.pressed.connect(_on_instruction_pressed)
	if instruction_fallback_btn != null and not instruction_fallback_btn.has_meta("bounce_attached"):
		instruction_fallback_btn.set_meta("bounce_attached", true)
		UIAnim.attach_press_bounce(instruction_fallback_btn)
	var section := instruction_section()
	if section != null and not section.resized.is_connected(_fit_instruction_view):
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
	if instruction_fallback_btn != null:
		instruction_fallback_btn.visible = not fits
	if _instruction_content != null and is_instance_valid(_instruction_content):
		_instruction_content.visible = fits


func _on_instruction_pressed() -> void:
	instruction_requested.emit()
