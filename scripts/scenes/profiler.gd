class_name ProfilerScene
extends BaseScene
## ============================================================================
## Màn HỒ SƠ CÁ NHÂN (scenes/profiler.tscn) — mockup/profiler.svg (dọc)
##
## Nguồn dữ liệu: PlayerProfileManager (qua facade `Profile`) + Sổ tay danh hiệu
## (`Archivement`) + Cửa hàng (`Shop`) cho mục "Trang bị đang dùng".
##
## Layout tĩnh (vị trí/kích thước/dây nút) khai trong
## `scenes/layout/portrait/profiler.tscn`; ở đây chỉ ĐỔ DỮ LIỆU +
## MÀU theo trạng thái (cấp bậc, tỉ lệ thắng, trạng thái ván…).
## ============================================================================

const ROW_SCENE := preload("res://nodes/profiler/activity_row.tscn")
const ICON_LOCK := preload("res://assets/images/icons/icon_lock.svg")

## Số hàng lịch sử hiển thị (mockup: 3)
const ACTIVITY_ROWS := 3
## Số huy hiệu trên giá (mockup: 3)
const BADGE_SLOTS := 3

# Màu số liệu (mockup: điểm đỏ · streak cam · thắng xanh · sao vàng)
const COLOR_GOLD := Color(0.7098, 0.3529, 0.0353)      # #B45309
const COLOR_RED := Color(0.8471, 0.2667, 0.2667)       # #D84444
const COLOR_STREAK := Color(0.8510, 0.4667, 0.0235)    # #D97706
const COLOR_GREEN := Color(0.0863, 0.6392, 0.2902)     # #16A34A
const COLOR_MUTED := Color(0.5804, 0.6392, 0.7216)     # #94A3B8

## Layout đang hiển thị (Portrait / Landscape — cùng tên node, bind qua @export)
var layout: ProfilerLayout = null

var _flash_token := 0


func _ready() -> void:
	_bind_refs()
	# Dây nút khai trong `scenes/profiler.tscn` (cả 2 hướng) — guard chỉ nối lại nếu mất
	if layout != null:
		ensure_signal(layout.btn_back, &"pressed", &"_on_back_pressed")
		ensure_signal(layout.btn_edit, &"pressed", &"_on_edit_pressed")
		ensure_signal(layout.btn_share, &"pressed", &"_on_share_pressed")
		var hero_btn := layout.hero_btn_avatar as BaseButton
		ensure_signal(hero_btn, &"pressed", &"_on_edit_pressed")
		ensure_signal(layout.btn_more(), &"pressed", &"_on_badges_more_pressed")
	orientation_changed.connect(_on_orientation_changed)
	_connect_manager()
	refresh()


func _bind_refs() -> void:
	layout = active_layout() as ProfilerLayout
	if layout == null:
		push_warning("profiler: bố cục chưa gắn ProfilerLayout — thiếu binding trong scenes/layout/<hướng>/profiler.tscn")


func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	refresh()


func _connect_manager() -> void:
	var m := Profile.manager()
	if m != null and m.has_signal("profile_changed") and not m.is_connected("profile_changed", _on_profile_changed):
		m.connect("profile_changed", _on_profile_changed)


func _on_profile_changed() -> void:
	refresh()


# ---------------------------------------------------------------------------
# API công khai (test)
# ---------------------------------------------------------------------------
## Nạp lại toàn bộ số liệu hồ sơ lên layout đang hiển thị
func refresh() -> void:
	if layout == null:
		return
	Archivement.refresh()
	_refresh_header()
	_refresh_hero()
	_refresh_stats()
	_refresh_badges()
	_refresh_gear()
	_refresh_activity()


func activity_row_count() -> int:
	if layout == null or layout.rows_box == null:
		return 0
	var count := 0
	for child in layout.rows_box.get_children():
		if child is ProfilerActivityRow:
			count += 1
	return count


# ---------------------------------------------------------------------------
# Nút
# ---------------------------------------------------------------------------
func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_main()


func _on_edit_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Popups.open(Popups.EDIT_PROFILE)


func _on_badges_more_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_archivement()


func _on_share_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var text := "%s • %s • %s %d/%d" % [
		Profile.display_name(),
		tr("STR_PROFILE_LEVEL_FORMAT").format([Profile.level()]),
		tr("STR_PROFILE_STAT_STARS"),
		int(Profile.stats().get("stars", 0)),
		int(Profile.stats().get("stars_max", 0)),
	]
	DisplayServer.clipboard_set(text)
	_flash_share_label()


## Nháy nhãn nút Chia sẻ thành "Đã sao chép hồ sơ!" rồi trả về như cũ
func _flash_share_label() -> void:
	var label := _button_label(layout.btn_share)
	if label == null:
		return
	_flash_token += 1
	var token := _flash_token
	label.text = tr("STR_PROFILE_SHARE_DONE")
	await get_tree().create_timer(1.4).timeout
	if token == _flash_token and is_instance_valid(label):
		label.text = tr("STR_PROFILE_SHARE_BTN")


# ---------------------------------------------------------------------------
# Nạp dữ liệu từng khu
# ---------------------------------------------------------------------------
func _refresh_header() -> void:
	var chip := layout.chip_text()
	if chip != null:
		chip.text = tr("STR_PROFILE_LEVEL_FORMAT").format([Profile.level()])
	if layout.lbl_title != null:
		layout.lbl_title.text = tr("STR_PROFILE_TITLE")


func _refresh_hero() -> void:
	_set_texture(layout.hero_avatar, Profile.avatar_icon(Profile.avatar_id()))
	_set_texture(layout.hero_frame, Profile.frame_icon(Profile.frame_id()))
	# Các nhãn thẻ hero: bind thẳng trong .tscn (2 hướng khai cùng tên)
	if layout.hero_name != null:
		layout.hero_name.text = Profile.display_name()
	if layout.hero_tier_text != null:
		layout.hero_tier_text.text = tr(Profile.title_key())
	if layout.hero_exp_value != null:
		layout.hero_exp_value.text = tr("STR_PROFILE_EXP_FORMAT").format([Profile.exp_in_level(), Profile.exp_step()])
	if layout.hero_uid != null:
		layout.hero_uid.text = tr("STR_PROFILE_UID_FORMAT").format([Profile.uid_text()])
	_fill_bar()


## Thanh EXP: bề rộng phần tô theo tỉ lệ EXP trong cấp
## (BarFill khai neo "left-wide" trong .tscn nên bề rộng = offset_right,
##  chiều cao do neo quyết định — đặt thẳng `size` sẽ bị hệ layout ghi đè)
func _fill_bar() -> void:
	var track := layout.hero_track
	var fill := layout.hero_fill
	if track == null or fill == null:
		return
	var step := maxi(Profile.exp_step(), 1)
	var ratio := clampf(float(Profile.exp_in_level()) / float(step), 0.0, 1.0)
	fill.offset_right = fill.offset_left + maxf(roundf(track.size.x * ratio), 4.0)


func _refresh_stats() -> void:
	var data := Profile.stats()
	_set_stat(0, tr("STR_PROFILE_STAT_STARS_VALUE").format([int(data.get("stars", 0)), int(data.get("stars_max", 0))]), COLOR_GOLD)
	_set_stat(1, tr("STR_PROFILE_STAT_FLOOR_VALUE").format([int(data.get("dungeon_floor", 0))]), COLOR_RED)
	_set_stat(2, tr("STR_PROFILE_STAT_STREAK_VALUE").format([int(data.get("streak", 0))]), COLOR_STREAK)
	var rate := float(data.get("win_rate", -1.0))
	if rate < 0.0:
		_set_stat(3, tr("STR_PROFILE_STAT_NONE"), COLOR_MUTED)
	else:
		_set_stat(3, tr("STR_PROFILE_STAT_WINRATE_VALUE").format(["%.1f" % rate]), COLOR_GREEN)


## index 0..3 ứng với Stat1..Stat4 khai trong .tscn (node con: Name · Value · Icon)
func _set_stat(index: int, value: String, color: Color) -> void:
	var card := layout.stat_card(index)
	if card == null:
		return
	var value_label := card.get_node_or_null("Value") as Label
	if value_label != null:
		value_label.text = value
		_tint(value_label, color)
	var icon := card.get_node_or_null("Icon") as TextureRect
	if icon != null:
		icon.self_modulate = color


func _refresh_badges() -> void:
	var ap := layout.ap_text()
	if ap != null:
		ap.text = tr("STR_PROFILE_AP_FORMAT").format([Archivement.points()])
	var entries := _badge_entries()
	for slot_index in BADGE_SLOTS:
		var slot := layout.badge_slot(slot_index)
		if slot == null:
			continue
		var has_entry := slot_index < entries.size()
		slot.visible = has_entry
		if not has_entry:
			continue
		var entry: Dictionary = entries[slot_index]
		var icon := slot.get_node_or_null("Icon") as TextureRect
		if icon != null:
			icon.texture = ICON_LOCK if bool(entry.get("secret_hidden", false)) else entry.get("icon", null) as Texture2D
			icon.self_modulate = Color(1, 1, 1, 1)
		var name_label := slot.get_node_or_null("Name") as Label
		if name_label != null:
			name_label.text = str(entry.get("title", ""))


## Huy hiệu trên giá: ưu tiên mục ĐÃ ĐẠT (nhiều AP trước), thiếu thì lấy mục sắp đạt
func _badge_entries() -> Array:
	var unlocked: Array = []
	var pending: Array = []
	for entry in Archivement.entries():
		if bool(entry.get("secret_hidden", false)):
			pending.append(entry)
		elif bool(entry.get("unlocked", false)):
			unlocked.append(entry)
		else:
			pending.append(entry)
	unlocked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("points", 0)) > int(b.get("points", 0)))
	pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("pct", 0)) > int(b.get("pct", 0)))
	var out: Array = []
	for entry in unlocked:
		if out.size() >= BADGE_SLOTS:
			break
		out.append(entry)
	for entry in pending:
		if out.size() >= BADGE_SLOTS:
			break
		out.append(entry)
	return out


func _refresh_gear() -> void:
	_set_gear_card(0, tr("STR_PROFILE_GEAR_PEN"), _pen_icon(), _pen_name(), Color(1, 1, 1, 1))
	var theme_item := Shop.item(Shop.equipped_theme())
	var theme_tint := Color(str(theme_item.get("color", "#3D83AE")))
	_set_gear_card(1, tr("STR_PROFILE_GEAR_THEME"), load("res://assets/images/icons/icon_paper.svg") as Texture2D,
		tr(str(theme_item.get("name_key", ""))), theme_tint)
	_set_gear_card(2, tr("STR_PROFILE_GEAR_FRAME"), load(Profile.frame_icon(Profile.frame_id())) as Texture2D,
		_frame_name(), Color(1, 1, 1, 1))


func _set_gear_card(index: int, caption: String, icon: Texture2D, name_text: String, tint: Color) -> void:
	var card := layout.gear_card(index)
	if card == null:
		return
	var caption_label := card.get_node_or_null("Caption") as Label
	if caption_label != null:
		caption_label.text = caption
	var name_label := card.get_node_or_null("Name") as Label
	if name_label != null:
		name_label.text = name_text
	var icon_rect := card.get_node_or_null("Icon") as TextureRect
	if icon_rect != null:
		icon_rect.texture = icon
		icon_rect.self_modulate = tint


func _pen_icon() -> Texture2D:
	var skin: Dictionary = PenSkin.SKINS.get(Shop.equipped_pen(), {})
	var icon_path := str(skin.get("icon", "res://assets/images/icons/icon_pen.svg"))
	return load(icon_path) as Texture2D


func _pen_name() -> String:
	var item := Shop.item(Shop.equipped_pen())
	var key := str(item.get("name_key", ""))
	return tr(key) if not key.is_empty() else tr("STR_PROFILE_GEAR_PEN")


func _frame_name() -> String:
	var frame_ident := Profile.frame_id()
	for entry in Profile.frames():
		if str(entry.get("id", "")) == frame_ident:
			return tr(str(entry.get("name_key", "")))
	return tr("STR_PROFILE_GEAR_FRAME")


func _refresh_activity() -> void:
	if layout.rows_box == null:
		return
	for child in layout.rows_box.get_children():
		if child is ProfilerActivityRow:
			layout.rows_box.remove_child(child)
			child.queue_free()
	var rows := Profile.recent(ACTIVITY_ROWS)
	var empty := layout.rows_box.get_node_or_null("Empty") as Label
	if empty != null:
		empty.visible = rows.is_empty()
	for row_data in rows:
		var row := ROW_SCENE.instantiate() as ProfilerActivityRow
		layout.rows_box.add_child(row)
		row.set_row(row_data)


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _set_texture(node: Control, path: String) -> void:
	var rect := node as TextureRect
	if rect == null or path.is_empty():
		return
	rect.texture = load(path) as Texture2D


## Nhãn trong nút 9-slice: Label tên "Text" (khai trong .tscn)
func _button_label(button: BaseButton) -> Label:
	return button.get_node_or_null("Text") as Label if button != null else null


## Màu chữ theo DỮ LIỆU (khác nhau mỗi ô) ⇒ nhân bản LabelSettings rồi đổi font_color
func _tint(label: Label, color: Color) -> void:
	if label.label_settings == null:
		label.add_theme_color_override("font_color", color)
		return
	var settings := label.label_settings.duplicate() as LabelSettings
	settings.font_color = color
	label.label_settings = settings
