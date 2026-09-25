class_name InstructionContent
extends Control
## ============================================================================
## NỘI DUNG HƯỚNG DẪN CHƠI (3 trang) — scene nền `nodes/popups/instruction/content_instruction.tscn`.
##
## Phần DÙNG CHUNG của mọi chế độ (khung giấy/khung popup nằm ở popup, KHÔNG ở đây):
##   Chip          — chip tên chế độ (CHỈ hiện khi mở bằng POPUP)
##   Tabs/Tab1..3  — hàng tab (HBox canh giữa; CHỈ hiện khi mở bằng POPUP)
##   Pages         — nơi scene CHẾ ĐỘ thêm Page1..3 (mỗi trang kế thừa `page.tscn`)
##   Prev · Next · Dots/Dot1..3 · Index — điều hướng trang
##
## Bố cục bằng ANCHORS theo BĂNG (chip/tabs trên · Pages giữa · điều hướng dưới) nên khung
## nào nạp vào cũng "tràn" kín:
##   · popup  — `popup_instruction.tscn` nạp vào `Panel/Content` (tờ giấy 460×740):
##              hiện ĐẦY ĐỦ chip/tabs/nav + Cta/Link của từng trang
##   · HUD ngang — GameHUD nạp vào `GuideHost` với `set_embedded(true)`: ẨN Chip/Tabs
##              (+Title do trang tự ẩn) và Cta/Link (popup mới cần), điều hướng dời vào
##              hàng tiêu đề “LUẬT CHƠI” theo mockup landscape
##
## Chữ của “ĐIỂM” (khung chú thích trên ảnh): generator giữ chuỗi gốc trong Label ẨN
## (`metadata/point` + `point_order`) — script đọc rồi đổ xuống `Points/List/PointRow#`.
##
## Mở bằng popup: `Popups.open_path("res://nodes/popups/popup_instruction.tscn", {"mode_id": ...})`.
## Nhúng trong HUD: `GameHUD.show_instruction_for(mode_id)`.
## ============================================================================

## CTA trang cuối / link "bỏ qua" xin đóng popup (CHỈ phát khi KHÔNG nhúng)
signal close_requested

const DRAG_THRESHOLD := 14.0    ## ngưỡng kéo (px) để tính là VUỐT chứ không phải bấm
const SWIPE_DISTANCE := 90.0    ## quãng vuốt (px) để lật trang
const FADE_TIME := 0.16
## Dàn dots: dot đang chọn rộng 19×9 (viên thuốc), dot thường 8×8, khe 3 (nửa cỡ mockup)
const DOT_ON_SIZE := Vector2(19.0, 9.0)
const DOT_OFF_SIZE := Vector2(8.0, 8.0)
const DOT_GAP := 3.0
## Khối “chi tiết điểm” (section của trang — script đổ chữ từ các chuỗi PT gốc vào)
const POINTS_HEAD_KEY := "STR_GI_POINTS_HEAD"
## Dấu nối các chữ trong CÙNG một điểm (vd “MỖI BƯỚC ĐI · -1 BƯỚC · Hết bước = THUA”)
const POINT_TEXT_SEP := " · "
## Cỡ nút ‹ › khi NHÚNG (điều hướng nằm trong hàng tiêu đề LUẬT CHƠI)
const EMBED_NAV_BTN := 28.0
## Khe giữa ‹ · dots · › khi nhúng (cụm gom SÁT nhau, canh phải trước “TRANG x / 3”)
const EMBED_NAV_GAP := 8.0

## Style/màu tab + dot do generator nướng sẵn từng chế độ (xem gen_instruction_popups.py)
@export var tab_on_style: StyleBoxFlat
@export var tab_off_style: StyleBoxFlat
@export var tab_on_ring_style: StyleBoxFlat
@export var tab_off_ring_style: StyleBoxFlat
@export var tab_on_text_color := Color("#FFFFFF")
@export var tab_off_text_color := Color("#718B9E")
@export var dot_on_style: StyleBoxFlat
@export var dot_off_style: StyleBoxFlat
## Màu tờ giấy theo chế độ — popup đọc 2 màu này để tô `Panel/Paper` (xem popup_instruction.gd)
@export var paper_bg := Color("#FFFDF9")
@export var paper_accent := Color("#6EA0C8")

## Bản NHÚNG trong HUD màn chơi: ẩn link "bỏ qua" + CTA "đã hiểu" (không có popup để đóng)
var embedded := false

var _pages: Array[Control] = []
var _page := 0
var _tabs: Array = []
var _dots: Array = []
var _prev: Button = null
var _next: Button = null
var _index: Label = null
var _dots_box: Control = null

var _drag_active := false
var _drag_moved := false
var _drag_start := Vector2.ZERO


# ---------------------------------------------------------------------------
# Vòng đời
# ---------------------------------------------------------------------------
func _ready() -> void:
	_collect_nodes()
	_connect_buttons()
	_fill_points()
	_show_page(_page, false)


# ---------------------------------------------------------------------------
# API cho test
# ---------------------------------------------------------------------------
## Số trang của bộ hướng dẫn (3 với mọi chế độ hiện tại)
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
	var lbl := node.get_node_or_null("Row/Label") as Label
	if lbl == null:
		return ""
	return _resolve(lbl.text)


## Chữ (đã dịch) trên nút CTA của trang đang xem
func cta_text() -> String:
	var btn := cta_button()
	return _resolve(btn.text) if btn != null else ""


## Chữ (đã dịch) của link "bỏ qua / xem lại" trên trang đang xem
func link_text() -> String:
	var btn := link_button()
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


## Bản NHÚNG (khung Hướng dẫn trong HUD theo mockup): ẩn Chip/Tabs/Title + Cta/Link
## (chỉ POPUP mới hiện các phần đó), điều hướng dời vào hàng tiêu đề “LUẬT CHƠI”.
func set_embedded(on: bool) -> void:
	embedded = on
	# Bản nhúng không còn băng chip/tabs trên · điều hướng dưới: cho `Pages` phủ KÍN khung
	# để bố cục trang (ảnh + điểm + luật) dùng hết chỗ — theo mockup landscape.
	var pages_root := get_node_or_null("Pages") as Control
	if pages_root != null and on:
		pages_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for page in _pages:
		if page.has_method("set_embedded"):
			page.call("set_embedded", on)
	_apply_embedded_chrome()
	_update_embed_nav()


# ---------------------------------------------------------------------------
# Thu thập node / nối nút
# ---------------------------------------------------------------------------
func _collect_nodes() -> void:
	_pages.clear()
	_tabs.clear()
	_dots.clear()
	var pages_root := get_node_or_null("Pages")
	if pages_root != null:
		for child in pages_root.get_children():
			if child is Control:
				_pages.append(child)
				# Trang đổi cỡ (bố cục dàn lại) -> cập nhật chỗ điều hướng khi NHÚNG
				if not child.resized.is_connected(_update_embed_nav):
					child.resized.connect(_update_embed_nav)
	var tabs_root := get_node_or_null("Tabs")
	if tabs_root != null:
		for child in tabs_root.get_children():
			if child is BaseButton:
				_tabs.append(child)
	_dots_box = get_node_or_null("Dots") as Control
	if _dots_box != null:
		for child in _dots_box.get_children():
			if child is BaseButton:
				_dots.append(child)
		# Khung dots đổi cỡ (bố cục dàn xong) -> dàn lại vị trí dots
		if not _dots_box.resized.is_connected(_update_dots):
			_dots_box.resized.connect(_update_dots)
	_prev = get_node_or_null("Prev") as Button
	_next = get_node_or_null("Next") as Button
	_index = get_node_or_null("Index") as Label


func _connect_buttons() -> void:
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
	_apply_embedded_chrome()
	_update_embed_nav()


## Bản NHÚNG: CHỈ hiện nội dung — ẩn Chip/Tabs (+Title do trang tự ẩn) và Cta/Link
## (2 thành phần này CHỈ dùng khi mở bằng POPUP), điều hướng dời lên hàng tiêu đề LUẬT CHƠI.
func _apply_embedded_chrome() -> void:
	var chip := get_node_or_null("Chip") as Control
	if chip != null:
		chip.visible = not embedded
	var tabs := get_node_or_null("Tabs") as Control
	if tabs != null:
		tabs.visible = not embedded
	for i in _pages.size():
		var page := _pages[i]
		var link := page.get_node_or_null("Link") as Control
		if link != null:
			link.visible = not embedded
		var cta := page.get_node_or_null("Cta") as Control
		if cta != null:
			cta.visible = not embedded


## Tab đang chọn đổi sang style/màu "đang chọn" (nướng sẵn trong scene chế độ)
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
		var ring := tab.get_node_or_null("Row/Ring") as Panel
		if ring != null:
			var ring_sb: StyleBox = tab_on_ring_style if on else tab_off_ring_style
			if ring_sb != null:
				ring.add_theme_stylebox_override("panel", ring_sb)
		var color := tab_on_text_color if on else tab_off_text_color
		var lbl := tab.get_node_or_null("Row/Label") as Label
		if lbl != null:
			lbl.add_theme_color_override("font_color", color)
		var num := tab.get_node_or_null("Row/Ring/Num") as Label
		if num != null:
			num.add_theme_color_override("font_color", color)


## Cuối/đầu danh sách thì nút tương ứng bị khoá (style mờ đã nướng sẵn)
func _update_nav() -> void:
	if _prev != null:
		_prev.disabled = _page <= 0
	if _next != null:
		_next.disabled = _page >= _pages.size() - 1


## Dot đang chọn phình thành viên thuốc, các dot khác co về chấm tròn.
## Hàng dots nằm trong Control `Dots` (neo theo bề rộng khung) — dot đầu ở x=0.
func _update_dots() -> void:
	var cy := (_dots_box.size.y * 0.5) if _dots_box != null else 0.0
	var x := 0.0
	for i in _dots.size():
		var dot := _dots[i] as Button
		if dot == null:
			continue
		var on := i == _page
		var dot_size := DOT_ON_SIZE if on else DOT_OFF_SIZE
		var sb: StyleBox = dot_on_style if on else dot_off_style
		if sb != null:
			for state in ["normal", "hover", "pressed"]:
				dot.add_theme_stylebox_override(state, sb)
		dot.size = dot_size
		dot.position = Vector2(x, cy - dot_size.y * 0.5)
		x += dot_size.x + DOT_GAP


func _update_index() -> void:
	if _index != null:
		_index.text = tr("STR_GI_PAGE_INDEX").format([_page + 1, _pages.size()])


# ---------------------------------------------------------------------------
# ĐIỂM: đọc chuỗi PT gốc (Label ẩn trong trang) + đổ xuống section “chi tiết điểm”
# ---------------------------------------------------------------------------
## Đổ chữ cho section `Body/Top/Points/List/PointRow#` của MỌI trang.
func _fill_points() -> void:
	for page in _pages:
		var list := page.get_node_or_null("Body/Top/Points/List") as VBoxContainer
		if list != null:
			var groups := _page_point_keys(page)
			var n := 1
			for row in list.get_children():
				_fill_point_row(row, groups.get(n, []))
				n += 1
		if page.has_method("refresh_points"):
			page.call("refresh_points")


## {số điểm: [các chuỗi gốc theo thứ tự]} của một trang — đọc từ Label ẨN trên `Body/Top/Image`.
func _page_point_keys(page: Node) -> Dictionary:
	var out := {}
	if page == null:
		return out
	var img := page.get_node_or_null("Body/Top/Image")
	if img == null:
		return out
	for child in img.get_children():
		if not child.has_meta("point"):
			continue
		var n := int(child.get_meta("point"))
		var order := int(maxi(int(child.get_meta("point_order")), 0))
		if not out.has(n):
			out[n] = []
		var arr: Array = out[n]
		while arr.size() <= order:
			arr.append("")
		arr[order] = str(child.get("text"))
	return out


## Một hàng điểm: chữ ĐẦU = tiêu đề, các chữ SAU nối bằng `POINT_TEXT_SEP` thành mô tả.
func _fill_point_row(row: Node, keys) -> void:
	var title := row.get_node_or_null("Body/Title") as Label
	var desc := row.get_node_or_null("Body/Desc") as Label
	var texts: Array[String] = []
	for k in keys:
		var s := _resolve(str(k))
		if not s.is_empty():
			texts.append(s)
	if title != null:
		title.text = texts[0] if texts.size() > 0 else ""
	if desc != null:
		if texts.size() > 1:
			var rest := PackedStringArray()
			for i in range(1, texts.size()):
				rest.append(texts[i])
			desc.text = POINT_TEXT_SEP.join(rest)
			desc.visible = true
		else:
			desc.text = ""
			desc.visible = false


## Bản NHÚNG: [‹ · dots · › · TRANG x/3] nằm bên phải hàng tiêu đề “LUẬT CHƠI”
## (trang cung cấp chỗ qua `nav_slot_rect()` — theo mockup landscape).
func _update_embed_nav() -> void:
	if not embedded or _pages.is_empty():
		return
	var page := _pages[_page]
	if not page.has_method("nav_slot_rect"):
		return
	var slot: Rect2 = page.call("nav_slot_rect")
	if slot.size.x <= 1.0:
		return
	var origin: Vector2 = page.global_position - global_position + slot.position
	var cy := origin.y + slot.size.y * 0.5
	var right := origin.x + slot.size.x
	var idx_w := 0.0
	var idx_h := 0.0
	if _index != null:
		idx_w = _index.get_combined_minimum_size().x
		idx_h = _index.size.y
		_place_free(_index, Vector2(right - idx_w, cy - idx_h * 0.5), Vector2(idx_w, idx_h))
	# Cụm [‹ · dots · ›] gom SÁT nhau, canh PHẢI ngay trước phần “TRANG x / 3” (theo mockup)
	var dots_w := _dots_total_width()
	var cluster_w := EMBED_NAV_BTN * 2.0 + dots_w + EMBED_NAV_GAP * 2.0
	var left := right - idx_w - 12.0 - cluster_w
	_place_free(_prev, Vector2(left, cy - EMBED_NAV_BTN * 0.5),
			Vector2(EMBED_NAV_BTN, EMBED_NAV_BTN))
	_place_free(_dots_box, Vector2(left + EMBED_NAV_BTN + EMBED_NAV_GAP,
			cy - EMBED_NAV_BTN * 0.5), Vector2(dots_w, EMBED_NAV_BTN))
	_place_free(_next, Vector2(
			left + EMBED_NAV_BTN + EMBED_NAV_GAP + dots_w + EMBED_NAV_GAP,
			cy - EMBED_NAV_BTN * 0.5), Vector2(EMBED_NAV_BTN, EMBED_NAV_BTN))


## Ghim node về hệ NEO-GÓC (0..0) + vị trí/cỡ cụ thể — tránh cảnh báo “non-equal opposite
## anchors” và không bị anchor kéo lại khi khung đổi cỡ (mỗi lần trang dàn xong ta đặt lại).
func _place_free(node: Control, pos: Vector2, node_size: Vector2) -> void:
	if node == null:
		return
	if node.anchor_left != 0.0 or node.anchor_top != 0.0 \
			or node.anchor_right != 0.0 or node.anchor_bottom != 0.0:
		node.set_anchors_preset(Control.PRESET_TOP_LEFT)
	node.position = pos
	node.size = node_size


## Tổng bề ngang hàng dots (dot đang chọn là viên thuốc, còn lại chấm tròn)
func _dots_total_width() -> float:
	var total := 0.0
	for i in _dots.size():
		total += DOT_ON_SIZE.x if i == _page else DOT_OFF_SIZE.x
	total += DOT_GAP * maxf(_dots.size() - 1, 0)
	return total


# ---------------------------------------------------------------------------
# API cho test — ĐIỂM của trang đang xem
# ---------------------------------------------------------------------------
## Số ĐIỂM của trang đang xem (chữ trong khung chú thích trên ảnh)
func point_count() -> int:
	if _pages.is_empty():
		return 0
	return _page_point_keys(_pages[_page]).size()


## Chữ (đã dịch) của từng điểm trang đang xem — mỗi phần tử = các dòng nối bằng “ · ”
func point_texts() -> PackedStringArray:
	var out: PackedStringArray = []
	if _pages.is_empty():
		return out
	var groups := _page_point_keys(_pages[_page])
	var nums: Array = groups.keys()
	nums.sort()
	for n in nums:
		var texts: Array[String] = []
		for k in groups[n]:
			var s := _resolve(str(k))
			if not s.is_empty():
				texts.append(s)
		out.append(POINT_TEXT_SEP.join(PackedStringArray(texts)))
	return out


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
	# Trang cuối: CTA = "đã hiểu" -> xin đóng popup. Các trang trước: sang trang kế.
	if _page >= _pages.size() - 1:
		Sfx.play(Sfx.BTN_CLICK)
		close_requested.emit()
	else:
		Sfx.play(Sfx.BTN_WOOD_TAP)
		next_page()


func _on_link_pressed() -> void:
	# Trang cuối: link = "xem lại từ đầu" -> về trang 1. Các trang trước: bỏ qua -> xin đóng.
	if _page >= _pages.size() - 1:
		Sfx.play(Sfx.PAGE_TURN)
		go_to_page(0)
	else:
		Sfx.play(Sfx.BTN_CLICK)
		close_requested.emit()


# ---------------------------------------------------------------------------
# Vuốt ngang / lăn chuột / phím mũi tên chuyển trang
# ===========================================================================
# Nút bấm trong khung "ăn" sự kiện kéo nên xử lý ở `_input` (nhận trước GUI)
# rồi `set_input_as_handled()` — cùng cách popup Ngôn ngữ.
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	# Bản NHÚNG nằm trong màn chơi — KHÔNG được nuốt sự kiện kéo/chạm của bàn cờ.
	if embedded:
		return
	if not is_visible_in_tree():
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
