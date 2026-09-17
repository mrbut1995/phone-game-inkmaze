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

## Số thẻ danh hiệu mỗi trang (khe giữa các thẻ nằm trong nodes/archivements/page.tscn)
const CARDS_PER_PAGE := 5
const SNAP_TIME := 0.22
const DRAG_THRESHOLD := 8.0
const CLICK_LOCK_TIME := 0.15

## Tab = "" (TẤT CẢ) + các category của ArchivementManager
const TABS := ["", "levels", "dungeon", "daily", "special"]

@onready var btn_back: TextureButton = $TopBar/Back
@onready var overview_bar: Control = $Sheet/Overview/Bar
@onready var overview_fill: TextureRect = $Sheet/Overview/Bar/Fill
@onready var overview_pct: Label = $Sheet/Overview/Percent
@onready var overview_summary: Label = $Sheet/Overview/Summary
@onready var tabs_box: HBoxContainer = $Sheet/Tabs
@onready var card_area: Control = $Sheet/CardArea
@onready var scroll: ScrollContainer = $Sheet/CardArea/Scroll
@onready var pages_host: HBoxContainer = $Sheet/CardArea/Scroll/Pages
@onready var dots_box: HBoxContainer = $Sheet/Dots
@onready var empty_label: Label = $Sheet/EmptyLabel
@onready var stamp_label: Label = $Sheet/Footer/Stamp/Label

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
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(btn_back)
	_connect_manager()

	Archivement.refresh()
	_build_tabs()
	resized.connect(_apply_layout)
	_reload(true)
	call_deferred("_apply_layout")
	call_deferred("_go_to_page", _page_for_first_claimable(), false)


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
	return overview_summary.text if overview_summary != null else ""


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
	_page_count = maxi(1, int(ceil(float(_entries.size()) / float(CARDS_PER_PAGE))))
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

	if overview_summary != null:
		overview_summary.text = tr("STR_ACH_OVERVIEW_FORMAT").format([
			unlocked, total, Archivement.points()])
	if overview_pct != null:
		overview_pct.text = tr("STR_ACH_PERCENT").format([percent])
	if overview_fill != null and overview_bar != null:
		overview_fill.size.x = maxf((overview_bar.size.x - 2.0) * float(percent) / 100.0, 0.0)
	if stamp_label != null:
		stamp_label.text = tr("STR_ACH_BADGES_FORMAT").format([unlocked, total])


func _build_pages() -> void:
	if pages_host == null:
		return
	for child in pages_host.get_children():
		pages_host.remove_child(child)
		child.queue_free()

	for page_index in _page_count:
		var page := PAGE_SCENE.instantiate() as AchPage
		page.name = "Page%d" % (page_index + 1)
		pages_host.add_child(page)

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

	if empty_label != null:
		empty_label.visible = _entries.is_empty()


func _page_node(index: int) -> Control:
	if pages_host == null or index < 0 or index >= pages_host.get_child_count():
		return null
	return pages_host.get_child(index) as Control


func _on_claim_requested(id: String) -> void:
	if Archivement.claim(id):
		Sfx.play(Sfx.STAMP_IMPACT)
		_refresh_all()


# ---------------------------------------------------------------------------
# Tab phân loại
# ---------------------------------------------------------------------------
func _build_tabs() -> void:
	if tabs_box == null:
		return
	for child in tabs_box.get_children():
		tabs_box.remove_child(child)
		child.queue_free()

	for index in TABS.size():
		var tab := TAB_SCENE.instantiate() as AchTabButton
		tab.name = "Tab%d" % index
		tabs_box.add_child(tab)
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
	if tabs_box == null:
		return
	var tabs := tabs_box.get_children()
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
	if dots_box == null:
		return
	for child in dots_box.get_children():
		dots_box.remove_child(child)
		child.queue_free()

	for index in _page_count:
		var dot := DOT_SCENE.instantiate() as AchPageDot
		dot.name = "Dot%d" % (index + 1)
		dots_box.add_child(dot)
		dot.pressed.connect(_on_dot_pressed.bind(index))

	dots_box.visible = _page_count > 1
	_update_dots()


func _update_dots() -> void:
	if dots_box == null:
		return
	var dots := dots_box.get_children()
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
	return clampi(int(round(float(scroll.scroll_horizontal) / _page_width)), 0, maxi(_page_count - 1, 0))


## Trang chứa danh hiệu đầu tiên đang chờ nhận thưởng (mở Sổ tay là thấy ngay)
func _page_for_first_claimable() -> int:
	for index in _entries.size():
		if bool((_entries[index] as Dictionary).get("claimable", false)):
			return clampi(index / CARDS_PER_PAGE, 0, maxi(_page_count - 1, 0))
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
	if scroll == null or _page_count <= 1:
		return
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
		_lock_clicks()
	if not _drag_moved:
		return
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
	if _drag_moved:
		_go_to_page(_nearest_page(), true)


## Khoá bấm nút trong lúc vuốt (tránh vừa vuốt vừa kích hoạt NHẬN)
func _lock_clicks() -> void:
	_click_lock_until = float(Time.get_ticks_msec()) / 1000.0 + CLICK_LOCK_TIME


func _on_back_pressed() -> void:
	Nav.goto_main()
