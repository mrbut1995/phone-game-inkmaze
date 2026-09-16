extends SceneTree
## ============================================================================
## Test: CÁC LỖI ASSET/POPUP ĐÃ SỬA (2026-09)
##
## 1. Icon nút Restart trên HUD (4 trạng thái) — thiết kế mới "icon reset" (2026-09-16):
##    mũi tên góc vuông (M 19 19 v 10 h 10) + cung tròn KHÔNG đè nét mũi tên.
## 2. Popup THẮNG MÀN: con dấu có CHỮ (n / m thử thách + số sao) và nút CHƠI LẠI có icon.
## 3. Popup THÔNG QUA TẦNG: con dấu hết méo (116×116) + có chữ "ĐÃ QUA" / "TẦNG 0n ✔".
## 4. Popup NGÔN NGỮ: hàng nút không tràn ra ngoài + VUỐT DỌC cuộn được danh sách.
## 5. Không còn ART nào của game dùng <text> (ThorVG không render chữ trong SVG).
## ============================================================================

const SCENES := {
	"winning": "res://nodes/popups/winning.tscn",
	"next_floor": "res://nodes/popups/next_floor.tscn",
	"language": "res://nodes/popups/language.tscn",
}
const RESTART_ICON := "M 19 29 A 16 16 0 1 1 35 51"
const RESTART_ARROW := "M 19 19 v 10 h 10"
## Art KHÔNG được chứa <text> (ThorVG bỏ qua chữ) — kiểm tra các file vừa sửa
const NO_TEXT_ART := [
	"res://assets/images/game/btn_restart_normal.svg",
	"res://assets/images/game/btn_restart_pressed.svg",
	"res://assets/images/game/btn_restart_focus.svg",
	"res://assets/images/game/btn_restart_disabled.svg",
	"res://assets/images/popups/stamp_excellent.svg",
	"res://assets/images/popups/stamp_passed.svg",
	"res://assets/images/main/logo_doodle_maze.svg",
]

var _failed := 0
var _checks := 0


func _init() -> void:
	print("\n========================================================")
	print("  TEST: ASSET & POPUP ĐÃ SỬA")
	print("========================================================\n")

	await process_frame
	root.size = Vector2i(1080, 1920)

	_section_1_restart_icon()
	await _section_2_winning()
	await _section_3_next_floor()
	await _section_4_language()
	_section_5_no_text_art()
	_section_6_locale_info()

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Icon nút Restart
# ---------------------------------------------------------------------------
func _section_1_restart_icon() -> void:
	print("[1] Icon nut Restart (4 trang thai)...")
	for state in ["normal", "pressed", "focus", "disabled"]:
		var path := "res://assets/images/game/btn_restart_%s.svg" % state
		var svg := FileAccess.get_file_as_string(path)
		_entry(svg.contains(RESTART_ICON), "btn_restart_%s: cung tron dung thiet ke" % state)
		_entry(svg.contains(RESTART_ARROW), "btn_restart_%s: mui ten goc vuong" % state)
		_entry(not svg.contains("L 18.5 22"),
			"btn_restart_%s: da bo mui ten gay cu (L 18.5 22)" % state)


# ---------------------------------------------------------------------------
# 2. Popup thắng màn
# ---------------------------------------------------------------------------
func _section_2_winning() -> void:
	print("[2] Popup THANG MAN (con dau + nut CHOI LAI)...")
	var popup := await _open(SCENES["winning"], {
		"level": 10, "grid": "5×5", "time": 12.0, "steps_used": 5, "steps_max": 9,
		"wall_hits": 0, "score": 1116, "next_available": true, "stars": 2,
		"challenges": [{"done": true}, {"done": true}, {"done": false}],
	})
	if popup == null:
		return
	var stamp := popup.get_node_or_null("Panel/Content/Stamp") as TextureRect
	_entry(stamp != null, "Co node con dau (Stamp)")
	if stamp != null:
		_entry(stamp.texture != null, "Con dau co art (stamp_excellent.svg)")
		_entry(absf(stamp.size.x - 156.0) < 3.0 and absf(stamp.size.y - 90.0) < 3.0,
			"Con dau dung co 156x90 (nhan %s)" % str(stamp.size))
		var title := stamp.get_node_or_null("StampTitle") as Label
		var sub := stamp.get_node_or_null("StampSub") as Label
		_entry(title != null and title.text.contains("2 / 3"),
			"Con dau co chu '2 / 3 THU THACH' (nhan '%s')" % (title.text if title != null else "?"))
		_entry(sub != null and sub.text.contains("2") and sub.text == tr("STR_WIN_STAMP_SUB").format([2]),
			"Con dau co chu sao dat duoc (nhan '%s')" % (sub.text if sub != null else "?"))
	var replay := popup.get_node_or_null("Panel/Content/ReplayBtn") as TextureButton
	_entry(replay != null, "Co nut CHOI LAI")
	if replay != null:
		var icon: Texture2D = null
		for child in replay.get_children():
			var tex_rect := child as TextureRect
			if tex_rect != null and tex_rect.texture != null:
				icon = tex_rect.texture
				_entry(absf(tex_rect.position.x + tex_rect.size.x * 0.5 - replay.size.x * 0.5) < 8.0,
					"Icon nut CHOI LAI canh giua (nut %.0f, icon tam %.0f)" % [
						replay.size.x, tex_rect.position.x + tex_rect.size.x * 0.5])
				break
		_entry(icon != null and icon.resource_path.ends_with("icon_replay.svg"),
			"Nut CHOI LAI co icon (nhan '%s')" % (icon.resource_path if icon != null else "KHONG CO"))
	popup.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 3. Popup thông qua tầng
# ---------------------------------------------------------------------------
func _section_3_next_floor() -> void:
	print("[3] Popup THONG QUA TANG (con dau)...")
	var popup := await _open(SCENES["next_floor"], {
		"floor": 4, "next_floor": 5, "steps_bonus": 5, "base_score": 1000,
		"move_bonus": 240, "perfect_bonus": 300, "total_score": 1540,
	})
	if popup == null:
		return
	var panel := popup.get_node_or_null("Panel") as Control
	var stamp := popup.get_node_or_null("Panel/Content/Stamp") as TextureRect
	_entry(stamp != null, "Co node con dau (Stamp)")
	if stamp != null:
		_entry(absf(stamp.size.x - 116.0) < 3.0 and absf(stamp.size.y - 116.0) < 3.0,
			"Con dau dung co 116x116, khong con meo (nhan %s)" % str(stamp.size))
		if panel != null:
			_entry(stamp.position.x > 0.0 and stamp.position.x + stamp.size.x < panel.size.x,
				"Con dau nam gon trong phieu (x %.0f..%.0f / rong %.0f)" % [
					stamp.position.x, stamp.position.x + stamp.size.x, panel.size.x])
		var title := stamp.get_node_or_null("StampTitle") as Label
		var sub := stamp.get_node_or_null("StampSub") as Label
		_entry(title != null and title.text == tr("STR_RESULT_STAMP_PASSED"),
			"Con dau co chu 'DA QUA' (nhan '%s')" % (title.text if title != null else "?"))
		_entry(sub != null and sub.text.contains("04"),
			"Con dau co chu 'TANG 04' (nhan '%s')" % (sub.text if sub != null else "?"))
	popup.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 4. Popup ngôn ngữ
# ---------------------------------------------------------------------------
func _section_4_language() -> void:
	print("[4] Popup NGON NGU (khong tran + vuot cuon)...")
	var popup := await _open(SCENES["language"], {})
	if popup == null:
		return
	var content := popup.get_node_or_null("Panel/Content") as VBoxContainer
	var buttons := popup.get_node_or_null("Panel/Content/Buttons") as HBoxContainer
	var scroll := popup.get_node_or_null("Panel/Content/Scroll") as ScrollContainer
	var list := popup.get_node_or_null("Panel/Content/Scroll/List") as VBoxContainer
	_entry(content != null and buttons != null and scroll != null and list != null,
		"Popup ngon ngu du node (Content/Buttons/Scroll/List)")
	if content == null or buttons == null or scroll == null or list == null:
		popup.queue_free()
		return
	var row_count := int(Loc.locales().size())
	_entry(list.get_child_count() == row_count, "Dung du %d hang ngon ngu (nhan %d)" % [
		row_count, list.get_child_count()])
	# Moi hang phai co TEN that (khong phai ma ngon ngu) + CO that (khong phai co generic)
	var bad_rows: Array[String] = []
	for row in list.get_children():
		var name_lbl := row.get_node_or_null("Name") as Label
		var flag := row.get_node_or_null("Flag") as TextureRect
		var row_id := str(row.name).replace("Row_", "")
		var ok_name := name_lbl != null and not name_lbl.text.is_empty() \
			and name_lbl.text != row_id.to_upper()
		var ok_flag := flag != null and flag.texture != null \
			and not flag.texture.resource_path.ends_with("flag_generic.svg")
		if not ok_name or not ok_flag:
			bad_rows.append(row_id)
	_entry(bad_rows.is_empty(), "Moi hang co ten + co rieng (hang thieu: %s)" % str(bad_rows))
	_entry(buttons.get_combined_minimum_size().x <= content.size.x + 1.0,
		"Hang nut KHONG tran ra ngoai (nut %.0f <= khung %.0f)" % [
			buttons.get_combined_minimum_size().x, content.size.x])
	# Art phải khớp 1:1 với nút: TextureButton mặc định stretch_mode = KEEP nên art vẽ ĐÚNG size gốc
	# (từng bị tràn vì nút 390x96 nhưng art `btn_popup_wide` 630x96)
	for btn_name in ["Cancel", "Apply"]:
		var btn := buttons.get_node_or_null(btn_name) as TextureButton
		var art_size := "?"
		var ok_art := false
		if btn != null and btn.texture_normal != null:
			art_size = str(btn.texture_normal.get_size())
			ok_art = btn.texture_normal.get_size() == btn.size
		_entry(ok_art, "Art nut %s khop 1:1 voi nut %s (art %s)" % [
			btn_name, str(btn.size) if btn != null else "?", art_size])
	_entry(scroll.get_v_scroll_bar().max_value > scroll.size.y,
		"Danh sach dai hon khung nhin (%.0f > %.0f)" % [
			scroll.get_v_scroll_bar().max_value, scroll.size.y])
	# Vuốt dọc -> cuộn được (trước đây bấm hàng "ăn" sự kiện kéo nên không cuộn)
	var before_scroll := scroll.scroll_vertical
	popup.call("_begin_drag", Vector2(540, 900))
	popup.call("_update_drag", Vector2(540, 500))
	popup.call("_end_drag")
	await process_frame
	_entry(scroll.scroll_vertical > before_scroll,
		"Vuot doc -> cuon duoc danh sach (scroll %d -> %d)" % [before_scroll, scroll.scroll_vertical])
	# Vừa vuốt thì không được tính là bấm chọn hàng
	var pending_before := str(popup.get("_pending_locale"))
	popup.call("_on_row_pressed", "en")
	_entry(str(popup.get("_pending_locale")) == pending_before,
		"Vua vuot -> bam hang KHONG doi lua chon (giu '%s')" % pending_before)
	# Kéo rất ngắn (dưới ngưỡng) thì vẫn tính là bấm bình thường
	popup.set("_click_lock_until", 0.0)
	popup.call("_begin_drag", Vector2(540, 900))
	popup.call("_update_drag", Vector2(540, 905))
	popup.call("_end_drag")
	popup.call("_on_row_pressed", "en")
	_entry(str(popup.get("_pending_locale")) == "en", "Keo ngan -> bam hang van chon duoc")
	popup.queue_free()
	await process_frame


# ---------------------------------------------------------------------------
# 5. Art không được chứa <text>
# ---------------------------------------------------------------------------
func _section_5_no_text_art() -> void:
	print("[5] Art khong dung <text> (ThorVG khong render chu)...")
	for path in NO_TEXT_ART:
		_entry(not _has_active_text(path), "%s: khong con <text>" % path.get_file())
	# Thống kê (không tính là lỗi) các art còn <text> trong project
	var leftovers: Array[String] = []
	_scan_text_art("res://assets/images", leftovers)
	if leftovers.is_empty():
		print("  [INFO] Khong con art nao dung <text>.")
	else:
		print("  [INFO] Art con <text> (khong render trong game): %s" % ", ".join(leftovers))


# ---------------------------------------------------------------------------
# 6. Bảng ngôn ngữ: đủ 19 ngôn ngữ, mỗi ngôn ngữ một TÊN riêng + một CỜ riêng
# ---------------------------------------------------------------------------
func _section_6_locale_info() -> void:
	print("[6] Bang ngon ngu (ten + co)...")
	var locales := Loc.locales()
	_entry(locales.size() >= 19, "Co it nhat 19 ngon ngu (nhan %d)" % locales.size())
	const EXPECTED := ["en", "vi", "zh_TW", "zh_CN", "es", "ar", "de", "fr", "hi", "id",
		"it", "ja", "ko", "ms", "pt", "pt_BR", "ru", "th", "tr"]
	var missing_locale: Array[String] = []
	for code in EXPECTED:
		if not locales.has(code):
			missing_locale.append(code)
	_entry(missing_locale.is_empty(), "Du 19 ma ngon ngu trong string.csv (thieu: %s)" % str(missing_locale))
	var no_name: Array[String] = []
	var no_flag: Array[String] = []
	var generic_flag: Array[String] = []
	for code in locales:
		var key := str(code)
		var info := Loc.info(key)
		if str(info.get("name", "")) == key.to_upper():
			no_name.append(key)
		var flag := str(info.get("flag", ""))
		if not ResourceLoader.exists(flag):
			no_flag.append(key)
		elif flag.ends_with("flag_generic.svg"):
			generic_flag.append(key)
	_entry(no_name.is_empty(), "Moi ngon ngu co TEN rieng, khong hien ma tho (thieu: %s)" % str(no_name))
	_entry(no_flag.is_empty(), "Moi ngon ngu co FILE co that trong assets (thieu: %s)" % str(no_flag))
	_entry(generic_flag.is_empty(), "Khong ngon ngu nao phai dung co 'generic' (con: %s)" % str(generic_flag))
	# Ten hien thi o man Settings: "Tiếng Việt (VN)"
	var vi_name := Loc.display_name("vi")
	_entry(vi_name.contains("Tiếng Việt") and vi_name.contains("VN"),
		"display_name('vi') = '%s'" % vi_name)


func _has_active_text(path: String) -> bool:
	return _strip_comments(FileAccess.get_file_as_string(path)).contains("<text")## Bỏ hết chú thích <!-- ... --> để không bắt nhầm chữ đã comment
func _strip_comments(content: String) -> String:
	var out := content
	while true:
		var start := out.find("<!--")
		if start < 0:
			break
		var end := out.find("-->", start)
		if end < 0:
			out = out.substr(0, start)
			break
		out = out.substr(0, start) + out.substr(end + 3)
	return out


func _scan_text_art(dir_path: String, found: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			if entry != "template":
				_scan_text_art(full, found)
		elif entry.ends_with(".svg") and _has_active_text(full):
			found.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()


# ---------------------------------------------------------------------------
# Harness
# ---------------------------------------------------------------------------
func _open(path: String, data: Dictionary) -> BasePopup:
	var packed := load(path) as PackedScene
	_entry(packed != null, "Load duoc %s" % path)
	if packed == null:
		return null
	var popup := packed.instantiate() as BasePopup
	root.add_child(popup)
	await process_frame
	popup.call("open", data)
	await create_timer(0.4).timeout     # chờ hiệu ứng mở xong (panel scale 0.94 -> 1)
	await process_frame
	_entry(popup.visible, "%s da mo" % path.get_file())
	return popup


func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)
