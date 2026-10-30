class_name MainScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình chính (Main Screen) — bố cục GỘP (Main = màn chọn màn).
##
## Màn Main hiển thị THẲNG bản đồ màn chơi (`LevelSection`, logic ở
## scripts/nodes/main/level_section.gd) — màn Levels riêng đã bị gỡ. Dungeon là nút nổi
## `DungeonPill` nằm trên bản đồ. Daily Challenge nằm trên DOCK (nút giữa); event = CỘT NÚT ICON nổi bên phải bản đồ
## (`EventButtonColumn`, tối đa 5, thời gian còn lại ngay dưới nút). 8 luật Special chỉ vào qua Daily/Event.
##
## Node UI nằm trong bố cục đang hiển thị (`Portrait` / `Landscape`) và đã BIND SẴN
## bằng `@export` trong `scenes/layout/<hướng>/main.tscn` ⇒ code đọc qua `layout.<tên>`.
## ============================================================================
const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const EventButtonColumnScene := preload("res://nodes/main/event_button_column.tscn")

var layout: MainLayout = null
## Cột nút event nổi trên bản đồ (dựng 1 lần, chuyển theo bố cục đang hiện)
var _event_buttons: Control = null


func _ready() -> void:
	_bind_layout()
	_refresh_all()
	_connect_profile_manager()
	_setup_buttons()
	_setup_animations()
	_setup_event_buttons()
	orientation_changed.connect(_on_orientation_changed)


## Quay lại Main (vd: thắng/thua màn xong) ⇒ số Sao/Xu/rương và bản đồ có thể đã đổi
func _on_active() -> void:
	_refresh_wallet()
	_refresh_stars()
	_refresh_dungeon_pill()
	_refresh_event_buttons()
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
	_setup_event_buttons()


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
	var gm := Svc.game()
	var total := 0
	if gm != null and gm.has_method("total_stars"):
		total = int(gm.call("total_stars"))
	layout.star_chip.set_value(total)


func _refresh_stamp() -> void:
	if layout == null or layout.stamp_label == null:
		return
	var app := Svc.app()
	var version := "1.0.0"
	if app != null:
		version = str(app.call("get_version"))
	layout.stamp_label.text = tr("STR_SETTINGS_VERSION").format([version])


## Nút Dungeon nổi: "DUNGEON · Tầng N" (kỷ lục)
func _refresh_dungeon_pill() -> void:
	if layout == null or layout.level_section == null or layout.level_section.dungeon_pill == null:
		return
	layout.level_section.dungeon_pill.setup(int(Achievement.stat_value("dungeon_best_floor")))


## Sticker HỒ SƠ: avatar + viền khung + cấp độ + tên + XP (node con tự lo)
func _refresh_profile() -> void:
	if layout != null and layout.profile_card != null:
		layout.profile_card.refresh()


## Hồ sơ đổi (đổi avatar/viền/tên ở popup) → thẻ hồ sơ cập nhật theo
func _connect_profile_manager() -> void:
	var m := Profile.manager()
	# keep-code: nối tới AUTOLOAD ProfileManager (không phải node tĩnh) — §5B.4 mục 4
	if m != null and m.has_signal("profile_changed") and not m.is_connected("profile_changed", _refresh_profile):
		m.connect("profile_changed", _refresh_profile)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh


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
	_connect_pressed(layout.dock_daily, _on_daily_pressed)
	_connect_pressed(layout.dock_badges, _on_achievement_pressed)
	if layout.level_section != null:
		_connect_pressed(layout.level_section.dungeon_pill, _on_dungeon_pressed)


func _on_daily_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_daily()


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
	var gm := Svc.game()
	if gm != null and gm.has_method("start_dungeon"):
		gm.start_dungeon()
	else:
		Nav.goto_game()


func _on_settings_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_settings()


func _on_achievement_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_achievement()


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

func _setup_event_buttons() -> void:
	if layout == null:
		return
	var section := layout.level_section
	if section == null:
		return
	if _event_buttons == null or not is_instance_valid(_event_buttons) or _event_buttons.get_parent() != section:
		_event_buttons = EventButtonColumnScene.instantiate() as Control
		# keep-code: tên node là HỢP ĐỒNG với test (`LevelSection/EventButtons`), không phải bố cục
		_event_buttons.name = "EventButtons"
		section.add_child(_event_buttons)
		_event_buttons.event_pressed.connect(_on_event_card_pressed)
		if section.map != null and not section.map.blockers.has(_event_buttons):
			section.map.blockers.append(_event_buttons)
	var em := Svc.event()
	# keep-code: nối tới AUTOLOAD EventManager (không phải node tĩnh) — §5B.4 mục 4
	if em != null and em.has_signal("events_changed") and not em.is_connected("events_changed", _on_events_changed):
		em.events_changed.connect(_on_events_changed)
	_refresh_event_buttons()


## Danh sách event hiện có (KHÔNG gồm Daily — Daily đã về dock). Tối đa 5 (cột tự cắt).
func _refresh_event_buttons() -> void:
	if _event_buttons == null or not is_instance_valid(_event_buttons):
		return
	var em := Svc.event()
	var list: Array = []
	if em != null and em.has_method("get_active_events"):
		for ev in em.call("get_active_events") as Array:
			if ev != null and not _is_daily_event(ev.id):
				list.append(ev)
	_event_buttons.set_events(list, em)
	# Bản đồ co lại phần bề rộng của cột nút ⇒ node level / cổng không bị nút event đè lên
	var section := layout.level_section if layout != null else null
	if section != null and section.map != null:
		_event_buttons.reserve_gutter(section.map.get_parent() as Control)


func _on_events_changed() -> void:
	_refresh_event_buttons()


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
	var em := Svc.event()
	if em == null or not em.has_method("get_event"):
		return event_id == &"daily"
	var event: EventData = em.call("get_event", event_id)
	return event != null and event.type == EventData.Type.DAILY
