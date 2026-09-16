extends SceneTree
## ============================================================================
## Test Case: SỔ TAY THÀNH TỰU (Danh hiệu) — tính năng 2026-02
##
## 1. Catalog: quét resources/archivements/*.tres -> id duy nhất, đủ 4 nhóm,
##    dữ liệu hợp lệ (tiêu đề/mục tiêu/icon), có danh hiệu ẨN.
## 2. Tiến độ: đủ ngưỡng -> claimable; claim() cộng xu + đánh dấu; claim lần 2 bị chặn.
## 3. Điểm AP = tổng điểm danh hiệu ĐÃ ĐẠT; % đã mở khoá đúng công thức.
## 4. Lưu trữ: export -> reset -> import khôi phục đúng xu/trạng thái/số liệu.
## 5. Scene: 5 thẻ/trang + paging theo tab + dots + bấm NHẬN trên thẻ.
## ============================================================================

const CARD_PAGE_TITLE := "SỔ TAY THÀNH TỰU"
const CARDS_PER_PAGE := 5

var _backup := ""
var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: %s" % CARD_PAGE_TITLE)
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	# Sao lưu dữ liệu thật (test không được phá tiến trình người chơi)
	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var manager: Node = root.get_node_or_null("ArchivementManager")
	assert(manager != null, "Autoload ArchivementManager phai ton tai")
	assert(manager.has_method("claim"), "ArchivementManager phai co claim()")

	var saved: Dictionary = manager.call("export_progress")

	_section_1_catalog(manager)
	_section_2_progress_and_claim(manager)
	_section_3_points(manager)
	_section_4_save_roundtrip(manager)
	await _section_5_scene(manager)

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
	print("--- 1. CATALOG DANH HIEU (.tres) ---")
	var total := int(manager.call("total_count"))
	_entry(total >= 20, "Catalog co it nhat 20 danh hieu (dang %d)" % total)

	var entries: Array[Dictionary] = manager.call("entries", "")
	_entry(entries.size() == total, "entries('') tra ve du %d danh hieu" % total)

	var categories: Array = manager.get("CATEGORIES")
	for category in categories:
		var count := int(manager.call("count_in_category", str(category)))
		_entry(count > 0, "Nhom '%s' co danh hieu (dang %d)" % [category, count])

	var seen := {}
	var secrets := 0
	var broken := 0
	for entry in entries:
		var id := str(entry.get("id", ""))
		if seen.has(id):
			broken += 1
			_entry(false, "id '%s' bi trung" % id)
		seen[id] = true
		if int(entry.get("target", 0)) <= 0 or str(entry.get("title", "")).is_empty() \
				or str(entry.get("desc", "")).is_empty() or entry.get("icon", null) == null:
			broken += 1
			print("[FAIL] Danh hieu '%s' thieu du lieu (target/title/desc/icon)" % id)
		if bool(entry.get("secret_hidden", false)):
			secrets += 1
	_entry(broken == 0, "Moi danh hieu co id duy nhat + target/title/desc/icon (loi: %d)" % broken)
	_entry(secrets >= 2, "Co it nhat 2 danh hieu AN khi chua dat (dang %d)" % secrets)

	var sample: Dictionary = manager.call("entry_for", "dn_floor_5")
	_entry(not sample.is_empty(), "entry_for('dn_floor_5') tra ve du lieu")
	if not sample.is_empty():
		print("[INFO] Vi du: %s | %s | tien do %d/%d"
			% [sample.get("id", ""), sample.get("title", ""),
			int(sample.get("progress", 0)), int(sample.get("target", 0))])


# ---------------------------------------------------------------------------
# 2. Tiến độ + nhận thưởng
# ---------------------------------------------------------------------------
func _section_2_progress_and_claim(manager: Node) -> void:
	print("\n--- 2. TIEN DO + NHAN THUONG ---")
	manager.call("reset_progress")
	_entry(int(manager.get("coins")) == 0, "reset_progress() dua xu ve 0")
	_entry(int(manager.call("claimed_count")) == 0, "reset_progress() xoa trang thai da nhan")

	# Chưa đủ ngưỡng -> chỉ hiện tiến độ, chưa cho nhận
	manager.call("set_stat_for_test", "dungeon_best_floor", 2)
	_entry(int(manager.call("progress_of", "dn_floor_5")) == 2,
		"progress_of('dn_floor_5') = 2 khi moi toi tang 2")
	_entry(not bool(manager.call("is_unlocked", "dn_floor_5")), "Chua du nguong -> chua mo khoa")
	_entry(not bool(manager.call("claim", "dn_floor_5")), "claim() khi chua du dieu kien = false")

	# Đủ ngưỡng -> mở khoá + chờ nhận
	manager.call("set_stat_for_test", "dungeon_best_floor", 5)
	_entry(bool(manager.call("is_unlocked", "dn_floor_5")), "Toi tang 5 -> mo khoa 'dn_floor_5'")
	_entry(bool(manager.call("is_claimable", "dn_floor_5")), "Da dat -> cho nhan thuong")
	_entry(int(manager.call("claimable_count")) >= 1, "claimable_count() >= 1")

	var entry: Dictionary = manager.call("entry_for", "dn_floor_5")
	var reward := int(entry.get("coins", 0))
	var coins_before := int(manager.get("coins"))
	_entry(bool(manager.call("claim", "dn_floor_5")), "claim() lan dau = true")
	_entry(int(manager.get("coins")) == coins_before + reward,
		"Nhan thuong cong %d xu (dang %d)" % [reward, int(manager.get("coins"))])
	_entry(bool(manager.call("is_claimed", "dn_floor_5")), "Danh dau da nhan")
	_entry(int(manager.call("claimed_count")) == 1, "claimed_count() = 1")
	_entry(not bool(manager.call("claim", "dn_floor_5")), "claim() lan 2 bi chan")
	_entry(int(manager.get("coins")) == coins_before + reward, "Khong cong xu lan thu 2")

	# Danh hiệu ẩn: thoả điều kiện mới hiện tên thật
	manager.call("set_stat_for_test", "dungeon_floors_total", 50)
	var secret: Dictionary = manager.call("entry_for", "sp_secret_dungeon_50")
	_entry(not bool(secret.get("secret_hidden", true)), "Danh hieu an hien ten khi da dat")
	_entry(not str(secret.get("title", "")).is_empty(), "Danh hieu an co tieu de that")
	_entry(str(secret.get("desc", "")).contains("50"), "Danh hieu an hien mo ta dieu kien")
	_entry(int(secret.get("coins", 0)) >= 250,
		"Danh hieu an co thuong lon (%d xu)" % int(secret.get("coins", 0)))


# ---------------------------------------------------------------------------
# 3. Điểm AP + % mở khoá
# ---------------------------------------------------------------------------
func _section_3_points(manager: Node) -> void:
	print("\n--- 3. DIEM DANH HIEU (AP) + %% MO KHOA ---")
	var entries: Array[Dictionary] = manager.call("entries", "")
	var manual := 0
	var unlocked := 0
	for entry in entries:
		if bool(entry.get("unlocked", false)):
			manual += int(entry.get("points", 0))
			unlocked += 1
	_entry(int(manager.call("points")) == manual, "AP = tong diem danh hieu da dat (%d)" % manual)
	_entry(int(manager.call("unlocked_count")) == unlocked, "unlocked_count() = %d" % unlocked)

	var total := int(manager.call("total_count"))
	var expect_percent := int(round(100.0 * float(unlocked) / float(maxi(total, 1))))
	_entry(int(manager.call("unlocked_percent")) == expect_percent,
		"unlocked_percent() = %d%%" % expect_percent)
	print("[INFO] Da mo %d/%d danh hieu (%d%%), %d AP, %d xu"
		% [unlocked, total, expect_percent, int(manager.call("points")), int(manager.get("coins"))])


# ---------------------------------------------------------------------------
# 4. Lưu trữ
# ---------------------------------------------------------------------------
func _section_4_save_roundtrip(manager: Node) -> void:
	print("\n--- 4. LUU TRU (export/import) ---")
	var snapshot: Dictionary = manager.call("export_progress")
	var coins := int(manager.get("coins"))
	var claimed := int(manager.call("claimed_count"))

	manager.call("reset_progress")
	_entry(int(manager.get("coins")) == 0 and int(manager.call("claimed_count")) == 0,
		"reset_progress() xoa xu + trang thai da nhan")

	manager.call("import_progress", snapshot)
	_entry(int(manager.get("coins")) == coins, "import khoi phuc %d xu" % coins)
	_entry(int(manager.call("claimed_count")) == claimed,
		"import khoi phuc %d danh hieu da nhan" % claimed)
	_entry(bool(manager.call("is_claimed", "dn_floor_5")), "Trang thai 'da nhan' duoc giu")
	_entry(int(manager.call("stat_value", "dungeon_floors_total")) == 50,
		"import khoi phuc so lieu tich luy (tong 50 tang)")
	_entry(str(snapshot.get("claimed", [])).contains("dn_floor_5"),
		"Blob luu co danh sach id da nhan")


# ---------------------------------------------------------------------------
# 5. Scene Sổ tay (paging + tabs + nút NHẬN)
# ---------------------------------------------------------------------------
func _section_5_scene(manager: Node) -> void:
	print("\n--- 5. SCENE SO TAY THANH TUU ---")
	var total := int(manager.call("total_count"))
	var scene: ArchivementScene = (load("res://scenes/archivement.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	_entry(scene.entry_count() == total, "Tab TAT CA hien thi du %d danh hieu" % total)
	var pages := scene.page_count()
	var expect_pages := int(ceil(float(total) / float(CARDS_PER_PAGE)))
	_entry(pages == expect_pages, "So trang = ceil(%d/%d) = %d (dang %d)"
		% [total, CARDS_PER_PAGE, expect_pages, pages])

	var sum := 0
	var full_pages := 0
	for index in pages:
		var count := scene.cards_on_page(index)
		sum += count
		if count == CARDS_PER_PAGE:
			full_pages += 1
	_entry(sum == total, "Tong so the tren cac trang = %d danh hieu" % total)
	_entry(scene.cards_on_page(0) == CARDS_PER_PAGE,
		"Trang dau co dung %d the (mockup)" % CARDS_PER_PAGE)
	_entry(full_pages >= pages - 1, "Cac trang deu day the (tru trang cuoi)")

	var dots := scene.get_node_or_null("Sheet/Dots")
	_entry(dots != null, "Co cum dots phan trang")
	if dots != null:
		_entry(dots.get_child_count() == pages, "So dots = so trang (%d)" % pages)
		_entry(dots.visible == (pages > 1), "Dots chi hien khi co > 1 trang")

	# Điều hướng trang
	scene.go_to_page(1, false)
	_entry(scene.current_page() == 1, "go_to_page(1) -> current_page() = 1")
	scene.go_to_page(0, false)
	_entry(scene.current_page() == 0, "go_to_page(0) -> current_page() = 0")

	# Tab lọc theo nhóm
	var dungeon_count := int(manager.call("count_in_category", "dungeon"))
	scene.set_category("dungeon", false)
	_entry(scene.current_category() == "dungeon", "set_category('dungeon')")
	_entry(scene.entry_count() == dungeon_count,
		"Tab DUNGEON co %d danh hieu" % dungeon_count)
	_entry(scene.page_count() == int(ceil(float(dungeon_count) / float(CARDS_PER_PAGE))),
		"So trang cua tab DUNGEON dung theo so luong")
	var tab_label := scene.get_node_or_null("Sheet/Tabs/Tab2/Label") as Label
	_entry(tab_label != null and not tab_label.text.is_empty(),
		"Tab thu 3 (DUNGEON) co nhan chu")

	scene.set_category("", false)
	_entry(scene.entry_count() == total, "Quay lai tab TAT CA")

	var summary := scene.overview_text()
	_entry(summary.contains("/") and summary.contains("AP"),
		"The tong ket hien thi tien do + AP ('%s')" % summary)

	# Bấm NHẬN trên ĐÚNG thẻ 'dn_floors_25'
	# (không dùng "thẻ claimable đầu tiên" vì dữ liệu save thật có thể có thẻ khác
	#  claimable đứng trước — VD dl_first_day / lv_first_step — làm test bấm nhầm)
	manager.call("set_stat_for_test", "dungeon_floors_total", 25)
	await process_frame
	await process_frame
	var pressed := false
	for page_index in scene.page_count():
		var page: Control = (scene.get("pages_host") as Node).get_child(page_index) as Control
		var column: Control = page.get_child(0) as Control
		for card in column.get_children():
			var raw_entry: Variant = card.get("_entry")
			var card_info: Dictionary = raw_entry if raw_entry is Dictionary else {}
			if str(card_info.get("id", "")) != "dn_floors_25":
				continue
			var button := card.get("claim_btn") as TextureButton
			if button != null and button.visible:
				button.pressed.emit()
				pressed = true
			break
		if pressed:
			break
	_entry(pressed, "Tim thay the dang cho NHAN trong scene")
	if not pressed:
		for page_index in scene.page_count():
			var page: Control = (scene.get("pages_host") as Node).get_child(page_index) as Control
			var column := page.get_child(0) as Control
			print("[INFO] Trang %d | Page=%s | Column=%s | %d con"
				% [page_index, page.name, column.name, column.get_child_count()])
			for card in column.get_children():
				var raw: Variant = card.get("_entry")
				var info: Dictionary = raw if raw is Dictionary else {}
				var button := card.get("claim_btn") as TextureButton
				var script := card.get_script() as Script
				print("[INFO]  - %s | script=%s | id=%s | claimable=%s | nut=%s"
					% [card.name, script.resource_path if script != null else "-",
					str(info.get("id", "?")), str(info.get("claimable", "?")),
					str(button.visible) if button != null else "khong co"])
	await process_frame
	_entry(bool(manager.call("is_claimed", "dn_floors_25")),
		"Bam NHAN tren the -> manager.claim('dn_floors_25')")

	scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failed += 1
	print("[%s] %s" % ["CHECK" if condition else "FAIL", label])
