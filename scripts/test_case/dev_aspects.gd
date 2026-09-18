extends SceneTree
## ============================================================================
## DEV TOOL: kiểm tra giao diện theo MỌI TỈ LỆ MÀN HÌNH (Windows/Android thật —
## cần render, KHÔNG chạy headless):
##
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_aspects.gd
##
## Option (đặt SAU `--`):
##   --shots                lưu PNG nửa độ phân giải vào tmp_aspect/<size>/<id>.png
##   --only main,game       chỉ kiểm tra vài màn (id: main, levels, game…)
##   --sizes 1920x1080      chỉ kiểm tra vài cỡ cửa sổ
##   --modes play,sum_path  chỉ kiểm tra vài chế độ của màn game
##
## Kiểm tra mỗi (màn × tỉ lệ):
##   · Cột nội dung 1080px canh giữa (scripts/scenes/base.gd)
##   · PaperFill phủ kín canvas · Background phủ kín cột
##   · Không có node hiển thị nào tràn ra ngoài màn hình
##   · Màn game: Board + HUD trong cột; popup pause có Dim phủ canvas, thẻ canh giữa cột
## ============================================================================

const ASPECTS := [
	{"label": "9:16  · 1080×1920 (dọc cơ bản)", "size": Vector2i(1080, 1920)},
	{"label": "9:18  · 1080×2160 (dọc dài)", "size": Vector2i(1080, 2160)},
	{"label": "9:19.5 · 1080×2340 (dọc dài)", "size": Vector2i(1080, 2340)},
	{"label": "9:21  · 1080×2520 (dọc siêu dài)", "size": Vector2i(1080, 2520)},
	{"label": "3:4   · 1080×1440 (dọc, rộng)", "size": Vector2i(1080, 1440)},
	{"label": "3:4   · 1200×1600 (dọc, rộng)", "size": Vector2i(1200, 1600)},
	{"label": "4:3   · 1600×1200 (NGANG)", "size": Vector2i(1600, 1200)},
	{"label": "16:9  · 1920×1080 (NGANG)", "size": Vector2i(1920, 1080)},
	{"label": "18:9  · 2160×1080 (NGANG)", "size": Vector2i(2160, 1080)},
	{"label": "19.5:9 · 2340×1080 (NGANG)", "size": Vector2i(2340, 1080)},
]

const SCREENS := [
	{"id": "main", "path": "res://scenes/main.tscn"},
	{"id": "splash", "path": "res://scenes/splash.tscn"},
	{"id": "title", "path": "res://scenes/title.tscn"},
	{"id": "levels", "path": "res://scenes/levels.tscn"},
	{"id": "chapters", "path": "res://scenes/chapters.tscn"},
	{"id": "daily", "path": "res://scenes/daily.tscn"},
	{"id": "settings", "path": "res://scenes/settings.tscn"},
	{"id": "shop", "path": "res://scenes/shop.tscn"},
	{"id": "ranking", "path": "res://scenes/ranking.tscn"},
	{"id": "archivement", "path": "res://scenes/archivement.tscn"},
	{"id": "credit", "path": "res://scenes/credit.tscn"},
	{"id": "debug", "path": "res://scenes/debug.tscn"},
]

const GAME_MODES := ["play", "dungeon", "minesweeper", "sum_path",
		"countdown_cost", "blind_memory", "fog_of_war", "fading_ink", "one_stroke", "wall_builder"]

const DESIGN_WIDTH := 1080.0
## Bề rộng cột nội dung tối đa ở màn DỌC (khớp `BaseScene.MAX_CONTENT_WIDTH`)
const MAX_CONTENT_WIDTH := 1440.0

var _shots := false
var _only: PackedStringArray = []
var _size_filter: PackedStringArray = []
var _mode_filter: PackedStringArray = []
var _checks := 0
var _fails := 0


func _init() -> void:
	_parse_args()
	print("\n=======================================================================")
	print("  KIỂM TRA TỈ LỆ MÀN HÌNH — %d tỉ lệ × màn hình + 9 chế độ game" % ASPECTS.size())
	print("=======================================================================\n")
	await process_frame
	TranslationServer.set_locale("vi")      # ngôn ngữ mặc định trong game (nếu không test sẽ lấy nhãn EN dài hơn)
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("unlocked_levels", 99)
	for aspect in ASPECTS:
		var size: Vector2i = aspect["size"]
		if not _size_filter.is_empty() and not ("%dx%d" % [size.x, size.y] in _size_filter):
			continue
		DisplayServer.window_set_size(size)
		await _frames(4)
		var canvas := root.get_visible_rect().size
		print("── %s   → canvas %.0f×%.0f   scale %.2f" % [
			str(aspect["label"]), canvas.x, canvas.y, root.size.y / maxf(canvas.y, 1.0)])
		for def_v in SCREENS:
			var def: Dictionary = def_v
			if not _allowed(_only, str(def["id"])):
				continue
			await _run_screen(def, size)
		if _allowed(_only, "game"):
			for m_v in GAME_MODES:
				var mode_id := str(m_v)
				if not _mode_allowed(mode_id):
					continue
				await _run_game(mode_id, size)
	print("\n-----------------------------------------------------------------------")
	if _fails == 0:
		print("  KẾT QUẢ: %d kiểm tra PASS — mọi màn OK ở mọi tỉ lệ đã thử." % _checks)
	else:
		print("  KẾT QUẢ: %d/%d kiểm tra FAIL." % [_fails, _checks])
	print("-----------------------------------------------------------------------\n")
	quit(0)


# ---------------------------------------------------------------------------
# Chạy từng màn
# ---------------------------------------------------------------------------
func _run_screen(def: Dictionary, size: Vector2i) -> void:
	var path := str(def["path"])
	var id := str(def["id"])
	var packed := load(path) as PackedScene
	if packed == null:
		print("  [FAIL] %s: không load được scene" % id)
		_fails += 1
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	current_scene = scene      # PopupManager.get_host() tìm host theo current_scene
	await _frames(20)          # chờ hiệu ứng slide-in/fade mở màn xong mới đo
	var issues := _check_common(scene as Control)
	_report(id, issues)
	if _shots:
		await _frames(10)
		await _save_shot(id, size)
	scene.queue_free()
	await _frames(1)


func _run_game(mode_id: String, size: Vector2i) -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", mode_id)
		gm.set("current_level", 1)
	var packed := load("res://scenes/game.tscn") as PackedScene
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	current_scene = scene      # PopupManager.get_host() tìm host theo current_scene
	await _frames(8)
	# Cửa sổ đổi cỡ có thể tới MUỘN 1 nhịp so với lúc tạo scene ⇒ chờ tới khi scene nhận
	# đúng hướng của cỡ đang kiểm tra, tránh báo lỗi oan bằng toạ độ của cỡ trước đó.
	var want_landscape: bool = size.x > size.y
	# Cỡ cửa sổ có thể đổi SAU khi scene vào cây (không phát RESIZED) ⇒ gọi lại bố cục
	# theo hướng để scene bắt đúng hướng của cỡ đang kiểm tra.
	scene.call("_apply_responsive_layout")
	for _i in 30:
		if bool(scene.get("is_landscape")) == want_landscape:
			break
		scene.call("_apply_responsive_layout")
		await process_frame
	await _frames(2)
	var issues := _check_common(scene as Control)
	issues.append_array(_check_game(scene as Control))
	_report("game/" + mode_id, issues)
	if _shots:
		await _frames(24)
		await _save_shot("game_" + mode_id, size)
	# Popup pause: kiểm tra riêng (sau khi đã chụp ảnh màn chơi)
	if mode_id == "play":
		var popup_issues := await _check_pause_popup(scene)
		_report("game/popup", popup_issues)
	scene.queue_free()
	await _frames(1)


# ---------------------------------------------------------------------------
# Kiểm tra
# ---------------------------------------------------------------------------
func _check_common(scene: Control) -> Array:
	var out: Array = []
	var canvas := root.get_visible_rect().size
	# 1. Cột nội dung: màn DỌC = clamp(canvas.x, 1080, 1440) canh giữa (base.gd);
	#    màn đã có layout NGANG thì ở hướng ngang root PHỦ KÍN canvas.
	var has_landscape_layout := scene.get_node_or_null("Landscape") != null
	var expect_x := 0.0
	var expect_w := canvas.x
	if not (has_landscape_layout and canvas.x > canvas.y):
		var column := clampf(canvas.x, DESIGN_WIDTH, MAX_CONTENT_WIDTH) if has_landscape_layout else DESIGN_WIDTH
		expect_x = floorf((canvas.x - column) * 0.5)
		expect_w = column
	if absf(scene.position.x - expect_x) > 1.5 or absf(scene.size.x - expect_w) > 1.5:
		out.append("FAIL cột nội dung sai (pos.x=%.0f mong %.0f · size.x=%.0f mong %.0f)" % [
			scene.position.x, expect_x, scene.size.x, expect_w])
	if absf(scene.size.y - canvas.y) > 1.5:
		out.append("WARN chiều cao cột %.0f ≠ canvas %.0f" % [scene.size.y, canvas.y])
	# 2. Nền giấy phủ kín canvas (Background trong cột + 2 dải SideL/SideR hai bên)
	var canvas_rect := Rect2(Vector2.ZERO, canvas)
	var col_left := scene.position.x
	var bg := scene.get_node_or_null("Background") as Control
	if bg == null:
		out.append("FAIL thiếu node Background")
	else:
		var col_rect := Rect2(scene.position, Vector2(expect_w, canvas.y))
		if not col_rect.grow(2.0).encloses(Rect2(bg.global_position, bg.size)):
			out.append("WARN Background không khớp cột nội dung")
		var side_l := bg.get_node_or_null("SideL") as Control
		var side_r := bg.get_node_or_null("SideR") as Control
		var need_l := Rect2(0, 0, col_left, canvas.y)
		var need_r := Rect2(col_left + expect_w, 0, maxf(canvas.x - col_left - expect_w, 0.0), canvas.y)
		if side_l == null or not need_l.grow(2.0).encloses(Rect2(side_l.global_position, side_l.size)):
			out.append("FAIL SideL không phủ hết mép trái (%s cần %s)" % [
				str(Rect2(side_l.global_position, side_l.size) if side_l != null else Rect2()), str(need_l)])
		if side_r == null or not need_r.grow(2.0).encloses(Rect2(side_r.global_position, side_r.size)):
			out.append("FAIL SideR không phủ hết mép phải (%s cần %s)" % [
				str(Rect2(side_r.global_position, side_r.size) if side_r != null else Rect2()), str(need_r)])
	# 4. Không node hiển thị nào tràn ra ngoài màn hình
	var overflow: Array = []
	_scan_overflow(scene, canvas_rect.grow(2.0), overflow, 0)
	if not overflow.is_empty():
		out.append("FAIL %d node tràn màn hình: %s" % [overflow.size(), ", ".join(overflow.slice(0, 6))])
	return out


## Màn game: Board + HUD + thanh nút + hint bar phải nằm gọn trong cột nội dung
func _check_game(scene: Control) -> Array:
	var out: Array = []
	var col := Rect2(scene.global_position, scene.size).grow(2.0)
	for path in ["Board", "Information", "HintGuide"]:
		var node := scene.call("ui", path) as Control
		if node == null:
			out.append("FAIL thiếu node %s" % path)
		elif not col.encloses(Rect2(node.global_position, node.size * node.scale)):
			out.append("FAIL %s vượt khỏi cột nội dung %s" % [path, str(Rect2(node.global_position, node.size))])
	# HUD trong khung Information (đã bị thay bằng HUD riêng của chế độ lúc chạy)
	var ui := scene.get("ui_controller") as Node
	var hud: Control = (ui.get("hud") as Control) if ui != null else null
	if hud != null and not col.encloses(Rect2(hud.global_position, hud.size)):
		out.append("FAIL HUD vượt khỏi cột nội dung %s" % str(Rect2(hud.global_position, hud.size)))
	return out


## Popup pause: Dim phủ kín canvas · thẻ popup canh giữa cột nội dung
func _check_pause_popup(scene: Control) -> Array:
	var out: Array = []
	var ui := scene.get("ui_controller") as Node
	if ui == null:
		out.append("FAIL không có ui_controller để mở popup pause")
		return out
	ui.call("toggle_settings")
	await _frames(20)          # chờ hiệu ứng mở popup (fade + scale 0.22s) xong mới đo
	var popups := scene.get_node_or_null("Popups")
	var pop: Control = null
	for i in range(popups.get_child_count() - 1, -1, -1):
		var c := popups.get_child(i) as Control
		if c != null and c.visible:
			pop = c
			break
	if pop == null:
		var pm := root.get_node_or_null("PopupManager")
		var host: Node = (pm.get("_host") as Node) if pm != null else null
		var stack: Array = (pm.get("_stack") as Array) if pm != null else []
		out.append("FAIL bấm pause không mở được popup | stack=%d host=%s" % [
			stack.size(), str(host.get_path()) if host != null else "<null>"])
		return out
	var canvas := root.get_visible_rect().size
	var dim := pop.get_node_or_null("Dim") as Control
	if dim != null:
		var dr := Rect2(dim.global_position, dim.size)
		if not Rect2(Vector2.ZERO, canvas).grow(2.0).encloses(dr):
			out.append("FAIL Dim popup không phủ canvas %s" % str(dr))
	var panel := pop.get_node_or_null("Panel") as Control
	if panel != null:
		var pcx := panel.global_position.x + panel.size.x * 0.5
		if absf(pcx - canvas.x * 0.5) > 2.0:
			out.append("FAIL thẻ popup lệch tâm canvas (%.2f vs %.2f) | id=%s panel=%s pos=%s gpos=%s scale=%s" % [
				pcx, canvas.x * 0.5, pop.popup_id, str(panel.size), str(panel.position),
				str(panel.global_position), str(panel.scale)])
	Popups.close_all()
	await _frames(2)
	return out


## Quét mọi Control ĐANG HIỆN (kể cả tổ tiên đều hiện) xem có node nào vượt ra ngoài canvas không.
## Bỏ qua nội dung bên trong ScrollContainer (được phép dài hơn khung nhìn — nó cuộn).
func _scan_overflow(node: Node, allowed: Rect2, out: Array, depth: int) -> void:
	if depth > 12 or out.size() > 24:
		return
	for child in node.get_children():
		if child.name == "Popups" or child is ScrollContainer:
			continue
		var c := child as Control
		if c != null and c.is_visible_in_tree() and c.size.x > 0.0 and c.size.y > 0.0:
			var rect := Rect2(c.global_position, c.size * c.scale)
			if not allowed.encloses(rect):
				out.append("%s%s" % [c.get_path().get_concatenated_names().substr(0, 40),
					str(rect).substr(0, 60)])
		_scan_overflow(child, allowed, out, depth + 1)


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _report(id: String, issues: Array) -> void:
	var fails := 0
	var warns := 0
	for line in issues:
		if str(line).begins_with("FAIL"):
			fails += 1
		else:
			warns += 1
	_checks += 1
	_fails += fails
	var tag := "OK  " if fails == 0 else "FAIL"
	var note := ""
	if fails > 0:
		note = "· " + " | ".join(issues)
	elif warns > 0:
		note = "· (cảnh báo: %d)" % warns
	print("   [%s] %-22s %s" % [tag, id, note])


func _save_shot(id: String, size: Vector2i) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		return
	img.resize(maxi(int(img.get_width() * 0.5), 1), maxi(int(img.get_height() * 0.5), 1), Image.INTERPOLATE_LANCZOS)
	var dir := "res://tmp_aspect/%dx%d" % [size.x, size.y]
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir + "/" + id + ".png")


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts: PackedStringArray = str(arg).split("=", true, 1)
		var key := parts[0]
		var val := parts[1] if parts.size() > 1 else ""
		match key:
			"--shots":
				_shots = true
			"--only":
				_only = val.split(",")
			"--sizes":
				_size_filter = val.split(",")
			"--modes":
				_mode_filter = val.split(",")
	print("  options: shots=%s only=%s sizes=%s modes=%s" % [
		str(_shots), str(_only), str(_size_filter), str(_mode_filter)])


func _allowed(filter: PackedStringArray, id: String) -> bool:
	return filter.is_empty() or id in filter


func _mode_allowed(mode_id: String) -> bool:
	return _mode_filter.is_empty() or mode_id in _mode_filter
