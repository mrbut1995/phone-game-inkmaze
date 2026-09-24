class_name ShopScene
extends BaseScene
## ============================================================================
## Màn CỬA HÀNG (mockup/shopping_*.svg) — 4 tab:
##   BÚT & MỰC (pen) · GIẤY VỞ (theme) · DỤNG CỤ (tool) · NẠP XU (coin)
##
## - Tab BÚT & MỰC / GIẤY VỞ: lưới 2 cột, 6 món/trang (có phân trang, VUỐT NGANG đổi trang)
## - Tab DỤNG CỤ: danh sách thẻ ngang 980×180 (cuộn dọc)
## - Tab NẠP XU: hàng VIP "Xoá quảng cáo" 980×200 nằm TRÊN CÙNG + lưới 2 cột các gói Xu
## - Mua bằng Xu Mực (ví dùng chung với Sổ tay thành tựu) hoặc gói nạp tiền thật (STUB IAP)
## - Bút / chủ đề sau khi mua có nút SỬ DỤNG -> ThemeSkin.apply_* (ĐÃ CHUẨN BỊ, chưa đổi giao diện)
## - VUỐT DỌC để cuộn danh sách (tự xử lý ở `_input` vì nút trên thẻ "ăn" sự kiện kéo)
## ============================================================================

const ROW_SCENE := preload("res://nodes/shop/item_row.tscn")
const TILE_SCENE := preload("res://nodes/shop/item_tile.tscn")
const COIN_SCENE := preload("res://nodes/shop/coin_tile.tscn")
const NOADS_SCENE := preload("res://nodes/shop/noads_row.tscn")
const DOODLE_PAD_SCENE := preload("res://nodes/shop/doodle_pad.tscn")
## Node UI của màn này đều là SCENE riêng (không tạo node bằng code)
const TAB_BUTTON_SCENE := preload("res://nodes/shop/tab_button.tscn")
const ITEM_GRID_SCENE := preload("res://nodes/shop/item_grid.tscn")
const PAGE_DOT_SCENE := preload("res://nodes/shop/page_dot.tscn")
const TAB_ACTIVE := preload("res://assets/images/shop/tab_active.svg")
const TAB_INACTIVE := preload("res://assets/images/shop/tab_inactive.svg")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Số món mỗi trang ở lưới 2 cột — GIÁ TRỊ THIẾT KẾ (màn 1080×1920).
## Số thực tế được tính lại theo CHIỀU CAO khung nhìn (`_grid_per_page`): màn thấp /
## xoay ngang thì ít hàng hơn, màn cao thì nhiều hàng hơn (content giãn hết chỗ trống).
const TILES_PER_PAGE := 3
## Lưới ô: bản DỌC 2 cột (khe ngang 30 / khe dọc 24 — khớp `_make_grid`); bản NGANG nở tối đa 4 cột
const GRID_COLUMNS := 2
const GRID_COLUMNS_MAX := 4
## Bề rộng TỐI THIỂU của 1 thẻ ô ở bản NGANG — cơ sở để chia số cột (thẻ tự nở đầy ô)
const TILE_MIN_W := 130.0
## Lưới GÓI NẠP XU luôn 2 cột (thẻ nở đầy ô) — giữ được cả khi khung hẹp (bố cục ngang 2 cột)
const COIN_COLUMNS := 2
const GRID_H_SEP := 30.0
const GRID_V_SEP := 24.0
## Khe dọc giữa các khối trong danh sách (khớp `List.theme_override_constants/separation`)
const LIST_SEP := 20.0
## Ngưỡng nhận diện kéo (px) và ngưỡng tính là "vuốt" (px)
const DRAG_THRESHOLD := 14.0
const SWIPE_MIN := 70.0
## Khoá bấm nút trong bao lâu sau khi vuốt (tránh vừa vuốt vừa mua nhầm)
const CLICK_LOCK_TIME := 0.35
const TAB_ORDER := ["pen", "theme", "tool", "coin"]
const TAB_KEYS := {
	"pen": "STR_SHOP_TAB_PEN",
	"theme": "STR_SHOP_TAB_THEME",
	"tool": "STR_SHOP_TAB_TOOL",
	"coin": "STR_SHOP_TAB_COIN",
}
## Nhóm hiện dạng lưới ô (2 cột); còn lại hiện dạng thẻ ngang
const GRID_CATEGORIES := ["pen", "theme"]

# --- Cỡ TAB & THẺ Ô theo màn hình (2026-09-17) -------------------------------
## MỌI CỠ ĐỀU LẤY TỪ LAYOUT/ART — sửa ở file scene/SVG, script chỉ nhân hệ số:
##   · TAB  : chiều cao = chiều cao art `tab_active.svg` (tab chưa chọn = art `tab_inactive.svg`)
##   · THẺ Ô: rộng × cao = `custom_minimum_size` của `nodes/shop/item_tile.tscn`
## Canvas thiết kế (chiều cao). Hệ số co giãn = cao_canvas / 1920, kẹp trong khoảng dưới.
const DESIGN_CANVAS_H := 1920.0
const SCREEN_SCALE_MIN := 0.85      # màn ngang / thấp: nhỏ nhất còn 0,85×
const SCREEN_SCALE_MAX := 1.5       # màn dọc siêu cao: lớn nhất 1,5×
## Hệ số phóng to THẺ Ô so với cỡ thiết kế trong `item_tile.tscn`
## (muốn cỡ khác: sửa số này HOẶC sửa cỡ thiết kế trong scene — không cần sửa gì khác)
const TILE_SCALE := 1.25
## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/shop.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: ShopLayout = null

var _tabs: Dictionary = {}          # category -> ShopTabButton (scene nodes/shop/tab_button.tscn)
var _cards: Array[Control] = []
var _category := "pen"
var _page := 0
var _pages := 1
## id món ĐẦU trang đang xem — dùng để giữ đúng vị trí khi xoay màn hình (phân trang lại)
var _page_first_id := ""
## Số món/trang đang áp dụng (để biết có cần phân trang lại khi màn hình đổi cỡ)
var _last_per_page := 0
## Cỡ THIẾT KẾ của thẻ ô (đọc 1 lần từ item_tile.tscn) — phục vụ tính số hàng vừa khung
static var _tile_size := Vector2.ZERO
## Cỡ thiết kế thẻ GÓI NẠP (đọc 1 lần từ `nodes/shop/coin_tile.tscn`)
var _coin_size := Vector2.ZERO
## Cỡ bàn nháp thử bút (đọc 1 lần từ doodle_pad.tscn)
static var _pad_h := 0.0
## Bàn nháp thử bút (chỉ tab BÚT & MỰC) + ngòi bút đang xem thử trên đó
var _doodle_pad: Control = null
var _preview_pen := ""
# Trạng thái kéo/vuốt (xem `_input`)
var _drag_active := false
var _drag_moved := false
var _drag_axis := 0                 # 0 = chưa rõ · 1 = ngang (vuốt trang) · 2 = dọc (cuộn)
var _drag_start := Vector2.ZERO
var _drag_last := Vector2.ZERO
var _drag_scroll := 0.0
var _click_lock_until := 0.0
# Số đo LAYOUT của hàng tab — đọc 1 lần từ shop.tscn lúc mở màn (xem `_capture_tab_layout`)
var _tabs_top := 0.0
var _tabs_row_w := 980.0
var _tabs_sep := 8.0
var _tab_line_h := 3.5
var _tabs_content_gap := 8.0
var _tabs_captured := false


func _ready() -> void:
	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)

	if layout.top_bar != null:
		UIAnim.play_slide_in(layout.top_bar, Vector2(0, -22), 0.0, 0.25)
	if layout.wallet_bar != null:
		UIAnim.play_slide_in(layout.wallet_bar, Vector2(0, -22), 0.04, 0.25)
	if layout.tabs_box != null:
		UIAnim.play_slide_in(layout.tabs_box, Vector2(0, -12), 0.08, 0.25)
	if layout.gift_banner != null:
		UIAnim.play_slide_in(layout.gift_banner, Vector2(0, 20), 0.12, 0.25)

	_capture_tab_layout()
	_build_tabs()
	_refresh_wallet()
	show_tab(_category)
	# Xoay màn hình (dọc ⇄ ngang) -> tính lại số món/trang và giữ nguyên món đang xem
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_on_viewport_resized):
		vp.size_changed.connect(_on_viewport_resized)
	# Khung danh sách chỉ có kích thước THẬT sau frame đầu -> tính lại phân trang cho khớp
	await get_tree().process_frame
	await get_tree().process_frame
	# Bố cục dùng CONTAINER (HBox/VBox): hàng tab chỉ biết bề rộng thật sau khi dàn xong frame đầu
	# ⇒ dàn lại tab/thẻ ở đây, nếu không tab sẽ dựng với bề rộng 0 (vô hình).
	_apply_tab_metrics()
	_apply_card_metrics()
	_refresh_pagination_if_needed()


## Gắn node của layout đang hiển thị (2 layout giữ cùng đường dẫn nên dùng `ui_path`)
func _bind_refs() -> void:
	layout = active_layout() as ShopLayout
	if layout == null:
		push_warning("shop: bố cục chưa gắn ShopLayout — thiếu binding trong scenes/layout/<hướng>/shop.tscn")


## Mỗi NODE chỉ nối signal 1 lần (xoay màn hình không nhân đôi connection/hiệu ứng)
func _wire_once(node: Node) -> bool:
	if node == null or node.has_meta("wired"):
		return false
	node.set_meta("wired", true)
	return true


func _wire_buttons() -> void:
	if _wire_once(layout.btn_back):
		layout.btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(layout.btn_back)
	if _wire_once(layout.wallet_plus):
		layout.wallet_plus.pressed.connect(_on_wallet_plus_pressed)
		UIAnim.attach_press_bounce(layout.wallet_plus)
	if _wire_once(layout.btn_prev):
		layout.btn_prev.pressed.connect(_on_prev_page)
		UIAnim.attach_press_bounce(layout.btn_prev)
	if _wire_once(layout.btn_next):
		layout.btn_next.pressed.connect(_on_next_page)
		UIAnim.attach_press_bounce(layout.btn_next)
	if _wire_once(layout.btn_gift):
		layout.btn_gift.pressed.connect(_on_gift_pressed)
		UIAnim.attach_press_bounce(layout.btn_gift)
		UIAnim.play_pulse(layout.btn_gift, 1.04, 1.8)


## Xoay màn hình: gắn lại node + dựng lại tab/trang của layout mới
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	_wire_buttons()
	_tabs_captured = false
	_tabs.clear()
	_capture_tab_layout()
	_build_tabs()
	_refresh_wallet()
	_refresh_pagination_if_needed()


## Hệ số co giãn theo CHIỀU CAO màn hình hiện tại (1,0 = canvas thiết kế 1920)
## Màn dọc cao (điện thoại 1080×2424) -> tab/thẻ cao hơn; màn ngang thấp -> thấp hơn (sàn 0,85).
func screen_scale() -> float:
	var canvas_h := get_viewport_rect().size.y if is_inside_tree() else 0.0
	if canvas_h <= 0.0:
		return 1.0
	return clampf(canvas_h / DESIGN_CANVAS_H, SCREEN_SCALE_MIN, SCREEN_SCALE_MAX)


## Chiều cao TAB đang dùng = chiều cao ART tab đang chọn (`tab_active.svg`) × hệ số màn hình
## (muốn đổi cỡ tab: sửa 2 file SVG trong assets/images/shop — không cần sửa script)
func tab_height() -> float:
	return ShopTabButton.art_height() * screen_scale()


## Cỡ THIẾT KẾ của thẻ ô — đọc từ `nodes/shop/item_tile.tscn` (layout là nguồn số thật)
func tile_design_size() -> Vector2:
	if _tile_size == Vector2.ZERO:
		var probe := TILE_SCENE.instantiate() as Control
		if probe != null:
			_tile_size = Vector2(
				maxf(probe.size.x, probe.custom_minimum_size.x),
				maxf(probe.size.y, probe.custom_minimum_size.y))
			probe.free()
		if _tile_size.x <= 0.0 or _tile_size.y <= 0.0:
			_tile_size = Vector2(475.0, 294.0)
	return _tile_size


## Cỡ THẺ Ô đang dùng: cao = thiết kế × `TILE_SCALE` × hệ số màn hình.
## Bản NGANG: rộng = bề rộng Ô LƯỚI (bố cục 2 cột) để lưới luôn vừa khung, không tràn cột.
func tile_size() -> Vector2:
	var design := tile_design_size()
	var height := design.y * TILE_SCALE * screen_scale()
	if not is_landscape:
		return Vector2(design.x, height)
	var width := layout.scroll.size.x if layout.scroll != null else design.x
	var columns := grid_columns()
	var cell := (width - GRID_H_SEP * float(columns - 1)) / float(columns)
	return Vector2(maxf(cell, TILE_MIN_W), height)


## Chiều cao THẺ Ô đang dùng (dùng cho tính số hàng vừa khung)
func tile_height() -> float:
	return tile_size().y


## Số CỘT của lưới ô: bản DỌC = 2; bản NGANG chia theo BỀ RỘNG khung danh sách với
## bề rộng thẻ TỐI THIỂU (thẻ nở đầy ô). Lưới GÓI NẠP luôn 2 cột (xem `COIN_COLUMNS`).
func grid_columns() -> int:
	if not is_landscape or _category == "coin":
		return GRID_COLUMNS
	var width := layout.scroll.size.x if layout.scroll != null else 0.0
	if width <= 0.0:
		return GRID_COLUMNS
	var columns := int((width + GRID_H_SEP * 0.5) / (TILE_MIN_W + GRID_H_SEP))
	return clampi(columns, GRID_COLUMNS, GRID_COLUMNS_MAX)


## Cỡ THIẾT KẾ của thẻ GÓI NẠP (đọc từ `nodes/shop/coin_tile.tscn`)
func coin_design_size() -> Vector2:
	if _coin_size == Vector2.ZERO:
		var probe := COIN_SCENE.instantiate() as Control
		if probe != null:
			_coin_size = Vector2(
				maxf(probe.size.x, probe.custom_minimum_size.x),
				maxf(probe.size.y, probe.custom_minimum_size.y))
			probe.free()
		if _coin_size.x <= 0.0 or _coin_size.y <= 0.0:
			_coin_size = Vector2(237.5, 120.0)
	return _coin_size


## Cỡ THẺ GÓI NẠP đang dùng: bản DỌC giữ cỡ thiết kế (2 cột vừa khung),
## bản NGANG cho thẻ NỞ ĐẦY Ô để lưới không bao giờ tràn ra ngoài khung cuộn.
func coin_tile_size() -> Vector2:
	var design := coin_design_size()
	if not is_landscape:
		return design
	var width := layout.scroll.size.x if layout.scroll != null else design.x
	var cell := (width - GRID_H_SEP * float(COIN_COLUMNS - 1)) / float(COIN_COLUMNS)
	return Vector2(maxf(cell, TILE_MIN_W), design.y)


## Số món mỗi trang theo CHIỀU CAO thật của khung danh sách (đổi khi xoay màn hình)
func _grid_per_page() -> int:
	var avail := layout.scroll.size.y if layout.scroll != null else 0.0
	if avail <= 0.0:
		return TILES_PER_PAGE
	# Bàn nháp thử bút (tab BÚT & MỰC) nếu nằm TRONG danh sách thì chiếm mất một khoảng dọc
	# (bố cục NGANG đặt bàn nháp sang cột trái ⇒ không trừ)
	var extra := 0.0
	if _category == "pen" and layout.pad_slot == null:
		extra = _doodle_pad_height() + LIST_SEP
	var grid_avail := maxf(avail - extra, 0.0)
	var columns := grid_columns()
	var row_h := tile_height() + GRID_V_SEP
	var rows := maxi(1, int(floor((grid_avail + GRID_V_SEP) / maxf(row_h, 1.0))))
	return maxi(columns, rows * columns)


## Chiều cao bàn nháp thử bút: cỡ thật khi đã dựng, nếu chưa thì đọc từ scene gốc
func _doodle_pad_height() -> float:
	if _doodle_pad != null and is_instance_valid(_doodle_pad) and _doodle_pad.size.y > 0.0:
		return _doodle_pad.size.y
	if _pad_h <= 0.0:
		var probe := DOODLE_PAD_SCENE.instantiate() as Control
		if probe != null:
			_pad_h = maxf(probe.size.y, probe.custom_minimum_size.y)
			probe.free()
		if _pad_h <= 0.0:
			_pad_h = 215.0
	return _pad_h


## Cỡ cao THIẾT KẾ của thẻ ô (đọc từ scene gốc 1 lần — fallback 294 như thiết kế)
func _tile_height() -> float:
	return tile_design_size().y


## Đọc số đo LAYOUT của hàng tab từ `shop.tscn` (đỉnh hàng · bề rộng · khe · vạch kẻ · khe tới danh sách)
## — không hard-code trong script nữa, sửa scene là đủ.
func _capture_tab_layout() -> void:
	if layout.tabs_box == null or _tabs_captured:
		return
	_tabs_captured = true
	_tabs_top = layout.tabs_box.offset_top
	_tabs_row_w = layout.tabs_box.offset_right - layout.tabs_box.offset_left
	_tabs_sep = float(layout.tabs_box.get_theme_constant("separation"))
	var line := layout.tab_line
	if line != null:
		_tab_line_h = line.size.y
	if layout.scroll != null:
		_tabs_content_gap = layout.scroll.offset_top - layout.tabs_box.offset_bottom


## Áp cỡ thẻ ô hiện tại cho mọi thẻ đang hiện (thẻ tự dàn khối bên trong bằng anchors)
func _apply_card_metrics() -> void:
	if not GRID_CATEGORIES.has(_category):
		return
	var size := tile_size()
	for card in _cards:
		if card != null and is_instance_valid(card):
			card.custom_minimum_size = size


## Đổi cỡ màn hình: co/giãn số món mỗi trang rồi đặt lại trang sao cho
## MÓN ĐANG XEM vẫn nằm trong trang hiện tại (không nhảy về trang 1).
func _on_viewport_resized() -> void:
	await get_tree().process_frame          # chờ khung Content nhận kích thước mới
	_apply_tab_metrics()                    # tab & vùng danh sách cao theo màn hình
	if not GRID_CATEGORIES.has(_category):
		return
	_apply_card_metrics()                   # thẻ ô cao theo màn hình
	_refresh_pagination_if_needed()


## Phân trang lại NẾU số món mỗi trang đã đổi (màn hình đổi cỡ) — giữ món đang xem
func _refresh_pagination_if_needed() -> void:
	if not is_inside_tree() or not GRID_CATEGORIES.has(_category):
		return
	var per_page := _grid_per_page()
	if per_page == _last_per_page:
		return
	var anchor := _page_first_id
	if per_page > 0 and not anchor.is_empty():
		var items := Shop.items(_category)
		for i in items.size():
			if str(items[i].get("id", "")) == anchor:
				_page = i / per_page
				break
	_rebuild()


# ---------------------------------------------------------------------------
# API cho test
# ---------------------------------------------------------------------------
func current_tab() -> String:
	return _category


func tab_button(category: String) -> TextureButton:
	return _tabs.get(category, null)


func item_count() -> int:
	return _cards.size()


func card_at(index: int) -> Control:
	return _cards[index] if index >= 0 and index < _cards.size() else null


func item_id_at(index: int) -> String:
	var card := card_at(index)
	if card == null:
		return ""
	return str(card.get("item_id"))


func page_count() -> int:
	return _pages


func current_page() -> int:
	return _page


func wallet_text() -> String:
	return layout.wallet_count.text if layout.wallet_count != null else ""


func items_per_page() -> int:
	return _grid_per_page() if GRID_CATEGORIES.has(_category) else 0


## Có đang khoá bấm nút không (vừa vuốt xong) — dùng cho test
func clicks_locked() -> bool:
	return _clicks_locked()


func doodle_pad() -> Control:
	return _doodle_pad if _doodle_pad != null and is_instance_valid(_doodle_pad) else null


func preview_pen_id() -> String:
	return _preview_pen


## Chọn 1 ngòi bút BÚT & MỰC để xem thử ở Bàn nháp (chạm thẻ bút)
func select_pen_for_preview(item_id: String) -> void:
	if _doodle_pad == null or not is_instance_valid(_doodle_pad):
		return
	if str(Shop.category_of(item_id)) != "pen" or item_id == _preview_pen:
		return
	Sfx.play(Sfx.CELL_STEP)
	_doodle_pad.call("select_pen", item_id)


# ---------------------------------------------------------------------------
# Tab
# ---------------------------------------------------------------------------
func _build_tabs() -> void:
	if layout.tabs_box == null:
		return
	for child in layout.tabs_box.get_children():
		layout.tabs_box.remove_child(child)
		child.queue_free()
	_tabs.clear()
	for category in TAB_ORDER:
		var button := TAB_BUTTON_SCENE.instantiate() as ShopTabButton
		button.name = "Tab_%s" % category
		layout.tabs_box.add_child(button)
		button.setup(category, str(TAB_KEYS.get(category, "")))
		button.pressed.connect(_on_tab_pressed.bind(category))
		UIAnim.attach_press_bounce(button, 0.96, 0.1)
		_tabs[category] = button
	_apply_tab_metrics()


## Dàn lại hàng tab theo chiều cao màn hình: tab đang chọn cao hết hàng (nhô lên),
## tab chưa chọn thấp hơn và canh ĐÁY hàng; vạch kẻ + vùng danh sách đi theo.
## Mọi số đo lấy từ `_capture_tab_layout()` (đọc từ scene) + chiều cao art tab.
func _apply_tab_metrics() -> void:
	if layout.tabs_box == null:
		return
	_capture_tab_layout()
	var h := tab_height()
	var landscape := is_landscape
	if not landscape:
		# Bản dọc: khối tab/vạch kẻ/danh sách đặt bằng OFFSET (toạ độ tuyệt đối) như trước giờ
		layout.tabs_box.offset_top = _tabs_top
		layout.tabs_box.offset_bottom = _tabs_top + h
	var count := maxi(TAB_ORDER.size(), 1)
	var row_w := maxf(layout.tabs_box.size.x, 1.0) if landscape else _tabs_row_w
	var tab_w := (row_w - _tabs_sep * float(count - 1)) / float(count)
	var inactive_h := h * ShopTabButton.inactive_ratio()
	for key in _tabs.keys():
		var button := _tabs[key] as ShopTabButton
		if button != null:
			button.apply_row_layout(tab_w, h, inactive_h)
	if landscape:
		# Bản ngang: hàng tab/vạch kẻ/danh sách do ANCHORS của scene dàn sẵn — không ghi đè offset
		return
	var line := layout.tab_line
	if line != null:
		line.offset_top = _tabs_top + h - _tab_line_h
		line.offset_bottom = _tabs_top + h
	if layout.scroll != null:
		layout.scroll.offset_top = _tabs_top + h + _tabs_content_gap


func show_tab(category: String) -> void:
	if not TAB_ORDER.has(category):
		return
	_category = category
	_page = 0
	_refresh_tab_visuals()
	_rebuild()


func _refresh_tab_visuals() -> void:
	for key in _tabs.keys():
		var button := _tabs[key] as ShopTabButton
		if button != null:
			button.set_active(str(key) == _category)
	# Tab đang chọn cao hơn -> cập nhật lại cỡ hàng tab cho khớp
	_apply_tab_metrics()


func _on_tab_pressed(category: String) -> void:
	if _clicks_locked():
		return
	if category == _category:
		return
	Sfx.play(Sfx.PAGE_TURN)
	show_tab(category)


# ---------------------------------------------------------------------------
# Dựng danh sách món hàng
# ---------------------------------------------------------------------------
func _rebuild() -> void:
	if layout.list_box == null:
		return
	for child in layout.list_box.get_children():
		layout.list_box.remove_child(child)
		child.queue_free()
	# Khung bàn nháp (bố cục NGANG) cũng phải dọn để tab khác không còn bàn nháp
	if layout.pad_slot != null:
		for child in layout.pad_slot.get_children():
			layout.pad_slot.remove_child(child)
			child.queue_free()
	_cards.clear()
	_doodle_pad = null

	var items := Shop.items(_category)
	if _category == "coin":
		_rebuild_coin(items)
	elif GRID_CATEGORIES.has(_category):
		_rebuild_grid(items)
	else:
		_rebuild_rows(items)
	_refresh_pager()
	if layout.scroll != null:
		layout.scroll.scroll_vertical = 0


func _rebuild_rows(items: Array[Dictionary]) -> void:
	_pages = 1
	_page = 0
	_page_first_id = ""
	var index := 0
	for item in items:
		var card: Control = ROW_SCENE.instantiate()
		layout.list_box.add_child(card)
		card.call("setup", item)
		if card.has_signal("action_pressed"):
			card.connect("action_pressed", _on_item_action)
		_cards.append(card)
		UIAnim.play_pop_in(card, 0.02 * index, 0.94, 0.18)
		index += 1


func _rebuild_grid(items: Array[Dictionary]) -> void:
	var per_page := _grid_per_page()
	_last_per_page = per_page
	_pages = maxi(1, int(ceil(float(items.size()) / float(per_page))))
	_page = clampi(_page, 0, _pages - 1)
	# Bàn nháp thử bút nằm TRÊN lưới (chỉ tab BÚT & MỰC — mockup/shopping_pencil.svg)
	if _category == "pen":
		_build_doodle_pad()
	var grid := _make_grid()
	layout.list_box.add_child(grid)

	var start := _page * per_page
	_page_first_id = str(items[start].get("id", "")) if start < items.size() else ""
	var index := 0
	var tile_size_now := tile_size()
	for offset in per_page:
		var item_index := start + offset
		if item_index >= items.size():
			break
		var card: Control = TILE_SCENE.instantiate()
		card.custom_minimum_size = tile_size_now
		grid.add_child(card)
		card.call("setup", items[item_index])
		if card.has_signal("action_pressed"):
			card.connect("action_pressed", _on_item_action)
		if card.has_signal("preview_pressed"):
			card.connect("preview_pressed", select_pen_for_preview)
		_cards.append(card)
		UIAnim.play_pop_in(card, 0.03 * index, 0.92, 0.2)
		index += 1
	_refresh_card_selection()


## Bàn nháp thử bút: nhớ ngòi đang xem thử giữa các lần dựng lại (mua/đổi trang/tab)
func _build_doodle_pad() -> void:
	if _preview_pen.is_empty() or not PenSkin.has_pen(_preview_pen):
		_preview_pen = Shop.equipped_pen()
	_doodle_pad = DOODLE_PAD_SCENE.instantiate()
	# Bố cục NGANG có khung riêng ở cột trái (mockup shopping_landscape.svg); bản DỌC để trong danh sách
	var host: Control = layout.pad_slot if layout.pad_slot != null else layout.list_box
	if host == null:
		host = layout.list_box
	host.add_child(_doodle_pad)
	_doodle_pad.call("setup", _preview_pen)
	if _doodle_pad.has_signal("pen_changed"):
		_doodle_pad.connect("pen_changed", _on_pad_pen_changed)
	UIAnim.play_pop_in(_doodle_pad, 0.0, 0.96, 0.2)


func _on_pad_pen_changed(pen_id: String) -> void:
	_preview_pen = pen_id
	_refresh_card_selection()


## Thẻ đang xem thử sáng vòng tròn icon hơn các thẻ khác
func _refresh_card_selection() -> void:
	for card in _cards:
		if card != null and is_instance_valid(card) and card.has_method("set_selected"):
			card.call("set_selected", str(card.get("item_id")) == _preview_pen)


## Tab NẠP XU: hàng VIP "Xoá quảng cáo" chiếm TRỌN MỘT HÀNG trên cùng,
## các gói Xu còn lại xếp lưới 2 cột (mockup/shopping_coin.svg)
func _rebuild_coin(items: Array[Dictionary]) -> void:
	_pages = 1
	_page = 0
	_page_first_id = ""
	var no_ads: Dictionary = {}
	var packs: Array[Dictionary] = []
	for item in items:
		if bool(item.get("no_ads", false)):
			no_ads = item
		else:
			packs.append(item)
	if not no_ads.is_empty():
		var row: Control = NOADS_SCENE.instantiate()
		layout.list_box.add_child(row)
		row.call("setup", no_ads)
		if row.has_signal("action_pressed"):
			row.connect("action_pressed", _on_item_action)
		_cards.append(row)
		UIAnim.play_pop_in(row, 0.0, 0.94, 0.18)
	var grid := _make_grid()
	layout.list_box.add_child(grid)
	var index := 0
	var coin_size_now := coin_tile_size()
	for item in packs:
		var card: Control = COIN_SCENE.instantiate()
		card.custom_minimum_size = coin_size_now
		grid.add_child(card)
		card.call("setup", item)
		if card.has_signal("action_pressed"):
			card.connect("action_pressed", _on_item_action)
		_cards.append(card)
		UIAnim.play_pop_in(card, 0.03 * index, 0.92, 0.2)
		index += 1


func _make_grid() -> GridContainer:
	var grid := ITEM_GRID_SCENE.instantiate() as ShopItemGrid
	if grid != null:
		# Số cột theo hướng màn hình (scene chỉ là mặc định 2 cột cho bản dọc)
		grid.columns = grid_columns()
	return grid


func _refresh_pager() -> void:
	var show_pager := _pages > 1
	if layout.pager != null:
		layout.pager.visible = show_pager
	if layout.page_label != null:
		layout.page_label.text = TranslationServer.translate("STR_SHOP_PAGE_FORMAT").format([_page + 1, _pages])
	if layout.btn_prev != null:
		layout.btn_prev.modulate = Color(1, 1, 1, 1) if _page > 0 else Color(1, 1, 1, 0.4)
	if layout.btn_next != null:
		layout.btn_next.modulate = Color(1, 1, 1, 1) if _page < _pages - 1 else Color(1, 1, 1, 0.4)
	if layout.dots_box == null:
		return
	for child in layout.dots_box.get_children():
		layout.dots_box.remove_child(child)
		child.queue_free()
	for index in _pages:
		var dot := PAGE_DOT_SCENE.instantiate() as ShopPageDot
		dot.name = "Dot%d" % (index + 1)
		layout.dots_box.add_child(dot)
		dot.set_current(index == _page)


func goto_page(index: int) -> void:
	if index == _page or index < 0 or index >= _pages:
		return
	_page = index
	_rebuild()


func _on_prev_page() -> void:
	if _clicks_locked():
		return
	_step_page(-1)


func _on_next_page() -> void:
	if _clicks_locked():
		return
	_step_page(1)


## Đổi trang 1 bước (dùng chung cho nút mũi tên và vuốt ngang)
func _step_page(step: int) -> void:
	var target := _page + step
	if target < 0 or target >= _pages:
		return
	Sfx.play(Sfx.PAGE_TURN)
	goto_page(target)


# ---------------------------------------------------------------------------
# VUỐT / CUỘN — tự xử lý ở mức `_input` (xem đầu file)
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if layout.scroll == null or not is_visible_in_tree():
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
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_drag(event.position)


func _begin_drag(pos: Vector2) -> void:
	if layout.scroll == null or not layout.scroll.get_global_rect().has_point(pos):
		return
	# Bàn nháp thử bút "ăn" sự kiện kéo để người chơi VẼ THỬ (không cuộn/vuốt trang)
	if _doodle_pad != null and is_instance_valid(_doodle_pad) \
			and _doodle_pad.has_method("blocks_scroll_at") \
			and bool(_doodle_pad.call("blocks_scroll_at", pos)):
		return
	_drag_active = true
	_drag_moved = false
	_drag_axis = 0
	_drag_start = pos
	_drag_last = pos
	_drag_scroll = float(layout.scroll.scroll_vertical)


func _update_drag(pos: Vector2) -> void:
	if not _drag_active:
		return
	_drag_last = pos
	var delta := pos - _drag_start
	if _drag_axis == 0:
		if absf(delta.x) < DRAG_THRESHOLD and absf(delta.y) < DRAG_THRESHOLD:
			return
		_drag_axis = 1 if absf(delta.x) > absf(delta.y) else 2
		_drag_moved = true
	# Dọc: kéo nội dung theo tay (kéo lên -> xem phần dưới)
	if _drag_axis == 2:
		layout.scroll.scroll_vertical = int(_drag_scroll - delta.y)
	_lock_clicks()
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _end_drag() -> void:
	if not _drag_active:
		return
	_drag_active = false
	if not _drag_moved:
		return
	var delta_x := _drag_last.x - _drag_start.x
	if _drag_axis == 1 and _pages > 1 and absf(delta_x) >= SWIPE_MIN:
		_step_page(1 if delta_x < 0.0 else -1)
	_lock_clicks()


func _clicks_locked() -> bool:
	return _now() < _click_lock_until


func _lock_clicks() -> void:
	_click_lock_until = _now() + CLICK_LOCK_TIME


func _now() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


# ---------------------------------------------------------------------------
# Hành động mua / dùng
# ---------------------------------------------------------------------------
func _on_item_action(item_id: String) -> void:
	if _clicks_locked():
		return
	var category: String = str(Shop.category_of(item_id))
	match category:
		"coin":
			if Shop.purchase_coin_pack(item_id):
				Sfx.play(Sfx.ACHIEVEMENT)
		"tool":
			if Shop.buy(item_id):
				Sfx.play(Sfx.BTN_CLICK)
		"pen", "theme":
			if category == "pen":
				_preview_pen = item_id          # bàn nháp xem thử đúng món vừa mua/dùng
			_handle_equip(item_id)
		_:
			return
	_refresh_wallet(true)
	_rebuild()


## Bút / chủ đề: chưa có thì MUA, có rồi thì chọn SỬ DỤNG (ThemeSkin.apply_* đã chuẩn bị sẵn)
func _handle_equip(item_id: String) -> void:
	if Shop.is_owned(item_id):
		var ok := false
		if Shop.category_of(item_id) == "theme":
			ok = ThemeSkin.apply_theme(item_id)
		else:
			ok = ThemeSkin.apply_pen(item_id)
		if ok:
			Sfx.play(Sfx.STAR_POP, 1)
		return
	if Shop.buy(item_id):
		Sfx.play(Sfx.ACHIEVEMENT)


func _on_gift_pressed() -> void:
	# Góc tiếp sức: bật tab NẠP XU (bản đầy đủ sẽ là luồng xem quảng cáo +50 Xu)
	if _clicks_locked():
		return
	Sfx.play(Sfx.BTN_CLICK)
	show_tab("coin")


func _on_wallet_plus_pressed() -> void:
	if _clicks_locked():
		return
	Sfx.play(Sfx.BTN_CLICK)
	show_tab("coin")


func _refresh_wallet(animate := false) -> void:
	if layout.wallet_count != null:
		layout.wallet_count.text = Shop.thousands(Shop.coins())
		if animate and DisplayServer.get_name() != "headless":
			layout.wallet_count.pivot_offset = layout.wallet_count.size * 0.5
			var tw := layout.wallet_count.create_tween()
			tw.tween_property(layout.wallet_count, "scale", Vector2(1.28, 1.28), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(layout.wallet_count, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_back_pressed() -> void:
	if _clicks_locked():
		return
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_main()
