class_name PopupInstruction
extends BasePopup
## ============================================================================
## POPUP HƯỚNG DẪN CHƠI — MỘT popup duy nhất cho mọi chế độ (thay 10 popup riêng cũ).
##
## Khung giấy nằm ở đây (Panel + Washi + PaperDetail + Close); NỘI DUNG nạp vào
## `Panel/Content` theo `mode_id` truyền lúc mở:
##   `Popups.open_path("res://nodes/popups/popup_instruction.tscn", {"mode_id": mode_id})`
##   (xem `GameController.open_instruction` — mode_id lấy từ chế độ đang chơi)
##
## Scene nạp vào là `nodes/popups/instruction/<mode>.tscn` (kế thừa `content_instruction.tscn`)
## — CÙNG scene mà khung Hướng dẫn của HUD màn chơi nhúng vào GuideHost (xem GameHUD).
## ============================================================================

const CONTENT_NODE := "Panel/Content"
const CLOSE_NODE := "Panel/Close"
const PAPER_NODE := "Panel/Paper"
const PAPER_RADIUS := 13.0
const PAPER_BORDER := 2.0

## Nội dung (`nodes/popups/instruction/<mode>.tscn`) đang nạp trong Panel/Content
var instruction_content: InstructionContent = null


func _on_open() -> void:
	_load_content()
	var close_btn := get_node_or_null(CLOSE_NODE) as BaseButton
	if close_btn != null and not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)


## Nạp scene nội dung của chế độ (`nodes/popups/instruction/<mode>.tscn`) vào Panel/Content
func _load_content() -> void:
	if instruction_content != null and is_instance_valid(instruction_content):
		instruction_content.queue_free()
	instruction_content = null
	var mode_id := str(data.get("mode_id", ""))
	var packed := load(GameController.instruction_scene_path(mode_id)) as PackedScene
	if packed == null:
		return
	var host := content if content != null else get_node_or_null(CONTENT_NODE) as Control
	if host == null:
		return
	var inst := packed.instantiate() as InstructionContent
	if inst == null:
		return
	host.add_child(inst)
	inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not inst.close_requested.is_connected(close):
		inst.close_requested.connect(close)
	_apply_paper_style(inst)
	instruction_content = inst


## Tô tờ giấy theo CHẾ ĐỘ (màu nướng trong scene chế độ qua 2 export paper_bg/paper_accent)
func _apply_paper_style(c: InstructionContent) -> void:
	var paper := get_node_or_null(PAPER_NODE) as Panel
	if paper == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = c.paper_bg
	sb.border_color = c.paper_accent
	sb.set_corner_radius_all(int(PAPER_RADIUS))
	sb.border_width_left = PAPER_BORDER
	sb.border_width_top = PAPER_BORDER
	sb.border_width_right = PAPER_BORDER
	sb.border_width_bottom = PAPER_BORDER
	paper.add_theme_stylebox_override("panel", sb)


func _on_close_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	close()


func _has_content() -> bool:
	return instruction_content != null and is_instance_valid(instruction_content)


## Node nội dung đang nạp (cho test)
func content_node() -> InstructionContent:
	return instruction_content


# ---------------------------------------------------------------------------
# API chuyển tiếp xuống content (cho test)
# ---------------------------------------------------------------------------
func page_count() -> int:
	return instruction_content.page_count() if _has_content() else 0


func current_page() -> int:
	return instruction_content.current_page() if _has_content() else 0


func go_to_page(index: int) -> void:
	if _has_content():
		instruction_content.go_to_page(index)


func next_page() -> void:
	if _has_content():
		instruction_content.next_page()


func prev_page() -> void:
	if _has_content():
		instruction_content.prev_page()


func tab_count() -> int:
	return instruction_content.tab_count() if _has_content() else 0


func tab_label(index: int) -> String:
	return instruction_content.tab_label(index) if _has_content() else ""


func cta_text() -> String:
	return instruction_content.cta_text() if _has_content() else ""


func link_text() -> String:
	return instruction_content.link_text() if _has_content() else ""


func page_index_text() -> String:
	return instruction_content.page_index_text() if _has_content() else ""


func page_title() -> String:
	return instruction_content.page_title() if _has_content() else ""


func is_prev_locked() -> bool:
	return instruction_content.is_prev_locked() if _has_content() else true


func is_next_locked() -> bool:
	return instruction_content.is_next_locked() if _has_content() else true


func cta_button() -> Button:
	return instruction_content.cta_button() if _has_content() else null


func link_button() -> Button:
	return instruction_content.link_button() if _has_content() else null
