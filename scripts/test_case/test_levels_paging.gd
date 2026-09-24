extends SceneTree
## ============================================================================
## Test Case: MÀN CHỌN MÀN - PHÂN TRANG khi có hơn 9 màn (bug 2026-09)
## - Danh sách màn lấy từ file .tres thật -> 12 màn = 2 trang (9 + 3).
## - Vuốt ngang (mô phỏng cảm ứng) phải sang được trang mới.
## - Dots phải đúng số trang + đúng trang đang chọn (bấm dot để nhảy trang).
## - Thẻ màn hiện số theo chương (1-1, 1-2...) và khoá/mở đúng.
## - Từ 2026-02 màn chọn màn CHỈ hiện màn của CHƯƠNG đang chơi
##   (GameManager.current_chapter) -> phần cuối test kiểm tra đúng chương 1 / chương 2.
## Dùng thư mục user://test_levels/ tạm nên KHÔNG đụng resources/levels thật.
## ============================================================================

const TEST_IDS := 12
const UNLOCKED := 10          # khoá 11, 12 để kiểm tra trạng thái khoá
const TEMP_DIR := "user://test_levels/"

var _original_dir := ""


func _init() -> void:
	print("\n========================================================")
	print("  TEST: LEVEL SELECT - PHAN TRANG (> 9 MAN)")
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

	var ids: Array = lm.call("get_level_ids")
	if ids.size() != TEST_IDS:
		print("[FAIL] LevelManager phai thay %d man (dang %d)" % [TEST_IDS, ids.size()])
		failures += 1
	else:
		print("[CHECK] LevelManager doc dung %d man tu thu muc tam." % ids.size())

	# --- Dựng màn chọn màn ---
	var levels_scene: LevelScenes = (load("res://scenes/levels.tscn") as PackedScene).instantiate()
	root.add_child(levels_scene)
	await process_frame
	await process_frame
	await create_timer(0.2).timeout

	failures += _check_pages(levels_scene)

	# --- Đổi trang bằng API ---
	levels_scene.go_to_page(0, false)
	await process_frame
	failures += _expect_page(levels_scene, 0, "go_to_page(0)")

	levels_scene.go_to_page(1)
	await create_timer(0.5).timeout
	failures += _expect_page(levels_scene, 1, "go_to_page(1) co animation")
	failures += _check_dots(levels_scene, 1)

	# --- Vuốt cảm ứng: trang 1 -> trang 2 (kéo nội dung sang trái) ---
	levels_scene.go_to_page(0, false)
	await process_frame
	_swipe(Vector2(950, 700), Vector2(-700, 0), 10)
	await create_timer(0.6).timeout
	failures += _expect_page(levels_scene, 1, "vuot sang trai de sang trang 2")

	# --- Vuốt ngược: trang 2 -> trang 1 (kéo nội dung sang phải) ---
	_swipe(Vector2(250, 700), Vector2(700, 0), 10)
	await create_timer(0.6).timeout
	failures += _expect_page(levels_scene, 0, "vuot sang phai de ve trang 1")

	# --- Vuốt ngắn (dưới nửa trang) phải QUAY VỀ trang cũ ---
	_swipe(Vector2(950, 700), Vector2(-120, 0), 6)
	await create_timer(0.6).timeout
	failures += _expect_page(levels_scene, 0, "vuot ngan phai snap ve trang cu")

	# --- Bấm dot để nhảy trang ---
	var dots := levels_scene.layout.dots_box.get_children()
	if dots.size() >= 2:
		(dots[0] as TextureButton).pressed.emit()
		await create_timer(0.5).timeout
		failures += _expect_page(levels_scene, 0, "bam dot trang 1")
	else:
		print("[FAIL] Phai co 2 dot cho 2 trang (dang %d)" % dots.size())
		failures += 1

	# --- Trở về thư mục levels THẬT: chỉ hiện màn của CHƯƠNG đang chơi ---
	lm.call("set_levels_dir", _original_dir)
	gm.set("current_chapter", 1)
	var chapter_ids: Array = lm.call("levels_in_chapter", 1)
	var expected_pages := maxi(1, int(ceil(float(chapter_ids.size()) / 9.0)))
	var real_scene: LevelScenes = (load("res://scenes/levels.tscn") as PackedScene).instantiate()
	root.add_child(real_scene)
	await process_frame
	await process_frame
	if real_scene.level_ids().size() != chapter_ids.size():
		print("[FAIL] Chuong 1: man chon man phai co %d man (dang %d)"
			% [chapter_ids.size(), real_scene.level_ids().size()])
		failures += 1
	elif real_scene.page_count() != expected_pages:
		print("[FAIL] Chuong 1 (%d man) phai co %d trang (dang %d)"
			% [chapter_ids.size(), expected_pages, real_scene.page_count()])
		failures += 1
	elif real_scene.layout.dots_box.visible != (expected_pages > 1):
		print("[FAIL] Dots phai %s khi co %d trang"
			% ["hien" if expected_pages > 1 else "an", expected_pages])
		failures += 1
	else:
		print("[CHECK] Chuong 1: %d man -> %d trang, dots %s."
			% [chapter_ids.size(), expected_pages, "hien" if expected_pages > 1 else "an"])
	real_scene.queue_free()
	await process_frame

	# --- Chương 2 (nếu đã có màn) -> chỉ hiện màn thuộc chương 2 ---
	var chapter2_ids: Array = lm.call("levels_in_chapter", 2)
	if chapter2_ids.size() > 0:
		gm.set("current_chapter", 2)
		var scene2: LevelScenes = (load("res://scenes/levels.tscn") as PackedScene).instantiate()
		root.add_child(scene2)
		await process_frame
		await process_frame
		var only_chapter2 := true
		for level_id in scene2.level_ids():
			if int(lm.call("chapter_of_level", level_id)) != 2:
				only_chapter2 = false
		if scene2.level_ids().size() != chapter2_ids.size() or not only_chapter2:
			print("[FAIL] Chuong 2: phai hien dung %d man cua chuong 2 (dang %d)"
				% [chapter2_ids.size(), scene2.level_ids().size()])
			failures += 1
		else:
			print("[CHECK] Chuong 2: %d man, tat ca deu thuoc chuong 2." % chapter2_ids.size())
		scene2.queue_free()
		await process_frame

	# --- Dọn dẹp ---
	levels_scene.queue_free()
	await process_frame
	gm.set("unlocked_levels", backup_unlocked)
	gm.set("level_stars", backup_stars)
	gm.set("current_chapter", backup_chapter)
	_remove_temp_levels()

	if failures > 0:
		print("\n[FAILED] %d loi o man chon man phan trang.\n" % failures)
		quit(1)
		return

	print("\n[SUCCESS] Man chon man phan trang dung: vuot trang + dots + so chuong!\n")
	quit(0)


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------
func _check_pages(scene: LevelScenes) -> int:
	var failures := 0
	if scene.level_ids().size() != TEST_IDS:
		print("[FAIL] Man chon man phai co %d man (dang %d)" % [TEST_IDS, scene.level_ids().size()])
		failures += 1
	if scene.page_count() != 2:
		print("[FAIL] Phai chia 2 trang cho 12 man (dang %d)" % scene.page_count())
		failures += 1

	var pages := scene.layout.pages_host.get_children()
	if pages.size() != 2:
		print("[FAIL] Phai co 2 node trang (dang %d)" % pages.size())
		return failures + 1

	var page1: GridContainer = pages[0].get_child(0)
	var page2: GridContainer = pages[1].get_child(0)
	if page1.get_child_count() != 9 or page2.get_child_count() != 3:
		print("[FAIL] Trang phai chia 9 + 3 the (dang %d + %d)"
			% [page1.get_child_count(), page2.get_child_count()])
		failures += 1

	# Số trên thẻ: chương 1 là 1-1..1-12 (màn chọn màn chỉ hiện 1 chương)
	failures += _expect_card_label(page1.get_child(0), "1-1", "the dau trang 1")
	failures += _expect_card_label(page1.get_child(8), "1-9", "the cuoi trang 1")
	failures += _expect_card_label(page2.get_child(0), "1-10", "the dau trang 2")

	# Trạng thái khoá/mở + sao
	var card10: LevelCard = page2.get_child(0)
	if card10.is_locked:
		print("[FAIL] Man 10 phai da mo (unlocked = %d)" % UNLOCKED)
		failures += 1
	if not (page2.get_child(1) as LevelCard).is_locked:
		print("[FAIL] Man 11 phai dang khoa")
		failures += 1
	if not (page2.get_child(2) as LevelCard).is_locked:
		print("[FAIL] Man 12 phai dang khoa")
		failures += 1
	if (page1.get_child(0) as LevelCard).rating != 3:
		print("[FAIL] Man 1 phai co 3 sao")
		failures += 1

	# Trang hiện tại = trang chứa MÀN NÊN CHƠI TIẾP của chương (màn 3 chưa đạt sao -> trang 1)
	if scene.current_page() != 0:
		print("[FAIL] Phai mo san trang chua man nen choi tiep (dang o trang %d)"
			% (scene.current_page() + 1))
		failures += 1

	failures += _check_dots(scene, 0)
	if failures == 0:
		print("[CHECK] 12 man (cung chuong 1) -> 2 trang (9 + 3 the), the hien 1-1..1-12, khoa/mo dung.")
	return failures


func _check_dots(scene: LevelScenes, expected_page: int) -> int:
	var failures := 0
	var dots := scene.layout.dots_box.get_children()
	if dots.size() != scene.page_count():
		print("[FAIL] So dot phai bang so trang (%d dot / %d trang)" % [dots.size(), scene.page_count()])
		failures += 1
	if not scene.layout.dots_box.visible:
		print("[FAIL] Dots phai hien khi co > 1 trang")
		failures += 1
	for index in dots.size():
		var dot := dots[index] as LevelsPageDot
		var is_active := dot != null and dot.is_current()
		if is_active != (index == expected_page):
			print("[FAIL] Dot %d phai %s (trang dang xem = %d)"
				% [index + 1, "sang" if index == expected_page else "mo", expected_page + 1])
			failures += 1
	if failures == 0:
		print("[CHECK] Dots: %d dot, dot trang %d dang sang." % [dots.size(), expected_page + 1])
	return failures


func _expect_page(scene: LevelScenes, expected: int, label: String) -> int:
	var actual := scene.current_page()
	if actual != expected:
		print("[FAIL] %s: phai o trang %d (dang %d)" % [label, expected + 1, actual + 1])
		return 1
	var width := int(round(float(scene.layout.scroll.size.x)))
	var scroll_x := scene.layout.scroll.scroll_horizontal
	if absi(scroll_x - expected * width) > 4:
		print("[FAIL] %s: vi tri truot phai la %d (dang %d)" % [label, expected * width, scroll_x])
		return 1
	print("[CHECK] %s: dung trang %d (scroll_x = %d)." % [label, actual + 1, scroll_x])
	return 0


func _expect_card_label(card: Node, expected: String, label: String) -> int:
	var lbl: Label = card.get_node_or_null("Panel/Level")
	if lbl == null:
		print("[FAIL] %s: khong tim thay Label so man" % label)
		return 1
	if lbl.text != expected:
		print("[FAIL] %s: phai hien '%s' (dang '%s')" % [label, expected, lbl.text])
		return 1
	return 0


## Mô phỏng thao tác vuốt bằng cảm ứng (touch) trên khung nhìn
func _swipe(from_pos: Vector2, delta: Vector2, steps: int) -> void:
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = from_pos
	root.push_input(touch)

	for step in steps:
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = from_pos + delta * (float(step + 1) / float(steps))
		drag.relative = delta / float(steps)
		root.push_input(drag)

	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = from_pos + delta
	root.push_input(release)


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
