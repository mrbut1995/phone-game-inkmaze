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

## Ảnh icon dock (glyph TRẮNG 96×96 nạp 1 lần — nút dock là khối MÀU đậm nên icon để trắng)
const ICON_SHOP := "res://assets/images-png/dock/dock_shop.png"
const ICON_RANK := "res://assets/images-png/dock/dock_ranking.png"
const ICON_BADGES := "res://assets/images-png/dock/dock_badges.png"
const ICON_RULES := "res://assets/images-png/dock/dock_rules.png"
const ICON_DAILY := "res://assets/images-png/dock/dock_daily.png"
const DOCK_BUTTON_SCENE := preload("res://nodes/main/dock_button.tscn")
const EventButtonColumnScript := preload("res://scripts/nodes/main/event_button_column.gd")

## Màu từng nút dock — PHẢI khớp bảng DOCK trong gen/gen_colorful_art.py: [mặt, viền sáng, đáy 3D tối]
## (code chỉ dùng mặt + đáy cho viền chữ / dự phòng khi thiếu PNG)
const DOCK_COLORS := {
	"shop": ["FF9F1C", "FFD58F", "B96400"],
	"rank": ["3B8EEA", "A3CDF8", "1D5AA3"],
	"badges": ["8E5BD9", "C9AEF2", "593596"],
	"rules": ["22B59B", "8FE3D2", "13796A"],
	"daily": ["E8504F", "F8B0AE", "9E2424"],
}

var layout: MainLayout = null
## Nút Daily trên dock (tạo bằng code — không cần sửa scene) và cột nút event nổi trên bản đồ
var _dock_daily: DockButton = null
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
	_setup_dock_button(layout.dock_shop, ICON_SHOP, tr("STR_BTN_SHOP"), "shop")
	_setup_dock_button(layout.dock_ranking, ICON_RANK, tr("STR_BTN_LEADERBOARD"), "rank")
	_setup_dock_button(layout.dock_badges, ICON_BADGES, tr("STR_BTN_ARCHIVEMENT"), "badges")
	_setup_dock_button(layout.dock_rules, ICON_RULES, tr("STR_MAIN_DOCK_RULES"), "rules")
	_ensure_dock_daily()
	
	if layout.profile_card != null:
		layout.profile_card.connect(&"pressed", _on_profile_pressed)
	
	# Badge danh hiệu: số đã mở / tổng — hiện ở dock Danh hiệu (chấm đỏ chỉ báo)
	if layout.dock_badges != null:
		layout.dock_badges.set_badge(0)
	
	# Ví Xu tự lo nút `+` (CoinChip mở Cửa hàng) — main chỉ cần cập nhật số dư


## Daily về DOCK (không còn nằm trong nhóm event): nút thứ 3 — chính giữa hàng 5 nút.
## Tạo bằng code từ `dock_button.tscn` nên KHÔNG phải sửa main.tscn (cả dọc lẫn ngang).
func _ensure_dock_daily() -> void:
	if layout == null or layout.dock_shop == null:
		return
	var row := layout.dock_shop.get_parent()
	if row == null:
		return
	if _dock_daily == null or not is_instance_valid(_dock_daily) or _dock_daily.get_parent() != row:
		_dock_daily = DOCK_BUTTON_SCENE.instantiate() as DockButton
		_dock_daily.name = "DockDaily"
		_dock_daily.layout_mode = 2
		_dock_daily.size_flags_horizontal = layout.dock_shop.size_flags_horizontal
		_dock_daily.size_flags_vertical = layout.dock_shop.size_flags_vertical
		_dock_daily.custom_minimum_size = layout.dock_shop.custom_minimum_size
		row.add_child(_dock_daily)
		row.move_child(_dock_daily, mini(2, row.get_child_count() - 1))
	var label := tr("STR_MAIN_DOCK_DAILY")
	if label == "STR_MAIN_DOCK_DAILY":
		label = "THỬ THÁCH"   # chưa có khoá dịch ⇒ chữ mặc định
	_setup_dock_button(_dock_daily, ICON_DAILY, label, "daily")
	_connect_pressed(_dock_daily, _on_daily_pressed)


func _on_daily_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_daily()


func _setup_dock_button(button: DockButton, icon_path: String, label: String, key: String) -> void:
	if button == null:
		return
	button.setup(load(icon_path), label)
	var colors: Array = DOCK_COLORS.get(key, DOCK_COLORS["shop"])
	_style_dock_button(button, key, Color(colors[0]), Color(colors[2]))


## Nút dock MÀU: art SVG→PNG 9-slice `assets/images-png/dock/dock_btn_<khoá>_{normal,pressed,focus}.png`
## (nguồn SVG ở `assets/images/dock/`; đổi theme = sửa SVG hoặc `gen/gen_colorful_art.py`).
## Thiếu PNG thì dùng StyleBoxFlat dự phòng. Chữ trắng + viền màu đáy nút; icon trắng.
func _style_dock_button(button: DockButton, key: String, face: Color, base: Color) -> void:
	var normal := _dock_tex_box(key, "normal")
	var pressed := _dock_tex_box(key, "pressed")
	if normal != null and pressed != null:
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", normal)
		button.add_theme_stylebox_override("pressed", pressed)
	else:
		var flat := _dock_box(face, face.lightened(0.4), base, 5.0, 0.0)
		button.add_theme_stylebox_override("normal", flat)
		button.add_theme_stylebox_override("hover", flat)
		button.add_theme_stylebox_override("pressed", _dock_box(face.darkened(0.1), face.lightened(0.4), base, 1.0, 4.0))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_tint_dock_labels(button, base)
	# Mặt nút cao ~57px (đáy 3D nằm dưới): kéo nhãn/icon lên để không đè lên đáy
	var icon_node := button.get_node_or_null("Icon") as Control
	if icon_node != null:
		icon_node.offset_top = 6.0
		icon_node.offset_bottom = 38.0
	var label_node := button.get_node_or_null("Label") as Control
	if label_node != null:
		label_node.offset_top = -27.0
		label_node.offset_bottom = -11.0


func _dock_tex_box(key: String, state: String) -> StyleBoxTexture:
	var path := "res://assets/images-png/dock/dock_btn_%s_%s.png" % [key, state]
	if not ResourceLoader.exists(path):
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.texture_margin_left = 20.0
	sb.texture_margin_right = 20.0
	sb.texture_margin_top = 20.0
	sb.texture_margin_bottom = 26.0
	return sb


func _dock_box(face: Color, light: Color, base: Color, drop: float, sink: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = face
	sb.border_color = light
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.shadow_color = base
	sb.shadow_size = 1
	sb.shadow_offset = Vector2(0.0, drop)
	if sink > 0.0:
		sb.expand_margin_top = -sink
		sb.expand_margin_bottom = sink
	sb.anti_aliasing = true
	return sb


## Mọi nhãn chữ trong nút dock: TRẮNG + viền màu đáy nút (đọc rõ trên nền màu).
func _tint_dock_labels(node: Node, outline: Color = Color(0, 0, 0, 0.35)) -> void:
	for child in node.get_children():
		if child is Label:
			var lbl := child as Label
			lbl.add_theme_color_override("font_color", Color.WHITE)
			lbl.add_theme_color_override("font_outline_color", outline)
			lbl.add_theme_constant_override("outline_size", 4)
		_tint_dock_labels(child, outline)


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

func _setup_event_buttons() -> void:
	if layout == null:
		return
	# Khối thẻ event cũ (header + carousel) ẨN HẲN — nhường chỗ cho bản đồ. Event giờ là cột nút icon.
	if layout.event_header != null:
		layout.event_header.visible = false
	if layout.event_carousel != null:
		layout.event_carousel.visible = false
	var section := layout.level_section
	if section == null:
		return
	# BỐ CỤC NGANG: header + carousel nằm trong cột `Left` (42% bề rộng) cạnh bản đồ ⇒ ẩn luôn cả cột đó
	# (kèm con dấu phiên bản) để bản đồ chiếm trọn chiều ngang. Bố cục dọc: header & carousel là con của
	# `Body` (cùng cha với bản đồ) ⇒ KHÔNG ẩn cha.
	if layout.event_header != null:
		var holder := layout.event_header.get_parent() as Control
		if holder != null and holder != section.get_parent():
			holder.visible = false
	if _event_buttons == null or not is_instance_valid(_event_buttons) or _event_buttons.get_parent() != section:
		_event_buttons = EventButtonColumnScript.new()
		_event_buttons.name = "EventButtons"
		section.add_child(_event_buttons)
		_event_buttons.event_pressed.connect(_on_event_card_pressed)
		if section.map != null and not section.map.blockers.has(_event_buttons):
			section.map.blockers.append(_event_buttons)
	var em := get_node_or_null("/root/EventManager")
	if em != null and em.has_signal("events_changed") and not em.is_connected("events_changed", _on_events_changed):
		em.events_changed.connect(_on_events_changed)
	_refresh_event_buttons()


## Danh sách event hiện có (KHÔNG gồm Daily — Daily đã về dock). Tối đa 5 (cột tự cắt).
func _refresh_event_buttons() -> void:
	if _event_buttons == null or not is_instance_valid(_event_buttons):
		return
	var em := get_node_or_null("/root/EventManager")
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
	var em := get_node_or_null("/root/EventManager")
	if em == null or not em.has_method("get_event"):
		return event_id == &"daily"
	var event: EventData = em.call("get_event", event_id)
	return event != null and event.type == EventData.Type.DAILY
