class_name InstructionPopup
extends BasePopup
## ============================================================================
## Popup HƯỚNG DẪN CHƠI theo từng chế độ — 9 scene riêng trong
## `nodes/popups/instruction/<mode>.tscn`, mỗi scene 3 trang (Page1..Page3).
##
## Bố cục scene (instance của base.tscn, Panel override thành tờ giấy 920×1480):
##
##   Panel/Guide                      ← khung giấy, DÙNG CHUNG cho cả 3 trang
##     ├── Washi · Paper · PaperDetail · Close
##     ├── Chip + ChipText
##     ├── Tabs/Tab1..3               (tab + vòng số — đổi màu theo trang)
##     ├── Pages/Page1..3             ← phần NỘI DUNG riêng từng trang
##     │     └── Img · các Label chữ trên ảnh · Title · Section ·
##     │         3 hàng luật Row1..3 · Cta · Link
##     ├── Prev · Next                (‹ › — khoá ở trang đầu/cuối)
##     ├── Dots/Dot1..3               (script dàn lại vị trí theo trang)
##     └── Index                      ("TRANG x / 3")
##
## Vì sao Cta/Link nằm TRONG từng trang? Vì mockup vẽ chúng khác nhau mỗi
## trang (trang cuối CTA đậm hơn, link "bỏ qua" khác link "xem lại").
##
## Quy ước dữ liệu:
##   - Số/ký hiệu trên grid (1 · 2 · 15 · 01:24 · = · ? · S · F…) ghi TRỰC TIẾP.
##   - Chữ có nghĩa dùng khoá dịch STR_GI_* (auto_translate); số trang format
##     lúc chạy từ STR_GI_PAGE_INDEX.
##   - Style tab/dot (đang chọn + thường) nướng vào scene qua các @export dưới.
##
## Mở bằng: Popups.open_path("res://nodes/popups/instruction/dungeon.tscn").
## ============================================================================

const DRAG_THRESHOLD := 14.0    ## ngưỡng kéo (px) để tính là VUỐT chứ không phải bấm
const SWIPE_DISTANCE := 90.0    ## quãng vuốt (px) để lật trang
const FADE_TIME := 0.16
## Dàn dots: dot đang chọn rộng 38x18 (viên thuốc), dot thường 16x16 (chấm tròn),
## hàng bắt đầu ở mép trái dot đầu tiên (lấy từ scene) — đúng như mockup.
const DOT_ON_SIZE := Vector2(38.0, 18.0)
const DOT_OFF_SIZE := Vector2(16.0, 16.0)
const DOT_GAP := 12.0

## Style/màu tab do generator nướng sẵn từng scene (xem build_shared_styles)
@export var tab_on_style: StyleBoxFlat
@export var tab_off_style: StyleBoxFlat
@export var tab_on_ring_style: StyleBoxFlat
@export var tab_off_ring_style: StyleBoxFlat
@export var tab_on_text_color := Color("#FFFFFF")
@export var tab_off_text_color := Color("#718B9E")
## Style dot đang chọn / dot thường
@export var dot_on_style: StyleBoxFlat
@export var dot_off_style: StyleBoxFlat

var _pages: Array[Control] = []
var _page := 0
var _tabs: Array = []
var _dots: Array = []
var _prev: Button = null
var _next: Button = null
var _index: Label = null
var _dots_x0 := 0.0
var _dots_cy := 0.0

var _drag_active := false
var _drag_moved := false
var _drag_start := Vector2.ZERO


# ---------------------------------------------------------------------------
# Vòng đời
# ---------------------------------------------------------------------------
func _ready() -> void:
	_collect_nodes()
	_connect_buttons()
	_show_page(_page, false)


func _on_open() -> void:
	_collect_nodes()
	_connect_buttons()
	_page = clampi(int(data.get("page", 0)), 0, maxi(_pages.size() - 1, 0))
	_show_page(_page, false)


# ---------------------------------------------------------------------------
# API cho test
# ---------------------------------------------------------------------------
## Số trang của popup (3 với mọi chế độ hiện tại)
func page_count() -> int:
	return _pages.size()


## Trang đang hiển thị (0-based)
func current_page() -> int:
	return _page


## Nhảy tới trang chỉ định (kẹp trong khoảng hợp lệ)
func go_to_page(index: int) -> void:
	if _pages.is_empty():
		return
	_show_page(clampi(index, 0, _pages.size() - 1), true)


func next_page() -> void:
	go_to_page(_page + 1)


func prev_page() -> void:
	go_to_page(_page - 1)


## Số tab của hàng tab dùng chung
func tab_count() -> int:
	return _tabs.size()


## Chữ (đã dịch) của tab thứ `index` (0-based)
func tab_label(index: int) -> String:
	if index < 0 or index >= _tabs.size():
		return ""
	var node: Node = _tabs[index]
	if node == null:
		return ""
	var lbl := node.get_node_or_null("Label") as Label
	if lbl == null:
		return ""
	return _resolve(lbl.text)


## Chữ (đã dịch) trên nút CTA của trang đang xem
func cta_text() -> String:
	var btn := _child_of(_page, "Cta") as Button
	return _resolve(btn.text) if btn != null else ""


## Chữ (đã dịch) của link "bỏ qua / xem lại" trên trang đang xem
func link_text() -> String:
	var btn := _child_of(_page, "Link") as Button
	return _resolve(btn.text) if btn != null else ""


## Nhãn "TRANG x / 3" đang hiển thị (đã dịch + format)
func page_index_text() -> String:
	return _index.text if _index != null else ""


## Tiêu đề (đã dịch) của trang đang xem
func page_title() -> String:
	var lbl := _child_of(_page, "Title") as Label
	return _resolve(lbl.text) if lbl != null else ""


## Nút Previous có bị khoá không (trang đầu khoá)
func is_prev_locked() -> bool:
	return _prev == null or _prev.disabled


## Nút Next có bị khoá không (trang cuối khoá)
func is_next_locked() -> bool:
	return _next == null or _next.disabled


## Nút CTA của trang đang xem (để test bấm trực tiếp)
func cta_button() -> Button:
	return _child_of(_page, "Cta") as Button


## Nút link của trang đang xem
func link_button() -> Button:
	return _child_of(_page, "Link") as Button


## Nút đóng của popup
func close_button() -> Button:
	return get_node_or_null("Panel/Guide/Close") as Button


# ---------------------------------------------------------------------------
# Thu thập node / nối nút
# ---------------------------------------------------------------------------
func _collect_nodes() -> void:
	var root := get_node_or_null("Panel/Guide")
	_pages.clear()
	_tabs.clear()
	_dots.clear()
	if root == null:
		return
	var pages_root := root.get_node_or_null("Pages")
	if pages_root != null:
		for child in pages_root.get_children():
			if child is Control:
				_pages.append(child)
	var tabs_root := root.get_node_or_null("Tabs")
	if tabs_root != null:
		for child in tabs_root.get_children():
			if child is BaseButton:
				_tabs.append(child)
	var dots_root := root.get_node_or_null("Dots")
	if dots_root != null:
		for child in dots_root.get_children():
			if child is BaseButton:
				_dots.append(child)
		if not _dots.is_empty():
			var first := _dots[0] as Control
			_dots_x0 = first.position.x
			_dots_cy = first.position.y + first.size.y * 0.5
	_prev = root.get_node_or_null("Prev") as Button
	_next = root.get_node_or_null("Next") as Button
	_index = root.get_node_or_null("Index") as Label


func _connect_buttons() -> void:
	var close_btn := close_button()
	if close_btn != null and not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)
	_connect(_prev, _on_prev_pressed)
	_connect(_next, _on_next_pressed)
	for i in _tabs.size():
		_connect(_tabs[i], _on_tab_pressed.bind(i))
	for i in _dots.size():
		_connect(_dots[i], _on_tab_pressed.bind(i))
	# Cta/Link nằm trong TỪNG trang (mockup vẽ khác nhau mỗi trang)
	for i in _pages.size():
		_connect(_pages[i].get_node_or_null("Cta"), _on_cta_pressed)
		_connect(_pages[i].get_node_or_null("Link"), _on_link_pressed)


func _connect(node: Node, handler: Callable) -> void:
	if node == null:
		return
	var btn := node as BaseButton
	if btn != null and not btn.pressed.is_connected(handler):
		btn.pressed.connect(handler)


# ---------------------------------------------------------------------------
# Chuyển trang + cập nhật trạng thái chrome dùng chung
# ---------------------------------------------------------------------------
func _show_page(index: int, animate: bool) -> void:
	if _pages.is_empty():
		return
	_page = clampi(index, 0, _pages.size() - 1)
	for i in _pages.size():
		var page := _pages[i]
		var on := i == _page
		page.visible = on
		if on and animate:
			var tw := create_tween()
			tw.tween_property(page, "modulate:a", 1.0, FADE_TIME).from(0.25)
	_update_tabs()
	_update_nav()
	_update_dots()
	_update_index()


## Tab đang chọn đổi sang style/màu "đang chọn" (nướng sẵn trong scene)
func _update_tabs() -> void:
	for i in _tabs.size():
		var tab := _tabs[i] as Button
		if tab == null:
			continue
		var on := i == _page
		var sb: StyleBox = tab_on_style if on else tab_off_style
		if sb != null:
			for state in ["normal", "hover", "pressed"]:
				tab.add_theme_stylebox_override(state, sb)
		var ring := tab.get_node_or_null("Ring") as Panel
		if ring != null:
			var ring_sb: StyleBox = tab_on_ring_style if on else tab_off_ring_style
			if ring_sb != null:
				ring.add_theme_stylebox_override("panel", ring_sb)
		var color := tab_on_text_color if on else tab_off_text_color
		var lbl := tab.get_node_or_null("Label") as Label
		if lbl != null:
			lbl.add_theme_color_override("font_color", color)
		var num := tab.get_node_or_null("Num") as Label
		if num != null:
			num.add_theme_color_override("font_color", color)


## Cuối/đầu danh sách thì nút tương ứng bị khoá (style mờ đã nướng sẵn)
func _update_nav() -> void:
	if _prev != null:
		_prev.disabled = _page <= 0
	if _next != null:
		_next.disabled = _page >= _pages.size() - 1


## Dot đang chọn phình thành viên thuốc, các dot khác co về chấm tròn;
## hàng dots canh trái từ mép dot đầu (đúng như mockup ở cả 3 trang).
func _update_dots() -> void:
	var x := _dots_x0
	for i in _dots.size():
		var dot := _dots[i] as Button
		if dot == null:
			continue
		var on := i == _page
		var size := DOT_ON_SIZE if on else DOT_OFF_SIZE
		var sb: StyleBox = dot_on_style if on else dot_off_style
		if sb != null:
			for state in ["normal", "hover", "pressed"]:
				dot.add_theme_stylebox_override(state, sb)
		dot.size = size
		dot.position = Vector2(x, _dots_cy - size.y * 0.5)
		x += size.x + DOT_GAP


func _update_index() -> void:
	if _index != null:
		_index.text = tr("STR_GI_PAGE_INDEX").format([_page + 1, _pages.size()])


# ---------------------------------------------------------------------------
# Tiện ích node
# ---------------------------------------------------------------------------
func _child_of(page_index: int, child_name: String) -> Node:
	if page_index < 0 or page_index >= _pages.size():
		return null
	return _pages[page_index].get_node_or_null(child_name)


## Trả về bản dịch của một chuỗi: nếu là khoá STR_* thì dịch, ngược lại giữ nguyên
func _resolve(text: String) -> String:
	if text.begins_with("STR_"):
		var t := tr(text)
		return t if t != text else text
	return text


# ---------------------------------------------------------------------------
# Nút bấm
# ---------------------------------------------------------------------------
func _on_prev_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	prev_page()


func _on_next_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	next_page()


func _on_tab_pressed(index: int) -> void:
	Sfx.play(Sfx.PAGE_TURN)
	go_to_page(index)


func _on_cta_pressed() -> void:
	# Trang cuối: CTA = "đã hiểu" -> đóng popup. Các trang trước: sang trang kế.
	if _page >= _pages.size() - 1:
		Sfx.play(Sfx.BTN_CLICK)
		close()
	else:
		Sfx.play(Sfx.BTN_WOOD_TAP)
		next_page()


func _on_link_pressed() -> void:
	# Trang cuối: link = "xem lại từ đầu" -> về trang 1. Các trang trước: bỏ qua -> đóng.
	if _page >= _pages.size() - 1:
		Sfx.play(Sfx.PAGE_TURN)
		go_to_page(0)
	else:
		Sfx.play(Sfx.BTN_CLICK)
		close()


func _on_close_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	close()


# ---------------------------------------------------------------------------
# Vuốt ngang / lăn chuột / phím mũi tên chuyển trang
# ===========================================================================
# Nút bấm trong popup "ăn" sự kiện kéo nên xử lý ở `_input` (nhận trước GUI)
# rồi `set_input_as_handled()` — cùng cách popup Ngôn ngữ.
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
