extends SceneTree
## ============================================================================
## Test Case: Tiến trình mở màn (level progression) + lưu tiến trình.
## - Vào game ở Play mode phải nạp ĐÚNG màn đang chọn trong GameManager
## - Số bước của ván phải theo đúng thiết kế của LevelData (không dùng mặc định mode)
## - Thắng màn -> popup win -> "Màn kế tiếp" phải mở màn kế và mở khoá màn đó
## - Tiến trình phải được ghi xuống blob lưu trữ (SaveManager.collect)
## ============================================================================

const LEVEL_UNDER_TEST := 3

var _backup := ""


func _init() -> void:
	print("\n========================================================")
	print("  TEST: LEVEL PROGRESSION & SAVE INTEGRATION")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	# Backup dữ liệu thật để không phá tiến trình của người chơi
	if FileAccess.file_exists("user://inkmaze_data.json"):
		var f := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = f.get_as_text()

	var gm: Node = root.get_node_or_null("GameManager")
	assert(gm != null, "Autoload GameManager phai ton tai")
	gm.set("current_mode", "play")
	gm.set("current_level", LEVEL_UNDER_TEST)
	gm.set("unlocked_levels", LEVEL_UNDER_TEST)

	var level_data: LevelData = (root.get_node("LevelManager") as Node).call(
		"load_level", LEVEL_UNDER_TEST
	)
	assert(level_data != null, "Level %d phai nap duoc" % LEVEL_UNDER_TEST)

	# --- 1. Ván chơi phải bắt đầu từ đúng màn đang chọn ---
	var game_scene: Node = await _open_game_scene()
	var state: Object = (game_scene.get("game_controller") as Node).get("game_state")
	assert(int(state.get("floor_number")) == LEVEL_UNDER_TEST,
		"Van phai bat dau tu man %d (dang la %d)" % [LEVEL_UNDER_TEST, int(state.get("floor_number"))])
	assert(int(state.get("max_steps")) == level_data.max_steps,
		"So buoc phai theo LevelData (%d) chu khong dung mac dinh cua mode (%d)"
			% [level_data.max_steps, int(state.get("max_steps"))])
	var maze: Object = (game_scene.get("grid_controller") as Node).get("maze")
	assert(int(maze.get("width")) == level_data.width and int(maze.get("height")) == level_data.height,
		"Me cung phai dung kich thuoc cua Level %d" % LEVEL_UNDER_TEST)
	print("[SUCCESS] Vao game dung man %d (%dx%d) voi %d buoc thiet ke!" % [
		LEVEL_UNDER_TEST, level_data.width, level_data.height, level_data.max_steps])

	# --- 2. Thắng màn -> popup win -> sang màn kế ---
	state.set("max_steps", 99)
	state.set("steps_remaining", 99)
	(game_scene.get("grid_controller") as Node).emit_signal("reached_end")
	for i in 4:
		await process_frame

	var popup := Popups.get_popup(Popups.WIN)
	assert(popup != null, "Thang man phai mo popup win (Play mode)")
	var next_btn: TextureButton = popup.find_child("NextBtn", true, false)
	assert(next_btn != null, "Popup win phai co nut Man ke tiep")
	next_btn.pressed.emit()
	await create_timer(0.4).timeout
	for i in 10:
		await process_frame

	var expected_next := LEVEL_UNDER_TEST + 1
	assert(int(gm.get("unlocked_levels")) >= expected_next,
		"Man %d phai duoc mo khoa (unlocked_levels = %d)" % [expected_next, int(gm.get("unlocked_levels"))])
	assert(int(gm.get("current_level")) == expected_next,
		"current_level phai la %d" % expected_next)

	var next_scene: Node = current_scene
	assert(next_scene != null and next_scene != game_scene, "Phai chuyen sang scene game moi")
	var next_state: Object = (next_scene.get("game_controller") as Node).get("game_state")
	assert(int(next_state.get("floor_number")) == expected_next,
		"Van moi phai o man %d (dang la %d)" % [expected_next, int(next_state.get("floor_number"))])
	print("[SUCCESS] Thang man %d -> mo khoa & choi tiep man %d!" % [LEVEL_UNDER_TEST, expected_next])

	# --- 3. Tiến trình phải được lưu xuống blob ---
	var sm: Node = root.get_node_or_null("SaveManager")
	assert(sm != null, "Autoload SaveManager phai ton tai")
	var blob: Dictionary = sm.call("collect")
	var section: Dictionary = blob.get("GameManager", {})
	assert(int(section.get("unlocked_levels", 0)) >= expected_next,
		"Blob luu tru phai chua unlocked_levels moi")
	assert(section.has("level_stars"), "Blob luu tru phai chua level_stars")
	print("[SUCCESS] Tien trinh duoc ghi vao blob luu tru (khoa=%s)!" % str(section.keys()))

	# --- Khoi phuc du lieu ban dau ---
	Save.reset_all()
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)

	print("\n[SUCCESS] Tat ca bai kiem tra tien trinh deu vuot qua!\n")
	quit(0)


## Mo scenes/game.tscn va doi 1 vai frame cho moi controller san sang
func _open_game_scene() -> Node:
	var packed: PackedScene = load("res://scenes/game.tscn")
	assert(packed != null, "scenes/game.tscn phai load duoc")
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in 4:
		await process_frame
	return scene
