extends SceneTree
## ============================================================================
## Test Case: HỒ SƠ CÁ NHÂN (Profiler) — tính năng 2026-02
##
## 1. Manager (PlayerProfileManager): catalog 6 avatar + 6 viền khung, mặc định
##    sở hữu, khoá theo mốc (Dungeon / Chuỗi Daily / AP).
## 2. Trang bị + tên: equip món sở hữu, chặn món chưa mở khoá, đổi tên 16 ký tự.
## 3. Thống kê: EXP = AP + Sao×25 · Cấp = 1 + EXP/200 · tỉ lệ thắng theo lịch sử.
## 4. Lịch sử ván: record_run ghi đúng + giới hạn 10 dòng.
## 5. Scene Profiler: 2 hướng bind layout, số liệu đổ lên UI, hàng hoạt động ≤ 3.
## 6. Popup DIỆN MẠO HỒ SƠ: 6 món/lưới, 2 tab, chọn mẫu đổi phần xem trước.
## 7. Lưu trữ: SaveManager đăng ký provider + export/import khôi phục hồ sơ.
## ============================================================================

const AVATAR_COUNT := 6
const FRAME_COUNT := 6
const MAX_RECENT := 10
const EXP_PER_LEVEL := 200
const EXP_PER_STAR := 25

var _backup := ""
var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: HO SO CA NHAN (PROFILER)")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	# Sao lưu dữ liệu thật (test không được phá tiến trình người chơi)
	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var manager: Node = root.get_node_or_null("PlayerProfileManager")
	assert(manager != null, "Autoload PlayerProfileManager phai ton tai")
	var saved: Dictionary = manager.call("export_progress")

	_section_1_catalog(manager)
	_section_2_equip_and_name(manager)
	_section_3_stats(manager)
	_section_4_recent(manager)
	await _section_5_scene(manager)
	await _section_6_popup(manager)
	_section_7_save(manager, saved)

	# --- Khôi phục dữ liệu người chơi ---
	manager.call("import_progress", saved)
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
	print("[INFO] Da khoi phuc tien trinh nguoi choi.")

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Catalog
# ---------------------------------------------------------------------------
func _section_1_catalog(manager: Node) -> void:
	print("--- 1. CATALOG AVATAR / VIEN KHUNG ---")
	var avatars: Array = manager.call("avatars")
	var frames: Array = manager.call("frames")
	_entry(avatars.size() == AVATAR_COUNT, "Co %d avatar" % AVATAR_COUNT)
	_entry(frames.size() == FRAME_COUNT, "Co %d vien khung" % FRAME_COUNT)

	var broken := 0
	for entry in avatars + frames:
		var icon := str(entry.get("icon", ""))
		if str(entry.get("id", "")).is_empty() or str(entry.get("name_key", "")).is_empty() \
				or not ResourceLoader.exists(icon):
			broken += 1
			print("[FAIL] Mon thieu du lieu: %s" % str(entry))
	_entry(broken == 0, "Moi mon co id + name_key + file icon ton tai (loi: %d)" % broken)

	_entry(str(manager.get("avatar_id")) == "avatar_ink", "Avatar mac dinh: chiến binh mực")
	_entry(str(manager.get("frame_id")) == "frame_gear", "Vien khung mac dinh: bánh răng vàng")

	# Mặc định đã sở hữu 3 avatar + 3 viền (mockup: ĐANG DÙNG / SỞ HỮU / khoá)
	_entry(bool(manager.call("owns_avatar", "avatar_wizard")), "So huu san Phù Thủy Số")
	_entry(bool(manager.call("owns_frame", "frame_laurel")), "So huu san Nguyệt Quế")
	_entry(not bool(manager.call("owns_avatar", "avatar_fox")), "Cáo Tinh Anh chua so huu (500 xu)")

	# Khoá theo mốc: Dungeon 50 · Chuỗi Daily 30 · 500 AP
	var robot_lock: Dictionary = manager.call("lock_of", "avatar", "avatar_robot")
	_entry(robot_lock.is_empty() or (str(robot_lock.get("stat", "")) == "dungeon_best_floor"
		and int(robot_lock.get("value", 0)) == 50),
		"Robot Logic khoá theo mốc Dungeon 50 (đang %s)" % str(robot_lock))
	var fire_lock: Dictionary = manager.call("lock_of", "frame", "frame_fire")
	_entry(fire_lock.is_empty() or (str(fire_lock.get("stat", "")) == "daily_streak"
		and int(fire_lock.get("value", 0)) == 30),
		"Gai Lửa khoá theo chuỗi Daily 30 (đang %s)" % str(fire_lock))

	var entry_fox: Dictionary = manager.call("avatar_entry", "avatar_fox")
	_entry(int(entry_fox.get("price", 0)) == 500, "Cáo Tinh Anh gia 500 xu")
	var entry_royal: Dictionary = manager.call("frame_entry", "frame_royal")
	_entry(int(entry_royal.get("price", 0)) == 800, "Hào Quang Đế Vương gia 800 xu")


# ---------------------------------------------------------------------------
# 2. Trang bị + tên hiển thị
# ---------------------------------------------------------------------------
func _section_2_equip_and_name(manager: Node) -> void:
	print("\n--- 2. TRANG BI + TEN HIEN THI ---")
	_entry(bool(manager.call("equip_avatar", "avatar_wizard")), "Doi sang avatar da so huu")
	_entry(str(manager.get("avatar_id")) == "avatar_wizard", "avatar_id cap nhat")
	_entry(not bool(manager.call("equip_avatar", "avatar_fox")), "Chan do avatar chua mua")
	_entry(not bool(manager.call("equip_avatar", "khong_ton_tai")), "Chan avatar la")
	_entry(bool(manager.call("equip_frame", "frame_laurel")), "Doi sang vien khung da so huu")

	var before := str(manager.call("display_name_text"))
	_entry(not before.is_empty(), "Co ten hien thi mac dinh ('%s')" % before)
	_entry(bool(manager.call("set_display_name", "Nguoi Choi 01")), "Dat ten moi")
	_entry(str(manager.call("display_name_text")) == "Nguoi Choi 01", "Ten hien thi cap nhat")
	_entry(bool(manager.call("set_display_name", "0123456789ABCDEFGHIJ")), "Ten dai -> cat bot")
	_entry(str(manager.call("display_name_text")).length() == 16, "Ten bi gioi han 16 ky tu")
	manager.call("set_display_name", "Nguoi Choi 01")


# ---------------------------------------------------------------------------
# 3. Thống kê / EXP
# ---------------------------------------------------------------------------
func _section_3_stats(manager: Node) -> void:
	print("\n--- 3. THONG KE + EXP ---")
	var ach: Node = root.get_node_or_null("ArchivementManager")
	var stats: Dictionary = manager.call("stats")
	var points := int(ach.call("points"))
	var stars := int(ach.call("stat_value", "level_stars_total"))
	_entry(int(stats.get("exp", -1)) == points + stars * EXP_PER_STAR,
		"EXP = AP(%d) + Sao(%d)x%d = %d (dang %d)"
		% [points, stars, EXP_PER_STAR, points + stars * EXP_PER_STAR, int(stats.get("exp", -1))])
	_entry(int(manager.call("level")) == 1 + int(stats.get("exp", 0)) / EXP_PER_LEVEL,
		"Cap = 1 + EXP/%d (dang %d)" % [EXP_PER_LEVEL, int(manager.call("level"))])
	_entry(int(stats.get("exp_step", 0)) == EXP_PER_LEVEL, "Moc EXP moi cap = %d" % EXP_PER_LEVEL)
	_entry(int(stats.get("stars_max", 0)) > 0, "Tong sao toi da > 0 (dang %d)" % int(stats.get("stars_max", 0)))
	_entry(not str(stats.get("title_key", "")).is_empty(), "Co khoa danh hieu theo cap")
	_entry(str(stats.get("title_key", "")).begins_with("STR_PROFILE_TIER_"),
		"Danh hieu dung ho khoa STR_PROFILE_TIER_")


# ---------------------------------------------------------------------------
# 4. Lịch sử ván
# ---------------------------------------------------------------------------
func _section_4_recent(manager: Node) -> void:
	print("\n--- 4. LICH SU VAN ---")
	manager.call("reset_progress")
	var plays_before := int(manager.get("runs_played"))
	manager.call("record_run", {
		"won": true, "mode_id": "play", "floor": 7, "elapsed": 33.5,
		"moves": 12, "wall_hits": 0, "width": 7, "height": 7, "stars": 3,
	})
	var rows: Array = manager.call("recent_activity", 1)
	_entry(rows.size() == 1, "record_run ghi 1 dong lich su")
	var row: Dictionary = rows[0] if not rows.is_empty() else {}
	_entry(int(row.get("floor", 0)) == 7 and bool(row.get("won", false)),
		"Dong lich su luu dung tang/ket qua")
	_entry(int(manager.get("runs_played")) == plays_before + 1, "runs_played tang 1")
	_entry(int(manager.get("runs_won")) == 1, "runs_won tang 1 khi thang")

	manager.call("record_run", {"won": false, "mode_id": "dungeon", "endless": true, "floor": 12, "score": 480})
	_entry(int(manager.call("recent_activity", 1)[0].get("floor", 0)) == 12, "Dong moi nhat dung dau")
	_entry(absf(float(manager.call("win_rate")) - 50.0) < 0.01, "Ti le thang = 50.0%")

	for i in MAX_RECENT + 3:
		manager.call("record_run", {"won": true, "mode_id": "play", "floor": i + 1})
	_entry(int(manager.get("recent").size()) == MAX_RECENT,
		"Lich su gioi han %d dong (dang %d)" % [MAX_RECENT, int(manager.get("recent").size())])


# ---------------------------------------------------------------------------
# 5. Scene Profiler
# ---------------------------------------------------------------------------
func _section_5_scene(manager: Node) -> void:
	print("\n--- 5. SCENE HO SO (2 HUONG) ---")
	manager.call("record_run", {
		"won": true, "mode_id": "play", "floor": 24, "elapsed": 38.0,
		"moves": 22, "width": 7, "height": 7, "stars": 3,
	})
	manager.call("record_run", {"won": true, "mode_id": "dungeon", "endless": true, "floor": 48, "score": 480})
	manager.call("record_run", {"won": true, "mode_id": "wall_builder", "daily": true, "floor": 30})

	var scene: ProfilerScene = (load("res://scenes/profiler.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_entry(scene.layout != null, "Scene gan ProfilerLayout")
	if scene.layout == null:
		scene.queue_free()
		await process_frame
		return

	var chip := scene.layout.chip_text()
	_entry(chip != null and not chip.text.is_empty(), "Chip cap do co chu ('%s')" % (chip.text if chip != null else ""))
	_entry(chip != null and chip.text.contains(str(manager.call("level"))), "Chip cap do khop manager")

	var hero_avatar := scene.layout.hero_avatar as TextureRect
	var hero_frame := scene.layout.hero_frame as TextureRect
	_entry(hero_avatar != null and hero_avatar.texture != null, "The hero hien avatar")
	_entry(hero_frame != null and hero_frame.texture != null, "The hero hien vien khung")
	var name_label := scene.layout.hero_node("Name") as Label
	_entry(name_label != null and name_label.text == str(manager.call("display_name_text")),
		"The hero hien dung ten hien thi")
	var uid_label := scene.layout.hero_node("Uid") as Label
	_entry(uid_label != null and uid_label.text.contains("IM-"), "Co dong UID (#IM-xxxx)")

	var values_ok := true
	for index in 4:
		var card := scene.layout.stat_card(index)
		var value := card.get_node_or_null("Value") as Label if card != null else null
		if value == null or value.text.strip_edges().is_empty():
			values_ok = false
	_entry(values_ok, "4 the thong ke deu co so lieu")

	var gear_ok := true
	for index in 3:
		var card := scene.layout.gear_card(index)
		var gear_name := card.get_node_or_null("Name") as Label if card != null else null
		var icon := card.get_node_or_null("Icon") as TextureRect if card != null else null
		if gear_name == null or gear_name.text.strip_edges().is_empty() or icon == null or icon.texture == null:
			gear_ok = false
	_entry(gear_ok, "3 the trang bi deu co ten + icon")

	var ap_text := scene.layout.ap_text()
	_entry(ap_text != null and ap_text.text.contains("AP"), "Gia huy hieu co chip AP ('%s')"
		% (ap_text.text if ap_text != null else ""))
	_entry(scene.activity_row_count() == 3, "Hien 3 hang hoat dong (dang %d)" % scene.activity_row_count())
	var row_node := scene.layout.rows_box.get_child(scene.layout.rows_box.get_child_count() - 1)
	_entry(row_node is ProfilerActivityRow, "Hang hoat dong dung scene nodes/profiler/activity_row.tscn")
	if row_node is ProfilerActivityRow:
		var title := row_node.get_node_or_null("Title") as Label
		_entry(title != null and not title.text.is_empty(), "Hang hoat dong co tieu de ('%s')"
			% (title.text if title != null else ""))

	# Nút mở popup đổi diện mạo (bấm nút trong scene)
	scene.layout.btn_edit.pressed.emit()
	await process_frame
	await process_frame
	var popup := Popups.get_popup(Popups.EDIT_PROFILE) as EditProfilePopup
	_entry(popup is EditProfilePopup, "Bấm ĐỔI AVATAR & TÊN -> mở popup DIỆN MẠO HỒ SƠ")
	if popup is EditProfilePopup:
		popup.close()
		await process_frame

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 6. Popup
# ---------------------------------------------------------------------------
func _section_6_popup(manager: Node) -> void:
	print("\n--- 6. POPUP DIEN MAO HO SO ---")
	var popup := Popups.open(Popups.EDIT_PROFILE) as EditProfilePopup
	await process_frame
	await process_frame
	_entry(popup != null, "Mo duoc popup edit_profile")
	if popup == null:
		return
	_entry(popup.tab() == "avatar", "Mac dinh mo tab AVATAR")
	_entry(popup.item_count() == AVATAR_COUNT, "Luoi co %d avatar" % AVATAR_COUNT)

	var preview_avatar := popup.get_node_or_null("Panel/Content/Preview/Avatar") as TextureRect
	_entry(preview_avatar != null and preview_avatar.texture != null, "The xem truoc co avatar")
	var name_edit := popup.get_node_or_null("Panel/Content/Preview/NameEdit") as LineEdit
	_entry(name_edit != null and name_edit.max_length == 16, "O ten gioi han 16 ky tu")

	popup.set_tab("frame")
	await process_frame
	_entry(popup.item_count() == FRAME_COUNT, "Tab VIEN KHUNG co %d mon" % FRAME_COUNT)
	popup.select_pending("frame_laurel")
	await process_frame
	var preview_frame := popup.get_node_or_null("Panel/Content/Preview/Frame") as TextureRect
	_entry(preview_frame != null and preview_frame.texture != null, "The xem truoc co vien khung")

	# Bấm SAVE -> đổi viền đang dùng trong hồ sơ
	var save_button := popup.get_node_or_null("Panel/Content/BtnSave") as Button
	_entry(save_button != null, "Popup co nut LUU THAY DOI")
	if save_button != null:
		save_button.pressed.emit()
		await process_frame
		await process_frame
	_entry(str(manager.get("frame_id")) == "frame_laurel", "Luu -> vien khung doi thanh frame_laurel")

	popup = Popups.open(Popups.EDIT_PROFILE) as EditProfilePopup
	await process_frame
	_entry(popup != null, "Mo lai popup de kiem tra HUY BO")
	if popup != null:
		var cancel := popup.get_node_or_null("Panel/Content/BtnCancel") as Button
		popup.set_tab("frame")
		popup.select_pending("frame_ink")
		if cancel != null:
			cancel.pressed.emit()
			await process_frame
			await process_frame
		_entry(str(manager.get("frame_id")) == "frame_laurel", "HUY BO khong doi vien khung")


# ---------------------------------------------------------------------------
# 7. Lưu trữ
# ---------------------------------------------------------------------------
func _section_7_save(manager: Node, saved: Dictionary) -> void:
	print("\n--- 7. LUU TRU (SaveManager) ---")
	var save_manager: Node = root.get_node_or_null("SaveManager")
	var registered := false
	if save_manager != null and save_manager.has_method("providers"):
		for provider in save_manager.call("providers"):
			if provider == manager:
				registered = true
	_entry(registered, "SaveManager da dang ky PlayerProfileManager (autosave)")

	manager.call("set_display_name", "Ho So Test")
	manager.call("equip_avatar", "avatar_wizard")
	var snapshot: Dictionary = manager.call("export_progress")
	_entry(str(snapshot.get("display_name", "")) == "Ho So Test", "Blob luu co ten hien thi")
	_entry(snapshot.get("recent") is Array, "Blob luu co lich su van")

	manager.call("reset_progress")
	manager.call("import_progress", snapshot)
	_entry(str(manager.call("display_name_text")) == "Ho So Test", "import khoi phuc ten")
	_entry(str(manager.get("avatar_id")) == "avatar_wizard", "import khoi phuc avatar dang dung")
	_entry(str(manager.get("uid_suffix")).length() == 4, "import khoi phuc UID 4 so")

	manager.call("import_progress", saved)


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
	print("[%s] %s" % ["CHECK" if condition else "FAIL", label])
