class_name InstructionPopup
extends BasePopup
## ============================================================================
## Popup HƯỚNG DẪN CHƠI theo từng chế độ (nodes/popups/instruction.tscn).
##
## - Nội dung lấy từ `Instruction` (scripts/utils/instruction.gd): mỗi chế độ 3 trang
##   (CÁCH CHƠI · LUẬT CHẾ ĐỘ · THỬ THÁCH & THƯỞNG), mỗi trang 1 ảnh minh hoạ + chữ.
## - Chuyển trang: VUỐT ngang (touch/kéo chuột), lăn chuột, phím ← →, nút mũi tên
##   hoặc bấm vào chấm trang (dots). Cuối/đầu danh sách thì nút tương ứng bị khoá.
## - Mở bằng: Popups.open(Popups.INSTRUCTION, {mode_id = "...", mode_name = "..."}).
## ============================================================================

const DOT_ACTIVE := preload("res://assets/images/level_selector/dot_active.svg")
const DOT_INACTIVE := preload("res://assets/images/level_selector/dot_inactive.svg")
const DOT_SIZE_ACTIVE := Vector2(34, 24)
const DOT_SIZE_INACTIVE := Vector2(12, 24)
## Ngưỡng kéo (px) để tính là VUỐT chứ không phải bấm
const DRAG_THRESHOLD := 14.0
## Quãng vuốt (px) để lật sang trang kế/trước
const SWIPE_DISTANCE := 90.0

@onready var lbl_title: Label = get_node_or_null("Panel/Content/Title")
@onready var lbl_subtitle: Label = get_node_or_null("Panel/Content/Subtitle")
@onready var page_image: TextureRect = get_node_or_null("Panel/Content/PageImage")
@onready var lbl_page_title: Label = get_node_or_null("Panel/Content/PageTitle")
@onready var lbl_page_body: Label = get_node_or_null("Panel/Content/PageBody")
@onready var lbl_page_index: Label = get_node_or_null("Panel/Content/PageIndex")
@onready var dots_box: HBoxContainer = get_node_or_null("Panel/Content/Dots")
@onready var btn_prev: TextureButton = get_node_or_null("Panel/Content/PrevBtn")
@onready var btn_next: TextureButton = get_node_or_null("Panel/Content/NextBtn")

var _pages: Array = []
var _page := 0
var _mode_id := ""
## Tên chế độ truyền vào lúc mở (dùng khi chưa có khoá dịch riêng)
var _mode_name := ""

var _drag_active := false
var _drag_moved := false
var _drag_start := Vector2.ZERO


# ---------------------------------------------------------------------------
# Vòng đời popup
# ---------------------------------------------------------------------------
func _on_open() -> void:
	_mode_id = _resolve_mode_id()
	_mode_name = str(data.get("mode_name", ""))
	_pages = Instruction.pages_for(_mode_id)
	_page = clampi(int(data.get("page", 0)), 0, maxi(_pages.size() - 1, 0))

	if lbl_title != null:
		lbl_title.text = tr("STR_INSTRUCTION_TITLE")
	if lbl_subtitle != null:
		lbl_subtitle.text = tr("STR_INSTRUCTION_MODE").format([display_mode_name()])

	bind_button("Panel/Content/PrevBtn", _on_prev_pressed)
	bind_button("Panel/Content/NextBtn", _on_next_pressed)
	bind_button("Panel/Content/CloseBtn", _on_close_pressed)

	_build_dots()
	_show_page()


# ---------------------------------------------------------------------------
# API cho test
# ---------------------------------------------------------------------------
## Số trang hướng dẫn của chế độ đang xem
func page_count() -> int:
	return _pages.size()


## Trang đang hiển thị (0-based)
func current_page() -> int:
	return _page


## Chế độ đang xem hướng dẫn
func mode_id() -> String:
	return _mode_id


## Tên chế độ hiển thị trên phụ đề (đã dịch nếu có khoá)
func display_mode_name() -> String:
	var key := Instruction.name_key(_mode_id)
	if not key.is_empty():
		var text := tr(key)
		if text != key:
			return text
	if not _mode_name.is_empty():
		return _mode_name
	return _mode_id.capitalize()


## Nhảy tới trang chỉ định (kẹp trong khoảng hợp lệ)
func go_to_page(index: int) -> void:
	if _pages.is_empty():
		return
	_page = clampi(index, 0, _pages.size() - 1)
	_show_page()


func next_page() -> void:
	go_to_page(_page + 1)


func prev_page() -> void:
	go_to_page(_page - 1)


## Nội dung đang hiển thị (đã dịch) — dùng cho test
func current_page_title() -> String:
	return lbl_page_title.text if lbl_page_title != null else ""


func current_page_body() -> String:
	return lbl_page_body.text if lbl_page_body != null else ""


## Số chấm trang đang dựng
func dot_count() -> int:
	return dots_box.get_child_count() if dots_box != null else 0


# ---------------------------------------------------------------------------
# Nội dung trang
# ---------------------------------------------------------------------------
## mode_id: data truyền vào -> GameManager.current_mode -> "play"
func _resolve_mode_id() -> String:
	var id := str(data.get("mode_id", "")).strip_edges()
	if id.is_empty():
		var gm: Node = get_node_or_null("/root/GameManager")
		if gm != null:
			id = str(gm.get("current_mode"))
	if id.is_empty():
		id = Instruction.FALLBACK_MODE
	return id.to_lower()


func _show_page() -> void:
	if _pages.is_empty():
		return
	var page: Dictionary = _pages[_page]

	if page_image != null:
		var texture := load(Instruction.image_path(str(page.get("img", "")))) as Texture2D
		page_image.texture = texture
		# Ảnh mới hiện mềm để người chơi thấy trang vừa đổi
		var tw := create_tween()
		tw.tween_property(page_image, "modulate:a", 1.0, 0.16).from(0.2)

	if lbl_page_title != null:
		lbl_page_title.text = tr(str(page.get("title", "")))
	if lbl_page_body != null:
		lbl_page_body.text = tr(str(page.get("body", "")))
	if lbl_page_index != null:
		lbl_page_index.text = tr("STR_INSTRUCTION_PAGE").format([_page + 1, _pages.size()])

	_update_dots()
	_update_arrows()


func _update_arrows() -> void:
	if btn_prev != null:
		var at_first := _page <= 0
		btn_prev.disabled = at_first
		btn_prev.modulate = Color(1, 1, 1, 0.45) if at_first else Color.WHITE
	if btn_next != null:
		var at_last := _page >= _pages.size() - 1
		btn_next.disabled = at_last
		btn_next.modulate = Color(1, 1, 1, 0.45) if at_last else Color.WHITE


# ---------------------------------------------------------------------------
# Chấm trang (dots)
# ---------------------------------------------------------------------------
func _build_dots() -> void:
	if dots_box == null:
		return
	for child in dots_box.get_children():
		dots_box.remove_child(child)
		child.queue_free()
	for index in _pages.size():
		var dot := TextureButton.new()
		dot.name = "Dot%d" % (index + 1)
		dot.ignore_texture_size = true
		dot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		dot.focus_mode = Control.FOCUS_NONE
		dot.pressed.connect(_on_dot_pressed.bind(index))
		dots_box.add_child(dot)


func _update_dots() -> void:
	if dots_box == null:
		return
	var dots := dots_box.get_children()
	for index in dots.size():
		var dot: TextureButton = dots[index]
		var is_current := index == _page
		dot.texture_normal = DOT_ACTIVE if is_current else DOT_INACTIVE
		dot.texture_hover = dot.texture_normal
		dot.texture_pressed = dot.texture_normal
		dot.custom_minimum_size = DOT_SIZE_ACTIVE if is_current else DOT_SIZE_INACTIVE


func _on_dot_pressed(index: int) -> void:
	go_to_page(index)


# ---------------------------------------------------------------------------
# Nút bấm
# ---------------------------------------------------------------------------
func _on_prev_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	prev_page()


func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	next_page()


func _on_close_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	close()


# ---------------------------------------------------------------------------
# Vuốt ngang / lăn chuột / phím mũi tên để chuyển trang
# ===========================================================================
# Nút bấm trong popup "ăn" sự kiện kéo nên phải tự xử lý ở `_input`
# (nhận trước GUI) rồi `set_input_as_handled()` — cùng cách popup Ngôn ngữ.
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if is_closing() or not is_visible_in_tree():
		return

	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and event.index == 0:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventMouseMotion and _drag_active:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			next_page()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			prev_page()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_RIGHT:
			next_page()
		elif event.keycode == KEY_LEFT:
			prev_page()


func _begin_drag(pos: Vector2) -> void:
	_drag_active = true
	_drag_moved = false
	_drag_start = pos


func _update_drag(pos: Vector2) -> void:
	if not _drag_active:
		return
	var delta_x := pos.x - _drag_start.x
	if not _drag_moved:
		if absf(delta_x) < DRAG_THRESHOLD:
			return
		_drag_moved = true      # kéo đủ xa -> coi là VUỐT (không phải bấm)
	if absf(delta_x) >= SWIPE_DISTANCE:
		if delta_x < 0.0:
			next_page()
		else:
			prev_page()
		_drag_start = pos
	if get_viewport() != null:
		get_viewport().set_input_as_handled()


func _end_drag() -> void:
	_drag_active = false
