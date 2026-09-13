class_name LevelScenes
extends BaseScene
## ============================================================================
## View Controller: Màn hình Chọn Màn chơi (Level Selection)
## - Danh sách màn lấy từ LevelManager (quét res://resources/levels/level_*.tres)
##   => hỗ trợ NHIỀU HƠN 9 MÀN: chia 9 thẻ/trang, VUỐT NGANG để sang trang mới.
## - Chỉ số trang (dots) dựng ĐỘNG theo số trang thật; bấm vào dot để nhảy trang.
## - Nút CTA dùng art "thẻ giấy xanh" đúng mockup (common/btn_paper_cta_*).
## Cấu trúc node: CardArea/Scroll/Pages (mỗi trang 1 GridContainer 3x3) + PaginationDots.
## ============================================================================

const LEVEL_CARD_SCENE := preload("res://nodes/level_selection/level_card.tscn")
const DOT_ACTIVE := preload("res://assets/images/level_selector/dot_active.svg")
const DOT_INACTIVE := preload("res://assets/images/level_selector/dot_inactive.svg")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

const CARDS_PER_PAGE := 9                        # 3 cột x 3 hàng
const GRID_COLUMNS := 3
const GRID_ORIGIN := Vector2(10.08, 11.04)       # giữ đúng vị trí lưới trong mockup
const GRID_H_SEP := 46
const GRID_V_SEP := 24
const SNAP_TIME := 0.22
const DOT_SIZE_ACTIVE := Vector2(34, 24)
const DOT_SIZE_INACTIVE := Vector2(12, 24)
## Quãng kéo tối thiểu (px) để tính là VUỐT trang (dưới ngưỡng = bấm vào thẻ)
const DRAG_THRESHOLD := 8.0
## Sau khi vuốt, bỏ qua thao tác bấm thẻ trong bao lâu (giây)
const CLICK_LOCK_TIME := 0.15

@onready var btn_back: TextureButton = $TopBar/Back
@onready var btn_continue: TextureButton = $ContinueButton
@onready var lbl_continue: Label = $ContinueButton/Label
@onready var lbl_stars: Label = $StarsCounter/Count
@onready var scroll: ScrollContainer = $CardArea/Scroll
@onready var pages_host: HBoxContainer = $CardArea/Scroll/Pages
@onready var dots_box: HBoxContainer = $PaginationDots

var _level_ids: Array[int] = []
var _level_data: Dictionary = {}        # level_id -> LevelData (chỉ các file có thật)
var _page_count := 1
var _page := 0
var _page_width := 0.0
var _scroll_tween: Tween = null
var _scrolling := false
var _click_lock_until := 0.0
var _drag_active := false
var _drag_moved := false
var _drag_start_x := 0.0
var _drag_start_scroll := 0.0


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(btn_back)
	if btn_continue != null:
		btn_continue.pressed.connect(_on_continue_pressed)
		UIAnim.attach_press_bounce(btn_continue)
		UIAnim.play_pulse(btn_continue, 1.03, 1.8)
	resized.connect(_apply_layout)

	_build_pages()
	_build_dots()
	_refresh_header()
	# Đợi layout xong mới biết bề rộng trang -> căn trang + nhảy tới màn đang chơi
	call_deferred("_apply_layout")
	call_deferred("_go_to_page", _page_for_level(_unlocked_level()), false)


# ---------------------------------------------------------------------------
# API cho test / điều khiển từ ngoài
# ---------------------------------------------------------------------------
func page_count() -> int:
	return _page_count


func current_page() -> int:
	return _page


func level_ids() -> Array[int]:
	return _level_ids.duplicate()


func page_for_level(level_id: int) -> int:
	return _page_for_level(level_id)


func go_to_page(index: int, animate := true) -> void:
	_go_to_page(index, animate)


# ---------------------------------------------------------------------------
# Dựng danh sách màn + các trang
# ---------------------------------------------------------------------------
func _build_pages() -> void:
	if pages_host == null:
		return

	for child in pages_host.get_children():
		pages_host.remove_child(child)
		child.queue_free()

	_load_level_ids()
	_page_count = maxi(1, int(ceil(float(_level_ids.size()) / float(CARDS_PER_PAGE))))

	var unlocked := _unlocked_level()
	var stars_dict := _stars_dict()
	var chapter_seen: Dictionary = {}      # chapter -> số màn đã đếm (để hiện 1-1, 1-2...)

	for page_index in _page_count:
		var page := Control.new()
		page.name = "Page%d" % (page_index + 1)
		page.mouse_filter = Control.MOUSE_FILTER_PASS
		pages_host.add_child(page)

		var grid := GridContainer.new()
		grid.name = "Grid"
		grid.columns = GRID_COLUMNS
		grid.add_theme_constant_override("h_separation", GRID_H_SEP)
		grid.add_theme_constant_override("v_separation", GRID_V_SEP)
		grid.position = GRID_ORIGIN
		page.add_child(grid)

		for slot in CARDS_PER_PAGE:
			var list_index := page_index * CARDS_PER_PAGE + slot
			if list_index >= _level_ids.size():
				break
			var level_id := _level_ids[list_index]
			var chapter := _chapter_of(level_id)
			chapter_seen[chapter] = int(chapter_seen.get(chapter, 0)) + 1
			var rating := int(stars_dict.get(level_id, 0))
			_add_card(grid, level_id, chapter, int(chapter_seen[chapter]),
				level_id > unlocked, rating, rating > 0)


func _add_card(grid: GridContainer, level_id: int, chapter: int, index_in_chapter: int,
		locked: bool, rating: int, done: bool) -> void:
	var card: Control = LEVEL_CARD_SCENE.instantiate()
	grid.add_child(card)
	if card.has_method("setup"):
		card.call("setup", level_id, locked, rating, done, chapter, index_in_chapter)
	elif card.has_method("update_visuals"):
		card.call("update_visuals")
	if card.has_signal("selected"):
		card.connect("selected", _on_level_selected)
	var card_idx := grid.get_child_count() - 1
	UIAnim.play_pop_in(card, 0.02 * card_idx, 0.88, 0.2)


## Danh sách level_id có file .tres thật (LevelManager quét resources/levels)
func _load_level_ids() -> void:
	_level_ids.clear()
	_level_data.clear()

	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm != null and lm.has_method("get_level_ids"):
		for level_id in lm.call("get_level_ids"):
			_level_ids.append(int(level_id))
		for level_id in _level_ids:
			_level_data[level_id] = lm.call("load_level", level_id)

	if _level_ids.is_empty():
		# Không có LevelManager (test/--script): giữ hành vi cũ 9 màn chương 1
		for level_id in range(1, 10):
			_level_ids.append(level_id)


func _chapter_of(level_id: int) -> int:
	var data: LevelData = _level_data.get(level_id, null)
	return maxi(data.chapter, 1) if data != null else 1


func _unlocked_level() -> int:
	var gm := _game_manager()
	return maxi(int(gm.get("unlocked_levels")), 1) if gm != null else 1


func _stars_dict() -> Dictionary:
	var gm := _game_manager()
	var stars: Variant = gm.get("level_stars") if gm != null else null
	return stars if stars is Dictionary else {}


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


# ---------------------------------------------------------------------------
# Chỉ số trang (dots) - dựng động theo số trang
# ---------------------------------------------------------------------------
func _build_dots() -> void:
	if dots_box == null:
		return
	for child in dots_box.get_children():
		dots_box.remove_child(child)
		child.queue_free()

	for index in _page_count:
		var dot := TextureButton.new()
		dot.name = "Dot%d" % (index + 1)
		dot.ignore_texture_size = true
		dot.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		dot.focus_mode = Control.FOCUS_NONE
		dot.pressed.connect(_on_dot_pressed.bind(index))
		dots_box.add_child(dot)

	dots_box.visible = _page_count > 1
	_update_dots()


func _update_dots() -> void:
	if dots_box == null:
		return
	var dots := dots_box.get_children()
	for index in dots.size():
		var dot: TextureButton = dots[index]
		var is_current := index == _page
		dot.texture_normal = DOT_ACTIVE if is_current else DOT_INACTIVE
		dot.custom_minimum_size = DOT_SIZE_ACTIVE if is_current else DOT_SIZE_INACTIVE


func _on_dot_pressed(index: int) -> void:
	Sfx.play(Sfx.PAGE_TURN)
	_go_to_page(index)


# ---------------------------------------------------------------------------
# Điều hướng trang
# ---------------------------------------------------------------------------
func _apply_layout() -> void:
	if scroll == null or pages_host == null:
		return
	_page_width = maxf(scroll.size.x, 1.0)
	for page in pages_host.get_children():
		page.custom_minimum_size = Vector2(_page_width, scroll.size.y)
	_stop_tween()
	scroll.scroll_horizontal = int(float(_page) * _page_width)


func _go_to_page(index: int, animate := true) -> void:
	_page = clampi(index, 0, maxi(_page_count - 1, 0))
	_update_dots()
	if scroll == null or _page_width <= 0.0:
		return

	var target := int(float(_page) * _page_width)
	_stop_tween()
	if not animate:
		scroll.scroll_horizontal = target
		return
	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_property(scroll, "scroll_horizontal", target, SNAP_TIME)


func _stop_tween() -> void:
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null


func _nearest_page() -> int:
	if _page_width <= 0.0:
		return 0
	var raw := float(scroll.scroll_horizontal) / _page_width
	return clampi(int(round(raw)), 0, maxi(_page_count - 1, 0))


func _page_for_level(level_id: int) -> int:
	var list_index := _level_ids.find(level_id)
	if list_index < 0:
		return 0
	return clampi(list_index / CARDS_PER_PAGE, 0, maxi(_page_count - 1, 0))


# ---------------------------------------------------------------------------
# VUỐT ĐỔI TRANG (tự xử lý gesture ở mức _input)
# - Card là Button nên sẽ "ăn" sự kiện kéo -> không thể dựa vào ScrollContainer.
# - `_input` nhận được mọi sự kiện trước GUI => vuốt được kể cả khi bắt đầu trên thẻ.
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
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
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_drag(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_go_to_page(_page + 1)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_go_to_page(_page - 1)


func _begin_drag(pos: Vector2) -> void:
	if scroll == null or _page_count <= 1:
		return
	# Chỉ bắt đầu vuốt khi ngón tay/chuột bắt đầu trong vùng thẻ màn
	if not scroll.get_global_rect().has_point(pos):
		return
	_stop_tween()
	_drag_active = true
	_drag_moved = false
	_drag_start_x = pos.x
	_drag_start_scroll = float(scroll.scroll_horizontal)


func _update_drag(pos: Vector2) -> void:
	if not _drag_active:
		return
	var delta_x := pos.x - _drag_start_x
	if not _drag_moved and absf(delta_x) >= DRAG_THRESHOLD:
		_drag_moved = true
		_scrolling = true          # khoá bấm thẻ trong lúc vuốt
	if not _drag_moved:
		return
	# Kéo nội dung theo tay (kéo sang trái -> xem trang sau)
	scroll.scroll_horizontal = int(_drag_start_scroll - delta_x)
	_lock_clicks()
	var index := _nearest_page()
	if index != _page:
		_page = index
		_update_dots()


func _end_drag() -> void:
	if not _drag_active:
		return
	_drag_active = false
	if not _drag_moved:
		return
	_go_to_page(_nearest_page())
	_lock_clicks()
	_scrolling = false


## Khoá bấm thẻ trong CLICK_LOCK_TIME giây kể từ bây giờ (tránh bấm nhầm sau khi vuốt)
func _lock_clicks() -> void:
	_click_lock_until = _now() + CLICK_LOCK_TIME


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right") or event.is_action_pressed("ui_page_down"):
		_go_to_page(_page + 1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_page_up"):
		_go_to_page(_page - 1)


# ---------------------------------------------------------------------------
# Header + chọn màn
# ---------------------------------------------------------------------------
## Cập nhật số sao tích lũy + nhãn nút "TIẾP TỤC MÀN {0}"
func _refresh_header() -> void:
	var total_stars := 0
	for value in _stars_dict().values():
		total_stars += int(value)

	if lbl_stars != null:
		lbl_stars.text = "%d/%d" % [total_stars, maxi(_level_ids.size(), 1) * 3]
	if lbl_continue != null:
		lbl_continue.text = tr("STR_BTN_CONTINUE_LEVEL").format([_unlocked_level()])


func _on_level_selected(level_id: int) -> void:
	# Bỏ qua cú bấm phát sinh ngay sau thao tác vuốt đổi trang
	if _scrolling or _now() < _click_lock_until:
		return
	var gm := _game_manager()
	if gm != null:
		gm.call("start_level", level_id)
	else:
		Nav.goto_game()


func _on_continue_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var level_id := _unlocked_level()
	var gm := _game_manager()
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", level_id)
	else:
		Nav.goto_game()


func _on_back_pressed() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Back)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm := _game_manager()
	if gm != null:
		gm.call("go_to_main_menu")
	else:
		Nav.goto_main()
