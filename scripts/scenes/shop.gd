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
const TAB_ACTIVE := preload("res://assets/images/shop/tab_active.svg")
const TAB_INACTIVE := preload("res://assets/images/shop/tab_inactive.svg")
const DOT_ACTIVE := preload("res://assets/images/level_selector/dot_active.svg")
const DOT_INACTIVE := preload("res://assets/images/level_selector/dot_inactive.svg")
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Số món mỗi trang ở lưới 2 cột (2 cột × 3 hàng — đúng mockup/shopping_pencil.svg)
const TILES_PER_PAGE := 6
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
@onready var btn_back: TextureButton = $TopBar/Back
@onready var tabs_box: HBoxContainer = $Tabs
@onready var list_box: VBoxContainer = $Content/List
@onready var scroll: ScrollContainer = $Content
@onready var wallet_count: Label = $Wallet/Count
@onready var wallet_plus: TextureButton = $Wallet/Plus
@onready var pager: Control = $Pager
@onready var page_label: Label = $Pager/PageLabel
@onready var btn_prev: TextureButton = $Pager/Prev
@onready var btn_next: TextureButton = $Pager/Next
@onready var dots_box: HBoxContainer = $Pager/Dots
@onready var btn_gift: TextureButton = $GiftBanner/GiftBtn

var _tabs: Dictionary = {}          # category -> TextureButton
var _cards: Array[Control] = []
var _category := "pen"
var _page := 0
var _pages := 1
# Trạng thái kéo/vuốt (xem `_input`)
var _drag_active := false
var _drag_moved := false
var _drag_axis := 0                 # 0 = chưa rõ · 1 = ngang (vuốt trang) · 2 = dọc (cuộn)
var _drag_start := Vector2.ZERO
var _drag_last := Vector2.ZERO
var _drag_scroll := 0.0
var _click_lock_until := 0.0


func _ready() -> void:
	if btn_back != null:
		btn_back.pressed.connect(_on_back_pressed)
		UIAnim.attach_press_bounce(btn_back)
	if wallet_plus != null:
		wallet_plus.pressed.connect(_on_wallet_plus_pressed)
	if btn_prev != null:
		btn_prev.pressed.connect(_on_prev_page)
	if btn_next != null:
		btn_next.pressed.connect(_on_next_page)
	if btn_gift != null:
		btn_gift.pressed.connect(_on_gift_pressed)
	_build_tabs()
	_refresh_wallet()
	show_tab(_category)


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
	return wallet_count.text if wallet_count != null else ""


func items_per_page() -> int:
	return TILES_PER_PAGE if GRID_CATEGORIES.has(_category) else 0


## Có đang khoá bấm nút không (vừa vuốt xong) — dùng cho test
func clicks_locked() -> bool:
	return _clicks_locked()


# ---------------------------------------------------------------------------
# Tab
# ---------------------------------------------------------------------------
func _build_tabs() -> void:
	if tabs_box == null:
		return
	for child in tabs_box.get_children():
		tabs_box.remove_child(child)
		child.queue_free()
	_tabs.clear()
	for category in TAB_ORDER:
		var button := TextureButton.new()
		button.name = "Tab_%s" % category
		button.custom_minimum_size = Vector2(240, 65)
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		button.focus_mode = Control.FOCUS_NONE
		button.texture_normal = TAB_INACTIVE
		button.texture_pressed = TAB_ACTIVE
		button.pressed.connect(_on_tab_pressed.bind(category))
		tabs_box.add_child(button)

		var label := Label.new()
		label.name = "Label"
		label.theme_type_variation = &"ShopTabLabel"
		label.text = TranslationServer.translate(str(TAB_KEYS.get(category, "")))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.add_child(label)
		_tabs[category] = button


func show_tab(category: String) -> void:
	if not TAB_ORDER.has(category):
		return
	_category = category
	_page = 0
	_refresh_tab_visuals()
	_rebuild()


func _refresh_tab_visuals() -> void:
	for key in _tabs.keys():
		var button: TextureButton = _tabs[key]
		var active: bool = str(key) == _category
		button.texture_normal = TAB_ACTIVE if active else TAB_INACTIVE
		button.texture_hover = button.texture_normal
		var label := button.get_node_or_null("Label") as Label
		if label != null:
			label.theme_type_variation = &"ShopTabLabelActive" if active else &"ShopTabLabel"


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
	if list_box == null:
		return
	for child in list_box.get_children():
		list_box.remove_child(child)
		child.queue_free()
	_cards.clear()

	var items := Shop.items(_category)
	if _category == "coin":
		_rebuild_coin(items)
	elif GRID_CATEGORIES.has(_category):
		_rebuild_grid(items)
	else:
		_rebuild_rows(items)
	_refresh_pager()
	if scroll != null:
		scroll.scroll_vertical = 0


func _rebuild_rows(items: Array[Dictionary]) -> void:
	_pages = 1
	_page = 0
	var index := 0
	for item in items:
		var card: Control = ROW_SCENE.instantiate()
		list_box.add_child(card)
		card.call("setup", item)
		if card.has_signal("action_pressed"):
			card.connect("action_pressed", _on_item_action)
		_cards.append(card)
		UIAnim.play_pop_in(card, 0.02 * index, 0.94, 0.18)
		index += 1


func _rebuild_grid(items: Array[Dictionary]) -> void:
	_pages = maxi(1, int(ceil(float(items.size()) / float(TILES_PER_PAGE))))
	_page = clampi(_page, 0, _pages - 1)
	var grid := _make_grid()
	list_box.add_child(grid)

	var start := _page * TILES_PER_PAGE
	var index := 0
	for offset in TILES_PER_PAGE:
		var item_index := start + offset
		if item_index >= items.size():
			break
		var card: Control = TILE_SCENE.instantiate()
		grid.add_child(card)
		card.call("setup", items[item_index])
		if card.has_signal("action_pressed"):
			card.connect("action_pressed", _on_item_action)
		_cards.append(card)
		UIAnim.play_pop_in(card, 0.03 * index, 0.92, 0.2)
		index += 1


## Tab NẠP XU: hàng VIP "Xoá quảng cáo" chiếm TRỌN MỘT HÀNG trên cùng,
## các gói Xu còn lại xếp lưới 2 cột (mockup/shopping_coin.svg)
func _rebuild_coin(items: Array[Dictionary]) -> void:
	_pages = 1
	_page = 0
	var no_ads: Dictionary = {}
	var packs: Array[Dictionary] = []
	for item in items:
		if bool(item.get("no_ads", false)):
			no_ads = item
		else:
			packs.append(item)
	if not no_ads.is_empty():
		var row: Control = NOADS_SCENE.instantiate()
		list_box.add_child(row)
		row.call("setup", no_ads)
		if row.has_signal("action_pressed"):
			row.connect("action_pressed", _on_item_action)
		_cards.append(row)
		UIAnim.play_pop_in(row, 0.0, 0.94, 0.18)
	var grid := _make_grid()
	list_box.add_child(grid)
	var index := 0
	for item in packs:
		var card: Control = COIN_SCENE.instantiate()
		grid.add_child(card)
		card.call("setup", item)
		if card.has_signal("action_pressed"):
			card.connect("action_pressed", _on_item_action)
		_cards.append(card)
		UIAnim.play_pop_in(card, 0.03 * index, 0.92, 0.2)
		index += 1


func _make_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.name = "Grid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 30)
	return grid


func _refresh_pager() -> void:
	var show_pager := _pages > 1
	if pager != null:
		pager.visible = show_pager
	if page_label != null:
		page_label.text = TranslationServer.translate("STR_SHOP_PAGE_FORMAT").format([_page + 1, _pages])
	if btn_prev != null:
		btn_prev.modulate = Color(1, 1, 1, 1) if _page > 0 else Color(1, 1, 1, 0.4)
	if btn_next != null:
		btn_next.modulate = Color(1, 1, 1, 1) if _page < _pages - 1 else Color(1, 1, 1, 0.4)
	if dots_box == null:
		return
	for child in dots_box.get_children():
		dots_box.remove_child(child)
		child.queue_free()
	for index in _pages:
		var dot := TextureRect.new()
		dot.name = "Dot%d" % (index + 1)
		dot.texture = DOT_ACTIVE if index == _page else DOT_INACTIVE
		dot.custom_minimum_size = Vector2(34, 24) if index == _page else Vector2(12, 24)
		dot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		dot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dots_box.add_child(dot)


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
	if scroll == null or not is_visible_in_tree():
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
	if scroll == null or not scroll.get_global_rect().has_point(pos):
		return
	_drag_active = true
	_drag_moved = false
	_drag_axis = 0
	_drag_start = pos
	_drag_last = pos
	_drag_scroll = float(scroll.scroll_vertical)


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
		scroll.scroll_vertical = int(_drag_scroll - delta.y)
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
			_handle_equip(item_id)
		_:
			return
	_refresh_wallet()
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


func _refresh_wallet() -> void:
	if wallet_count != null:
		wallet_count.text = Shop.thousands(Shop.coins())


func _on_back_pressed() -> void:
	if _clicks_locked():
		return
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_main()
