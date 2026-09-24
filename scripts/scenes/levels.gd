class_name LevelScenes
extends BaseScene
## ============================================================================
## View Controller: Màn hình Chọn Màn chơi (Level Selection)
## - Danh sách màn lấy từ LevelManager (quét res://resources/levels/level_*.tres)
##   => hỗ trợ NHIỀU HƠN 9 MÀN: chia 9 thẻ/trang, VUỐT NGANG để sang trang mới.
## - CHỈ hiện các màn thuộc CHƯƠNG đang chơi (GameManager.current_chapter); banner
##   trên cùng hiện tên chương + dòng "ĐỔI CHƯƠNG" bấm được (-> màn Chọn Chương).
## - Chỉ số trang (dots) dựng ĐỘNG theo số trang thật; bấm vào dot để nhảy trang.
## - Nút CTA dùng art "thẻ giấy xanh" đúng mockup (common/btn_paper_cta_*).
## Cấu trúc node: CardArea/Scroll/Pages (mỗi trang 1 GridContainer 3x3) + PaginationDots.
## ============================================================================

const LEVEL_CARD_SCENE := preload("res://nodes/level_selection/level_card.tscn")
## Node UI của màn này đều là SCENE riêng (không tạo node bằng code)
const PAGE_SCENE := preload("res://nodes/level_selection/page.tscn")
const DOT_SCENE := preload("res://nodes/level_selection/page_dot.tscn")
## Banner chương: bản thường + bản "focus" (có chương đủ Sao để mở)
const BANNER_NORMAL := preload("res://assets/images/level_selector/chapter_banner.svg")
const BANNER_FOCUS := preload("res://assets/images/level_selector/chapter_banner_focus.svg")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Số thẻ màn chơi mỗi trang bản DỌC (lưới 3×3 nằm trong nodes/level_selection/page.tscn)
const CARDS_PER_PAGE := 9
## Bản NGANG giữ 3 hàng nhưng nở số CỘT theo bề rộng vùng cuộn (⇒ nhiều thẻ/trang hơn)
const ROWS_PER_PAGE := 3
const GRID_COLUMNS_PORTRAIT := 3
## Cỡ 1 thẻ + khe lưới (đọc theo scene nodes/level_selection/page.tscn — dùng để suy số cột)
const CARD_SIZE := Vector2(297.0, 355.0)
const GRID_SEP := Vector2(46.0, 24.0)
const SNAP_TIME := 0.22
## Quãng kéo tối thiểu (px) để tính là VUỐT trang (dưới ngưỡng = bấm vào thẻ)
const DRAG_THRESHOLD := 8.0
## Sau khi vuốt, bỏ qua thao tác bấm thẻ trong bao lâu (giây)
const CLICK_LOCK_TIME := 0.15

## Node UI gắn lại mỗi lần ĐỔI HƯỚNG (2 layout dùng CÙNG tên node)
## Bố cục đang hiển thị = script `LevelsLayout` gắn trong `scenes/layout/<hướng>/levels.tscn`.
## Node UI được BIND SẴN bằng `@export` ngay trong .tscn nên code không tra đường dẫn nữa.
var layout: LevelsLayout = null

var _current_columns := GRID_COLUMNS_PORTRAIT
var _level_ids: Array[int] = []
var _level_data: Dictionary = {}        # level_id -> LevelData (chỉ các file có thật)
var _banner_focus := false
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
	_bind_refs()
	_wire_buttons()
	resized.connect(_apply_layout)
	orientation_changed.connect(_on_orientation_changed)

	_build_pages()
	_build_dots()
	_refresh_header()
	# Đợi layout xong mới biết bề rộng trang -> căn trang + nhảy tới màn đang chơi
	call_deferred("_apply_layout")
	call_deferred("_go_to_page", _page_for_level(chapter_continue_level()), false)


## Gắn node UI từ BỐ CỤC đang hiển thị (bản dọc / bản ngang là 2 scene riêng nhưng CÙNG script
## `LevelsLayout`) — mọi node đã bind bằng `@export` trong .tscn, thêm/đổi node chỉ cần sửa
## scene + export, KHÔNG phải sửa script màn.
func _bind_refs() -> void:
	layout = active_layout() as LevelsLayout
	if layout == null:
		push_warning("LevelScenes: bố cục chưa gắn LevelsLayout — thiếu binding trong scenes/layout/<hướng>/levels.tscn")


## Nối signal + hiệu ứng (gọi lại được khi xoay màn hình, không nhân đôi connection)
func _wire_buttons() -> void:
	if layout.btn_back != null:
		if not layout.btn_back.pressed.is_connected(_on_back_pressed):
			layout.btn_back.pressed.connect(_on_back_pressed)
		if not layout.btn_back.has_meta("bounce_attached"):
			layout.btn_back.set_meta("bounce_attached", true)
			UIAnim.attach_press_bounce(layout.btn_back)
	if layout.btn_continue != null:
		if not layout.btn_continue.pressed.is_connected(_on_continue_pressed):
			layout.btn_continue.pressed.connect(_on_continue_pressed)
		if not layout.btn_continue.has_meta("bounce_attached"):
			layout.btn_continue.set_meta("bounce_attached", true)
			UIAnim.attach_press_bounce(layout.btn_continue)
			UIAnim.play_pulse(layout.btn_continue, 1.03, 1.8)
	# Nhãn "ĐỔI CHƯƠNG" chỉ để trang trí: bấm Ở ĐÂU trên banner cũng mở màn Chọn Chương
	if layout.lbl_change_chapter != null:
		layout.lbl_change_chapter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if layout.banner != null:
		layout.banner.mouse_filter = Control.MOUSE_FILTER_STOP
		if not layout.banner.gui_input.is_connected(_on_banner_input):
			layout.banner.gui_input.connect(_on_banner_input)


## Số thẻ mỗi trang: bản DỌC giữ 3×3 = 9; bản NGANG nở số cột theo bề rộng vùng cuộn
func _cards_per_page() -> int:
	return _columns_per_page() * ROWS_PER_PAGE


func _columns_per_page() -> int:
	if not is_landscape:
		return GRID_COLUMNS_PORTRAIT
	var width := layout.scroll.size.x if layout.scroll != null else 0.0
	if width <= 0.0:
		return GRID_COLUMNS_PORTRAIT
	var columns := int((width + GRID_SEP.x * 0.5) / (CARD_SIZE.x + GRID_SEP.x))
	return clampi(columns, GRID_COLUMNS_PORTRAIT, 8)


## Xoay màn hình: gắn lại node của layout mới rồi dựng lại trang + nạp lại header
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	_wire_buttons()
	_current_columns = _columns_per_page()
	_build_pages()
	_build_dots()
	_refresh_header()
	_apply_layout()
	_go_to_page(_page_for_level(chapter_continue_level()), false)


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
	if layout.pages_host == null:
		return

	for child in layout.pages_host.get_children():
		layout.pages_host.remove_child(child)
		child.queue_free()

	_load_level_ids()
	_page_count = maxi(1, int(ceil(float(_level_ids.size()) / float(_cards_per_page()))))

	var unlocked := _unlocked_level()
	var stars_dict := _stars_dict()
	var chapter_seen: Dictionary = {}      # chapter -> số màn đã đếm (để hiện 1-1, 1-2...)

	for page_index in _page_count:
		var page := PAGE_SCENE.instantiate() as LevelsPage
		page.name = "Page%d" % (page_index + 1)
		layout.pages_host.add_child(page)

		var grid := page.grid()
		grid.columns = _columns_per_page()

		for slot in _cards_per_page():
			var list_index := page_index * _cards_per_page() + slot
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
		_filter_by_chapter()

	if _level_ids.is_empty():
		# Không có LevelManager (test/--script): giữ hành vi cũ 9 màn chương 1
		for level_id in range(1, 10):
			_level_ids.append(level_id)


## Chỉ giữ các màn thuộc CHƯƠNG đang chơi (GameManager.current_chapter).
## Chương rỗng / không có màn nào -> giữ toàn bộ để không chặn người chơi.
func _filter_by_chapter() -> void:
	var chapter := _current_chapter()
	if chapter <= 0:
		return
	var filtered: Array[int] = []
	for level_id in _level_ids:
		if _chapter_of(level_id) == chapter:
			filtered.append(level_id)
	if not filtered.is_empty():
		_level_ids = filtered


## Chương đang chơi (0 = không có GameManager -> hiện tất cả)
func _current_chapter() -> int:
	var gm := _game_manager()
	if gm == null:
		return 0
	var value: Variant = gm.get("current_chapter")
	return maxi(int(value), 0) if value != null else 0


## Tên chương để hiện trên banner ("CHƯƠNG 2: SUY LUẬN")
func chapter_title() -> String:
	var chapter := _chapter_data()
	if chapter == null:
		return ""
	return TranslationServer.translate("STR_CHAPTER_TITLE_FORMAT").format([chapter.chapter_id, chapter.title])


func _chapter_data() -> ChapterData:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_chapter"):
		return null
	var chapter := _current_chapter()
	if chapter <= 0:
		chapter = 1
	return lm.call("get_chapter", chapter) as ChapterData


func _chapter_of(level_id: int) -> int:
	var data: LevelData = _level_data.get(level_id, null)
	return maxi(data.chapter, 1) if data != null else 1


func _unlocked_level() -> int:
	var gm := _game_manager()
	return maxi(int(gm.get("unlocked_levels")), 1) if gm != null else 1


## Màn "nên chơi tiếp" TRONG chương đang xem: màn CHƯA đạt sao đầu tiên (xong hết -> màn cuối)
func chapter_continue_level() -> int:
	var stars := _stars_dict()
	for level_id in _level_ids:
		if int(stars.get(level_id, 0)) <= 0:
			return level_id
	return _level_ids[_level_ids.size() - 1] if not _level_ids.is_empty() else 1


## Chương đang xem đã hoàn thành HẾT màn chưa (mọi màn đều có ít nhất 1 sao)
func chapter_cleared() -> bool:
	var stars := _stars_dict()
	for level_id in _level_ids:
		if int(stars.get(level_id, 0)) <= 0:
			return false
	return not _level_ids.is_empty()


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
	if layout.dots_box == null:
		return
	for child in layout.dots_box.get_children():
		layout.dots_box.remove_child(child)
		child.queue_free()

	for index in _page_count:
		var dot := DOT_SCENE.instantiate() as LevelsPageDot
		dot.name = "Dot%d" % (index + 1)
		layout.dots_box.add_child(dot)
		dot.pressed.connect(_on_dot_pressed.bind(index))

	layout.dots_box.visible = _page_count > 1
	_update_dots()


func _update_dots() -> void:
	if layout.dots_box == null:
		return
	var dots := layout.dots_box.get_children()
	for index in dots.size():
		var dot := dots[index] as LevelsPageDot
		if dot != null:
			dot.set_current(index == _page)


func _on_dot_pressed(index: int) -> void:
	Sfx.play(Sfx.PAGE_TURN)
	_go_to_page(index)


# ---------------------------------------------------------------------------
# Điều hướng trang
# ---------------------------------------------------------------------------
func _apply_layout() -> void:
	if layout.scroll == null or layout.pages_host == null:
		return
	var columns := _columns_per_page()
	if columns != _current_columns:
		# Bề rộng vùng cuộn đổi (xoay màn hình) -> chia lại trang theo số cột mới
		_current_columns = columns
		_build_pages()
		_build_dots()
		_refresh_header()
	_page = clampi(_page, 0, maxi(_page_count - 1, 0))
	_page_width = maxf(layout.scroll.size.x, 1.0)
	for page in layout.pages_host.get_children():
		page.custom_minimum_size = Vector2(_page_width, layout.scroll.size.y)
	_stop_tween()
	layout.scroll.scroll_horizontal = int(float(_page) * _page_width)


func _go_to_page(index: int, animate := true) -> void:
	_page = clampi(index, 0, maxi(_page_count - 1, 0))
	_update_dots()
	if layout.scroll == null or _page_width <= 0.0:
		return

	var target := int(float(_page) * _page_width)
	_stop_tween()
	if not animate:
		layout.scroll.scroll_horizontal = target
		return
	_scroll_tween = create_tween()
	_scroll_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_scroll_tween.tween_property(layout.scroll, "scroll_horizontal", target, SNAP_TIME)


func _stop_tween() -> void:
	if _scroll_tween != null and _scroll_tween.is_valid():
		_scroll_tween.kill()
	_scroll_tween = null


func _nearest_page() -> int:
	if _page_width <= 0.0:
		return 0
	var raw := float(layout.scroll.scroll_horizontal) / _page_width
	return clampi(int(round(raw)), 0, maxi(_page_count - 1, 0))


func _page_for_level(level_id: int) -> int:
	var list_index := _level_ids.find(level_id)
	if list_index < 0:
		return 0
	return clampi(list_index / _cards_per_page(), 0, maxi(_page_count - 1, 0))


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
	if layout.scroll == null or _page_count <= 1:
		return
	# Chỉ bắt đầu vuốt khi ngón tay/chuột bắt đầu trong vùng thẻ màn
	if not layout.scroll.get_global_rect().has_point(pos):
		return
	_stop_tween()
	_drag_active = true
	_drag_moved = false
	_drag_start_x = pos.x
	_drag_start_scroll = float(layout.scroll.scroll_horizontal)


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
	layout.scroll.scroll_horizontal = int(_drag_start_scroll - delta_x)
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
## Cập nhật số Sao CỦA CHƯƠNG + banner chương + nhãn nút "TIẾP TỤC MÀN {0}"
func _refresh_header() -> void:
	var chapter := _chapter_data()
	var own := 0
	var total := maxi(_level_ids.size(), 1) * 3
	var lm: Node = get_node_or_null("/root/LevelManager")
	if chapter != null and lm != null and lm.has_method("chapter_stars"):
		# Số sao hiển thị là sao ĐẠT ĐƯỢC TRONG CHƯƠNG này (trước đây lấy tổng mọi chương
		# nhưng chia cho tối đa của 1 chương -> ra "30/27" sai)
		own = int(lm.call("chapter_stars", chapter.chapter_id))
		total = maxi(int(lm.call("chapter_star_total", chapter.chapter_id)), 1)
	else:
		for value in _stars_dict().values():
			own += int(value)

	if layout.lbl_stars != null:
		layout.lbl_stars.text = "%d/%d" % [own, total]
	if layout.lbl_chapter != null:
		var title := chapter_title()
		if not title.is_empty():
			layout.lbl_chapter.text = title
	_refresh_chapter_banner()
	if layout.lbl_continue != null:
		layout.lbl_continue.text = TranslationServer.translate("STR_CHAPTER_SCREEN_TITLE") if chapter_cleared() \
			else tr("STR_BTN_CONTINUE_LEVEL").format([chapter_continue_level()])


## Banner chương: có chương ĐỦ Sao để mở -> đổi sang art "focus" + nhấp nháy + đổi dòng gợi ý
func _refresh_chapter_banner() -> void:
	var gm := _game_manager()
	var unlockable := gm != null and gm.has_method("has_unlockable_chapter") \
		and bool(gm.call("has_unlockable_chapter"))
	if unlockable != _banner_focus:
		_banner_focus = unlockable
		if layout.banner != null:
			layout.banner.texture = BANNER_FOCUS if unlockable else BANNER_NORMAL
		if layout.lbl_change_chapter != null:
			layout.lbl_change_chapter.theme_type_variation = &"LevelsChangeChapterFocus" if unlockable \
				else &"LevelsChangeChapter"
		if unlockable and layout.banner != null:
			UIAnim.play_pulse(layout.banner, 1.02, 1.6)
	if layout.lbl_change_chapter != null:
		layout.lbl_change_chapter.text = TranslationServer.translate(
			"STR_CHAPTER_UNLOCKABLE" if unlockable else "STR_CHANGE_CHAPTER")


## Bấm vào BANNER CHƯƠNG (bất kỳ chỗ nào) -> sang màn Chọn Chương
func _on_banner_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		Nav.goto_chapters()


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
	var gm := _game_manager()
	if chapter_cleared():
		# Đã xong hết màn của chương -> mời sang màn Chọn Chương để mở chương mới
		Nav.goto_chapters()
		return
	var level_id := chapter_continue_level()
	if gm != null and level_id <= _unlocked_level() and gm.has_method("start_level"):
		gm.call("start_level", level_id)
	elif gm != null:
		# Màn chưa mở (ví dụ chương chưa unlock) -> về màn Chọn Chương thay vì nhảy màn sai
		Nav.goto_chapters()
	else:
		Nav.goto_game()


func _on_back_pressed() -> void:
	# SFX: gõ thẻ giấy cho nút phụ (Back)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	# Màn Chọn màn là màn CHÍNH khi bấm CHƠI -> Back quay về Main
	Nav.goto_main()
