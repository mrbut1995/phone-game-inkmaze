extends SceneTree
## ============================================================================
## Test Case: LOCALIZATION — bảo vệ hệ thống chuỗi dịch (2026-02)
##
## 1. CSV hợp lệ: 2 file, header đủ cột, mọi dòng đủ ô, id duy nhất + đúng dạng.
## 2. Không còn MOJIBAKE: cột chữ Việt/CJK/Thái… không còn dấu hiệu mã hoá nhầm
##    (á»…/Ä‘/Æ°/Æ¡/â€) và không có ký tự điều khiển C1 trong CSV lẫn .tscn/.gd/.tres.
## 3. Mọi khoá "STR_…" dùng trong scene/code phải TỒN TẠI trong CSV.
## 4. Tên node KHÔNG được bị thay bằng khoá dịch (lỗi từng gặp khi migrate hàng loạt).
## 5. Khoá dịch của Thành tựu / Chương (title_key, desc_key…) trỏ tới khoá có thật.
## 6. TranslationServer trả về chuỗi đã dịch thật (vi + en), không trả lại khoá thô.
## 7. [INFO] Khoá không dùng — báo số lượng để dọn dần (không làm đỏ test).
## ============================================================================

const CSV_MAIN := "res://resources/localization/string.csv"
const CSV_EXTRA := "res://resources/localization/string_extra.csv"
const SCAN_DIRS := ["res://scripts", "res://scenes", "res://nodes", "res://resources"]
const SCAN_SUFFIXES := "gd,tscn,tres"
## Bỏ qua khi quét: công cụ Python, chính thư mục test (chứa chuỗi mẫu), file dịch
const SKIP_PARTS := ["res://tools", "res://scripts/test_case", "res://resources/localization"]
## Dấu hiệu mojibake (UTF-8 bị đọc bằng CP1252 rồi ghi lại)
const MOJIBAKE_MARKERS := ["á»", "áº", "Ä‘", "Æ°", "Æ¡", "â€"]
const KEY_RE := "\"(STR_[A-Z0-9_]+)\""

var _checks := 0
var _failed := 0
var _keys := {}                 # id -> true (từ 2 file CSV)
var _used := {}                 # id -> số lần dùng trong scene/code
var _unused: Array[String] = []
var _overrides: Array[String] = [] # khoá bị khai ở cả 2 file (extra ghi đè)
var _cached: Array[String] = [] # danh sách file .gd/.tscn/.tres (quét 1 lần)


func _init() -> void:
	print("\n========================================================")
	print("  TEST: LOCALIZATION (CSV + khoa dich + chong mojibake)")
	print("========================================================\n")

	await process_frame

	_section_1_csv()
	_section_2_no_mojibake()
	_section_3_keys_exist()
	_section_4_node_names()
	_section_5_resource_keys()
	_section_6_runtime_translation()
	_section_7_translation_files()

	print("\n--------------------------------------------------------")
	if _failed == 0:
		print("  KET QUA: %d/%d CHECK PASS" % [_checks, _checks])
	else:
		print("  KET QUA: %d/%d CHECK FAIL" % [_failed, _checks])
	print("--------------------------------------------------------\n")
	quit(1 if _failed > 0 else 0)


# ---------------------------------------------------------------------------
# 1. Cấu trúc CSV
# ---------------------------------------------------------------------------
func _section_1_csv() -> void:
	print("[1] Cau truc file CSV...")
	var expected_columns := {CSV_MAIN: 20, CSV_EXTRA: 3}
	for path in expected_columns:
		_entry(FileAccess.file_exists(path), "Ton tai %s" % path.get_file())
		var rows := _csv_rows(path)
		_entry(not rows.is_empty(), "%s doc duoc (%d dong)" % [path.get_file(), rows.size()])
		if rows.is_empty():
			continue
		var header: PackedStringArray = rows[0]
		_entry(header.size() == expected_columns[path],
			"%s co %d cot (nhan %d)" % [path.get_file(), expected_columns[path], header.size()])
		_entry(header[0] == "id", "%s cot dau la 'id'" % path.get_file())
		_entry(header.has("en") and header.has("vi"), "%s co cot en + vi" % path.get_file())
		var width := header.size()
		var wrong := 0
		var bad_id := 0
		var seen_here := {}
		var regex := RegEx.create_from_string("^STR_[A-Z0-9_]+$")
		for index in range(1, rows.size()):
			var row: PackedStringArray = rows[index]
			if row.size() != width:
				wrong += 1
				continue
			var id := row[0]
			if regex.search(id) == null:
				bad_id += 1
			if seen_here.has(id):
				bad_id += 1
			seen_here[id] = true
			if _keys.has(id):
				# Ghi đè có chủ đích: string_extra.csv nạp SAU nên thay bản dịch en/vi
				_overrides.append(id)
			_keys[id] = true
		_entry(wrong == 0, "%s moi dong du %d o (sai %d)" % [path.get_file(), width, wrong])
		_entry(bad_id == 0, "%s id dung dang STR_… va khong trung trong file (%d loi)" % [
			path.get_file(), bad_id])
	if not _overrides.is_empty():
		print("  [INFO] Ghi de giua 2 file (extra nạp sau): %s" % ", ".join(_overrides))


# ---------------------------------------------------------------------------
# 2. Không còn mojibake
# ---------------------------------------------------------------------------
func _section_2_no_mojibake() -> void:
	print("[2] Kiem tra mojibake...")
	for path in [CSV_MAIN, CSV_EXTRA]:
		var text := _read_text(path)
		var marker_hits := 0
		for marker in MOJIBAKE_MARKERS:
			marker_hits += text.count(marker)
		_entry(marker_hits == 0, "%s khong con dau hieu mojibake (%d)" % [
			path.get_file(), marker_hits])
		_entry(_control_hits(text) == 0, "%s khong co ky tu dieu khien C1 (%d)" % [
			path.get_file(), _control_hits(text)])

	var files := _files()
	var dirty: Array[String] = []
	for path in files:
		var hits := _control_hits(_read_text(path))
		if hits > 0:
			dirty.append("%s (%d)" % [path.get_file(), hits])
	_entry(dirty.is_empty(), "Scene/code khong dinh ky tu C1 (%s)" % ", ".join(dirty))

	var literal := 0
	for path in files:
		var text := _read_text(path)
		for marker in MOJIBAKE_MARKERS:
			literal += text.count(marker)
	_entry(literal == 0, "Scene/code khong con chuoi mojibake (%d)" % literal)


# ---------------------------------------------------------------------------
# 3. Khoá dùng trong scene/code phải tồn tại
# ---------------------------------------------------------------------------
func _section_3_keys_exist() -> void:
	print("[3] Khoa STR_… dung trong scene/code...")
	var files := _files()
	var regex := RegEx.create_from_string(KEY_RE)
	var missing := {}
	for path in files:
		for found in regex.search_all(_read_text(path)):
			var id := found.get_string(1)
			_used[id] = int(_used.get(id, 0)) + 1
			if not _keys.has(id):
				missing[id] = path.get_file()
	_entry(not _used.is_empty(), "Tim thay khoa duoc dung (%d khoa khac nhau)" % _used.size())
	for id in missing:
		_entry(false, "Khoa '%s' dung trong %s nhung KHONG co trong CSV" % [id, missing[id]])
	_entry(missing.is_empty(), "Moi khoa dung trong scene/code deu ton tai trong CSV")
	for id in _keys:
		if not _used.has(id):
			_unused.append(id)
	print("  [INFO] Khoa chua thay cho dung: %d" % _unused.size())

	# Vài khoá trọng yếu phải có (HUD, công cụ, tutorial, thành tựu, chương)
	for id in ["STR_DAILY_CHALLENGE_TITLE", "STR_SELECT_LEVEL_TITLE", "STR_HUD_SUM",
			"STR_HUD_TARGET", "STR_TOOL_SUBMIT", "STR_TOOL_RESTART", "STR_TOOL_UNDO",
			"STR_TOOL_HINT", "STR_TOOL_SKIP", "STR_TUT_SUM_HUD_FORMAT",
			"STR_TUT_WB_COUNTER_FORMAT", "STR_ACH_LV_FIRST_STEP_TITLE",
			"STR_ACH_LV_FIRST_STEP_DESC", "STR_CHAPTER_1_NAME", "STR_CHAPTER_1_SUB"]:
		_entry(_keys.has(id), "Co khoa trong yếu '%s'" % id)

	# Khoá dạng _FORMAT phải có chỗ trống {0}
	var format_bad: Array[String] = []
	var rows := _csv_rows(CSV_MAIN) + _csv_rows(CSV_EXTRA)
	for row in rows:
		if row.size() < 2:
			continue
		if row[0].ends_with("_FORMAT") and not row[1].contains("{0}"):
			format_bad.append(row[0])
	_entry(format_bad.is_empty(), "Khoa _FORMAT co {0} (%s)" % ", ".join(format_bad))


# ---------------------------------------------------------------------------
# 4. Tên node không được bị thay bằng khoá dịch
# ---------------------------------------------------------------------------
func _section_4_node_names() -> void:
	print("[4] Ten node trong .tscn...")
	var files := _files()
	var bad: Array[String] = []
	for path in files:
		if path.get_extension() != "tscn":
			continue
		for line in _read_text(path).split("\n"):
			var trimmed := line.strip_edges()
			if trimmed.begins_with("[node name=\"STR_") or trimmed.contains("parent=\"STR_"):
				bad.append("%s :: %s" % [path.get_file(), trimmed])
	_entry(bad.is_empty(), "Khong node nao bi dat ten bang khoa dich (%d)" % bad.size())
	for item in bad:
		print("      -> %s" % item)


# ---------------------------------------------------------------------------
# 5. Khoá dịch của Thành tựu / Chương
# ---------------------------------------------------------------------------
func _section_5_resource_keys() -> void:
	print("[5] Khoa dich trong .tres (thanh tuu / chuong)...")
	_check_tres_keys("res://resources/archivements", ["title_key", "desc_key"])
	_check_tres_keys("res://resources/chapters", ["title_key", "subtitle_key"])


func _check_tres_keys(folder: String, properties: Array) -> void:
	var files: Array[String] = []
	_collect_files(folder, files, true)
	_entry(not files.is_empty(), "Co file .tres trong %s (%d)" % [folder, files.size()])
	var missing_prop := 0
	var dangling: Array[String] = []
	for path in files:
		var text := _read_text(path)
		for prop in properties:
			var regex := RegEx.create_from_string("%s = \"(STR_[A-Z0-9_]*)\"" % prop)
			var found := regex.search(text)
			if found == null:
				missing_prop += 1
				continue
			var id := found.get_string(1)
			if id.is_empty() or not _keys.has(id):
				dangling.append("%s -> %s" % [path.get_file(), id])
	_entry(missing_prop == 0, "%s: moi file co %s" % [folder.get_file(), ", ".join(properties)])
	_entry(dangling.is_empty(), "%s: khoa tro toi dich that (%s)" % [
		folder.get_file(), ", ".join(dangling)])


# ---------------------------------------------------------------------------
# 6. Dịch thật lúc chạy
# ---------------------------------------------------------------------------
func _section_6_runtime_translation() -> void:
	print("[6] TranslationServer tra ve chuoi da dich...")
	var manager: Node = root.get_node_or_null("LocalizationManager")
	_entry(manager != null, "Autoload LocalizationManager ton tai")
	var backup := TranslationServer.get_locale()
	for pair in [["vi", "THỬ THÁCH HẰNG NGÀY"], ["en", "DAILY CHALLENGE"]]:
		TranslationServer.set_locale(pair[0])
		var translated := TranslationServer.translate("STR_DAILY_CHALLENGE_TITLE")
		_entry(translated == pair[1], "Locale %s dich dung ('%s')" % [pair[0], translated])
		_entry(translated != "STR_DAILY_CHALLENGE_TITLE", "Locale %s khong tra lai khoa tho" % pair[0])
	TranslationServer.set_locale(backup)


# ---------------------------------------------------------------------------
# 7. File .translation (ban du phong cho build export) phai KHOP CSV
#    Lech = sua CSV ma QUEN de Godot nhap lai: `--headless --path . --editor --quit`
# ---------------------------------------------------------------------------
func _section_7_translation_files() -> void:
	print("[7] File .translation (du phong build export) khop CSV...")
	var absent: Array[String] = []
	var stale := 0
	for path: String in [CSV_MAIN, CSV_EXTRA]:
		var base := path.get_file().get_basename()
		var rows := _csv_rows(path)
		var header: PackedStringArray = rows[0]
		for locale in ["vi", "en"]:
			# Tra cot theo HANG TIEU DE (string.csv co 20 cot) — khong ghim row[2] cho ca 2 locale
			var col := header.find(locale)
			if col < 0:
				_entry(false, "%s thieu cot '%s'" % [path.get_file(), locale])
				continue
			var values := {}
			for index in range(1, rows.size()):
				var row: PackedStringArray = rows[index]
				if row.size() > col and row[0] != "id":
					values[row[0]] = row[col]
			var file_path := "%s/%s.%s.translation" % [path.get_base_dir(), base, locale]
			if not ResourceLoader.exists(file_path):
				absent.append(file_path.get_file())
				continue
			var table := load(file_path) as Translation
			if table == null:
				_entry(false, "%s load duoc" % file_path.get_file())
				continue
			var keys := table.get_message_list()
			var redund := 0
			var missed := 0
			var diff := 0
			for key in keys:
				if not values.has(key):
					redund += 1
				elif str(values[key]) != table.get_message(key):
					diff += 1
			for key in values.keys():
				if not (key in keys):
					missed += 1
			stale += redund + missed + diff
			_entry(redund + missed + diff == 0,
				"%s.%s.translation khop %s (thua %d · thieu %d · lech chu %d)" % [
					base, locale, path.get_file(), redund, missed, diff])
	if not absent.is_empty():
		print("  [INFO] Chua co file .translation (Godot sinh khi nhap CSV): %s" % ", ".join(absent))
	_entry(stale == 0, "Khong co khoa/chu lech giua .translation va CSV")


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _entry(condition: bool, label: String) -> void:
	_checks += 1
	if condition:
		print("  [PASS] %s" % label)
	else:
		_failed += 1
		print("  [FAIL] %s" % label)


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	return "" if file == null else file.get_as_text()


func _control_hits(text: String) -> int:
	var hits := 0
	for index in text.length():
		var code := text.unicode_at(index)
		if code >= 0x80 and code <= 0x9F:
			hits += 1
	return hits


func _csv_rows(path: String) -> Array:
	return _parse_csv(FileAccess.get_file_as_string(path))


## Parser CSV dang STATE MACHINE: hieu o boc nhay kep (ke ca "" escape), dau phay trong o,
## va o NHIEU DONG — khong cat ngay tho theo dong nhu ban cu (gay lech cot khi o xuong dong).
func _parse_csv(text: String) -> Array:
	var rows: Array = []
	var row := PackedStringArray()
	var cell := ""
	var in_quotes := false
	var index := 0
	while index < text.length():
		var ch := text[index]
		if in_quotes:
			if ch == "\"":
				if index + 1 < text.length() and text[index + 1] == "\"":
					cell += "\""
					index += 1
				else:
					in_quotes = false
			else:
				cell += ch
		elif ch == "\"":
			in_quotes = true
		elif ch == ",":
			row.append(cell)
			cell = ""
		elif ch == "\n":
			row.append(cell)
			cell = ""
			if row.size() > 1 or not row[0].is_empty():
				rows.append(row)
			row = PackedStringArray()
		elif ch != "\r":
			cell += ch
		index += 1
	if not cell.is_empty() or row.size() > 0:
		row.append(cell)
		rows.append(row)
	return rows


func _files() -> Array[String]:
	if _cached.is_empty():
		for folder in SCAN_DIRS:
			_collect_files(folder, _cached)
	return _cached


func _collect_files(folder: String, out: Array[String], leaf_only: bool = false) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	var skipped := false
	for part in SKIP_PARTS:
		if folder.begins_with(part):
			skipped = true
	if skipped:
		return
	if not leaf_only:
		for sub in dir.get_directories():
			_collect_files(folder.path_join(sub), out, leaf_only)
	for file in dir.get_files():
		var path := folder.path_join(file)
		if not SCAN_SUFFIXES.split(",").has(path.get_extension()):
			continue
		out.append(path)
