extends SceneTree
## ============================================================================
## Test Case: LƯỢT CHƠI (LIFE) — §5.11
##
## 1. GameManager: tối đa 5 lượt, thua chốt ván trừ 1 lượt (mỗi ván chỉ 1 lần).
## 2. Hồi lượt: 30 phút/lượt, bắt kịp thời gian offline, đầy lượt thì dừng đếm.
## 3. Cộng lượt: chỉ từ nguồn hợp lệ (purchase/mission/daily_milestone), đầy thì không cộng.
## 4. Lưu/đọc: `lives` + `next_life_at` nằm trong blob tiến trình.
## 5. Chặn vào ván khi hết lượt: KHÔNG đổi scene, mở popup HẾT LƯỢT CHƠI.
## 6. Popup: đủ node binding + nút THOÁT RA / CỬA HÀNG; CỬA HÀNG nhớ màn để Back quay lại.
## 7. LifeChip: nhãn "còn/tối đa", nút `+` chỉ hiện khi CHƯA đầy.
## 8. Shop: có gói LƯỢT CHƠI, mua được khi thiếu lượt, đầy lượt thì không mua được.
## 9. Mọi layout có CoinChip đều có đúng 1 LifeChip (Settings/Tutorial/Splash/Profiler: 0).
## ============================================================================

const LIFE_POPUP_SCENE := "res://nodes/popups/out_of_life.tscn"
const LAYOUT_CHIP_EXCLUDED := ["settings", "tutorial", "splash", "title", "profiler_popup"]
## Ngoại lệ: màn có "thanh trên" KHÔNG phải dải ngang nên 2 chip dùng chung của base_layout không
## hiển thị được — màn tự khai 2 chip cục bộ đặt đúng chỗ và ẩn 2 chip dùng chung (`visible = false`).
## (`landscape/event`: thanh trên là CỘT DỌC 36 px bên trái, tiêu đề nằm trong hàng tiêu đề của nội dung)
const LAYOUT_LOCAL_CHIPS := {"landscape/event": 2}

var _backup := ""
var _checks := 0
var _failed := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: LUOT CHOI (LIFE) + POPUP HET LUOT + CHIP HEADER")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	if FileAccess.file_exists("user://inkmaze_data.json"):
		var rf := FileAccess.open("user://inkmaze_data.json", FileAccess.READ)
		_backup = rf.get_as_text()

	var gm: Node = root.get_node_or_null("GameManager")
	_check(gm != null, "Autoload GameManager ton tai")
	if gm == null:
		_finish()
		return

	_check(int(gm.call("max_lives")) == 5, "Toi da 5 luot choi")
	_check(int(gm.get("LIFE_RECHARGE_SECONDS")) == 30 * 60, "Moi 30 phut hoi 1 luot")

	gm.set("life_cost_in_tests", true)
	gm.set("life_gate_override", 0)
	gm.call("debug_set_lives", 5)

	_section_consume(gm)
	_section_recharge(gm)
	_section_grant(gm)
	_section_save(gm)
	await _section_gate(gm)
	await _section_popup()
	await _section_chip()
	await _section_shop(gm)
	await _section_layouts()

	# Trả lại trạng thái ban đầu
	gm.set("life_cost_in_tests", false)
	gm.set("life_gate_override", 0)
	gm.call("debug_set_lives", 5)
	gm.set("next_life_at", 0)
	_finish()


func _finish() -> void:
	if not _backup.is_empty():
		var wf := FileAccess.open("user://inkmaze_data.json", FileAccess.WRITE)
		wf.store_string(_backup)
		wf.flush()
	print("\n--------------------------------------------------------")
	print("  KET QUA: %d/%d CHECK PASS" % [_checks - _failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Trừ lượt khi thua
# ---------------------------------------------------------------------------
func _section_consume(gm: Node) -> void:
	print("[1] Tru luot khi thua...")
	gm.call("debug_set_lives", 5)
	_check(bool(gm.call("has_life")), "Day luot => con luot")
	_check(int(gm.call("consume_life")), "Tru 1 luot thanh cong")
	_check(int(gm.call("lives_left")) == 4, "Con 4 luot (nhan %d)" % int(gm.call("lives_left")))
	_check(int(gm.call("seconds_to_next_life")) > 29 * 60, "Bat dau dem nguoc hoi luot")

	# Mỗi ván chỉ trừ 1 lần: gọi lần 2 không trừ nữa
	gm.set("_loss_charged", false)
	_check(int(gm.call("register_run_loss")), "register_run_loss tru 1 luot")
	_check(not int(gm.call("register_run_loss")), "Goi lai KHONG tru them (moi van 1 lan)")
	_check(int(gm.call("lives_left")) == 3, "Con 3 luot (nhan %d)" % int(gm.call("lives_left")))

	gm.call("begin_run_guard")
	_check(int(gm.call("register_run_loss")), "Van moi => lai duoc tru luot")
	_check(int(gm.call("lives_left")) == 2, "Con 2 luot (nhan %d)" % int(gm.call("lives_left")))

	# Ván debug không trừ
	gm.set("debug_run", true)
	gm.call("begin_run_guard")
	_check(not int(gm.call("register_run_loss")), "Van DEBUG khong tru luot")
	gm.set("debug_run", false)


# ---------------------------------------------------------------------------
# 2. Hồi lượt theo thời gian
# ---------------------------------------------------------------------------
func _section_recharge(gm: Node) -> void:
	print("[2] Hoi luot theo thoi gian...")
	gm.call("debug_set_lives", 2)
	var now := int(Time.get_unix_time_from_system())
	gm.set("next_life_at", now - 1)
	gm.call("_refresh_life_recharge")
	_check(int(gm.call("lives_left")) == 3, "Qua han => +1 luot (nhan %d)" % int(gm.call("lives_left")))

	# Offline 3 chu ky => +3 luot (nhung khong vuot toi da)
	gm.call("debug_set_lives", 1)
	gm.set("next_life_at", now - 30 * 60 * 2 + 5)
	gm.call("_refresh_life_recharge")
	_check(int(gm.call("lives_left")) == 3, "Offline 2 chu ky => +2 luot (nhan %d)" % int(gm.call("lives_left")))

	gm.set("next_life_at", now - 30 * 60 * 9)
	gm.call("_refresh_life_recharge")
	_check(int(gm.call("lives_left")) == 5, "Khong hoi vuot toi da (nhan %d)" % int(gm.call("lives_left")))
	_check(int(gm.call("seconds_to_next_life")) == 0, "Day luot => khong dem nguoc")

	# Hết lượt ⇒ luôn có hẹn hồi
	gm.call("debug_set_lives", 0)
	_check(int(gm.call("seconds_to_next_life")) > 0, "Het luot => co hen hoi luot")
	_check(not gm.call("consume_life"), "Het luot => khong tru duoc nua")


# ---------------------------------------------------------------------------
# 3. Cộng lượt từ nguồn hợp lệ
# ---------------------------------------------------------------------------
func _section_grant(gm: Node) -> void:
	print("[3] Cong luot tu nguon hop le...")
	gm.call("debug_set_lives", 2)
	_check(not bool(gm.call("grant_lives", 1, "debug")), "Nguon 'debug' KHONG duoc cong")
	_check(int(gm.call("lives_left")) == 2, "Khong doi so luot khi nguon sai")
	_check(bool(gm.call("grant_lives", 1, "purchase")), "Nguon 'purchase' duoc cong")
	_check(int(gm.call("lives_left")) == 3, "Con 3 luot")
	_check(bool(gm.call("grant_lives", 1, "mission")), "Nguon 'mission' duoc cong")
	_check(bool(gm.call("grant_lives", 5, "purchase")), "Cong nhieu luot van duoc")
	gm.call("debug_set_lives", 5)
	_check(not bool(gm.call("grant_lives", 1, "purchase")), "Day luot => khong cong them")


# ---------------------------------------------------------------------------
# 4. Lưu / đọc
# ---------------------------------------------------------------------------
func _section_save(gm: Node) -> void:
	print("[4] Luu / doc luot choi...")
	gm.call("debug_set_lives", 3)
	var blob: Dictionary = gm.call("export_progress")
	_check(blob.has("lives") and blob.has("next_life_at"), "Blob co 'lives' + 'next_life_at'")
	gm.call("debug_set_lives", 5)
	gm.call("import_progress", blob)
	_check(int(gm.call("lives_left")) == 3, "Import tra lai dung so luot (nhan %d)"
		% int(gm.call("lives_left")))


# ---------------------------------------------------------------------------
# 5. Chặn vào ván khi hết lượt
# ---------------------------------------------------------------------------
func _section_gate(gm: Node) -> void:
	print("[5] Chan vao van khi het luot...")
	var before := str(current_scene.scene_file_path) if current_scene != null else ""
	gm.call("debug_set_lives", 0)
	gm.set("life_gate_override", -1)
	_check(not bool(gm.call("can_start_run")), "Het luot => can_start_run() = false")
	gm.call("start_level", 1)
	await process_frame
	await process_frame
	var after := str(current_scene.scene_file_path) if current_scene != null else ""
	_check(before == after, "Khong chuyen sang man choi khi het luot")
	_check(Popups.is_open(Popups.OUT_OF_LIFE), "Mo popup HET LUOT CHOI")
	Popups.close_all()
	await process_frame

	gm.call("debug_set_lives", 1)
	gm.set("life_gate_override", 0)
	_check(bool(gm.call("can_start_run")), "Con luot => can_start_run() = true")


# ---------------------------------------------------------------------------
# 6. Popup HẾT LƯỢT CHƠI
# ---------------------------------------------------------------------------
func _section_popup() -> void:
	print("[6] Popup HET LUOT CHOI...")
	var packed := load(LIFE_POPUP_SCENE) as PackedScene
	_check(packed != null, "Nap duoc out_of_life.tscn")
	if packed == null:
		return
	var popup := packed.instantiate()
	root.add_child(popup)
	_check(popup.get("label_title") != null, "Bind label_title")
	_check(popup.get("label_subtitle") != null, "Bind label_subtitle")
	_check(popup.get("label_recharge") != null, "Bind label_recharge")
	_check(popup.get("btn_exit") != null, "Bind btn_exit")
	_check(popup.get("btn_shop") != null, "Bind btn_shop")
	_check(popup.has_signal("exit_requested"), "Co signal exit_requested")
	_check(popup.has_signal("shop_requested"), "Co signal shop_requested")
	popup.call("open", {"max_lives": 5})
	await process_frame
	var title: Label = popup.get("label_title")
	var subtitle: Label = popup.get("label_subtitle")
	var recharge: Label = popup.get("label_recharge")
	_check(title != null and not title.text.is_empty()
		and title.text != "STR_LIFE_EMPTY_TITLE", "Tieu de da dich ('%s')" % title.text)
	_check(subtitle != null and subtitle.text.contains("5"), "Phu de neu so luot toi da")
	_check(recharge != null and not recharge.text.is_empty()
		and recharge.text != "STR_LIFE_EMPTY_RECHARGE", "Co dong dem nguoc hoi luot ('%s')" % recharge.text)
	popup.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 7. LifeChip
# ---------------------------------------------------------------------------
func _section_chip() -> void:
	print("[7] LifeChip...")
	var chip: LifeChip = (load("res://nodes/main/life_chip.tscn") as PackedScene).instantiate() as LifeChip
	_check(chip != null, "Nap duoc life_chip.tscn")
	if chip == null:
		return
	root.add_child(chip)
	await process_frame
	chip.set_values(3, 5)
	_check(chip.value_label.text == "3/5", "Nhan '3/5' (nhan '%s')" % chip.value_label.text)
	_check(chip.plus_button.visible, "Thieu luot => hien nut '+'")
	chip.set_values(5, 5)
	_check(chip.value_label.text == "5/5", "Nhan '5/5' (nhan '%s')" % chip.value_label.text)
	_check(not chip.plus_button.visible, "Day luot => an nut '+'")
	chip.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 8. Shop bán gói lượt chơi
# ---------------------------------------------------------------------------
func _section_shop(gm: Node) -> void:
	print("[8] Shop ban goi LUOT CHOI...")
	_check(Shop.has_item("life_x1"), "Co mon 'life_x1' trong Cua hang")
	_check(Shop.is_life_pack("life_x1"), "life_x1 la goi luot choi")
	_check(Shop.category_of("life_x1") == "tool", "life_x1 nam trong tab DUNG CU")

	var shop: Node = root.get_node_or_null("ShopManager")
	var wallet: Node = root.get_node_or_null("ArchivementManager")
	var coins_backup := int(wallet.get("coins")) if wallet != null else 0
	gm.call("debug_set_lives", 5)
	_check(not Shop.buy("life_x1"), "Day luot => KHONG mua duoc goi luot")
	gm.call("debug_set_lives", 4)
	if wallet != null:
		wallet.set("coins", 1000)
		wallet.call("notify_coins_changed")
	var coins_before := Shop.coins()
	_check(Shop.buy("life_x1"), "Thieu luot + du Xu => mua duoc")
	_check(int(gm.call("lives_left")) == 5, "Mua xong duoc +1 luot (nhan %d)" % int(gm.call("lives_left")))
	_check(Shop.coins() == coins_before - Shop.price_of("life_x1"), "Tru dung gia bang Xu")
	_check(shop != null and shop.has_method("is_life_pack"), "ShopManager co is_life_pack")
	if wallet != null:
		wallet.set("coins", coins_backup)
		wallet.call("notify_coins_changed")

	# Back của Shop quay về ĐÚNG màn trước đó khi vào từ popup hết lượt
	gm.set("shop_return_path", "res://scenes/levels.tscn")
	var shop_scene := (load("res://scenes/shop.tscn") as PackedScene).instantiate()
	root.add_child(shop_scene)
	await process_frame
	await process_frame
	_check(str(shop_scene.get("_return_path")) == "res://scenes/levels.tscn",
		"Shop doc duoc man can quay ve ('%s')" % str(shop_scene.get("_return_path")))
	_check(str(gm.get("shop_return_path")).is_empty(), "Man quay ve chi dung 1 lan")
	shop_scene.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 9. Chip dùng chung khai trong `base_layout` + ẩn/hiện từng màn khai thẳng trong `.tscn`
# ---------------------------------------------------------------------------
func _section_layouts() -> void:
	print("[9] Chip dung chung trong base_layout + an/hien khai trong tscn...")
	var base_text := FileAccess.get_file_as_string("res://scenes/layout/base_layout.tscn")
	_check(_count_nodes(base_text, "CoinChip") == 1, "base_layout co dung 1 CoinChip")
	_check(_count_nodes(base_text, "LifeChip") == 1, "base_layout co dung 1 LifeChip")
	_check(base_text.contains('parent="TopBar"'), "Hai chip nam trong TopBar cua base_layout")

	for path in ["portrait", "landscape"]:
		var dir := DirAccess.open("res://scenes/layout/%s" % path)
		if dir == null:
			_check(false, "Mo duoc scenes/layout/%s" % path)
			continue
		for file in dir.get_files():
			if not file.ends_with(".tscn"):
				continue
			var scene_path := "res://scenes/layout/%s/%s" % [path, file]
			var text := FileAccess.get_file_as_string(scene_path)
			var base := file.get_basename()
			var key := "%s/%s" % [path, base]
			var local_expected: int = int(LAYOUT_LOCAL_CHIPS.get(key, 0))
			var coin_local := _count_nodes(text, "CoinChip")
			var life_local := _count_nodes(text, "LifeChip")
			if local_expected == 0:
				# Layout KHÔNG khai lại 2 chip: chỉ kế thừa từ base_layout
				_check(coin_local == 0 and life_local == 0,
					"%s: khong khai lai chip (dung chip cua base_layout)" % file)
			else:
				# Ngoại lệ: màn có thanh trên KHÔNG phải dải ngang (xem LAYOUT_LOCAL_CHIPS)
				_check(coin_local == 1 and life_local == 1,
					"%s: khai 2 chip cuc bo dung cho thanh tren dac biet" % file)
			var hides := _hides_shared_chips(text)
			var should_hide := LAYOUT_CHIP_EXCLUDED.has(base) or local_expected > 0
			_check(hides == should_hide, "%s: an 2 chip dung chung = %s (muon %s)"
				% [file, hides, should_hide])

	# Xác nhận RUNTIME: `.tscn` khai `visible = false` thì 2 chip thật sự ẩn, màn có ví thì vẫn hiện
	await _check_shared_chip_visibility("res://scenes/layout/portrait/title.tscn", false)
	await _check_shared_chip_visibility("res://scenes/layout/portrait/chapters.tscn", true)


## Nạp thẳng 1 layout và kiểm tra 2 chip dùng chung hiện/ẩn đúng như khai trong `.tscn`.
func _check_shared_chip_visibility(scene_path: String, expect_visible: bool) -> void:
	var scene := (load(scene_path) as PackedScene).instantiate()
	root.add_child(scene)
	await process_frame
	var coin := scene.get_node_or_null("TopBar/CoinChip") as Control
	var life := scene.get_node_or_null("TopBar/LifeChip") as Control
	_check(coin != null and life != null, "%s: co 2 chip dung chung" % scene_path)
	_check(coin != null and coin.visible == expect_visible,
		"%s: CoinChip visible = %s" % [scene_path, expect_visible])
	_check(life != null and life.visible == expect_visible,
		"%s: LifeChip visible = %s" % [scene_path, expect_visible])
	scene.queue_free()
	await process_frame


## Layout có ẩn 2 chip dùng chung (khai trong `base_layout`) bằng override `visible = false`
## trong `.tscn` không? — việc hiện/ẩn CHỈ được khai trong tscn, không bằng code.
func _hides_shared_chips(text: String) -> bool:
	var hidden := 0
	for chip_name in ["CoinChip", "LifeChip"]:
		var start := text.find('[node name="%s" parent="TopBar"]' % chip_name)
		if start < 0:
			continue
		var chunk := text.substr(start)
		var end := chunk.find("\n[", 1)
		if end >= 0:
			chunk = chunk.substr(0, end)
		if chunk.contains("visible = false"):
			hidden += 1
	return hidden == 2


## Đếm node ĐƯỢC KHAI MỚI trong file (bỏ qua dòng override thuộc tính của node kế thừa,
## vốn không có `instance=`).
func _count_nodes(text: String, node_name: String) -> int:
	var count := 0
	for line in text.split("\n"):
		if line.begins_with('[node name="%s"' % node_name) and line.contains("instance="):
			count += 1
	return count


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % message)
	else:
		_failed += 1
		print("  [FAIL] %s" % message)
