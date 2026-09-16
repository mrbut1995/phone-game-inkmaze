class_name InstructionPopup
extends BasePopup
## ============================================================================
## Popup HƯỚNG DẪN CHƠI theo từng chế độ — 9 scene riêng trong
## `nodes/popups/instruction/<mode>.tscn`, mỗi scene 3 trang (Page1..Page3).
##
## Khác bản cũ (popup dùng chung + dữ liệu sinh động):
##   - Toàn bộ nội dung (tiêu đề, tab, mục, 3 hàng luật, chữ trên khung minh hoạ,
##     nút CTA, link, chấm trang, mũi tên) được "nướng" thẳng vào scene theo
##     đúng mockup, mỗi trang là 1 nhóm node riêng (Page1..3).
##   - Script này chỉ lo HÀNH VI: ẩn/hiện trang, nối nút, vuốt ngang, phím mũi
##     tên, lăn chuột, phát sfx, đóng popup — không sinh nội dung.
##   - Chữ dùng khoá dịch STR_GI_* (auto_translate), riêng số trang
##     "TRANG x / 3" được format lúc chạy.
##
## Mở bằng: Popups.open_path("res://nodes/popups/instruction/dungeon.tscn").
## ============================================================================

const DRAG_THRESHOLD := 14.0   ## ngưỡng kéo (px) để tính là VUỐT chứ không phải bấm
const SWIPE_DISTANCE := 90.0   ## quãng vuốt (px) để lật trang
const TAB_RING := 26.0         ## đường kính vòng tròn số thứ tự tab
const TAB_GAP := 6.0           ## khoảng cách vòng số -> chữ tab
const FADE_TIME := 0.16

var _pages: Array[Control] = []
var _page := 0

var _drag_active := false
var _drag_moved := false
var _drag_start := Vector2.ZERO


# ---------------------------------------------------------------------------
# Vòng đời
# ---------------------------------------------------------------------------
func _ready() -> void:
	_collect_pages()
	#_center_tabs()
	_connect_buttons()
	_show_page(_page, false)


func _on_open() -> void:
	_collect_pages()
	_connect_buttons()
	_page = clampi(int(data.get("page", 0)), 0, maxi(_pages.size() - 1, 0))
	_refresh_page_index()
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


## Số tab của trang đang xem (0 nếu trang không có tab)
func tab_count() -> int:
	var tabs := _tabs_of(_page)
	return tabs.size() if tabs != null else 0


## Chữ (đã dịch) của tab thứ `index` (0-based) trên trang đang xem
func tab_label(index: int) -> String:
	var tabs := _tabs_of(_page)
	if tabs == null or index < 0 or index >= tabs.size():
		return ""
	var node: Node = tabs[index]
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
	var lbl := _child_of(_page, "Index") as Label
	return lbl.text if lbl != null else ""


## Tiêu đề (đã dịch) của trang đang xem
func page_title() -> String:
	var lbl := _child_of(_page, "Title") as Label
	return _resolve(lbl.text) if lbl != null else ""


## Nút Previous của trang đang xem có bị khoá không (trang 1 khoá)
func is_prev_locked() -> bool:
	var btn := _child_of(_page, "Prev") as Button
	return btn == null or btn.disabled


## Nút Next của trang đang xem có bị khoá không (trang cuối khoá)
func is_next_locked() -> bool:
	var btn := _child_of(_page, "Next") as Button
	return btn == null or btn.disabled


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
# Dựng / chuyển trang
# ---------------------------------------------------------------------------
func _collect_pages() -> void:
	var root := get_node_or_null("Panel/Guide/Pages")
	if root == null:
		_pages.clear()
		return
	var pages: Array[Control] = []
	for child in root.get_children():
		if child is Control:
			pages.append(child)
	_pages = pages


func _connect_buttons() -> void:
	var close_btn := close_button()
	if close_btn != null and not close_btn.pressed.is_connected(_on_close_pressed):
		close_btn.pressed.connect(_on_close_pressed)
	for i in _pages.size():
		var page := _pages[i]
		_connect(page.get_node_or_null("Prev"), _on_prev_pressed)
		_connect(page.get_node_or_null("Next"), _on_next_pressed)
		_connect(page.get_node_or_null("Cta"), _on_cta_pressed)
		_connect(page.get_node_or_null("Link"), _on_link_pressed)
		var tabs := _tabs_of(i)
		if tabs != null:
			for t in tabs.size():
				_connect(tabs[t], _on_tab_pressed.bind(t))
		var dots := page.get_node_or_null("Dots") as Control
		if dots != null:
			for d in dots.get_child_count():
				_connect(dots.get_child(d), _on_tab_pressed.bind(d))
	_refresh_page_index()


func _connect(node: Node, handler: Callable) -> void:
	if node == null:
		return
	var btn := node as BaseButton
	if btn != null and not btn.pressed.is_connected(handler):
		btn.pressed.connect(handler)


### Canh giữa "vòng số + chữ" của tab theo bề rộng chữ thật của font
#func _center_tabs() -> void:
	#for i in _pages.size():
		#var tabs := _tabs_of(i)
		#if tabs == null:
			#continue
		#for tab in tabs:
			#var node := tab as Control
			#if node == null:
				#continue
			#var lbl := node.get_node_or_null("Label") as Label
			#var ring := node.get_node_or_null("Ring") as Control
			#var num := node.get_node_or_null("Num") as Label
			#if lbl == null or ring == null:
				#continue
			#var font: Font = lbl.get_theme_font("font")
			#var size: int = lbl.get_theme_font_size("font_size")
			#var w := node.size.x
			#var text_w := 0.0
			#if font != null:
				#text_w = font.get_string_size(lbl.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			#var total := TAB_RING + TAB_GAP + text_w
			#var x := (w - total) * 0.5
			#ring.position = Vector2(x, (node.size.y - TAB_RING) * 0.5)
			#lbl.position = Vector2(x + TAB_RING + TAB_GAP, 0.0)
			#lbl.size = Vector2(text_w + 4.0, node.size.y)
			#if num != null:
				#num.position = ring.position
				#num.size = Vector2(TAB_RING, TAB_RING)


func _refresh_page_index() -> void:
	for i in _pages.size():
		var lbl := _child_of(i, "Index") as Label
		if lbl != null:
			lbl.text = tr("STR_GI_PAGE_INDEX").format([i + 1, _pages.size()])


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


# ---------------------------------------------------------------------------
# Tiện ích node
# ---------------------------------------------------------------------------
func _child_of(page_index: int, child_name: String) -> Node:
	if page_index < 0 or page_index >= _pages.size():
		return null
	return _pages[page_index].get_node_or_null(child_name)


func _tabs_of(page_index: int) -> Array:
	var box := _child_of(page_index, "Tabs") as Control
	if box == null:
		return []
	var out: Array = []
	for child in box.get_children():
		if child is BaseButton:
			out.append(child)
	return out


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
