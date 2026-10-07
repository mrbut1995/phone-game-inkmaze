extends SceneTree
## ============================================================================
## Test Case: MÀN CHỌN MÀN — BẢN ĐỒ ROAD MAP (thay lưới thẻ phân trang, 2026-10)
##   · Mỗi màn của chương = 1 nút trên bản đồ, nối nhau bằng MỘT đường UỐN LƯỢN
##     dạng chữ S (mọi nút nằm đúng trên đường, giữa 2 nút có điểm uốn xen kẽ);
##     màn 1 ở DƯỚI CÙNG.
##   · Nhấn giữ nút: số màn + hàng sao trôi theo nút (không "float"), thả ra về chỗ.
##   · Trạng thái nút: KHOÁ / ĐÃ XONG / MÀN NÊN CHƠI TIẾP (CURRENT) / BỎ QUA / thường.
##   · Nút màn + đường nối sinh trong `Tracks/Items`; cờ đích + mũi chỉ là node CÓ SẴN
##     trong `level_map.tscn` (script chỉ canh vị trí).
##   · Kéo dọc để đi trên bản đồ; kéo ở header/banner (ngoài khung bản đồ) KHÔNG cuộn.
##   · Mỗi lần cuộn, bản đồ phát tiến độ → nền giấy parallax trượt theo.
## Dùng thư mục user://test_levels/ tạm nên KHÔNG đụng resources/levels thật.
## ============================================================================

const TEST_IDS := 12
const UNLOCKED := 10          # khoá 11, 12 để kiểm tra trạng thái khoá
const TEMP_DIR := "user://test_levels/"
## Độ lệch tối thiểu của điểm giữa cung so với dây cung nối 2 nút (px): nhỏ hơn
## ngưỡng này nghĩa là đường bị "thẳng" — mất dáng uốn chữ S của mockup.
const MIN_SEGMENT_BULGE := 40.0

var _original_dir := ""


func _init() -> void:
	print("\n========================================================")
	print("  TEST: LEVEL SELECT - BAN DO ROAD MAP")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	var lm: Node = root.get_node_or_null("LevelManager")
	var gm: Node = root.get_node_or_null("GameManager")
	assert(lm != null and gm != null, "Autoload LevelManager + GameManager phai ton tai")

	_original_dir = str(lm.call("get_levels_dir"))
	var backup_unlocked := int(gm.get("unlocked_levels"))
	var backup_stars: Dictionary = gm.get("level_stars")
	var backup_chapter := int(gm.get("current_chapter"))

	var failures := 0
	failures += _prepare_temp_levels()

	lm.call("set_levels_dir", TEMP_DIR)
	gm.set("unlocked_levels", UNLOCKED)
	gm.set("level_stars", { 1: 3, 2: 2, 10: 1 })
	gm.set("current_chapter", 1)

	# ---------------------------------------------------------------- A. Bản đồ
	var stage := Control.new()
	stage.size = Vector2(540, 570)          # khung bản đồ (khớp MapArea thật)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE   # không nuốt input của nút Node2D
	root.add_child(stage)
	var map: LevelMap = (load("res://nodes/level_selection/level_map.tscn") as PackedScene).instantiate()
	stage.add_child(map)
	await process_frame
	var stars: Dictionary = gm.get("level_stars")
	map.build(_ids(TEST_IDS), stars, UNLOCKED, 3)
	await process_frame
	failures += _check_structure(map)
	failures += _check_road(map)
	failures += _check_states(map)
	failures += _check_decor(map)
	failures += _check_tap(map)
	failures += await _check_press_follow(map)
	failures += await _check_scroll_to(map)

	# ------------------------------------------------- B. Màn chọn màn thật
	var scene: LevelScenes = (load("res://scenes/levels.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await create_timer(0.7).timeout      # đợi auto-scroll tới màn đang chơi
	failures += _check_screen_wiring(scene)
	failures += await _check_drag_inside_outside(scene)
	failures += await _check_parallax(scene)

	# ---------------------------------------------------------------- Dọn dẹp
	stage.queue_free()
	scene.queue_free()
	await process_frame
	lm.call("set_levels_dir", _original_dir)
	gm.set("unlocked_levels", backup_unlocked)
	gm.set("level_stars", backup_stars)
	gm.set("current_chapter", backup_chapter)
	_remove_temp_levels()

	if failures > 0:
		print("\n[FAILED] %d loi o ban do man choi.\n" % failures)
		quit(1)
		return
	print("\n[SUCCESS] Ban do man choi dung: nut/trang thai/duong uon chu S/nhan giu/cuon/parallax.\n")
	quit(0)


func _ids(count: int) -> Array[int]:
	var list: Array[int] = []
	for level_id in range(1, count + 1):
		list.append(level_id)
	return list


# ---------------------------------------------------------------------------
# A. Cấu trúc bản đồ
# ---------------------------------------------------------------------------
func _check_structure(map: LevelMap) -> int:
	var failures := 0
	if map.node_count() != TEST_IDS:
		print("[FAIL] Ban do phai co %d nut (dang %d)" % [TEST_IDS, map.node_count()])
		return failures + 1

	# Màn 1 ở DƯỚI CÙNG (y = 0), các màn sau leo lên với khoảng cách ĐỀU
	var first := map.node_for(1)
	var second := map.node_for(2)
	if first == null or second == null or not is_equal_approx(first.position.y, 0.0):
		print("[FAIL] Man 1 phai nam duoi cung (y = %.1f)" % (first.position.y if first != null else 999.0))
		failures += 1
	else:
		var spacing := first.position.y - second.position.y
		if spacing <= 0.0:
			print("[FAIL] Man sau phai o TREN man truoc (spacing = %.1f)" % spacing)
			failures += 1
		for level_id in range(2, TEST_IDS + 1):
			var node := map.node_for(level_id)
			var expected := -float(level_id - 1) * spacing
			if node == null or not is_equal_approx(node.position.y, expected):
				print("[FAIL] Man %d phai o y = %.1f (dang %.1f)"
					% [level_id, expected, node.position.y if node != null else 999.0])
				failures += 1
				break
		# Zigzag: 2 màn liền nhau lệch về 2 phía của trục giữa
		var center_x := 540.0 * 0.5
		if not (first.position.x > center_x and second.position.x < center_x):
			print("[FAIL] Nut phai zigzag quanh truc giua (%.1f · %.1f · tam %.1f)"
				% [first.position.x, second.position.x, center_x])
			failures += 1

	# Items = nút màn + MỘT đường nối liền mạch (n + 1)
	var expected_items := TEST_IDS + 1
	if map.items == null or map.items.get_child_count() != expected_items:
		print("[FAIL] Items phai co %d con (dang %d)"
			% [expected_items, map.items.get_child_count() if map.items != null else -1])
		failures += 1

	if failures == 0:
		print("[CHECK] Ban do: %d nut, man 1 duoi cung, leo deu len tren, zigzag dung, Items = %d con."
			% [TEST_IDS, expected_items])
	return failures


## Đường nối: ĐÚNG MỘT path uốn liền mạch qua tâm TẤT CẢ các nút
func _check_road(map: LevelMap) -> int:
	var failures := 0
	var road: LevelMapPath = null
	var road_count := 0
	for child in map.items.get_children():
		if child is LevelMapPath:
			road_count += 1
			road = child as LevelMapPath
	if road_count != 1:
		print("[FAIL] Phai co DUNG 1 duong noi lien mach (dang %d)" % road_count)
		return failures + 1
	if road.path_node == null or road.path_node.curve == null:
		print("[FAIL] Duong noi phai giu curve tron ven trong `Path`")
		return failures + 1
	var curve := road.path_node.curve
	# n nút + (n-1) điểm uốn xen kẽ giữa các đoạn
	var expected_controls := map.node_count() * 2 - 1
	if curve.point_count != expected_controls:
		print("[FAIL] Curve phai co %d diem kiem soat (nut + diem uon) (dang %d)"
			% [expected_controls, curve.point_count])
		failures += 1
	for level_id in range(1, TEST_IDS + 1):
		var node := map.node_for(level_id)
		if node == null:
			continue
		if curve.get_closest_point(node.position).distance_to(node.position) > 0.5:
			print("[FAIL] Nut man %d phai nam TREN duong noi" % level_id)
			failures += 1
			break
	# Đường phải UỐN (chữ S) chứ không nối thẳng: đo độ lệch của điểm giữa cung
	# so với dây cung nối 2 nút liền nhau.
	var min_bulge := 99999.0
	for index in range(1, TEST_IDS):
		var from_node := map.node_for(index)
		var to_node := map.node_for(index + 1)
		if from_node == null or to_node == null:
			continue
		var from_d := curve.get_closest_offset(from_node.position)
		var to_d := curve.get_closest_offset(to_node.position)
		var arc_mid := curve.sample_baked((from_d + to_d) * 0.5)
		var chord_point := Geometry2D.get_closest_point_to_segment(arc_mid, from_node.position, to_node.position)
		min_bulge = minf(min_bulge, arc_mid.distance_to(chord_point))
	if min_bulge < MIN_SEGMENT_BULGE:
		print("[FAIL] Duong noi bi THANG giua cac nut (lech giua doan chi %.1fpx < %.0fpx)"
			% [min_bulge, MIN_SEGMENT_BULGE])
		failures += 1
	if failures == 0:
		print("[CHECK] Duong noi uon chu S: 1 path qua %d nut (lech giua doan >= %.1fpx), moi nut nam tren duong."
			% [TEST_IDS, min_bulge])
	return failures


func _check_states(map: LevelMap) -> int:
	var failures := 0
	var expected := {
		1: LevelMapNode.State.DONE,      # 3 sao
		2: LevelMapNode.State.DONE,      # 2 sao
		3: LevelMapNode.State.CURRENT,   # chua dat sao -> man nen choi tiep
		4: LevelMapNode.State.NORMAL,
		9: LevelMapNode.State.NORMAL,
		10: LevelMapNode.State.DONE,     # co sao du da mo
		11: LevelMapNode.State.LOCKED,
		12: LevelMapNode.State.LOCKED,
	}
	for level_id in expected:
		var node := map.node_for(level_id)
		if node == null:
			print("[FAIL] Thieu nut man %d" % level_id)
			failures += 1
			continue
		if node.state != expected[level_id]:
			print("[FAIL] Man %d phai o trang thai %s (dang %s)"
				% [level_id, LevelMapNode.State.keys()[expected[level_id]],
					LevelMapNode.State.keys()[node.state]])
			failures += 1
	if failures == 0:
		print("[CHECK] Trang thai nut dung: xong 1-2, current man 3, thuong 4-9, khoa 11-12.")
	return failures


func _check_decor(map: LevelMap) -> int:
	var failures := 0
	var current := map.node_for(3)
	if map.marker == null or not map.marker.visible:
		print("[FAIL] Mui chi 'man tiep theo' phai hien")
		failures += 1
	elif current != null and map.marker.position.y >= current.position.y:
		print("[FAIL] Mui chi phai nam TREN nut current (%.1f vs %.1f)"
			% [map.marker.position.y, current.position.y])
		failures += 1
	var last := map.node_for(TEST_IDS)
	if map.goal == null or not map.goal.visible:
		print("[FAIL] Co dich phai hien")
		failures += 1
	elif last != null and map.goal.position.y >= last.position.y:
		print("[FAIL] Co dich phai nam TREN man cuoi (%.1f vs %.1f)"
			% [map.goal.position.y, last.position.y])
		failures += 1
	if failures == 0:
		print("[CHECK] Mui chi tren man current + co dich tren man cuoi.")
	return failures


func _check_tap(map: LevelMap) -> int:
	var failures := 0
	var fired: Array[int] = []
	map.level_selected.connect(func(level_id: int) -> void: fired.append(level_id))
	# Màn đã mở: bấm phát `level_selected`
	map.node_for(5).button.pressed.emit()
	if fired != [5]:
		print("[FAIL] Bam man da mo phai phat level_selected(5) (dang %s)" % str(fired))
		failures += 1
	# Màn khoá: bấm KHÔNG phát gì
	fired.clear()
	map.node_for(12).button.pressed.emit()
	if not fired.is_empty():
		print("[FAIL] Bam man KHOA khong duoc phat level_selected (dang %s)" % str(fired))
		failures += 1
	if failures == 0:
		print("[CHECK] Bam nut: man mo phat signal, man khoa im lang.")
	return failures


## Nhấn GIỮ nút: số màn + hàng sao phải trôi theo nút (không float); thả ra về chỗ cũ
func _check_press_follow(map: LevelMap) -> int:
	var failures := 0
	map.scroll_to(5, false)
	await process_frame
	var node := map.node_for(5)
	if node == null:
		print("[FAIL] Thieu nut man 5 de thu nhan giu")
		return failures + 1
	var pos: Vector2 = map.tracks.get_global_transform() * node.position
	var stars_base := node.stars_box.position.y
	var label_base := node.label.position.y
	_push_motion(pos)
	_push_button(pos, true)
	await create_timer(0.2).timeout
	var stars_down := node.stars_box.position.y - stars_base
	var label_down := node.label.position.y - label_base
	if stars_down < 1.5 or label_down < 1.5:
		print("[FAIL] Nhan giu: sao + so phai chim 2px theo nut (sao %.2f, so %.2f)"
			% [stars_down, label_down])
		failures += 1
	if absf(stars_down - label_down) > 0.1:
		print("[FAIL] Sao va so phai chim CUNG mot do (%.2f vs %.2f)" % [stars_down, label_down])
		failures += 1
	# Thả chuột + rời con trỏ đi chỗ khác -> nội dung trôi về vị trí gốc
	_push_button(pos, false)
	_push_motion(Vector2(2, 2))
	await create_timer(0.2).timeout
	stars_down = node.stars_box.position.y - stars_base
	if absf(stars_down) > 0.1:
		print("[FAIL] Tha nut: sao phai ve dung cho cu (%.2f)" % stars_down)
		failures += 1
	if failures == 0:
		print("[CHECK] Nhan giu nut: sao + so chim theo nut roi ve dung cho.")
	return failures


func _check_scroll_to(map: LevelMap) -> int:
	var failures := 0
	map.scroll_to(1, false)
	await process_frame
	var bottom := map.scroll_offset_y()
	# Màn 1 phải nằm giữa khung khi cuộn tới
	var node := map.node_for(1)
	if node != null:
		var screen_y := map.tracks.position.y + node.position.y
		if absf(screen_y - 570.0 * 0.5) > 2.0:
			print("[FAIL] scroll_to(1) phai dua nut vao giua khung (y = %.1f, mong %.1f)"
				% [screen_y, 570.0 * 0.5])
			failures += 1
	map.scroll_to(TEST_IDS, false)
	await process_frame
	var top := map.scroll_offset_y()
	# Màn cuối ở TRÊN ⇔ `Tracks` bị kéo XUỐNG nhiều hơn (tracks.y lớn hơn)
	if not (top > bottom):
		print("[FAIL] Cuon len man cuoi phai keo Tracks xuong nhieu hon man 1 (%.1f · %.1f)"
			% [bottom, top])
		failures += 1
	if absf(map.scroll_progress()) > 1.0:
		print("[FAIL] Tien do cuon phai trong [-1, 1] (dang %.2f)" % map.scroll_progress())
		failures += 1
	if failures == 0:
		print("[CHECK] scroll_to: man 1 o duoi, man cuoi o tren, nut duoc can giua khung.")
	return failures


# ---------------------------------------------------------------------------
# B. Màn chọn màn thật (binding + dây signal + parallax + kéo)
# ---------------------------------------------------------------------------
func _check_screen_wiring(scene: LevelScenes) -> int:
	var failures := 0
	var layout: LevelsLayout = scene.layout
	if scene.map == null or scene.background == null:
		print("[FAIL] Node goc phai bind `map` + `background` bang @export")
		return failures + 1
	if layout == null or layout.level_map != scene.map:
		print("[FAIL] Bo cuc phai duoc bind `level_map` tro dung node ban do")
		failures += 1
	if layout.btn_back == null or not layout.btn_back.pressed.is_connected(Callable(scene, "_on_back_pressed")):
		print("[FAIL] Nut Back phai noi bang [connection] trong scenes/levels.tscn")
		failures += 1
	if layout.btn_continue == null \
			or not layout.btn_continue.pressed.is_connected(Callable(scene, "_on_continue_pressed")):
		print("[FAIL] Nut Tiep tuc phai noi bang [connection] trong scenes/levels.tscn")
		failures += 1
	if layout.banner == null or not layout.banner.gui_input.is_connected(Callable(scene, "_on_banner_input")):
		print("[FAIL] Banner phai noi gui_input bang [connection]")
		failures += 1
	if not scene.map.level_selected.is_connected(Callable(scene, "_on_level_selected")):
		print("[FAIL] LevelMap.level_selected phai noi bang [connection]")
		failures += 1
	if not scene.map.scrolled.is_connected(Callable(scene, "_on_map_scrolled")):
		print("[FAIL] LevelMap.scrolled phai noi bang [connection] (nui nen parallax)")
		failures += 1
	failures += _check_real_click(scene)
	# Màn đang chơi phải được canh vào giữa khung bản đồ
	var area := scene.map.get_parent() as Control
	var node := scene.map.node_for(scene.chapter_continue_level())
	if area != null and node != null:
		var screen_y := _node_screen_y(scene, node)
		if absf(screen_y - area.size.y * 0.5) > 12.0:
			print("[FAIL] Man dang choi phai o giua khung ban do (y = %.1f, mong %.1f)"
				% [screen_y, area.size.y * 0.5])
			failures += 1
	if failures == 0:
		print("[CHECK] Binding + day signal trong .tscn dung, man dang choi o giua khung.")
	return failures


## Bấm CHUỘT THẬT vào nút màn đang chơi — bắt cả lỗi "root Control nuốt sự kiện" khiến
## `TextureButton2D` (dùng `_unhandled_input`) không bao giờ nhận được cú bấm.
func _check_real_click(scene: LevelScenes) -> int:
	var failures := 0
	var target := scene.map.node_for(scene.chapter_continue_level())
	if target == null:
		print("[FAIL] Khong tim thay nut man dang choi de bam thu")
		return failures + 1
	var area := scene.map.get_parent() as Control
	var pos: Vector2 = scene.map.tracks.get_global_transform() * target.position
	if area == null or not area.get_global_rect().has_point(pos):
		print("[FAIL] Nut bam thu phai nam trong khung ban do (%s)" % str(pos))
		return failures + 1
	# Ngắt tạm dây lên màn để cú bấm thử không kích hoạt vào màn chơi
	var handler := Callable(scene, "_on_level_selected")
	var rewire := scene.map.level_selected.is_connected(handler)
	if rewire:
		scene.map.level_selected.disconnect(handler)
	var fired: Array[int] = []
	scene.map.level_selected.connect(func(level_id: int) -> void: fired.append(level_id))
	_click_at(pos)
	if fired != [target.level_id]:
		print("[FAIL] Bam chuot vao nut man %d phai phat level_selected (dang %s)"
			% [target.level_id, str(fired)])
		failures += 1
	if rewire:
		scene.map.level_selected.connect(handler)
	if failures == 0:
		print("[CHECK] Bam chuot that vao nut man %d: phat level_selected." % target.level_id)
	return failures


## Bấm chuột trái tại 1 điểm (kèm nhịp rê để nút Node2D cập nhật hover).
## LƯU Ý: `push_input(ev, true)` = toạ độ theo CANVAS (mặc định là toạ độ CỬA SỔ nên bị
## chia theo tỉ lệ stretch ⇒ cú bấm lệch chỗ).
func _click_at(pos: Vector2) -> void:
	_push_motion(pos)
	for pressed in [true, false]:
		_push_button(pos, pressed)


func _push_motion(pos: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	root.push_input(motion, true)


func _push_button(pos: Vector2, pressed: bool) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	click.position = pos
	click.global_position = pos
	root.push_input(click, true)


## Vị trí Y của nút trong khung bản đồ (đã tính độ cuộn hiện tại)
func _node_screen_y(scene: LevelScenes, node: LevelMapNode) -> float:
	return scene.map.tracks.position.y + node.position.y


func _check_drag_inside_outside(scene: LevelScenes) -> int:
	var failures := 0
	scene.map.scroll_to(5, false)
	await process_frame
	var start := scene.map.scroll_offset_y()
	# Kéo trong khung bản đồ (y ~ 400) -> cuộn
	_swipe(Vector2(270, 400), Vector2(0, -120), 8)
	await create_timer(0.7).timeout      # đợi quán tính tắt hẳn rồi mới đo
	var dragged := scene.map.scroll_offset_y()
	if absf(dragged - start) < 100.0:
		print("[FAIL] Keo trong khung ban do phai cuon (%.1f -> %.1f)" % [start, dragged])
		failures += 1
	# Kéo ở KHE header (ngoài khung bản đồ, không đè lên banner) -> KHÔNG cuộn
	_swipe(Vector2(270, 85), Vector2(0, -160), 8)
	await create_timer(0.2).timeout
	if absf(scene.map.scroll_offset_y() - dragged) > 0.5:
		print("[FAIL] Keo o header khong duoc cuon ban do (%.1f -> %.1f)"
			% [dragged, scene.map.scroll_offset_y()])
		failures += 1
	if failures == 0:
		print("[CHECK] Keo trong khung cuon duoc, keo o header khong cuon.")
	return failures


func _check_parallax(scene: LevelScenes) -> int:
	var failures := 0
	var bg: SceneBackground = scene.background
	if bg.layer_far == null or bg.layer_mid == null or bg.layer_near == null:
		print("[FAIL] Nen phai bind du 3 lop parallax (far/mid/near)")
		return failures + 1
	# Nền trượt theo ĐỘ DỊCH THẬT của bản đồ: mỗi lớp dịch = delta × scroll_scale (tỉ lệ CỐ ĐỊNH)
	scene.map.scroll_to(1, false)
	await process_frame
	var delta_low: float = scene.map.scroll_delta_y()
	var near_low := bg.layer_near.scroll_offset.y
	var far_low := bg.layer_far.scroll_offset.y
	scene.map.scroll_to(TEST_IDS, false)
	await process_frame
	var delta_high: float = scene.map.scroll_delta_y()
	var near_high := bg.layer_near.scroll_offset.y
	var far_high := bg.layer_far.scroll_offset.y
	var moved_map := delta_high - delta_low
	if is_equal_approx(near_low, near_high):
		print("[FAIL] Nen phai truot khi ban do cuon (near %.2f)" % near_high)
		failures += 1
	# Tỉ lệ lớp gần = scroll_scale (0.28): nền chạy đúng nhịp tay kéo, không lệch tốc độ
	var near_ratio := absf(near_high - near_low) / absf(moved_map) if absf(moved_map) > 0.01 else 0.0
	if absf(near_ratio - bg.layer_near.scroll_scale.y) > 0.02:
		print("[FAIL] Lop gan phai truot dung ti le %.2f (dang %.3f)"
			% [bg.layer_near.scroll_scale.y, near_ratio])
		failures += 1
	# Lớp càng xa trượt càng ít (he so parallax)
	if absf(far_high - far_low) >= absf(near_high - near_low):
		print("[FAIL] Lop xa phai truot IT hon lop gan (%.2f vs %.2f)"
			% [far_high - far_low, near_high - near_low])
		failures += 1
	if failures == 0:
		print("[CHECK] Parallax: 3 lop truot theo ban do, lop gan dung ti le %.2f (far %.1f · near %.1f)."
			% [near_ratio, far_high, near_high])
	return failures


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
## Mô phỏng thao tác vuốt bằng cảm ứng (touch) trên khung nhìn.
## `push_input(ev, true)` = toạ độ theo CANVAS (mặc định là toạ độ CỬA SỔ).
func _swipe(from_pos: Vector2, delta: Vector2, steps: int) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = from_pos
	root.push_input(touch, true)

	for step in steps:
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = from_pos + delta * (float(step + 1) / float(steps))
		drag.relative = delta / float(steps)
		root.push_input(drag, true)

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = from_pos + delta
	root.push_input(release, true)


# ---------------------------------------------------------------------------
# Thư mục level tạm (user://test_levels) để test 12 màn
# ---------------------------------------------------------------------------
func _prepare_temp_levels() -> int:
	_remove_temp_levels()
	var absolute := ProjectSettings.globalize_path(TEMP_DIR)
	DirAccess.make_dir_recursive_absolute(absolute)

	for level_id in range(1, TEST_IDS + 1):
		var data := LevelData.new()
		data.level_id = level_id
		data.level_title = "Test %d" % level_id
		data.chapter = 1        # màn chọn màn chỉ hiện 1 chương -> để 12 màn cùng chương 1
		data.width = 2
		data.height = 2
		data.start_pos = Vector2i(0, 1)
		data.end_pos = Vector2i(1, 0)
		data.max_steps = 6
		data.par_time = 20.0
		var v := PackedByteArray()
		v.resize((data.width + 1) * data.height)
		v.fill(1)
		var h := PackedByteArray()
		h.resize(data.width * (data.height + 1))
		h.fill(1)
		data.v_walls = v
		data.v_walls_visible = v
		data.h_walls = h
		data.h_walls_visible = h
		var err := ResourceSaver.save(data, "%slevel_%d.tres" % [TEMP_DIR, level_id])
		if err != OK:
			print("[FAIL] Khong tao duoc %slevel_%d.tres (err %d)" % [TEMP_DIR, level_id, err])
			return 1

	print("[CHECK] Da tao 12 man tam trong %s" % TEMP_DIR)
	return 0


func _remove_temp_levels() -> void:
	var absolute := ProjectSettings.globalize_path(TEMP_DIR)
	if not DirAccess.dir_exists_absolute(absolute):
		return
	for level_id in range(1, TEST_IDS + 1):
		var file_path := "%slevel_%d.tres" % [TEMP_DIR, level_id]
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(file_path))
	DirAccess.remove_absolute(absolute)
