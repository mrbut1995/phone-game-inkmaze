extends SceneTree
## ============================================================================
## Test Case: SCENE DỰNG SẴN CHO UI
## (không tạo node UI bằng `.new()` trong code — mọi node UI phải có .tscn + script)
##
## 1. Từng scene con của các màn phải dựng ĐÚNG cấu trúc con
##    (node con của root phải ghi parent="." trong .tscn).
## 2. API lấy từ scene hoạt động: setup / set_active / set_current / cỡ theo layout.
## 3. Không script màn hình nào còn `.new()` cho lớp UI.
## ============================================================================

const UI_CLASSES := ["Control", "Label", "TextureRect", "TextureButton", "Button",
	"NinePatchRect", "ColorRect", "VBoxContainer", "HBoxContainer", "GridContainer",
	"MarginContainer", "PanelContainer", "ScrollContainer", "TextureProgressBar"]
## Script ngoại lệ (dev-only, không phải UI người chơi — xem TODO vòng 17)
const SKIP_SOURCES := ["debug.gd"]

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: SCENE DUNG SAN CHO UI")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	_section_1_shop()
	_section_2_archivement()
	_section_3_levels()
	_section_4_ranking()
	_section_5_host()
	_section_6_sources()
	_section_7_board_hud_popup()

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Cửa hàng: tab · lưới 2 cột · chấm trang
# ---------------------------------------------------------------------------
func _section_1_shop() -> void:
	print("[1] Scene con màn Cửa hàng...")

	var tab := _spawn("res://nodes/shop/tab_button.tscn") as ShopTabButton
	_entry(tab != null, "tab_button.tscn instantiate ra ShopTabButton")
	if tab == null:
		return
	_entry(tab.get_node_or_null("Label") != null,
		"tab_button.tscn co node con 'Label' (parent=\".\")")
	_entry(tab.get_child_count() == 1, "tab chi co 1 node con (nhan)")
	_entry(is_equal_approx(ShopTabButton.art_height(), 98.0),
		"chieu cao tab lay tu art = 98 (dang %.0f)" % ShopTabButton.art_height())
	_entry(ShopTabButton.inactive_ratio() > 0.0 and ShopTabButton.inactive_ratio() < 1.0,
		"tab chua chon thap hon tab dang chon")

	tab.setup("pen", "STR_SHOP_TAB_PEN")
	_entry(not tab.label.text.is_empty(), "setup() gan nhan: '%s'" % tab.label.text)

	tab.set_active(true)
	var art_active: Texture2D = tab.texture_normal
	tab.set_active(false)
	_entry(art_active != null and art_active != tab.texture_normal,
		"set_active() doi art giua 2 trang thai")

	tab.set_active(true)
	tab.apply_row_layout(200.0, 98.0, 83.0)
	_entry(tab.custom_minimum_size == Vector2(200, 98), "tab dang chon: 200x98")
	tab.set_active(false)
	tab.apply_row_layout(200.0, 98.0, 83.0)
	_entry(tab.custom_minimum_size == Vector2(200, 83), "tab chua chon: 200x83")
	_entry(is_equal_approx(tab.label.position.y, -15.0),
		"nhan tab chua chon duoc nang len cho thang hang (%.0f)" % tab.label.position.y)
	_entry(tab.size_flags_vertical == Control.SIZE_SHRINK_END, "tab canh DAY hang")
	tab.queue_free()

	var grid := _spawn("res://nodes/shop/item_grid.tscn") as ShopItemGrid
	_entry(grid != null, "item_grid.tscn instantiate ra ShopItemGrid")
	if grid != null:
		_entry(grid.columns == 2, "luoi the: 2 cot")
		_entry(grid.get_theme_constant("h_separation") == 30, "khe ngang 30 (tu scene)")
		_entry(grid.get_theme_constant("v_separation") == 24, "khe doc 24 (tu scene)")
		grid.queue_free()

	var dot := _spawn("res://nodes/shop/page_dot.tscn") as ShopPageDot
	_entry(dot != null, "page_dot.tscn instantiate ra ShopPageDot")
	if dot != null:
		dot.set_current(true)
		_entry(dot.custom_minimum_size == Vector2(34, 24), "cham dang xem: 34x24")
		dot.set_current(false)
		_entry(dot.custom_minimum_size == Vector2(12, 24), "cham thuong: 12x24")
		dot.queue_free()


# ---------------------------------------------------------------------------
# 2. Sổ tay: tab · trang (cột dọc) · chấm trang
# ---------------------------------------------------------------------------
func _section_2_archivement() -> void:
	print("[2] Scene con màn Sổ tay...")

	var tab := _spawn("res://nodes/archivements/tab_button.tscn") as AchTabButton
	_entry(tab != null, "tab_button.tscn instantiate ra AchTabButton")
	if tab != null:
		_entry(tab.get_node_or_null("Label") != null, "tab Sổ tay co nhan tu scene")
		tab.setup("all")
		_entry(not tab.label.text.is_empty(), "setup() gan nhan: '%s'" % tab.label.text)
		tab.set_active(true)
		var on_color := tab.label.modulate
		tab.set_active(false)
		var off_color := tab.label.modulate
		_entry(on_color != off_color, "set_active() doi mau nhan")
		tab.queue_free()

	var page := _spawn("res://nodes/archivements/page.tscn") as AchPage
	_entry(page != null, "page.tscn instantiate ra AchPage")
	if page != null:
		_entry(page.get_node_or_null("Column") != null,
			"trang co node con 'Column' (parent=\".\")")
		_entry(page.column() != null and page.column().get_parent() == page,
			"column() tra ve cot that su cua trang")
		_entry(page.column().get_theme_constant("separation") == 20,
			"khe giua cac the = 20 (tu scene)")
		page.column().add_child(Label.new())
		_entry(page.column().get_child_count() == 1, "them the vao cot = vao dung trang")
		page.queue_free()

	var dot := _spawn("res://nodes/archivements/page_dot.tscn")
	_entry(dot != null, "page_dot.tscn instantiate duoc")
	if dot != null:
		dot.call("set_current", true)
		_entry(dot.custom_minimum_size.x > 0.0, "dot dang xem co co (%.0fx%.0f)"
			% [dot.custom_minimum_size.x, dot.custom_minimum_size.y])
		dot.queue_free()


# ---------------------------------------------------------------------------
# 3. Chọn màn: trang (lưới 3 cột) · chấm trang
# ---------------------------------------------------------------------------
func _section_3_levels() -> void:
	print("[3] Scene con màn Chọn màn...")

	var page := _spawn("res://nodes/level_selection/page.tscn") as LevelsPage
	_entry(page != null, "page.tscn instantiate ra LevelsPage")
	if page != null:
		_entry(page.get_node_or_null("Grid") != null,
			"trang co node con 'Grid' (parent=\".\")")
		_entry(page.grid() != null and page.grid().get_parent() == page,
			"grid() tra ve luoi that su cua trang")
		_entry(page.grid().columns == 3, "luoi 3 cot (tu scene)")
		_entry(page.grid().get_theme_constant("h_separation") == 46, "khe ngang 46")
		_entry(page.grid().get_theme_constant("v_separation") == 24, "khe doc 24")
		page.grid().add_child(Control.new())
		_entry(page.grid().get_child_count() == 1, "them the man vao luoi = vao dung trang")
		page.queue_free()

	var dot := _spawn("res://nodes/level_selection/page_dot.tscn")
	_entry(dot != null, "page_dot.tscn instantiate duoc")
	if dot != null:
		dot.call("set_current", true)
		_entry(dot.custom_minimum_size.x > 0.0, "dot dang xem co co")
		dot.queue_free()


# ---------------------------------------------------------------------------
# 4. Xếp hạng: tab (cỡ riêng theo bảng)
# ---------------------------------------------------------------------------
func _section_4_ranking() -> void:
	print("[4] Scene con màn Xếp hạng...")

	var tab := _spawn("res://nodes/ranking/tab_button.tscn") as RankTabButton
	_entry(tab != null, "tab_button.tscn instantiate ra RankTabButton")
	if tab == null:
		return
	_entry(tab.get_node_or_null("Label") != null, "tab Xếp hạng co nhan tu scene")
	tab.setup("play", "THU THACH", 235.0)
	_entry(tab.custom_minimum_size == Vector2(235, 52),
		"tab nhan be rong rieng, cao theo scene (235x52)")
	_entry(tab.label.text == "THU THACH", "setup() gan tieu de")
	tab.set_active(true)
	var art_active: Texture2D = tab.texture_normal
	_entry(art_active != null, "tab dang chon co art")
	tab.set_active(false)
	_entry(art_active != tab.texture_normal, "set_active() doi art")
	_entry(tab.label.has_theme_color_override("font_color"), "nhan doi mau theo trang thai")
	tab.queue_free()


# ---------------------------------------------------------------------------
# 5. Lớp phủ chứa popup
# ---------------------------------------------------------------------------
func _section_5_host() -> void:
	print("[5] Lop phu popup...")

	var host := _spawn("res://nodes/popups/host.tscn") as PopupHost
	_entry(host != null, "host.tscn instantiate ra PopupHost")
	if host == null:
		return
	_entry(host.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"lop phu khong chan input (mouse_filter = IGNORE)")
	_entry(is_equal_approx(host.anchor_right, 1.0) and is_equal_approx(host.anchor_bottom, 1.0),
		"lop phu bam kin man hinh (full-rect)")
	host.queue_free()


# ---------------------------------------------------------------------------
# 6. Không script màn hình nào còn .new() cho lớp UI
# ---------------------------------------------------------------------------
func _section_6_sources() -> void:
	print("[6] Quet ma nguon man hinh...")

	var pattern := RegEx.new()
	var kind := "|".join(UI_CLASSES)
	pattern.compile("(%s)\\.new\\x28" % kind)
	# Bỏ phần CHÚ THÍCH trước khi quét (tài liệu có nhắc `.new()` để giải thích)
	var comments := RegEx.new()
	comments.compile("#[^\\n]*")

	var sources: Array[String] = []
	for folder in ["res://scripts/scenes", "res://scripts/nodes"]:
		_collect_sources(folder, sources)

	var offenders: Array[String] = []
	var scanned := 0
	for path in sources:
		var name := path.get_file()
		if SKIP_SOURCES.has(name):
			continue
		if not FileAccess.file_exists(path):
			continue
		scanned += 1
		var source := FileAccess.get_file_as_string(path)
		var cleaned := comments.sub(source, "", true)
		for m in pattern.search_all(cleaned):
			offenders.append("%s:%d" % [name, cleaned.substr(0, m.get_start()).count("\n") + 1])

	_entry(scanned >= 20, "quet duoc %d script UI" % scanned)
	_entry(offenders.is_empty(),
		"khong script UI nao dung .new() cho lop UI%s"
			% ("" if offenders.is_empty() else " — con: %s" % ", ".join(offenders)))


# ---------------------------------------------------------------------------
# 7. Scene con của Bàn mê cung · HUD đếm ngược · hàng ngôn ngữ
# ---------------------------------------------------------------------------
func _section_7_board_hud_popup() -> void:
	print("[7] Scene con bàn chơi · HUD · hàng ngôn ngữ...")

	var layers: BoardLayers = _spawn("res://nodes/game/board_layers.tscn") as BoardLayers
	_entry(layers != null, "board_layers.tscn instantiate ra BoardLayers")
	if layers != null:
		_entry(layers.cells() != null and layers.lines() != null and layers.walls() != null
			and layers.anchors() != null and layers.markers() != null,
			"đủ 5 lớp vẽ (Cells · Lines · Walls · Anchors · Markers)")
		_entry(layers.cells().get_parent() == layers, "lớp Cells là con của BoardLayers")
		_entry(layers.cells().mouse_filter == Control.MOUSE_FILTER_IGNORE,
			"lớp vẽ không chặn input của bàn")
		layers.queue_free()

	var footstep: InkFootstep = _spawn("res://nodes/game/ink_footstep.tscn") as InkFootstep
	_entry(footstep != null, "ink_footstep.tscn instantiate ra InkFootstep")
	if footstep != null:
		_entry(footstep.mark != null, "vệt mực có node con 'Mark' (parent=\".\")")
		footstep.setup(Vector2(50, 100), null, Color(0.2, 0.3, 0.9))
		_entry(footstep.size == Vector2(36, 36) and footstep.position == Vector2(82, 182),
			"setup() đặt vệt mực đúng TÂM ô (36×36)")
		_entry(is_equal_approx(footstep.mark.modulate.a, 0.45), "độ mờ vệt mực 0.45")
		footstep.queue_free()

	var segment: CountdownSegment = _spawn("res://nodes/hud/countdown_segment.tscn") as CountdownSegment
	_entry(segment != null, "countdown_segment.tscn instantiate ra CountdownSegment")
	if segment != null:
		segment.set_width(20.0)
		_entry(segment.custom_minimum_size == Vector2(20, 12),
			"vạch rộng 20 · cao 12 (cao lấy từ scene)")
		segment.set_width(999.0)
		_entry(segment.custom_minimum_size.x == 38.0, "vạch tự kẹp bề rộng tối đa 38")
		segment.set_used(true)
		var art_off: Texture2D = segment.texture
		segment.set_used(false)
		_entry(art_off != null and art_off != segment.texture, "set_used() đổi art xám ⇄ cam")
		segment.queue_free()

	var row: LanguageRow = _spawn("res://nodes/popups/language_row.tscn") as LanguageRow
	_entry(row != null, "language_row.tscn instantiate ra LanguageRow")
	if row != null:
		_entry(row.check != null and row.flag != null, "hàng ngôn ngữ đủ cờ + dấu tích")
		row.setup({"name": "Tiếng Việt", "sub": "Vietnamese"}, null)
		_entry(row.name_label.text == "Tiếng Việt" and row.sub_label.text == "Vietnamese",
			"setup() điền tên + phụ đề")
		row.set_selected(true)
		_entry(row.button_pressed and row.check.visible, "set_selected() bật nền sáng + dấu tích")
		row.set_selected(false)
		_entry(not row.check.visible, "bỏ chọn thì ẩn dấu tích")
		row.queue_free()


# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------
func _collect_sources(folder: String, out: Array[String]) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	for name in dir.get_files():
		if name.ends_with(".gd"):
			out.append("%s/%s" % [folder, name])
	for sub in dir.get_directories():
		_collect_sources("%s/%s" % [folder, sub], out)


func _spawn(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		_entry(false, "load duoc %s" % path)
		return null
	var node := packed.instantiate()
	root.add_child(node)
	return node


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
