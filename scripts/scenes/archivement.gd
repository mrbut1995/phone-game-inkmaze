class_name ArchivementScene
extends BaseScene
## ============================================================================
## View Controller: "Sổ tay thành tựu" (scenes/archivement.tscn)
##
## - Danh sách danh hiệu lấy từ ArchivementManager (quét resources/archivements/*.tres)
##   => khi có NHIỀU danh hiệu: chia 5 thẻ/trang + VUỐT NGANG đổi trang + dots (giống màn Chọn màn).
## - 5 tab phân loại: TẤT CẢ · MÀN CHƠI · DUNGEON · DAILY · ĐẶC BIỆT (dựng lại trang theo tab).
## - Thẻ tổng kết: thanh tiến độ % đã mở khoá + "Đã mở: x / y Danh hiệu • Điểm: n AP".
## - Bấm "NHẬN +N" trên thẻ đủ điều kiện -> ArchivementManager.claim() -> vẽ lại + cập nhật tổng kết.
##
## Cấu trúc node (scenes/archivement.tscn): TopBar/Sheet{Overview, Tabs, CardArea{Scroll/Pages}, Dots, Footer}
## ============================================================================

const CARD_SCENE := preload("res://nodes/archivements/card.tscn")
## Node UI của màn này đều là SCENE riêng (không tạo node bằng code)
const TAB_SCENE := preload("res://nodes/archivements/tab_button.tscn")
const PAGE_SCENE := preload("res://nodes/archivements/page.tscn")
const DOT_SCENE := preload("res://nodes/archivements/page_dot.tscn")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Số thẻ danh hiệu mỗi trang ở bản DỌC (1 cột × 5 hàng — khe nằm trong nodes/archivements/page.tscn)
const CARDS_PER_PAGE := 5
## Bản NGANG: lưới nhiều cột (thẻ 710px) × số hàng vừa khung cuộn
const PORTRAIT_COLUMNS := 1
const CARD_SIZE := Vector2(710.0, 170.0)
const GRID_SEP := Vector2(20.0, 20.0)
const SNAP_TIME := 0.22
const DRAG_THRESHOLD := 8.0
const CLICK_LOCK_TIME := 0.15

## Tab = "" (TẤT CẢ) + các category của ArchivementManager
const TABS := ["", "levels", "dungeon", "daily", "special"]

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/archivement.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: ArchivementLayout = null

var _current_columns := PORTRAIT_COLUMNS

var _category := ""
var _entries: Array = []
var _page := 0
var _page_count := 1
var _page_width := 0.0
var _scroll_tween: Tween = null
var _click_lock_until := 0.0
var _drag_active := false
var _drag_moved := false
var _drag_start_x := 0.0
var _drag_start_scroll := 0.0


func _ready() -> void:
	_bind_refs()
	if layout.btn_back != null:
		layout.btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(layout.btn_back)
	_connect_manager()
	orientation_changed.connect(_on_orientation_changed)

	Archivement.refresh()
	_build_tabs()
	resized.connect(_apply_layout)
	_reload(true)
	call_deferred("_apply_layout")
	call_deferred("_go_to_page", _page_for_first_claimable(), false)


## Gắn node của layout đang hiển thị (2 layout giữ cùng đường dẫn nên dùng `ui_path`)
func _bind_refs() -> void:
	layout = active_layout() as ArchivementLayout
	if layout == null:
		push_warning("archivement: bố cục chưa gắn ArchivementLayout — thiếu binding trong scenes/layout/<hướng>/archivement.tscn")


## Số thẻ mỗi trang: bản DỌC = 5 (1 cột × 5 hàng); bản NGANG = lưới nhiều cột × số hàng vừa khung
func _cards_per_page() -> int:
	return _columns_per_page() * _rows_per_page()


func _columns_per_page() -> int:
	if not is_landscape:
		return PORTRAIT_COLUMNS
	var width := layout.scroll.size.x if layout.scroll != null else 0.0
	if width <= 0.0:
		return PORTRAIT_COLUMNS
	var columns := int((width + GRID_SEP.x * 0.5) / (CARD_SIZE.x + GRID_SEP.x))
	return clampi(columns, 1, 5)


func _rows_per_page() -> int:
	if not is_landscape:
		return CARDS_PER_PAGE
	var height := layout.scroll.size.y if layout.scroll != null else 0.0
	if height <= 0.0:
		return 3
	var rows := int((height + GRID_SEP.y * 0.5) / (CARD_SIZE.y + GRID_SEP.y))
	return clampi(rows, 2, 6)


## Xoay màn hình: gắn lại node của layout mới rồi chia lại trang theo số cột mới
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	_current_columns = _columns_per_page()
	_reload(true)
	_apply_layout()
	_go_to_page(_page_for_first_claimable(), false)


# ---------------------------------------------------------------------------
# API cho test / điều khiển từ ngoài
# ---------------------------------------------------------------------------
func current_category() -> String:
	return _category


func set_category(category: String, animate := false) -> void:
	_category = category if TABS.has(category) else ""
	_update_tabs()
	_reload(false)
	_go_to_page(_page_for_first_claimable(), animate)


func page_count() -> int:
	return _page_count


func current_page() -> int:
	return _page


func entry_count() -> int:
	return _entries.size()


func cards_on_page(page_index: int) -> int:
	var page := _page_node(page_index)
	if page == null:
		return 0
	return page.get_child(0).get_child_count() if page.get_child_count() > 0 else 0

func go_to_page(index: int, animate := true) -> void:
	_go_to_page(index, animate)


func overview_text() -> String:
	return layout.overview_summary.text if layout.overview_summary != null else ""


# ---------------------------------------------------------------------------
# Dựng nội dung
# ---------------------------------------------------------------------------
func _connect_manager() -> void:
	var manager := Archivement.manager()
	if manager != null and manager.has_signal("progress_changed"):
		if not manager.is_connected("progress_changed", _on_manager_changed):
			manager.connect("progress_changed", _on_manager_changed)


func _on_manager_changed() -> void:
	# Tránh dựng lại ngay giữa lúc đang bấm nút NHẬN
	call_deferred("_refresh_all")


func _refresh_all() -> void:
	if not is_inside_tree():
		return
	_reload(true)


func _reload(keep_page: bool) -> void:
	_entries = Archivement.entries(_category)
	_page_count = maxi(1, int(ceil(float(_entries.size()) / float(_cards_per_page()))))
	if not keep_page:
		_page = 0
	_page = clampi(_page, 0, _page_count - 1)

	_refresh_overview()
	_build_pages()
	_build_dots()
	_apply_layout()


func _refresh_overview() -> void:
	var total := Archivement.total_count()
	var unlocked := Archivement.unlocked_count()
	var percent := Archivement.unlocked_percent()

	if layout.overview_summary != null:
		layout.overview_summary.text = tr("STR_ACH_OVERVIEW_FORMAT").format([
			unlocked, total, Archivement.points()])
	if layout.overview_pct != null:
		layout.overview_pct.text = tr("STR_ACH_PERCENT").format([percent])
	if layout.overview_fill != null and layout.overview_bar != null:
		layout.overview_fill.size.x = maxf((layout.overview_bar.size.x - 2.0) * float(percent) / 100.0, 0.0)
	if layout.stamp_label != null:
		layout.stamp_label.text = tr("STR_ACH_BADGES_FORMAT").format([unlocked, total])


func _build_pages() -> void:
	if layout.pages_host == null:
		return
	for child in layout.pages_host.get_children():
		layout.pages_host.remove_child(child)
		child.queue_free()

	for page_index in _page_count:
		var page := PAGE_SCENE.instantiate() as AchPage
		page.name = "Page%d" % (page_index + 1)
		layout.pages_host.add_child(page)

		var column := page.column()
		for slot in CARDS_PER_PAGE:
			var list_index := page_index * CARDS_PER_PAGE + slot
			if list_index >= _entries.size():
				break
			var card: Control = CARD_SCENE.instantiate()
			column.add_child(card)
			if card.has_method("setup"):
				card.call("setup", _entries[list_index])
			if card.has_signal("claim_requested"):
				card.connect("claim_requested", _on_claim_requested)
			UIAnim.play_pop_in(card, 0.02 * slot, 0.9, 0.18)

	if layout.empty_label != null:
		layout.empty_label.visible = _entries.is_empty()


func _page_node(index: int) -> Control:
	if layout.pages_host == null or index < 0 or index >= layout.pages_host.get_child_count():
		return null
	return layout.pages_host.get_child(index) as Control


func _on_claim_requested(id: String) -> void:
	if Archivement.claim(id):
		Sfx.play(Sfx.STAMP_IMPACT)
		_refresh_all()


# ---------------------------------------------------------------------------
# Tab phân loại
# ---------------------------------------------------------------------------
func _build_tabs() -> void:
	if layout.tabs_box == null:
		return
	for child in layout.tabs_box.get_children():
		layout.tabs_box.remove_child(child)
		child.queue_free()

	for index in TABS.size():
		var tab := TAB_SCENE.instantiate() as AchTabButton
		tab.name = "Tab%d" % index
		layout.tabs_box.add_child(tab)
		tab.setup(TABS[index])
		tab.pressed.connect(_on_tab_pressed.bind(TABS[index]))

	_update_tabs()


func _tab_text(category: String) -> String:
	match category:
		"":
			return tr("STR_ACH_TAB_ALL").format([Archivement.total_count()])
		"levels":
			return tr("STR_ACH_TAB_LEVELS")
		"dungeon":
			return tr("STR_ACH_TAB_DUNGEON")
		"daily":
			return tr("STR_ACH_TAB_DAILY")
		_:
			return tr("STR_ACH_TAB_SPECIAL")


func _update_tabs() -> void:
	if layout.tabs_box == null:
		return
	var tabs := layout.tabs_box.get_children()
	for index in tabs.size():
		var tab := tabs[index] as AchTabButton
		if tab == null:
			continue
		var category: String = TABS[index]
		tab.set_label_text(_tab_text(category))
		tab.set_active(category == _category)


func _on_tab_pressed(category: String) -> void:
	Sfx.play(Sfx.PAGE_TURN)
	set_category(category)


# ---------------------------------------------------------------------------
# Chỉ số trang (dots)
# ---------------------------------------------------------------------------
func _build_dots() -> void:
	if layout.dots_box == null:
		return
	for child in layout.dots_box.get_children():
		layout.dots_box.remove_child(child)
		child.queue_free()

	for index in _page_count:
		var dot := DOT_SCENE.instantiate() as AchPageDot
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
		var dot := dots[index] as AchPageDot
		if dot != null:
			dot.set_current(index == _page)


func _on_dot_pressed(index: int) -> void:
	Sfx.play(Sfx.PAGE_TURN)
	_go_to_page(index)


# ---------------------------------------------------------------------------
# Điều hướng trang (giống màn Chọn màn: trang rộng bằng khung + vuốt ngang)
# ---------------------------------------------------------------------------
func _apply_layout() -> void:
	if layout.scroll == null or layout.pages_host == null:
		return
	var columns := _columns_per_page()
	if columns != _current_columns:
		# Khung cuộn đổi bề rộng (xoay màn hình) -> chia lại trang theo số cột mới
		_current_columns = columns
		_reload(true)
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
	return clampi(int(round(float(layout.scroll.scroll_horizontal) / _page_width)), 0, maxi(_page_count - 1, 0))


## Trang chứa danh hiệu đầu tiên đang chờ nhận thưởng (mở Sổ tay là thấy ngay)
func _page_for_first_claimable() -> int:
	var per_page := maxi(_cards_per_page(), 1)
	for index in _entries.size():
		if bool((_entries[index] as Dictionary).get("claimable", false)):
			return clampi(index / per_page, 0, maxi(_page_count - 1, 0))
	return 0


# ---------------------------------------------------------------------------
# Vuốt đổi trang (tự xử lý gesture: thẻ là Button nên "ăn" sự kiện kéo)
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
		_lock_clicks()
	if not _drag_moved:
		return
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
	if _drag_moved:
		_go_to_page(_nearest_page(), true)


## Khoá bấm nút trong lúc vuốt (tránh vừa vuốt vừa kích hoạt NHẬN)
func _lock_clicks() -> void:
	_click_lock_until = float(Time.get_ticks_msec()) / 1000.0 + CLICK_LOCK_TIME


func _on_back_pressed() -> void:
	Nav.goto_main()
