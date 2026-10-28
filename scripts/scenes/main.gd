class_name MainScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình chính (Main Screen) — bố cục GỘP (Main = màn chọn màn).
##
## Màn Main hiển thị THẲNG bản đồ màn chơi (`LevelSection`, logic ở
## scripts/nodes/main/level_section.gd) — màn Levels riêng đã bị gỡ. Dungeon là nút nổi
## `DungeonPill` nằm trên bản đồ. Daily Challenge nằm trong KHỐI SỰ KIỆN (carousel,
## ghim đầu). 8 luật Special chỉ vào qua Daily/Event.
##
## Node UI nằm trong bố cục đang hiển thị (`Portrait` / `Landscape`) và đã BIND SẴN
## bằng `@export` trong `scenes/layout/<hướng>/main.tscn` ⇒ code đọc qua `layout.<tên>`.
## ============================================================================
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Ảnh icon dock (nạp 1 lần)
const ICON_SHOP := "res://assets/images-png/dock/dock_shop.png"
const ICON_RANK := "res://assets/images-png/dock/dock_ranking.png"
const ICON_BADGES := "res://assets/images-png/dock/dock_badges.png"
const ICON_RULES := "res://assets/images-png/dock/dock_rules.png"

var layout: MainLayout = null


func _ready() -> void:
	_bind_layout()
	_refresh_all()
	_connect_profile_manager()
	_setup_buttons()
	_setup_animations()
	_setup_event_carousel()
	orientation_changed.connect(_on_orientation_changed)


## Quay lại Main (vd: thắng/thua màn xong) ⇒ số Sao/Xu/rương và bản đồ có thể đã đổi
func _on_active() -> void:
	_refresh_wallet()
	_refresh_stars()
	_refresh_dungeon_pill()
	if layout != null and layout.level_section != null:
		layout.level_section.refresh()


## Gắn lại toàn bộ node UI theo layout ĐANG HIỂN THỊ (dọc ⇄ ngang)
func _bind_layout() -> void:
	layout = active_layout() as MainLayout
	if layout == null:
		push_warning("main: bố cục chưa gắn MainLayout — thiếu binding trong scenes/layout/<hướng>/main.tscn")
		return
	var section := layout.level_section
	if section != null:
		ensure_signal(section, &"scrolled", &"_on_map_scrolled")
		ensure_signal(section, &"chest_claimed", &"_on_chest_claimed")


## Kéo bản đồ ⇒ nền giấy (parallax) trượt theo, như màn Levels cũ
func _on_map_scrolled(delta_y: float) -> void:
	var background := get_node_or_null("Background") as SceneBackground
	if background != null:
		background.set_scroll_delta(delta_y)


## Nhận rương mốc ⇒ Xu/Sao đổi
func _on_chest_claimed() -> void:
	_refresh_wallet()
	_refresh_stars()


## Back cứng / Esc: khung "chương đang khoá" đang mở ⇒ chỉ đóng khung
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	var section := layout.level_section if layout != null else null
	if section != null and section.is_sheet_open():
		section.close_sheet()
		get_viewport().set_input_as_handled()


func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_bind_layout()
	_refresh_all()
	_setup_buttons()
	_setup_animations()
	_setup_event_carousel()


# ---------------------------------------------------------------------------
# DỮ LIỆU HIỂN THỊ
# ---------------------------------------------------------------------------

func _refresh_all() -> void:
	_refresh_profile()
	_refresh_wallet()
	_refresh_stars()
	_refresh_stamp()
	_refresh_dungeon_pill()


func _refresh_wallet() -> void:
	if layout != null and layout.coin_chip != null:
		layout.coin_chip.set_value(Shop.coins())


func _refresh_stars() -> void:
	if layout == null or layout.star_chip == null:
		return
	var gm := get_node_or_null("/root/GameManager")
	var total := 0
	if gm != null and gm.has_method("total_stars"):
		total = int(gm.call("total_stars"))
	layout.star_chip.set_value(total)


func _refresh_stamp() -> void:
	if layout == null or layout.stamp_label == null:
		return
	var app := get_node_or_null("/root/AppManager")
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	layout.stamp_label.text = tr("STR_SETTINGS_VERSION").format([version])


## Nút Dungeon nổi: "DUNGEON · Tầng N" (kỷ lục)
func _refresh_dungeon_pill() -> void:
	if layout == null or layout.level_section == null or layout.level_section.dungeon_pill == null:
		return
	layout.level_section.dungeon_pill.setup(int(Archivement.stat_value("dungeon_best_floor")))


## Sticker HỒ SƠ: avatar + viền khung + cấp độ + tên + XP (node con tự lo)
func _refresh_profile() -> void:
	if layout != null and layout.profile_card != null:
		layout.profile_card.refresh()


## Hồ sơ đổi (đổi avatar/viền/tên ở popup) → thẻ hồ sơ cập nhật theo
func _connect_profile_manager() -> void:
	var m := Profile.manager()
	if m != null and m.has_signal("profile_changed") and not m.is_connected("profile_changed", _refresh_profile):
		m.connect("profile_changed", _refresh_profile)


# ---------------------------------------------------------------------------
# DÂY NÚT
# ---------------------------------------------------------------------------

func _connect_pressed(button: BaseButton, handler: Callable) -> void:
	if button == null:
		return
	ensure_signal(button, &"pressed", handler.get_method())
	UIAnim.attach_press_down(button)


func _setup_buttons() -> void:
	if layout == null:
		return
	_connect_pressed(layout.btn_settings, _on_settings_pressed)
	_connect_pressed(layout.dock_shop, _on_shop_pressed)
	_connect_pressed(layout.dock_ranking, _on_leaderboard_pressed)
	_connect_pressed(layout.dock_badges, _on_archivement_pressed)
	_connect_pressed(layout.dock_rules, _on_rules_pressed)
	#_connect_pressed(layout.profile_card, _on_profile_pressed)
	if layout.level_section != null:
		_connect_pressed(layout.level_section.dungeon_pill, _on_dungeon_pressed)

	# Dock: gán icon + nhãn
	_setup_dock_button(layout.dock_shop, ICON_SHOP, tr("STR_BTN_SHOP"))
	_setup_dock_button(layout.dock_ranking, ICON_RANK, tr("STR_BTN_LEADERBOARD"))
	_setup_dock_button(layout.dock_badges, ICON_BADGES, tr("STR_BTN_ARCHIVEMENT"))
	_setup_dock_button(layout.dock_rules, ICON_RULES, tr("STR_MAIN_DOCK_RULES"))
	
	if layout.profile_card != null:
		layout.profile_card.connect(&"pressed", _on_profile_pressed)
	
	# Badge danh hiệu: số đã mở / tổng — hiện ở dock Danh hiệu (chấm đỏ chỉ báo)
	if layout.dock_badges != null:
		layout.dock_badges.set_badge(0)
	
	# Ví Xu tự lo nút `+` (CoinChip mở Cửa hàng) — main chỉ cần cập nhật số dư


func _setup_dock_button(button: DockButton, icon_path: String, label: String) -> void:
	if button == null:
		return
	button.setup(load(icon_path), label)
	_tint_dock_labels(button)


## Dock nền trắng kiểu v8 ⇒ mọi nhãn chữ trong nút dock dùng mực navy #164663 (icon cũng là bản mực).
func _tint_dock_labels(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			(child as Label).add_theme_color_override("font_color", Color("164663"))
			(child as Label).add_theme_color_override("font_outline_color", Color(0, 0, 0, 0))
		_tint_dock_labels(child)


func _setup_animations() -> void:
	if layout == null:
		return
	if layout.logo != null:
		UIAnim.play_float_idle(layout.logo, 4.0, 2.4)
	if layout.stamp_panel != null:
		UIAnim.play_pop_in(layout.stamp_panel, 0.2, 0.85, 0.25)


# ---------------------------------------------------------------------------
# HÀNH VI NÚT
# ---------------------------------------------------------------------------

func _on_dungeon_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("start_dungeon"):
		gm.start_dungeon()
	else:
		Nav.goto_game()


func _on_settings_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_settings()


func _on_archivement_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_archivement()


## Luật chơi → màn DANH SÁCH bài hướng dẫn (bấm 1 bài mới vào màn CHI TIẾT)
func _on_rules_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_tutorial_list()


## Thẻ HỒ SƠ mở POPUP hồ sơ cá nhân (không đổi màn hình)
func _on_profile_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Popups.open(Popups.PROFILER)


func _on_leaderboard_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_ranking()


func _on_shop_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_shop()


# ---------------------------------------------------------------------------
# EVENT CAROUSEL
# ---------------------------------------------------------------------------

func _setup_event_carousel() -> void:
	if layout == null or layout.event_carousel == null:
		return
	var carousel := layout.event_carousel
	if carousel.event_card_pressed.is_connected(_on_event_card_pressed):
		carousel.event_card_pressed.disconnect(_on_event_card_pressed)
	carousel.event_card_pressed.connect(_on_event_card_pressed)
	var em := get_node_or_null("/root/EventManager")
	if em != null and em.has_signal("events_changed"):
		if not em.is_connected("events_changed", _on_events_changed):
			em.events_changed.connect(_on_events_changed)
	carousel.refresh()
	# Chấm phân trang dời lên cạnh badge số event (EventHeader.DotsSlot)
	if layout.event_header != null:
		layout.event_header.attach_dots(carousel.get_node_or_null("EventDots") as Control)
	_refresh_event_header()


func _refresh_event_header() -> void:
	if layout == null or layout.event_header == null:
		return
	var em := get_node_or_null("/root/EventManager")
	var count := 0
	if layout.event_carousel.has_method("get_displayed_event_count"):
		count = layout.event_carousel.get_displayed_event_count()
	elif em != null and em.has_method("get_active_events"):
		count = (em.call("get_active_events") as Array).size()
	layout.event_header.set_count(count)
	# Giai đoạn 1: ẩn "Xem tất cả" (mở EventListScreen ở giai đoạn 2 — §B5)
	layout.event_header.set_view_all_visible(false)


func _on_events_changed() -> void:
	if layout != null and layout.event_carousel != null:
		layout.event_carousel.refresh()
	_refresh_event_header()


func _on_event_card_pressed(event_id: StringName) -> void:
	Sfx.play(Sfx.BTN_CLICK)
	# Thẻ DAILY mở THẲNG màn Daily (`scenes/daily.tscn`): Daily là event ẢO do EventManager
	# tạo (không có file .tres, không có màn chi tiết riêng) nên không đi qua `scenes/event.tscn`.
	# Mọi loại event khác vẫn mở màn chi tiết Event.
	if _is_daily_event(event_id):
		Nav.goto_daily()
		return
	Nav.goto_event(event_id)


## Có phải event DAILY (ảo) không — dùng EventManager để tra loại theo id
func _is_daily_event(event_id: StringName) -> bool:
	var em := get_node_or_null("/root/EventManager")
	if em == null or not em.has_method("get_event"):
		return event_id == &"daily"
	var event: EventData = em.call("get_event", event_id)
	return event != null and event.type == EventData.Type.DAILY
