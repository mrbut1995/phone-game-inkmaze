extends SceneTree
## ============================================================================
## Test Case: LUỒNG TUTORIAL LẦN ĐẦU (onboarding) + TUTORIAL LẦN ĐẦU THEO CHẾ ĐỘ
##
## 1. TutorialManager: chuỗi bước đúng thứ tự
##    first_time → how_to_play_move → MÀN 1 → how_to_play_checking_wall
##    → MÀN 2 → how_to_use_tool → MÀN 3 → MÀN 4 → congrats_first_time.
## 2. GameManager: lưu/đọc bước luồng (tương thích save cũ đã học xong bộ CORE).
## 3. Đi hết luồng bằng thao tác thật: Title → từng bài/màn → bài CHÚC MỪNG
##    (chọn “CHƠI BÀN TIẾP THEO” → màn 5 · chọn “VỀ MÀN HÌNH CHÍNH” → Main).
## 4. Nút "?" trong luồng: màn thực hành chỉ mở ĐÚNG bài của màn đó.
## 5. Tutorial lần đầu theo chế độ: vào màn blind_memory lần đầu → mở bài học rồi vào màn;
##    lần sau vào thẳng màn.
## 6. Màn thực hành 1·2·3: đúng vai (1 toàn tường hiện · 2·3 có tường ẩn · luôn có đường).
## ============================================================================

const TUTORIAL_SCENE_PATH := "res://scenes/tutorial.tscn"
const GAME_SCENE_PATH := "res://scenes/game.tscn"
const MAIN_SCENE_PATH := "res://scenes/main.tscn"
const BLIND_MEMORY_LEVEL := 16

var _failed := 0
var _checks := 0
var _gm: Node = null
var _tm: Node = null
var _save_backup := ""
var _backup: Dictionary = {}


func _init() -> void:
	print("\n========================================================")
	print("  TEST: LUONG TUTORIAL LAN DAU (ONBOARDING) + THEO CHE DO")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	_gm = root.get_node_or_null("GameManager")
	_tm = root.get_node_or_null("TutorialManager")
	assert(_gm != null, "Autoload GameManager phai ton tai")
	assert(_tm != null, "Autoload TutorialManager phai ton tai")

	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_save_backup = rf.get_as_text()
	_backup = {
		"step": int(_gm.get("tutorial_flow_step")),
		"done": bool(_gm.get("tutorial_flow_done")),
		"progress": (_gm.get("tutorial_progress") as Dictionary).duplicate(),
		"unlocked": int(_gm.get("unlocked_levels")),
		"level": int(_gm.get("current_level")),
		"mode": str(_gm.get("current_mode")),
		"difficulty": str(_gm.get("current_difficulty")),
		"level_run": bool(_gm.get("level_run")),
		"debug_run": bool(_gm.get("debug_run")),
	}

	_section_1_manager()
	await _section_2_walkthrough()
	await _section_2b_skip_all()
	await _section_2c_unlocked_save()
	await _section_2d_resume()
	await _section_3_question_mark()
	await _section_3b_question_mark_resumes_flow()
	await _section_4_mode_tutorial()
	_section_5_practice_levels()

	_restore_state()
	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. TutorialManager + lưu trữ bước luồng
# ---------------------------------------------------------------------------
func _section_1_manager() -> void:
	print("-- 1. TutorialManager + luu buoc luong --")
	var consts: Dictionary = _tm.get_script().get_script_constant_map()
	var flow: Array = consts.get("FLOW", [])
	_check(flow.size() == 9, "Luong onboarding co 9 buoc (dang %d)" % flow.size())

	var ids := ""
	for step: Dictionary in flow:
		if str(step.get("kind", "")) == "tutorial":
			ids += "%s|" % str(step.get("id", ""))
		else:
			ids += "M%d|" % int(step.get("id", 0))
	_check(ids == "first_time|how_to_play_move|M1|how_to_play_checking_wall|M2|how_to_use_tool|M3|M4|congrats_first_time|",
		"Thu tu buoc dung (dang '%s')" % ids)
	_check(flow.size() == 9 and str((flow[8] as Dictionary).get("id", "")) == "congrats_first_time",
		"Buoc CUOI cua luong la bai CHUC MUNG (dang '%s')" % str((flow[8] as Dictionary).get("id", "")))

	var mode_tutorials: Dictionary = consts.get("MODE_TUTORIALS", {})
	_check(mode_tutorials.size() == 8 and str(mode_tutorials.get("blind_memory", "")) == "how_to_play_blind_memory",
		"8 che do Special co tutorial rieng (blind_memory -> how_to_play_blind_memory)")

	_gm.set("tutorial_flow_done", false)
	_check(bool(_tm.call("needs_onboarding")), "Luong chua xong -> can onboarding")
	_gm.set("tutorial_flow_done", true)
	_check(not bool(_tm.call("needs_onboarding")), "Luong da xong -> khong onboarding")

	# Lưu/đọc bước luồng
	_gm.set("tutorial_flow_step", 4)
	_gm.set("tutorial_flow_done", false)
	var blob: Dictionary = _gm.call("export_progress")
	_check(int(blob.get("tutorial_flow_step", -1)) == 4 and not bool(blob.get("tutorial_flow_done", true)),
		"export_progress co buoc luong")
	_gm.call("import_progress", {"tutorial_flow_step": 6, "tutorial_flow_done": true})
	_check(int(_gm.get("tutorial_flow_step")) == 6 and bool(_gm.get("tutorial_flow_done")),
		"import_progress khoi phuc buoc luong")

	# Save CŨ (không có khoá flow_done): ai đã học xong bộ CORE thì không bắt học lại
	_gm.set("tutorial_flow_done", false)
	_gm.call("import_progress", {"tutorial_progress": {"core_completed": true}})
	_check(bool(_gm.get("tutorial_flow_done")), "Save cu da hoc xong CORE -> coi nhu xong luong")


# ---------------------------------------------------------------------------
# 2. Đi hết luồng onboarding bằng thao tác thật
# ---------------------------------------------------------------------------
func _section_2_walkthrough() -> void:
	print("\n-- 2. Nguoi moi: Title -> first_time -> ... -> MAN 4 -> xong luong --")
	_set_flow_state(0, false, 1)

	# Title của người chơi mới -> mở màn Tutorial (first_time)
	var title: Node = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _settle(2)
	title.call("_on_start_pressed")
	await _settle(4)
	title.queue_free()
	_check(_scene_path() == TUTORIAL_SCENE_PATH,
		"Title nguoi moi -> man Tutorial (dang '%s')" % _scene_path())
	var ctrl: Node = _tutorial_controller()
	_check(str(_current_tutorial_id()) == "first_time",
		"Bat dau o bai first_time (dang '%s')" % _current_tutorial_id())
	_check(current_scene != null and bool(current_scene.get("_in_flow")),
		"Man Tutorial biet dang chay LUONG onboarding")

	# first_time xong -> how_to_play_move chạy tiếp TRONG màn
	_complete_active_tutorial(ctrl)
	await _settle(3)
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "how_to_play_move",
		"first_time xong -> how_to_play_move (khong ve Main)")

	# how_to_play_move xong -> vào MÀN 1
	_complete_active_tutorial(ctrl)
	await _settle(4)
	_check(_scene_path() == GAME_SCENE_PATH, "how_to_play_move xong -> vao MAN 1")
	_check(int(_gm.get("current_level")) == 1 and bool(_gm.get("level_run")),
		"MAN 1 duoc nap dung (level_run · level 1)")

	# Xong MÀN 1 -> mở bài how_to_play_checking_wall
	await _clear_current_level()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "how_to_play_checking_wall",
		"Xong MAN 1 -> how_to_play_checking_wall")

	# Xong bài kiểm tường -> MÀN 2
	_complete_active_tutorial(_tutorial_controller())
	await _settle(4)
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 2,
		"how_to_play_checking_wall xong -> MAN 2")

	# Xong MÀN 2 -> bài công cụ
	await _clear_current_level()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "how_to_use_tool",
		"Xong MAN 2 -> how_to_use_tool")

	# Xong bài công cụ -> MÀN 3
	_complete_active_tutorial(_tutorial_controller())
	await _settle(4)
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 3,
		"how_to_use_tool xong -> MAN 3")

	# Xong MÀN 3 -> MÀN 4 (không có bài học giữa 2 màn)
	await _clear_current_level()
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 4,
		"Xong MAN 3 -> MAN 4 (khong co bai hoc)")

	# Xong MÀN 4 -> bài CHÚC MỪNG (bước cuối luồng) — chưa kết thúc luồng ngay
	await _clear_current_level()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "congrats_first_time",
		"Xong MAN 4 -> bai CHUC MUNG (dang '%s' · '%s')" % [_scene_path(), _current_tutorial_id()])
	_check(current_scene != null and bool(current_scene.get("_in_flow")),
		"Bai CHUC MUNG nam TRONG luong onboarding")
	_check(not bool(_gm.get("tutorial_flow_done")), "Chua bam chon -> luong CHUA ket thuc")

	# Bài chúc mừng có đủ 2 lựa chọn: CHƠI BÀN TIẾP THEO · VỀ MÀN HÌNH CHÍNH
	var congrats: Node = _tutorial_controller().get("active_tutorial_node")
	_check(congrats != null and congrats.get("btn_continue") != null and congrats.get("btn_main") != null,
		"Bai CHUC MUNG co du 2 nut lua chon (tiep tuc · ve Main)")

	# Chọn “CHƠI BÀN TIẾP THEO” -> vào luôn MÀN 5 và luồng kết thúc
	if congrats != null:
		congrats.call("_on_continue_pressed")
	await _settle(6)
	_check(bool(_gm.get("tutorial_flow_done")), "Chon choi tiep -> ket thuc luong onboarding")
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 5,
		"Chon choi tiep -> vao MAN 5 (dang '%s' · level %d)" % [_scene_path(), int(_gm.get("current_level"))])
	_check(not bool(_tm.get("flow_active")), "Luong da dung (flow_active = false)")


# ---------------------------------------------------------------------------
# 2b. Nút "Bỏ qua tất cả" ở first_time
# ---------------------------------------------------------------------------
func _section_2b_skip_all() -> void:
	print("\n-- 2b. Bo qua tat ca --")
	_set_flow_state(0, false, 1)

	var title: Node = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _settle(2)
	title.call("_on_start_pressed")
	await _settle(4)
	title.queue_free()
	_check(str(_current_tutorial_id()) == "first_time", "Vao bai first_time truoc khi bo qua")

	var active: Node = _tutorial_controller().get("active_tutorial_node")
	_check(active != null, "Co bai dang mo de bam Bo qua tat ca")
	if active != null:
		active.call("skip_all_tutorials")
	await _settle(4)
	_check(bool(_gm.get("tutorial_flow_done")), "Bo qua tat ca -> ket thuc luong onboarding")
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 1,
		"Bo qua tat ca -> vao thang MAN 1 (dang '%s')" % _scene_path())


# ---------------------------------------------------------------------------
# 2c. Save đã mở sẵn nhiều màn (người chơi cũ / Debug / vừa xoá tiến trình tutorial)
#     → luồng VẪN phải hiện đủ các MÀN THỰC HÀNH, không được bỏ qua
# ---------------------------------------------------------------------------
func _section_2c_unlocked_save() -> void:
	print("\n-- 2c. Save da mo san nhieu man: van phai hien MAN THUC HANH --")
	_set_flow_state(0, false, 20)

	await _open_title_start()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "first_time",
		"Luong moi: bat dau o first_time")
	_complete_active_tutorial(_tutorial_controller())
	await _settle(3)
	_complete_active_tutorial(_tutorial_controller())
	await _settle(4)
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 1,
		"Khong bo qua MAN 1 du da mo khoa san (dang '%s' · level %d)"
			% [_scene_path(), int(_gm.get("current_level"))])

	await _clear_current_level()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "how_to_play_checking_wall",
		"Xong MAN 1 -> how_to_play_checking_wall")
	_complete_active_tutorial(_tutorial_controller())
	await _settle(4)
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 2,
		"Khong bo qua MAN 2 du da mo khoa san (dang '%s' · level %d)"
			% [_scene_path(), int(_gm.get("current_level"))])


# ---------------------------------------------------------------------------
# 2d. Thoát app giữa chừng → mở lại → quay lại ĐÚNG màn hình đang làm dở
# ---------------------------------------------------------------------------
func _section_2d_resume() -> void:
	print("\n-- 2d. Thoat giua chung -> mo lai app -> quay lai dung man hinh --")
	_set_flow_state(0, false, 1)

	# (a) Đang học first_time mà thoát → mở lại vẫn vào first_time
	await _open_title_start()
	_check(str(_current_tutorial_id()) == "first_time", "Mo lan dau: dang o first_time")
	_quit_app_sim()
	await _open_title_start()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "first_time",
		"Thoat giua first_time -> mo lai quay ve first_time (dang '%s')" % _current_tutorial_id())

	# (b) Thoát khi đang ở bài how_to_play_checking_wall (bước 3)
	_gm.set("tutorial_flow_step", 3)
	_quit_app_sim()
	await _open_title_start()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "how_to_play_checking_wall",
		"Thoat giua checking_wall -> mo lai quay ve checking_wall (dang '%s')" % _current_tutorial_id())

	# (c) Thoát khi đang chơi MÀN 1-2 (bước 4) — kể cả save đã mở sẵn nhiều màn
	_gm.set("tutorial_flow_step", 4)
	_gm.set("unlocked_levels", 20)
	_quit_app_sim()
	await _open_title_start()
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 2,
		"Thoat khi dang o MAN 1-2 -> mo lai quay ve MAN 1-2 (dang '%s' · level %d)"
			% [_scene_path(), int(_gm.get("current_level"))])

	# (d) Thoát khi đang ở bài CHÚC MỪNG (bước cuối) → mở lại vẫn vào bài chúc mừng;
	#     chọn “VỀ MÀN HÌNH CHÍNH” → về Main và kết thúc luồng
	_gm.set("tutorial_flow_step", 8)
	_gm.set("unlocked_levels", 5)
	_quit_app_sim()
	await _open_title_start()
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "congrats_first_time",
		"Thoat giua bai CHUC MUNG -> mo lai quay ve bai CHUC MUNG (dang '%s')" % _current_tutorial_id())
	var cg: Node = _tutorial_controller().get("active_tutorial_node") if _tutorial_controller() != null else null
	if cg != null:
		cg.call("_on_main_pressed")
	await _settle(6)
	_check(bool(_gm.get("tutorial_flow_done")), "Chon ve Main -> ket thuc luong onboarding")
	_check(_scene_path() == MAIN_SCENE_PATH,
		"Chon ve Main -> mo man hinh chinh (dang '%s')" % _scene_path())


# ---------------------------------------------------------------------------
# 3. Nút "?" trong luồng: màn thực hành chỉ mở đúng bài của màn
# ---------------------------------------------------------------------------
func _section_3_question_mark() -> void:
	print("\n-- 3. Nut '?' trong luong onboarding --")
	# Giả lập: đang trong luồng, dừng ở bước MÀN 1
	_gm.set("tutorial_flow_done", false)
	_gm.set("tutorial_flow_step", 2)
	_gm.set("unlocked_levels", 1)
	_tm.set("flow_active", true)
	_tm.set("_flow_index", 2)
	_gm.set("pending_tutorial", "")
	_gm.set("pending_return_to_game", false)

	_check(str(_tm.call("practice_tutorial_for_level", 1)) == "how_to_play_move",
		"Man 1 -> how_to_play_move")
	_check(str(_tm.call("practice_tutorial_for_level", 2)) == "how_to_play_checking_wall",
		"Man 2 -> how_to_play_checking_wall")
	_check(str(_tm.call("practice_tutorial_for_level", 3)) == "how_to_use_tool",
		"Man 3 -> how_to_use_tool")
	_check(str(_tm.call("practice_tutorial_for_level", 4)) == "",
		"Man 4 khong phai man thuc hanh")

	# Mở màn chơi MÀN 1 rồi bấm "?" — chỉ được yêu cầu ĐÚNG 1 bài
	_gm.call("prepare_level_run", 1)
	var gs: Node = (load(GAME_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(gs)
	await _settle(2)
	gs.game_controller.call("open_instruction")
	_check(str(_gm.get("pending_tutorial")) == "how_to_play_move",
		"Nut ? o MAN 1 chi mo how_to_play_move (dang '%s')" % str(_gm.get("pending_tutorial")))
	_check(bool(_gm.get("pending_return_to_game")), "Nut ? -> hoc xong quay lai man choi")
	await _settle(3)
	gs.queue_free()
	await _settle(2)


# ---------------------------------------------------------------------------
# 3b. Nút "?" khi LUỒNG ĐANG CHỜ 1 BÀI HỌC: học xong bài thực hành thì bài của luồng
#     phải chạy tiếp NGAY trong màn Tutorial — KHÔNG nhảy về màn chơi (màn chơi khởi động
#     lại từ đầu = nháy màn hình) rồi mới mở bài.
# ---------------------------------------------------------------------------
func _section_3b_question_mark_resumes_flow() -> void:
	print("\n-- 3b. Nut '?' khi luong dang cho BAI HOC -> chay tiep trong man Tutorial --")
	# Đúng trạng thái save thật: luồng ở BƯỚC 3 (chờ bài how_to_play_checking_wall), người chơi
	# đang ở MÀN 1 và bấm "?" (bài thực hành của MÀN 1 = how_to_play_move)
	_set_flow_state(3, false, 5)
	_tm.set("flow_active", true)
	_tm.set("_flow_index", 3)
	_gm.set("current_level", 1)
	_gm.call("prepare_level_run", 1)
	var gs: Node = (load(GAME_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(gs)
	current_scene = gs
	await _settle(3)
	gs.game_controller.call("open_instruction")
	_check(str(_gm.get("pending_tutorial")) == "how_to_play_move",
		"Nut ? o MAN 1 mo bai thuc hanh how_to_play_move (dang '%s')" % str(_gm.get("pending_tutorial")))
	_check(str(_tm.call("resume_flow_lesson")) == "how_to_play_checking_wall",
		"Luong dang cho bai how_to_play_checking_wall (dang '%s')" % str(_tm.call("resume_flow_lesson")))
	await _settle(4)
	_check(_scene_path() == TUTORIAL_SCENE_PATH and str(_current_tutorial_id()) == "how_to_play_move",
		"Bai thuc hanh mo trong man Tutorial (dang '%s')" % _current_tutorial_id())

	# Học xong bài thực hành → bài của LUỒNG chạy tiếp NGAY (không về màn chơi)
	_complete_active_tutorial(_tutorial_controller())
	await _settle(4)
	_check(_scene_path() == TUTORIAL_SCENE_PATH,
		"Xong bai thuc hanh -> VAN o man Tutorial, khong nhay ve man choi (dang '%s')" % _scene_path())
	_check(str(_current_tutorial_id()) == "how_to_play_checking_wall",
		"Bai cua luong chay tiep trong man (dang '%s')" % _current_tutorial_id())
	_check(current_scene != null and bool(current_scene.get("_in_flow")),
		"Man Tutorial chuyen sang che do chay LUONG (in_flow = true)")
	_check(current_scene != null and not bool(current_scene.get("_return_to_game")),
		"Da tat co 'hoc xong quay ve man choi'")

	# Học xong bài của luồng → luồng đi tiếp bước kế (MÀN 2)
	_complete_active_tutorial(_tutorial_controller())
	await _settle(5)
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == 2,
		"Xong bai cua luong -> di tiep MAN 2 (dang '%s' · level %d)"
			% [_scene_path(), int(_gm.get("current_level"))])


# ---------------------------------------------------------------------------
# 4. Tutorial lần đầu theo chế độ (blind_memory)
# ---------------------------------------------------------------------------
func _section_4_mode_tutorial() -> void:
	print("\n-- 4. Tutorial lan dau theo che do (blind_memory) --")
	_gm.set("tutorial_flow_done", true)
	_set_flow_state(int(_gm.get("tutorial_flow_step")), true, 99)
	_gm.call("set_tutorial_completed", "how_to_play_blind_memory", false)
	_gm.set("debug_run", false)

	# Lần đầu vào màn blind_memory -> mở bài học TRƯỚC, chưa vào màn
	_gm.call("start_level", BLIND_MEMORY_LEVEL)
	await _settle(4)
	_check(_scene_path() == TUTORIAL_SCENE_PATH,
		"Lan dau vao che do -> mo bai hoc (dang '%s')" % _scene_path())
	_check(str(_current_tutorial_id()) == "how_to_play_blind_memory",
		"Mo dung bai how_to_play_blind_memory (dang '%s')" % _current_tutorial_id())
	_check(current_scene != null and bool(current_scene.get("_return_to_game")),
		"Hoc xong se quay lai man choi (khong phai luong onboarding)")

	# Học xong -> vào đúng màn chơi đã nạp
	_complete_active_tutorial(_tutorial_controller())
	await _settle(4)
	_check(_scene_path() == GAME_SCENE_PATH and int(_gm.get("current_level")) == BLIND_MEMORY_LEVEL,
		"Hoc xong -> vao dung man %d" % BLIND_MEMORY_LEVEL)
	_check(bool(_gm.call("is_tutorial_completed", "how_to_play_blind_memory")),
		"Da ghi co hoan thanh bai hoc cua che do")

	# Lần sau vào lại -> KHÔNG mở bài học nữa
	_gm.call("start_level", BLIND_MEMORY_LEVEL)
	await _settle(4)
	_check(_scene_path() == GAME_SCENE_PATH,
		"Da hoc roi -> lan sau vao thang man choi (dang '%s')" % _scene_path())


# ---------------------------------------------------------------------------
# 5. Màn thực hành 1·2·3
# ---------------------------------------------------------------------------
func _section_5_practice_levels() -> void:
	print("\n-- 5. Man thuc hanh 1-2-3 --")
	var lm: Node = root.get_node_or_null("LevelManager")
	_check(lm != null, "Autoload LevelManager ton tai")
	if lm == null:
		return

	var l1: LevelData = lm.call("load_level", 1)
	_check(l1.width == 3 and l1.height == 3, "MAN 1 la 3x3")
	_check(_hidden_wall_count(l1) == 0, "MAN 1 toan bo tuong HIEN (bai hoc keo duong)")
	var maze1: MazeData = l1.to_maze_data()
	var steps1: int = maze1.get_shortest_path(maze1.get_start(), maze1.get_end()).size() - 1
	_check(steps1 == 4, "MAN 1 duong ngan nhat 4 buoc (dang %d)" % steps1)
	_check(l1.max_steps >= steps1, "MAN 1 du buoc de thu suc")

	var l2: LevelData = lm.call("load_level", 2)
	_check(_hidden_wall_count(l2) == 1, "MAN 2 co DUNG 1 tuong an (bai hoc doc so)")
	var maze2: MazeData = l2.to_maze_data()
	var steps2: int = maze2.get_shortest_path(maze2.get_start(), maze2.get_end()).size() - 1
	_check(steps2 == 4, "MAN 2 luon co duong (4 buoc)")
	_check(l2.max_steps >= steps2, "MAN 2 du buoc")

	var l3: LevelData = lm.call("load_level", 3)
	_check(_hidden_wall_count(l3) == 1, "MAN 3 co 1 tuong an (bai hoc cong cu)")
	var maze3: MazeData = l3.to_maze_data()
	var steps3: int = maze3.get_shortest_path(maze3.get_start(), maze3.get_end()).size() - 1
	_check(steps3 == 6, "MAN 3 duong dai hon (6 buoc, can Goi y/Hoan tac)")
	_check(l3.max_steps >= steps3, "MAN 3 du buoc")


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
	print("[%s] %s" % ["CHECK" if condition else "FAIL", label])


## Đợi vài frame cho đổi scene / tween chạy xong (change_scene hoãn tới cuối frame)
func _settle(frames := 3) -> void:
	for i in frames:
		await process_frame


func _scene_path() -> String:
	return current_scene.scene_file_path if current_scene != null else ""


func _tutorial_controller() -> Node:
	if current_scene == null:
		return null
	return current_scene.get("tutorial_controller")


func _current_tutorial_id() -> String:
	var ctrl := _tutorial_controller()
	return str(ctrl.get("current_tutorial_id")) if ctrl != null else ""


func _complete_active_tutorial(ctrl: Node) -> void:
	var active: Node = ctrl.get("active_tutorial_node") if ctrl != null else null
	if active != null:
		active.call("complete_tutorial")


## Giả lập người chơi bấm "TIẾP TỤC" trên popup thắng của màn đang chơi
func _clear_current_level() -> void:
	var gc: Node = current_scene.get("game_controller") if current_scene != null else null
	var mode_id := ""
	var gmc: Node = gc.get("game_mode_controller") if gc != null else null
	if gmc != null and gmc.get("game_mode") != null:
		mode_id = str(gmc.get("game_mode").mode_id)
	print("   [INFO] bam TIEP TUC: scene=%s · gc=%s · state=%s · mode=%s · flow=%s/%d"
		% [_scene_path(), str(gc != null), str(gc != null and gc.get("game_state") != null), mode_id,
			str(_tm.get("flow_active")), int(_tm.get("_flow_index"))])
	if gc != null:
		gc.call("_on_continue_requested")
	await _settle(4)
	print("   [INFO] sau khi tiep tuc: scene=%s · level=%d" % [_scene_path(), int(_gm.get("current_level"))])


## Mở màn Title như lúc khởi động app rồi bấm "CHẠM ĐỂ BẮT ĐẦU" (chờ đổi scene xong)
func _open_title_start() -> void:
	var title: Node = (load("res://scenes/title.tscn") as PackedScene).instantiate()
	root.add_child(title)
	await _settle(2)
	title.call("_on_start_pressed")
	await _settle(4)
	title.queue_free()


## Giả lập THOÁT APP: gỡ scene đang mở + xoá trạng thái luồng trong RAM
## (chỉ giữ lại phần đã lưu trong GameManager — đúng như mở lại app)
func _quit_app_sim() -> void:
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	_tm.set("flow_active", false)
	_tm.set("_flow_index", 0)
	_gm.set("pending_tutorial", "")
	_gm.set("pending_return_to_game", false)
	await _settle(2)


## Đặt trạng thái luồng: bước · xong chưa · số màn đã mở; xoá sạch cờ tutorial
func _set_flow_state(step: int, done: bool, unlocked: int) -> void:
	var progress: Dictionary = _gm.get("tutorial_progress")
	for key in progress:
		progress[key] = false
	_gm.set("tutorial_flow_step", step)
	_gm.set("tutorial_flow_done", done)
	_gm.set("unlocked_levels", unlocked)
	_tm.set("flow_active", false)
	_tm.set("_flow_index", 0)
	_gm.set("pending_tutorial", "")
	_gm.set("pending_return_to_game", false)


func _hidden_wall_count(lvl: LevelData) -> int:
	var hidden := 0
	for i in lvl.v_walls.size():
		if lvl.v_walls[i] == 1 and i < lvl.v_walls_visible.size() and lvl.v_walls_visible[i] == 0:
			hidden += 1
	for i in lvl.h_walls.size():
		if lvl.h_walls[i] == 1 and i < lvl.h_walls_visible.size() and lvl.h_walls_visible[i] == 0:
			hidden += 1
	return hidden


func _restore_state() -> void:
	# Gỡ scene đang mở (nếu là scene do test điều hướng tới) rồi trả GameManager về như cũ
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	_gm.set("tutorial_flow_step", int(_backup.get("step", 0)))
	_gm.set("tutorial_flow_done", bool(_backup.get("done", false)))
	_gm.set("tutorial_progress", _backup.get("progress", {}))
	_gm.set("unlocked_levels", int(_backup.get("unlocked", 1)))
	_gm.set("current_level", int(_backup.get("level", 1)))
	_gm.set("current_mode", str(_backup.get("mode", "dungeon")))
	_gm.set("current_difficulty", str(_backup.get("difficulty", "medium")))
	_gm.set("level_run", bool(_backup.get("level_run", false)))
	_gm.set("debug_run", bool(_backup.get("debug_run", false)))
	_gm.set("pending_tutorial", "")
	_gm.set("pending_return_to_game", false)
	_tm.set("flow_active", false)
	_tm.set("_flow_index", 0)
	if not _save_backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_save_backup)
	print("[INFO] Da khoi phuc trang thai GameManager + file save.")
