class_name DebugScene
extends BaseScene
## ============================================================================
## Màn hình DEBUG / DEV CONSOLE (scenes/debug.tscn) — chỉ dùng khi phát triển.
##
## Cách mở:
##   - Phím F9 (input action "debug_console" do DebugManager tự đăng ký), bấm lần nữa để quay lại
##   - Bấm 5 lần vào con dấu phiên bản ở màn Settings (chỉ trong bản debug)
##   - Nav.goto_debug() từ code/test
##
## Nội dung các nhóm được dựng bằng code (dữ liệu khai báo trong _build()) để dễ
## thêm/bớt mục mà không phải sửa .tscn. Chữ trong màn này là chữ dev, không dịch.
## ============================================================================

const ROW_NORMAL := preload("res://assets/images/settings/row_button_normal.svg")
const ROW_PRESSED := preload("res://assets/images/settings/row_button_pressed.svg")
const ROW_FOCUS := preload("res://assets/images/settings/row_button_focus.svg")
const ROW_DANGER_N := preload("res://assets/images/settings/row_button_danger_normal.svg")
const ROW_DANGER_P := preload("res://assets/images/settings/row_button_danger_pressed.svg")
const ROW_DANGER_F := preload("res://assets/images/settings/row_button_danger_focus.svg")
const CHIP := preload("res://assets/images/settings/section_chip.svg")
const DIVIDER := preload("res://assets/images/settings/divider_dashed.svg")
const CHECK_ON := preload("res://assets/images/common/checkbox_checked.svg")
const CHECK_OFF := preload("res://assets/images/common/checkbox_normal.svg")
const CHECK_PRESS := preload("res://assets/images/common/checkbox_pressed.svg")
const CHECK_FOCUS := preload("res://assets/images/common/checkbox_focus.svg")
const BACK_NORMAL := preload("res://assets/images/btn_header_back_normal.svg")
const BACK_PRESSED := preload("res://assets/images/btn_header_back_pressed.svg")

const TOTAL_LEVELS := 9

@onready var _btn_back: TextureButton = $TopBar/Back
@onready var _lbl_title: Label = $TopBar/Title
@onready var _rows: VBoxContainer = $Panel/Content/Scroll/Rows
@onready var _lbl_stats: Label = $Panel/Content/Stats
@onready var _lbl_footer: Label = $Panel/Content/Footer


func _ready() -> void:
	if _btn_back != null:
		_btn_back.pressed.connect(_on_back_pressed)
	if _lbl_title != null:
		_lbl_title.text = "DEBUG CONSOLE"
	if _lbl_footer != null:
		_lbl_footer.text = "~ F9 để đóng · chỉ hiển thị trong bản debug ~"
	_build()


func _process(_delta: float) -> void:
	if _lbl_stats == null:
		return
	_lbl_stats.text = "FPS %d · MEM %.1f MB · Obj %d · Locale %s · Mode %s" % [
		Engine.get_frames_per_second(),
		float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0,
		int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		Loc.current(),
		_current_mode(),
	]


# ---------------------------------------------------------------------------
# Dựng nội dung
# ---------------------------------------------------------------------------
func _build() -> void:
	if _rows == null:
		return
	for child in _rows.get_children():
		child.queue_free()

	_build_state()
	_build_navigate()
	_build_progress()
	_build_daily()
	_build_save()
	_build_popups()
	_build_debug_flags()


func _build_state() -> void:
	_add_section("STATE")
	_add_value("Mode", _current_mode())
	_add_value("Current level", str(_gm_value("current_level", 1)))
	_add_value("Unlocked levels", str(_gm_value("unlocked_levels", 1)))
	_add_value("Save backend", "%s (cloud=%s)" % [Save.backend_id(), str(Save.is_cloud())])
	_add_value("Debug build", str(OS.is_debug_build()))
	_add_value("Platform", OS.get_name())
	_add_value("Popups open", str(Popups.has_open()))


func _build_navigate() -> void:
	_add_section("NAVIGATE")
	_add_action("Main Menu", "scenes/main.tscn", func() -> void: Nav.goto_main())
	_add_action("Select Level", "scenes/levels.tscn", func() -> void: Nav.goto_levels())
	_add_action("Daily Challenge", "scenes/daily.tscn", func() -> void: Nav.goto_daily())
	_add_action("Settings", "scenes/settings.tscn", func() -> void: Nav.goto_settings())
	_add_action("Badge Book", "scenes/archivement.tscn", func() -> void: Nav.goto_archivement())
	_add_action("Dungeon run", "DungeonGameMode - tầng 1", func() -> void: _gm_call("start_dungeon"))


func _build_progress() -> void:
	_add_section("PROGRESS")
	_add_label("Nhảy tới màn (Play mode):", &"PopupSubtitle")
	_add_level_grid()
	_add_action("Unlock all levels", "Mở khoá 1..%d và lưu lại" % TOTAL_LEVELS, _unlock_all_levels)
	_add_action("Set 3 stars (màn đã mở)", "Ghi 3 sao cho mọi màn đang mở khoá", _set_all_stars)
	_add_action("Reset progress", "Xoá màn đã mở + sao (không xoá Daily)", _reset_progress, true)


func _build_daily() -> void:
	_add_section("DAILY")
	_add_value("Today", str(_daily_value("get_today", 1)))
	_add_value("Streak", str(_daily_value("get_streak", 0)))
	_add_action("Play today's daily", "Mở game với challenge của hôm nay", _play_today_daily)
	_add_action("Mark today done (3★)", "Đánh dấu ngày hôm nay hoàn thành", _complete_today_daily)
	_add_action("Reset daily data", "Xoá toàn bộ ngày/sao đã lưu", _reset_daily, true)


func _build_save() -> void:
	_add_section("SAVE")
	_add_value("Backend", Save.backend_id())
	_add_value("Cloud available", str(Save.cloud_available()))
	_add_action("Save now", "SaveManager.save_now() - ghi file ngay", func() -> void: Save.flush())
	_add_action("Reload from disk", "Đọc lại blob và áp vào các manager", func() -> void: Save.reload_all())
	_add_action("Use local backend", "Lưu trên máy (mặc định)", func() -> void: Save.use_local())
	_add_action("Use Google Play backend", "Chỉ chạy khi đã cài plugin Play Games", func() -> void: Save.use_play_games())
	_add_action("Reset ALL saved data", "Xoá tiến trình + daily rồi ghi lại (nguy hiểm)", func() -> void: Save.reset_all(), true)
	_add_label("Blob hiện tại:", &"PopupSubtitle")
	_add_blob_dump()


func _build_popups() -> void:
	_add_section("POPUPS")
	_add_action("Win popup", "Thắng màn (Play mode)", func() -> void: _open_popup(Popups.WIN, _win_data()))
	_add_action("Next floor popup", "Qua tầng (Dungeon)", func() -> void: _open_popup(Popups.NEXT_FLOOR, _next_floor_data()))
	_add_action("Game over popup", "Hết bước / đâm tường", func() -> void: _open_popup(Popups.GAME_OVER, _game_over_data()))
	_add_action("Pause popup", "Tạm dừng + âm lượng", func() -> void: _open_popup(Popups.PAUSE, _pause_data()))
	_add_action("Language popup", "Chọn ngôn ngữ", func() -> void: _open_popup(Popups.LANGUAGE, {}))
	_add_action("Close all popups", "Đóng mọi popup đang mở", func() -> void: Popups.close_all())


func _build_debug_flags() -> void:
	_add_section("DEBUG FLAGS")
	var dbg := _debug_manager()
	if dbg == null:
		_add_label("Không tìm thấy DebugManager", &"PopupSubtitle")
		return
	_add_toggle("Debug logging", "Tắt/bật toàn bộ log debug", bool(dbg.get("enabled")),
		func(on: bool) -> void: dbg.call("set_enabled", on))
	for category in [dbg.CAT_GENERAL, dbg.CAT_SFX, dbg.CAT_FLOW, dbg.CAT_SAVE]:
		var name := str(category)
		var current := bool(dbg.call("is_flag_on", name))
		_add_toggle("· %s" % name, "Nhóm log", current,
			func(on: bool) -> void: dbg.call("set_flag", name, on))
	_add_action("Test log (all categories)", "In thử 4 dòng log", _test_logs)


# ---------------------------------------------------------------------------
# Hành động
# ---------------------------------------------------------------------------
func _unlock_all_levels() -> void:
	var gm := _game_manager()
	if gm == null:
		return
	gm.set("unlocked_levels", TOTAL_LEVELS)
	for id in range(1, TOTAL_LEVELS + 1):
		var stars: Dictionary = gm.get("level_stars")
		if not stars.has(id):
			stars[id] = 0
	gm.set("level_stars", gm.get("level_stars"))
	Save.queue_save()
	_rebuild_after_action("Đã mở khoá %d màn" % TOTAL_LEVELS)


func _set_all_stars() -> void:
	var gm := _game_manager()
	if gm == null:
		return
	var unlocked := int(gm.get("unlocked_levels"))
	var stars: Dictionary = gm.get("level_stars")
	for id in range(1, unlocked + 1):
		stars[id] = 3
	gm.set("level_stars", stars)
	Save.queue_save()
	_rebuild_after_action("Đã ghi 3 sao cho %d màn" % unlocked)


func _reset_progress() -> void:
	var gm := _game_manager()
	if gm == null:
		return
	gm.set("unlocked_levels", 1)
	gm.set("level_stars", { 1: 0 })
	gm.set("level_best_time", {})
	gm.set("current_level", 1)
	Save.queue_save()
	_rebuild_after_action("Đã xoá tiến trình màn chơi")


func _play_today_daily() -> void:
	_gm_call("start_daily", int(_daily_value("get_today", 1)))


func _complete_today_daily() -> void:
	var daily := _daily_manager()
	if daily == null:
		return
	daily.call("set_day_stars", int(daily.call("get_today")), 3)
	_rebuild_after_action("Đã đánh dấu hôm nay hoàn thành (3★)")


func _reset_daily() -> void:
	var daily := _daily_manager()
	if daily == null:
		return
	if daily.has_method("reset_progress"):
		daily.call("reset_progress")
	Save.queue_save()
	_rebuild_after_action("Đã xoá dữ liệu Daily")


func _test_logs() -> void:
	var dbg := _debug_manager()
	if dbg == null:
		return
	dbg.call("log", dbg.CAT_GENERAL, "debug console test - general")
	dbg.call("log", dbg.CAT_SFX, "debug console test - sfx")
	dbg.call("log", dbg.CAT_FLOW, "debug console test - flow")
	dbg.call("log", dbg.CAT_SAVE, "debug console test - save")


func _open_popup(id: String, data: Dictionary) -> void:
	if not Popups.has_open():
		Popups.open(id, data)


func _rebuild_after_action(message: String) -> void:
	Sfx.play(Sfx.CHECKBOX)
	if _lbl_footer != null:
		_lbl_footer.text = "~ %s ~" % message
	_build()


# ---------------------------------------------------------------------------
# Dữ liệu mẫu cho popup
# ---------------------------------------------------------------------------
func _win_data() -> Dictionary:
	return {
		"level": _gm_value("current_level", 1), "grid": "5×5", "time": 48.0,
		"steps_used": 11, "steps_max": 20, "wall_hits": 0, "score": 2850, "stars": 3,
	}


func _next_floor_data() -> Dictionary:
	return {
		"floor": 4, "next_floor": 5, "steps_bonus": 5, "base_score": 500,
		"move_bonus": 240, "perfect_bonus": 300, "total_score": 4690,
	}


func _game_over_data() -> Dictionary:
	return {"floor": 4, "progress": 75.0, "wall_hits": 3, "score": 850}


func _pause_data() -> Dictionary:
	return {"floor": 4, "steps_left": 14, "steps_max": 20, "mode_name": "dungeon"}


# ---------------------------------------------------------------------------
# Tiện ích dựng UI
# ---------------------------------------------------------------------------
func _add_section(title: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 58)
	_rows.add_child(row)

	var chip := TextureRect.new()
	chip.texture = CHIP
	chip.custom_minimum_size = Vector2(212, 40)
	chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(chip)

	var label := Label.new()
	label.theme_type_variation = &"PopupSectionLabel"
	label.text = title
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 6
	label.offset_top = 6
	label.offset_right = -6
	label.offset_bottom = -6
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chip.add_child(label)

	var divider := TextureRect.new()
	divider.texture = DIVIDER
	divider.custom_minimum_size = Vector2(0, 6)
	divider.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider.stretch_mode = TextureRect.STRETCH_TILE
	_rows.add_child(divider)


func _add_label(text: String, variation: StringName) -> void:
	var label := Label.new()
	label.theme_type_variation = variation
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(label)


## Hàng chỉ để xem thông tin: tên bên trái, giá trị bên phải
func _add_value(name: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 42)
	_rows.add_child(row)

	var key := Label.new()
	key.theme_type_variation = &"PopupRowLabel"
	key.text = name
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(key)

	var val := Label.new()
	val.theme_type_variation = &"PopupStatValueSm"
	val.text = value
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(val)


## Nút hành động (danger = đỏ cho hành động phá dữ liệu)
func _add_action(text: String, desc: String, handler: Callable, danger := false) -> TextureButton:
	var button := TextureButton.new()
	button.custom_minimum_size = Vector2(0, 84)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_SCALE
	if danger:
		button.texture_normal = ROW_DANGER_N
		button.texture_pressed = ROW_DANGER_P
		button.texture_hover = ROW_DANGER_P
		button.texture_focused = ROW_DANGER_F
	else:
		button.texture_normal = ROW_NORMAL
		button.texture_pressed = ROW_PRESSED
		button.texture_hover = ROW_PRESSED
		button.texture_focused = ROW_FOCUS
	button.pressed.connect(handler)
	_rows.add_child(button)

	var title := Label.new()
	title.theme_type_variation = &"PopupBtnTextMuted" if danger else &"PopupBtnText"
	title.text = text
	title.position = Vector2(30, 10)
	title.size = Vector2(600, 30)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(title)

	var sub := Label.new()
	sub.theme_type_variation = &"LangSub"
	sub.text = desc
	sub.position = Vector2(30, 42)
	sub.size = Vector2(600, 26)
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_child(sub)

	return button


## Hàng có checkbox bật/tắt
func _add_toggle(text: String, desc: String, value: bool, handler: Callable) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 74)
	row.add_theme_constant_override("separation", 16)
	_rows.add_child(row)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text_box)

	var title := Label.new()
	title.theme_type_variation = &"PopupRowLabel"
	title.text = text
	text_box.add_child(title)

	var sub := Label.new()
	sub.theme_type_variation = &"LangSub"
	sub.text = desc
	text_box.add_child(sub)

	var check := TextureButton.new()
	check.custom_minimum_size = Vector2(50, 50)
	check.toggle_mode = true
	check.button_pressed = value
	check.ignore_texture_size = true
	check.stretch_mode = TextureButton.STRETCH_SCALE
	check.texture_normal = CHECK_OFF
	check.texture_pressed = CHECK_ON
	check.texture_hover = CHECK_PRESS
	check.texture_focused = CHECK_FOCUS
	check.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	check.toggled.connect(func(on: bool) -> void:
		Sfx.play(Sfx.CHECKBOX)
		handler.call(on)
	)
	row.add_child(check)


## Lưới nút nhảy nhanh tới từng màn
func _add_level_grid() -> void:
	var grid := GridContainer.new()
	grid.columns = TOTAL_LEVELS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	_rows.add_child(grid)

	for id in range(1, TOTAL_LEVELS + 1):
		var level_id := id
		var unlocked := level_id <= int(_gm_value("unlocked_levels", 1))
		var btn := TextureButton.new()
		btn.custom_minimum_size = Vector2(0, 74)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.texture_normal = ROW_NORMAL
		btn.texture_pressed = ROW_PRESSED
		btn.texture_hover = ROW_PRESSED
		btn.texture_focused = ROW_FOCUS
		btn.pressed.connect(func() -> void:
			Sfx.play(Sfx.BTN_CLICK)
			_gm_call("start_level", level_id)
		)
		grid.add_child(btn)

		var num := Label.new()
		num.theme_type_variation = &"PopupTotalLabelSm"
		num.text = str(level_id)
		num.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.modulate = Color(1, 1, 1, 1) if unlocked else Color(1, 1, 1, 0.45)
		btn.add_child(num)


## Xem nhanh blob lưu trữ (JSON) - hữu ích khi kiểm tra tiến trình
func _add_blob_dump() -> void:
	var sm := _save_manager()
	var dump := "(không có SaveManager)"
	if sm != null:
		var blob: Dictionary = sm.call("collect")
		dump = JSON.stringify(blob, "  ")
	var label := Label.new()
	label.theme_type_variation = &"LangSub"
	label.text = dump
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rows.add_child(label)


# ---------------------------------------------------------------------------
# Truy cập manager (dùng /root để chạy được cả trong test --script)
# ---------------------------------------------------------------------------
func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _daily_manager() -> Node:
	return get_node_or_null("/root/DailyManager")


func _save_manager() -> Node:
	return get_node_or_null("/root/SaveManager")


func _debug_manager() -> Node:
	return get_node_or_null("/root/DebugManager")


func _gm_value(key: String, fallback: Variant) -> Variant:
	var gm := _game_manager()
	return gm.get(key) if gm != null else fallback


func _gm_call(method: String, arg: Variant = null) -> void:
	var gm := _game_manager()
	if gm == null:
		return
	Sfx.play(Sfx.BTN_CLICK)
	if arg == null:
		gm.call(method)
	else:
		gm.call(method, arg)


func _daily_value(method: String, fallback: Variant) -> Variant:
	var daily := _daily_manager()
	return daily.call(method) if daily != null else fallback


func _current_mode() -> String:
	return str(_gm_value("current_mode", "dungeon"))


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_main()
