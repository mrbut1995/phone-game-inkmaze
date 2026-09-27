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
## Những scene đã KHAI SẴN trong scene cha (node MẪU hoặc node cố định) ⇒ script này KHÔNG được
## nhắc tới đường dẫn của chúng nữa (không preload, không instantiate) — xem GDD §10.2g.
const FIXED_SCENES := {
	"res://scripts/nodes/game/board.gd": [
		"nodes/game/cell.tscn", "nodes/game/anchor.tscn", "nodes/game/wall_segment.tscn",
		"nodes/game/history_line.tscn", "nodes/game/moving_line.tscn",
		"nodes/game/player_cursor.tscn", "nodes/game/board_layers.tscn",
	],
	"res://scripts/scenes/shop.gd": ["nodes/shop/tab_button.tscn", "nodes/shop/item_grid.tscn"],
	"res://scripts/scenes/ranking.gd": ["nodes/ranking/tab_button.tscn"],
	"res://scripts/scenes/archivement.gd": ["nodes/archivements/tab_button.tscn"],
}

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
	_section_8_fixed_scenes()
	_section_9_hud_bindings()
	_section_10_hud_minimal()

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
	_entry(is_equal_approx(ShopTabButton.art_height(), 49.0),
		"chieu cao tab lay tu art = 49 (dang %.0f)" % ShopTabButton.art_height())
	_entry(ShopTabButton.inactive_ratio() > 0.0 and ShopTabButton.inactive_ratio() < 1.0,
		"tab chua chon thap hon tab dang chon")

	tab.set_label_text("nhan thu")
	_entry(tab.label.text == "nhan thu", "set_label_text() doi nhan tab")

	tab.set_active(true)
	var art_active: Texture2D = tab.texture_normal
	tab.set_active(false)
	_entry(art_active != null and art_active != tab.texture_normal,
		"set_active() doi art giua 2 trang thai")

	tab.set_active(true)
	tab.apply_metrics(49.0)
	_entry(tab.custom_minimum_size == Vector2(0, 49),
		"tab dang chon: rong do HBox chia, cao 49 (dang %s)" % tab.custom_minimum_size)
	tab.set_active(false)
	tab.apply_metrics(49.0)
	_entry(is_equal_approx(tab.custom_minimum_size.y, 49.0 * ShopTabButton.inactive_ratio()),
		"tab chua chon: cao %.1f" % tab.custom_minimum_size.y)
	_entry(is_equal_approx(tab.label.position.y, tab.custom_minimum_size.y - 49.0),
		"nhan tab chua chon duoc nang len cho thang hang (%.1f)" % tab.label.position.y)
	_entry(tab.size_flags_vertical == Control.SIZE_SHRINK_END, "tab canh DAY hang")
	tab.queue_free()

	# Tab khai san trong scene: gan `category` + `label_key` TRƯỚC khi vào cây ⇒ `_ready` tự dịch nhãn
	var packed_tab := load("res://nodes/shop/tab_button.tscn") as PackedScene
	var scene_tab := packed_tab.instantiate() as ShopTabButton
	scene_tab.category = "theme"
	scene_tab.label_key = "STR_SHOP_TAB_THEME"
	root.add_child(scene_tab)
	_entry(scene_tab.category == "theme" and not scene_tab.label.text.is_empty(),
		"tab khai trong scene tu dich nhan ('%s')" % scene_tab.label.text)
	scene_tab.queue_free()

	var grid := _spawn("res://nodes/shop/item_grid.tscn") as ShopItemGrid
	_entry(grid != null, "item_grid.tscn instantiate ra ShopItemGrid")
	if grid != null:
		_entry(grid.columns == 2, "luoi the: 2 cot")
		_entry(grid.get_theme_constant("h_separation") == 15, "khe ngang 15 (tu scene)")
		_entry(grid.get_theme_constant("v_separation") == 12, "khe doc 12 (tu scene)")
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
		# Cột thẻ là VBoxContainer (1 cột) — khe dọc khai tường minh trong page.tscn
		_entry(page.column().get_theme_constant("separation") == 4,
			"khe giua cac the = 4 (tu scene)")
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
		_entry(page.grid().get_theme_constant("h_separation") == 23, "khe ngang 23")
		_entry(page.grid().get_theme_constant("v_separation") == 12, "khe doc 12")
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
	tab.setup("play", "THU THACH", 117.5)
	_entry(tab.custom_minimum_size == Vector2(117.5, 26),
		"tab nhan be rong rieng, cao theo scene (117.5x26)")
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
	for folder in ["res://scripts/scenes", "res://scripts/nodes", "res://scripts/utils"]:
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
# 8. Scene đã KHAI SẴN trong scene cha ⇒ script màn không được dựng lại bằng code
# ---------------------------------------------------------------------------
func _section_8_fixed_scenes() -> void:
	print("[8] Scene da khai san — khong duoc instantiate lai...")

	# Bỏ CHÚ THÍCH trước khi quét (tài liệu được phép nhắc tên scene)
	var comments := RegEx.new()
	comments.compile("#[^\\n]*")

	var offenders: Array[String] = []
	for path: String in FIXED_SCENES:
		if not FileAccess.file_exists(path):
			offenders.append("%s: khong thay file" % path)
			continue
		var cleaned := comments.sub(FileAccess.get_file_as_string(path), "", true)
		var lines := cleaned.split("\n")
		for scene_path: String in FIXED_SCENES[path]:
			for i in lines.size():
				var line := lines[i]
				# Chỉ tính là lỗi khi ĐƯỜNG DẪN đó được preload/instantiate (cảnh báo trong
				# push_warning() nhắc tên scene thì không sao)
				if line.contains(scene_path) \
						and (line.contains("instantiate(") or line.contains("preload(")):
					offenders.append("%s:%d <- %s" % [path.get_file(), i + 1, scene_path])

	_entry(FIXED_SCENES.size() >= 4, "rao duoc %d script (scene da khai trong scene cha)" % FIXED_SCENES.size())
	_entry(offenders.is_empty(),
		"khong script nao con preload/instantiate scene DA KHAI SAN%s"
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
		var wall_t := layers.wall_template()
		var history_t := layers.history_template()
		_entry(layers.fixed_nodes().size() == 7,
			"7 node KHAI SẴN không bị dọn khi đổi tầng (%d)" % layers.fixed_nodes().size())
		_entry(layers.cell_template() != null and not layers.cell_template().visible,
			"node MẪU ô khai trong scene (Cells/CellTemplate · đang ẩn)")
		_entry(wall_t != null and not wall_t.visible,
			"node MẪU tường khai trong scene (Walls/WallTemplate · đang ẩn)")
		_entry(layers.anchor_template() != null and not layers.anchor_template().visible,
			"node MẪU neo khai trong scene (Anchors/AnchorTemplate · đang ẩn)")
		_entry(history_t != null and not history_t.visible,
			"node MẪU vệt mực cũ khai trong scene (Lines/HistoryTemplate · đang ẩn)")
		_entry(wall_t != null and history_t != null
			and is_equal_approx(wall_t.width, 5.5) and is_equal_approx(history_t.width, 20.0),
			"cỡ THIẾT KẾ đọc từ node mẫu (tường 5.5 · vệt mực 20)")
		layers.queue_free()

	var board: BoardView = _spawn("res://nodes/game/board.tscn") as BoardView
	_entry(board != null, "board.tscn instantiate ra BoardView")
	if board != null:
		_entry(board.get_node_or_null("Layers") is BoardLayers,
			"board.tscn khai sẵn node Layers (không instantiate lúc chạy)")
		board.queue_free()

	var footstep: InkFootstep = _spawn("res://nodes/game/ink_footstep.tscn") as InkFootstep
	_entry(footstep != null, "ink_footstep.tscn instantiate ra InkFootstep")
	if footstep != null:
		_entry(footstep.mark != null, "vệt mực có node con 'Mark' (parent=\".\")")
		footstep.setup(Vector2(50, 100), null, Color(0.2, 0.3, 0.9))
		_entry(footstep.size == Vector2(18, 18) and footstep.position == Vector2(41, 91),
			"setup() đặt vệt mực đúng TÂM ô (18×18)")
		_entry(is_equal_approx(footstep.mark.modulate.a, 0.45), "độ mờ vệt mực 0.45")
		footstep.queue_free()

	var segment: CountdownSegment = _spawn("res://nodes/hud/portrait/game/countdown_segment.tscn") as CountdownSegment
	_entry(segment != null, "countdown_segment.tscn instantiate ra CountdownSegment")
	if segment != null:
		segment.set_width(20.0)
		_entry(segment.custom_minimum_size == Vector2(20, 6),
			"vạch rộng 20 · cao 6 (cao lấy từ scene)")
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
# 9. HUD: node con của scene phải được BIND vào `@export` — script KHÔNG dò đường dẫn
#    ("Content/ModeInformation/...") nữa; xem GDD §10.2g.
# ---------------------------------------------------------------------------
const HUD_FOLDERS := [
	"res://nodes/hud/portrait/game",
	"res://nodes/hud/landscape/game",
]
## Export CHỈ có ở HUD NGANG (khung Hướng dẫn nhúng `InstructionSection`) — HUD DỌC để trống là
## ĐÚNG thiết kế (xem `GameHUD.instruction_section()`).
const HUD_PORTRAIT_OPTIONAL := [
	"instruction_section_node", "instruction_host", "instruction_fallback_btn",
]
## Scene HUD TRƯU TƯỢNG (chưa có `Time` riêng của bản NGANG ⇒ node do từng HUD chế độ khai).
## Bỏ qua scene này khi kiểm export: mọi HUD CHẾ ĐỘ đều được kiểm riêng.
const HUD_ABSTRACT_SCENES := ["game_hud.tscn"]
## Export CỐ Ý để trống vì node đã XOÁ khỏi scene (2026-09-27 — “chỉ hiện thứ cần thiết”):
## bản NGANG khai `Time` trong từng HUD chế độ nên xoá được; bản DỌC dùng node KẾ THỪA
## (`game_hud.tscn`) nên chỉ ẩn được — vì vậy bảng này theo TÊN FILE (áp cho cả 2 hướng).
const HUD_EXPORT_OPTIONAL := {
	"dungeon_mode.tscn": ["time_value_node"],       # Dungeon: chỉ SỐ BƯỚC + TẦNG
	"countdown_hud.tscn": ["time_value_node"],      # Countdown: chỉ NGÂN SÁCH CÒN
	"fog_of_war_hud.tscn": ["time_value_node"],     # Fog of War: chỉ LƯỢT THỬ LẠI
	"sum_path_hud.tscn": ["time_value_node"],       # Sum Path: chỉ TỔNG · TOÁN TỬ · MỤC TIÊU
	"fading_ink_hud.tscn": ["time_value_node"],     # bản NGANG xoá `Time`, bản DỌC vẫn có (kế thừa)
}


func _section_9_hud_bindings() -> void:
	print("[9] HUD: node con bind qua @export...")

	var scenes: Array[String] = []
	for folder in HUD_FOLDERS:
		var dir := DirAccess.open(folder)
		if dir == null:
			continue
		for name in dir.get_files():
			if name.ends_with(".tscn"):
				scenes.append("%s/%s" % [folder, name])

	var missing: Array[String] = []
	var exports := 0
	for path in scenes:
		var packed := load(path) as PackedScene
		if packed == null:
			missing.append("%s: khong load duoc" % path.get_file())
			continue
		var node := packed.instantiate()
		var script: Script = node.get_script()
		if script != null and not HUD_ABSTRACT_SCENES.has(path.get_file()):
			for prop in script.get_script_property_list():
				if prop.hint != PROPERTY_HINT_NODE_TYPE:
					continue
				if HUD_PORTRAIT_OPTIONAL.has(prop.name) and path.contains("/portrait/"):
					continue
				if (HUD_EXPORT_OPTIONAL.get(path.get_file(), []) as Array).has(prop.name):
					continue
				exports += 1
				if node.get(prop.name) == null:
					missing.append("%s: %s" % [path.get_file(), prop.name])
		node.free()

	_entry(scenes.size() >= 18, "quet duoc %d scene HUD (2 huong)" % scenes.size())
	_entry(exports >= 30, "HUD co %d export NODE can bind" % exports)
	_entry(missing.is_empty(),
		"moi export node cua HUD deu duoc BIND trong scene%s"
			% ("" if missing.is_empty() else " — thieu: %s" % ", ".join(missing)))

	# Hàng rào: script HUD KHÔNG được dò node con bằng đường dẫn nữa
	var comments := RegEx.new()
	comments.compile("#[^\\n]*")
	var offenders: Array[String] = []
	var sources: Array[String] = []
	_collect_sources("res://scripts/nodes/hud", sources)
	for path in sources:
		if not FileAccess.file_exists(path):
			continue
		var cleaned := comments.sub(FileAccess.get_file_as_string(path), "", true)
		var lines := cleaned.split("\n")
		for i in lines.size():
			var line := lines[i]
			if line.contains("get_node_or_null(\"Content/") or line.contains("get_node(\"Content/"):
				offenders.append("%s:%d" % [path.get_file(), i + 1])

	_entry(not sources.is_empty(), "quet duoc %d script HUD" % sources.size())
	_entry(offenders.is_empty(),
		"khong script HUD nao con do node con bang duong dan%s"
			% ("" if offenders.is_empty() else " — con: %s" % ", ".join(offenders)))


# ---------------------------------------------------------------------------
# 10. HUD “CHỈ HIỆN THỨ CẦN THIẾT” (2026-09-27) — đúng danh sách node CÒN LẠI của mỗi chế độ
# ---------------------------------------------------------------------------
## Node CON HIỆN của `Content/ModeInformation` (node vừa xoá thì không còn; node kế thừa bị ẩn
## `visible = false` thì coi như không hiện) — mỗi HUD 2 HƯỚNG phải giống nhau.
const HUD_VISIBLE_CARDS := {
	"level_mode.tscn": ["Time"],                     # Play: CHỈ THỜI GIAN (thử thách ở popup)
	"minesweep_hud.tscn": ["Time"],                  # Minesweeper: CHỈ THỜI GIAN
	"blind_memory_hud.tscn": ["Time"],               # Blind Memory: CHỈ THỜI GIAN
	"fading_ink_hud.tscn": ["Time"],                 # Fading Ink: CHỈ THỜI GIAN
	"one_stroke_hud.tscn": ["Time"],                 # One Stroke: CHỈ THỜI GIAN
	"wall_builder_hud.tscn": ["Time"],               # Wall Builder: CHỈ THỜI GIAN
	"dungeon_mode.tscn": ["Step", "Floor"],         # Dungeon: SỐ BƯỚC + TẦNG
	"countdown_hud.tscn": ["Sheet"],                 # Countdown: NGÂN SÁCH CÒN
	"fog_of_war_hud.tscn": ["Sheet"],                # Fog of War: LƯỢT THỬ LẠI
	"sum_path_hud.tscn": ["Sheet"],                  # Sum Path: TỔNG · TOÁN TỬ · MỤC TIÊU
}
## Bên trong thẻ `Sheet` chỉ còn đúng những node này
const HUD_SHEET_ROWS := {
	"countdown_hud.tscn": ["Budget"],
	"fog_of_war_hud.tscn": ["Retry"],
	"sum_path_hud.tscn": ["BlockCurrent", "Emblem", "BlockTarget"],
}


func _section_10_hud_minimal() -> void:
	print("[10] HUD chi hien thu can thiet...")

	var bad: Array[String] = []
	var checked := 0
	for folder in HUD_FOLDERS:
		var dir := DirAccess.open(folder)
		if dir == null:
			continue
		for name in dir.get_files():
			var file_name := name.get_file()
			if not name.ends_with(".tscn") or not HUD_VISIBLE_CARDS.has(file_name):
				continue
			var node := (load("%s/%s" % [folder, name]) as PackedScene).instantiate()
			var info := node.get_node_or_null("Content/ModeInformation")
			var shown: Array[String] = []
			if info != null:
				for child in info.get_children():
					var c := child as Control
					if c != null and c.visible:
						shown.append(String(c.name))
			var want: Array = HUD_VISIBLE_CARDS[file_name]
			shown.sort()
			var want_sorted := want.duplicate()
			want_sorted.sort()
			checked += 1
			if shown != want_sorted:
				bad.append("%s (%s): hien [%s] — can [%s]" % [folder.contains("landscape") and "NGANG" or "DỌC",
					file_name, ", ".join(shown), ", ".join(want_sorted)])
			# bên trong Sheet
			if HUD_SHEET_ROWS.has(file_name):
				var sheet := node.get_node_or_null("Content/ModeInformation/Sheet")
				var rows: Array[String] = []
				if sheet != null:
					for child in sheet.get_children():
						rows.append(String(child.name))
				rows.sort()
				var want_rows: Array = (HUD_SHEET_ROWS[file_name] as Array).duplicate()
				want_rows.sort()
				var shape_ok := sheet != null and rows == want_rows
				checked += 1
				if not shape_ok:
					bad.append("%s %s Sheet: con [%s] — can [%s]" % [
						folder.contains("landscape") and "NGANG" or "DỌC",
						file_name, ", ".join(rows), ", ".join(want_rows)])
			node.free()

	_entry(checked >= 20, "kiem %d luot (scene HUD x 2 huong + the Sheet)" % checked)
	_entry(bad.is_empty(),
		"moi HUD chi hien dung thu can thiet%s"
			% ("" if bad.is_empty() else " — sai: %s" % "; ".join(bad)))


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
