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
	_section_11_tutorials()

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
		_entry(not tab.label.text.is_empty(), "nhan tab So tay khai trong scene: '%s'" % tab.label.text)
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
	_entry(is_equal_approx(tab.custom_minimum_size.x, 0.0)
			and is_equal_approx(tab.custom_minimum_size.y, 26.0),
		"tab giu CHIEU CAO 26, be rong do HBox chia (%.0fx%.0f)"
			% [tab.custom_minimum_size.x, tab.custom_minimum_size.y])

	# Tab khai trong scene bo cuc: gan `board_id` + `label_key` TRUOC khi vao cay ⇒ `_ready` tu dich nhan
	var packed_rank_tab := load("res://nodes/ranking/tab_button.tscn") as PackedScene
	var scene_tab := packed_rank_tab.instantiate() as RankTabButton
	scene_tab.board_id = "play"
	scene_tab.label_key = "STR_RANK_TAB_PLAY"
	root.add_child(scene_tab)
	_entry(scene_tab.board_id == "play" and not scene_tab.label.text.is_empty(),
		"tab Xep hang khai trong scene tu dich nhan ('%s')" % scene_tab.label.text)
	var emitted: Array[String] = []
	scene_tab.tab_pressed.connect(func(id: String) -> void: emitted.append(id))
	scene_tab.pressed.emit()
	_entry(emitted.size() == 1 and emitted[0] == "play",
		"tab Xep hang tu noi `pressed` → phat `tab_pressed('play')`")
	scene_tab.queue_free()
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
	"fog_of_war_hud.tscn": ["time_value_node", "retry_note_label"],
		# Fog of War: bản DỌC chỉ còn LƯỢT THỬ LẠI (Value · Max trong `Retry/Control`) — node
		# `Note` đã xoá nên export để trống; bản NGANG vẫn giữ `Note` (script tự bỏ qua khi null).
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
			var huong := "NGANG" if folder.contains("landscape") else "DỌC"
			if shown != want_sorted:
				bad.append("%s (%s): hien [%s] — can [%s]" % [huong,
					file_name, ", ".join(shown), ", ".join(want_sorted)])
			# bên trong Sheet
			if HUD_SHEET_ROWS.has(file_name):
				var sheet := node.get_node_or_null("Content/ModeInformation/Sheet")
				var rows: Array[String] = []
				var wrapped: Array[String] = []
				if sheet != null:
					for child in sheet.get_children():
						rows.append(String(child.name))
					# Bản DỌC có thể gom các khối vào 1 BoxContainer — chấp nhận cả 2 dạng
					if sheet.get_child_count() == 1 and sheet.get_child(0) is BoxContainer:
						for child in sheet.get_child(0).get_children():
							wrapped.append(String(child.name))
				rows.sort()
				wrapped.sort()
				var want_rows: Array = (HUD_SHEET_ROWS[file_name] as Array).duplicate()
				want_rows.sort()
				var shape_ok := sheet != null and (rows == want_rows or wrapped == want_rows)
				checked += 1
				if not shape_ok:
					bad.append("%s %s Sheet: con [%s] — can [%s]" % [
						huong, file_name, ", ".join(rows), ", ".join(want_rows)])
			node.free()

	_entry(checked >= 20, "kiem %d luot (scene HUD x 2 huong + the Sheet)" % checked)
	_entry(bad.is_empty(),
		"moi HUD chi hien dung thu can thiet%s"
			% ("" if bad.is_empty() else " — sai: %s" % "; ".join(bad)))


# ---------------------------------------------------------------------------
# 11. TUTORIAL (2026-09-27): node · dây tín hiệu · art đều KHAI TRONG .tscn
#     — script chỉ giữ luật + bind qua `@export`; xem GDD §10.2g.
# ---------------------------------------------------------------------------
const TUTORIAL_SCENES := [
	"res://nodes/tutorials/base_tutorial.tscn",
	"res://nodes/tutorials/first_time.tscn",
	"res://nodes/tutorials/how_to_play_move.tscn",
	"res://nodes/tutorials/how_to_play_checking_wall.tscn",
	"res://nodes/tutorials/how_to_play_minesweeper.tscn",
	"res://nodes/tutorials/how_to_play_one_stroke.tscn",
	"res://nodes/tutorials/how_to_play_sum_path.tscn",
	"res://nodes/tutorials/how_to_play_wall_builder.tscn",
]
## Số phần tử mong đợi của export MẢNG (`Array[TutorialCell]` — ô XEM TRƯỚC của bài mở đầu)
const TUTORIAL_EXPECTED_ARRAYS := {
	"first_time.tscn": {"preview_cells": 3},
}
## Số Ô mong đợi của BÀN MINI dựng LÚC CHẠY bằng component chung `BoardTutorial`
## (kế thừa BoardView thật — scene chỉ giữ export `board_tutorial`, không khai ô trong .tscn)
const TUTORIAL_EXPECTED_BOARD_CELLS := {
	"how_to_play_move.tscn": 3,
	"how_to_play_checking_wall.tscn": 4,
	"how_to_play_minesweeper.tscn": 9,
	"how_to_play_one_stroke.tscn": 9,
	"how_to_play_sum_path.tscn": 9,
	"how_to_play_wall_builder.tscn": 4,
}
## Vẽ bằng code là CẤM: art nằm trong `assets/images/tutorial/*.svg` (TextureRect/NinePatchRect)
const TUTORIAL_DRAW_CALLS := [
	"draw_rect(", "draw_line(", "draw_polyline(", "draw_circle(", "draw_colored_polygon(",
]


func _section_11_tutorials() -> void:
	print("[11] Tutorial: node · signal · export deu nam trong .tscn...")

	var unbound: Array[String] = []
	var bad: Array[String] = []
	var bad_conn: Array[String] = []
	var exports := 0
	var arrays := 0
	var boards := 0
	var cells_total := 0
	var steps_total := 0
	var effects_checked := 0

	for path: String in TUTORIAL_SCENES:
		var file_name := path.get_file()
		var packed := load(path) as PackedScene
		if packed == null:
			_entry(false, "%s: load duoc" % file_name)
			continue
		var node := packed.instantiate()
		root.add_child(node)
		_entry(node.get_script() != null, "%s: nap duoc + co script rieng" % file_name)

		# (1) Mọi export kiểu NODE phải được bind NGAY TRONG .tscn
		var script: Script = node.get_script()
		for prop in script.get_script_property_list():
			if prop.hint != PROPERTY_HINT_NODE_TYPE:
				continue
			exports += 1
			if node.get(prop.name) == null:
				unbound.append("%s: %s" % [file_name, prop.name])

		# (2) Export MẢNG (ô XEM TRƯỚC của bài mở đầu) phải bind đúng số phần tử
		var expected: Dictionary = TUTORIAL_EXPECTED_ARRAYS.get(file_name, {})
		for prop_name: String in expected:
			var want := int(expected[prop_name])
			var value: Variant = node.get(prop_name)
			var got := -1
			if value is Array:
				got = (value as Array).size()
			arrays += 1
			if got != want:
				bad.append("%s: %s = %d (can %d)" % [file_name, prop_name, got, want])

		# (2b) Bàn mini dùng CHUNG component `BoardTutorial` (kế thừa BoardView thật):
		#      export `board_tutorial` trỏ đúng node, số ô DỰNG LÚC CHẠY khớp thiết kế
		var want_cells := int(TUTORIAL_EXPECTED_BOARD_CELLS.get(file_name, 0))
		if want_cells > 0:
			boards += 1
			var board := node.get_node_or_null("BoardHost/BoardTutorial") as BoardTutorial
			if board == null:
				bad.append("%s: thieu node BoardHost/BoardTutorial" % file_name)
			elif node.get("board_tutorial") != board:
				bad.append("%s: export board_tutorial chua tro toi BoardHost/BoardTutorial" % file_name)
			else:
				var built := board.get_all_cells().size()
				cells_total += built
				if built != want_cells:
					bad.append("%s: ban mini dung %d o (can %d)" % [file_name, built, want_cells])

		# (3) Ô xem trước (nếu có): mỗi ô 1 `grid_pos`, không trùng
		var seen: Array[Vector2i] = []
		for cell in _tutorial_cells(node):
			if seen.has(cell.grid_pos):
				bad.append("%s: trung grid_pos %s" % [file_name, str(cell.grid_pos)])
			seen.append(cell.grid_pos)

		# (4) BoardHost phải NHƯỜNG chuột (ô bàn cũng vậy) để tutorial nhận thao tác kéo ở root
		var board := node.get_node_or_null("BoardHost")
		if board is Control and (board as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			bad.append("%s: BoardHost phai MOUSE_FILTER_IGNORE" % file_name)

		# (5) [connection] khai trong .tscn phải trỏ tới node + hàm có thật
		_check_tutorial_connections(path, node, bad_conn)

		# (6) Bài học phải nạp được danh sách bước
		if file_name != "base_tutorial.tscn":
			var steps: Variant = node.get("steps_data")
			if not (steps is Array) or (steps as Array).size() == 0:
				bad.append("%s: chua nap step nao" % file_name)
			else:
				steps_total += (steps as Array).size()
				# (7) Đi hết các bước: bước cuối → phát `tutorial_completed` ĐÚNG id (1 lần)
				var completed: Array[String] = []
				node.connect("tutorial_completed",
					func(id: String) -> void: completed.append(id))
				for _i in (steps as Array).size():
					node.call("next_step")
				var expected_id := str(node.get("tutorial_id"))
				if completed.size() != 1 or completed[0] != expected_id:
					bad.append("%s: di het buoc chua phat tutorial_completed dung id ('%s' × %d)"
						% [file_name, expected_id, completed.size()])
				# (8) Hiệu ứng không vỡ: mở bài · pháo giấy · phản hồi · chữ nổi · nháy lỗi
				node.call("play_entrance")
				node.call("play_cells_win")
				node.call("show_fail_feedback", "STR_TUT_KHONG_CO", "sai thu")
				node.call("show_success_feedback", "", "✓ thu")
				var toast := node.get("toast_label") as Label
				if toast == null or toast.text.is_empty():
					bad.append("%s: toast phan hoi khong duoc ghi" % file_name)
				if node.get("board_host") != null:
					node.call("spawn_board_text", "+1", Vector2(80, 80))
					node.call("flash_fail", node.get("board_host"))
				effects_checked += 1
		node.queue_free()

	_entry(TUTORIAL_SCENES.size() >= 8, "quet duoc %d scene tutorial" % TUTORIAL_SCENES.size())
	_entry(exports >= 20, "tutorial co %d export NODE can bind" % exports)
	_entry(unbound.is_empty(),
		"moi export NODE cua tutorial deu duoc BIND trong .tscn%s"
			% ("" if unbound.is_empty() else " — thieu: %s" % ", ".join(unbound)))
	_entry(arrays >= 1, "co %d export MANG (o xem truoc) bind trong scene" % arrays)
	_entry(boards >= 6, "co %d bai dung ban mini CHUNG (BoardTutorial) bind qua export" % boards)
	_entry(cells_total >= 30, "tong so o ban mini dung luc chay: %d" % cells_total)
	_entry(steps_total >= 30, "tong so buoc nap tu 7 bai: %d" % steps_total)
	_entry(effects_checked >= 7, "hieu ung (mo bai · phao giay · toast · chu noi) chay duoc tren %d bai" % effects_checked)
	_entry(bad.is_empty(),
		"ban co mini · step · BoardHost dung chuan%s"
			% ("" if bad.is_empty() else " — sai: %s" % "; ".join(bad)))
	_entry(bad_conn.is_empty(),
		"moi [connection] trong .tscn tro dung node + ham%s"
			% ("" if bad_conn.is_empty() else " — sai: %s" % "; ".join(bad_conn)))

	# Script tutorial KHÔNG được vẽ bằng code nữa (art đã chuyển thành SVG)
	var comments := RegEx.new()
	comments.compile("#[^\\n]*")
	var offenders: Array[String] = []
	var sources: Array[String] = []
	_collect_sources("res://scripts/nodes/tutorial", sources)
	for path in sources:
		if not FileAccess.file_exists(path):
			continue
		var cleaned := comments.sub(FileAccess.get_file_as_string(path), "", true)
		for call in TUTORIAL_DRAW_CALLS:
			if cleaned.contains(call):
				offenders.append("%s: %s" % [path.get_file(), call])
	_entry(sources.size() >= 9, "quet duoc %d script tutorial" % sources.size())
	_entry(offenders.is_empty(),
		"khong script tutorial nao con ve bang draw_*%s"
			% ("" if offenders.is_empty() else " — con: %s" % ", ".join(offenders)))

	# Bảng scene của TutorialController phải trỏ tới scene CÓ THẬT
	var controller := FileAccess.get_file_as_string("res://scripts/core/controllers/tutorial_controller.gd")
	var route_re := RegEx.new()
	route_re.compile("\"res://nodes/tutorials/([a-z_]+\\.tscn)\"")
	var routes := route_re.search_all(controller)
	var bad_paths: Array[String] = []
	for m in routes:
		if not FileAccess.file_exists("res://nodes/tutorials/%s" % m.get_string(1)):
			bad_paths.append(m.get_string(1))
	_entry(routes.size() >= 7, "TutorialController tro toi %d bai hoc" % routes.size())
	_entry(bad_paths.is_empty(),
		"moi bai trong TutorialController deu co scene%s"
			% ("" if bad_paths.is_empty() else " — thieu: %s" % ", ".join(bad_paths)))


func _tutorial_cells(from_node: Node) -> Array[TutorialCell]:
	var out: Array[TutorialCell] = []
	for child in from_node.find_children("*", "TutorialCell", true, false):
		out.append(child as TutorialCell)
	return out


## Đọc từng dòng `[connection …]` trong .tscn: `from` phải là node có thật, `to`.`method` phải có hàm
func _check_tutorial_connections(scene_path: String, node: Node, out: Array[String]) -> void:
	var file_name := scene_path.get_file()
	var from_re := RegEx.new()
	from_re.compile("from=\"([^\"]+)\"")
	var to_re := RegEx.new()
	to_re.compile("to=\"([^\"]+)\"")
	var method_re := RegEx.new()
	method_re.compile("method=\"([^\"]+)\"")
	for line in FileAccess.get_file_as_string(scene_path).split("\n"):
		if not line.begins_with("[connection "):
			continue
		var from_match := from_re.search(line)
		var to_match := to_re.search(line)
		var method_match := method_re.search(line)
		if from_match == null or to_match == null or method_match == null:
			out.append("%s: dong [connection] khong doc duoc" % file_name)
			continue
		var from_path := from_match.get_string(1)
		if node.get_node_or_null(from_path) == null:
			out.append("%s: thieu node nguon '%s'" % [file_name, from_path])
			continue
		var to_path := to_match.get_string(1)
		var target: Node = node if to_path == "." else node.get_node_or_null(to_path)
		if target == null:
			out.append("%s: thieu node nhan '%s'" % [file_name, to_path])
			continue
		var method_name := method_match.get_string(1)
		if not target.has_method(method_name):
			out.append("%s: '%s' khong co ham %s()" % [file_name, target.name, method_name])


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
