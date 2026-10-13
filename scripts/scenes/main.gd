class_name MainScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình chính (Main Screen) — bố cục mới (§A).
##
## Hai cổng chơi thường trực là 2 thẻ giấy `ModeCard`: Play (chọn màn) & Dungeon
## (vô tận). Daily Challenge KHÔNG còn thẻ riêng — nằm trong KHỐI SỰ KIỆN (carousel
## thẻ dọc, ghim đầu). 8 luật Special chỉ vào qua Daily/Event.
##
## Node UI nằm trong bố cục đang hiển thị (`Portrait` / `Landscape`) và đã BIND SẴN
## bằng `@export` trong `scenes/layout/<hướng>/main.tscn` ⇒ code đọc qua `layout.<tên>`.
## ============================================================================
const UIAnim := preload("res://scripts/utils/ui_anim.gd")

## Ảnh icon dùng cho 2 thẻ chế độ + dock (nạp 1 lần)
const ICON_STARS := "res://assets/images-png/icons/icon_stat_stars.png"
const ICON_STEPS := "res://assets/images-png/icons/icon_steps.png"
const ICON_PLAY := "res://assets/images-png/icons/icon_play.png"
const ICON_CASTLE := "res://assets/images-png/icons/icon_castle.png"
const ICON_SHOP := "res://assets/images-png/icons/icon_shop.png"
const ICON_RANK := "res://assets/images-png/icons/icon_trophy.png"
const ICON_BADGES := "res://assets/images-png/icons/icon_badge_medal.png"
const ICON_RULES := "res://assets/images-png/icons/icon_book.png"

var layout: MainLayout = null


func _ready() -> void:
	_bind_layout()
	_refresh_all()
	_connect_profile_manager()
	_setup_buttons()
	_setup_animations()
	_setup_event_carousel()
	orientation_changed.connect(_on_orientation_changed)


## Gắn lại toàn bộ node UI theo layout ĐANG HIỂN THỊ (dọc ⇄ ngang)
func _bind_layout() -> void:
	layout = active_layout() as MainLayout
	if layout == null:
		push_warning("main: bố cục chưa gắn MainLayout — thiếu binding trong scenes/layout/<hướng>/main.tscn")


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
	_refresh_mode_cards()


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


## 2 thẻ chế độ (Play · Dungeon) — dữ liệu màn/kỷ lục/tổng sao
func _refresh_mode_cards() -> void:
	if layout == null:
		return
	var gm := get_node_or_null("/root/GameManager")
	var level := 1
	if gm != null:
		level = maxi(int(gm.get("current_level")), 1)
	var stars := 0
	if gm != null and gm.has_method("total_stars"):
		stars = int(gm.call("total_stars"))
	var star_total := _total_stars()
	var floor := Archivement.stat_value("dungeon_best_floor")

	if layout.card_play != null:
		layout.card_play.setup({
			"icon": load(ICON_PLAY),
			"chip": tr("STR_MODECARD_PLAY_CHIP"),
			"chip_color": Color("#9CCBE8"),
			"chip_text": Color("#164663"),
			"title": tr("STR_MODE_PLAY_TITLE"),
			"subtitle": tr("STR_MODE_PLAY_DESC_1"),
			"info": tr("STR_MODECARD_PLAY_INFO").format([stars, star_total]),
			"info_icon": load(ICON_STARS),
			"stat_label": tr("STR_MODECARD_PLAY_STAT"),
			"stat_value": tr("STR_MODECARD_LEVEL_VAL").format([level]),
			"button": tr("STR_MODECARD_PLAY_BUTTON"),
			"tape_color": Color("#9CCBE8"),
			"accent_color": Color("#256C96"),
		})

	if layout.card_dungeon != null:
		layout.card_dungeon.setup({
			"icon": load(ICON_CASTLE),
			"chip": tr("STR_MODECARD_DUNGEON_CHIP"),
			"chip_color": Color("#F6C453"),
			"chip_text": Color("#6B4406"),
			"title": tr("STR_MODE_DUNGEON_TITLE"),
			"subtitle": tr("STR_MODE_DUNGEON_DESC_1"),
			"info": tr("STR_MODECARD_DUNGEON_INFO"),
			"info_icon": load(ICON_STEPS),
			"stat_label": tr("STR_MODECARD_DUNGEON_STAT"),
			"stat_value": tr("STR_MODECARD_FLOOR_VAL").format([floor]),
			"button": tr("STR_MODECARD_DUNGEON_BUTTON"),
			"tape_color": Color("#F6C453"),
			"accent_color": Color("#F59E0B"),
		})


## Tổng số sao tối đa (số màn × 3) — dùng cho "x / y sao" trên thẻ Play
func _total_stars() -> int:
	var lm := get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_level_count"):
		return 0
	return int(lm.call("get_level_count")) * 3


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
	UIAnim.attach_press_bounce(button)


func _setup_buttons() -> void:
	if layout == null:
		return
	_connect_pressed(layout.btn_settings, _on_settings_pressed)
	_connect_pressed(layout.dock_shop, _on_shop_pressed)
	_connect_pressed(layout.dock_ranking, _on_leaderboard_pressed)
	_connect_pressed(layout.dock_badges, _on_archivement_pressed)
	_connect_pressed(layout.dock_rules, _on_rules_pressed)
	#_connect_pressed(layout.profile_card, _on_profile_pressed)
	_connect_mode_card(layout.card_play, _on_play_pressed)
	_connect_mode_card(layout.card_dungeon, _on_dungeon_pressed)

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
	
	# Ví Xu: nút `+` mở Cửa hàng
	if layout.coin_chip != null and not layout.coin_chip.plus_pressed.is_connected(_on_shop_pressed):
		layout.coin_chip.plus_pressed.connect(_on_shop_pressed)


## ModeCard phát `card_pressed` (không dùng `pressed` để tránh trùng với nút CTA bên trong)
func _connect_mode_card(card: ModeCard, handler: Callable) -> void:
	if card == null:
		return
	if card.card_pressed.is_connected(handler):
		return
	card.card_pressed.connect(handler)
	UIAnim.attach_press_bounce(card)


func _setup_dock_button(button: DockButton, icon_path: String, label: String) -> void:
	if button == null:
		return
	button.setup(load(icon_path), label)


func _setup_animations() -> void:
	if layout == null:
		return
	if layout.logo != null:
		UIAnim.play_float_idle(layout.logo, 4.0, 2.4)
	if layout.mode_box != null:
		UIAnim.play_slide_in(layout.mode_box, Vector2(0, 22), 0.0, 0.26)
	if layout.stamp_panel != null:
		UIAnim.play_pop_in(layout.stamp_panel, 0.2, 0.85, 0.25)


# ---------------------------------------------------------------------------
# HÀNH VI NÚT
# ---------------------------------------------------------------------------

func _on_play_pressed(_mode_id: StringName = &"") -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("go_to_levels"):
		gm.go_to_levels()
	else:
		Nav.goto_levels()


func _on_dungeon_pressed(_mode_id: StringName = &"") -> void:
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


## Luật chơi → màn TUTORIAL (đề xuất §A5)
func _on_rules_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_tutorial()


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
	Nav.goto_event(event_id)
