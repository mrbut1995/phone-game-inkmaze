extends Node
## ============================================================================
## Manager: LocalizationManager - Quản lý ngôn ngữ hiển thị (vi/en).
## - Dùng TranslationServer của Godot; lựa chọn lưu qua SettingManager (key "locale").
## ============================================================================

signal locale_changed(locale: String)

const CSV_PATH := "res://resources/localization/string.csv"
## File bo sung (cac key chua co trong string.csv) - nap them neu ton tai
const CSV_EXTRA_PATHS := ["res://resources/localization/string_extra.csv"]
const DEFAULT_LOCALE := "vi"

## Danh sach ngon ngu - nap tu dong tu string.csv luc _ready()
var supported_locales: PackedStringArray = ["vi", "en"]

## Ten/co hien thi cho tung ngon ngu (co = icon svg, khong dung emoji)
## Đủ CẢ 19 ngôn ngữ trong string.csv — thiếu ở đây thì popup sẽ hiện mã thô + cờ "generic"
const LOCALE_INFO := {
	"vi": {"flag": "res://assets/images/icons/flags/flag_vi.svg", "code": "VN", "name": "Tiếng Việt", "sub": "Mặc định hệ thống"},
	"en": {"flag": "res://assets/images/icons/flags/flag_en.svg", "code": "US", "name": "English", "sub": "United States"},
	"zh_TW": {"flag": "res://assets/images/icons/flags/flag_zh_tw.svg", "code": "TW", "name": "繁體中文", "sub": "Traditional Chinese"},
	"zh_CN": {"flag": "res://assets/images/icons/flags/flag_zh_cn.svg", "code": "CN", "name": "简体中文", "sub": "Simplified Chinese"},
	"es": {"flag": "res://assets/images/icons/flags/flag_es.svg", "code": "ES", "name": "Español", "sub": "Spanish"},
	"ar": {"flag": "res://assets/images/icons/flags/flag_ar.svg", "code": "AR", "name": "العربية", "sub": "Arabic"},
	"de": {"flag": "res://assets/images/icons/flags/flag_de.svg", "code": "DE", "name": "Deutsch", "sub": "German"},
	"fr": {"flag": "res://assets/images/icons/flags/flag_fr.svg", "code": "FR", "name": "Français", "sub": "French"},
	"hi": {"flag": "res://assets/images/icons/flags/flag_hi.svg", "code": "IN", "name": "हिन्दी", "sub": "Hindi"},
	"id": {"flag": "res://assets/images/icons/flags/flag_id.svg", "code": "ID", "name": "Bahasa Indonesia", "sub": "Indonesian"},
	"it": {"flag": "res://assets/images/icons/flags/flag_it.svg", "code": "IT", "name": "Italiano", "sub": "Italian"},
	"ja": {"flag": "res://assets/images/icons/flags/flag_ja.svg", "code": "JP", "name": "日本語", "sub": "Japanese"},
	"ko": {"flag": "res://assets/images/icons/flags/flag_ko.svg", "code": "KR", "name": "한국어", "sub": "Korean"},
	"ms": {"flag": "res://assets/images/icons/flags/flag_ms.svg", "code": "MY", "name": "Bahasa Melayu", "sub": "Malay"},
	"pt": {"flag": "res://assets/images/icons/flags/flag_pt.svg", "code": "PT", "name": "Português", "sub": "Portuguese"},
	"pt_BR": {"flag": "res://assets/images/icons/flags/flag_pt_br.svg", "code": "BR", "name": "Português (Brasil)", "sub": "Brazilian Portuguese"},
	"ru": {"flag": "res://assets/images/icons/flags/flag_ru.svg", "code": "RU", "name": "Русский", "sub": "Russian"},
	"th": {"flag": "res://assets/images/icons/flags/flag_th.svg", "code": "TH", "name": "ไทย", "sub": "Thai"},
	"tr": {"flag": "res://assets/images/icons/flags/flag_tr.svg", "code": "TR", "name": "Türkçe", "sub": "Turkish"},
}

## Mã ngôn ngữ trong CSV viết khác khoá ở trên (để tra LOCALE_INFO)
const LOCALE_ALIASES := {
	"zh_cn": "zh_CN",
	"zh_tw": "zh_TW",
	"pt_br": "pt_BR",
}

const FLAG_FALLBACK := "res://assets/images/icons/flags/flag_generic.svg"

var current_locale := DEFAULT_LOCALE


func _ready() -> void:
	_load_translations()
	var sm: Variant = get_node_or_null("/root/SettingManager")
	var saved := DEFAULT_LOCALE
	if sm != null:
		saved = str(sm.call("get_setting", "locale", DEFAULT_LOCALE))
	set_locale(saved, false)


# ---------------------------------------------------------------------------
# Nap ban dich truc tiep tu string.csv (khong phu thuoc buoc import cua editor)
# ---------------------------------------------------------------------------
func _load_translations() -> void:
	var tables := {}
	_load_csv_into(tables, CSV_PATH)
	for extra in CSV_EXTRA_PATHS:
		_load_csv_into(tables, extra)
	if tables.is_empty():
		push_warning("[LocalizationManager] Chua nap duoc ban dich nao")
		return
	supported_locales = PackedStringArray()
	for code in tables:
		TranslationServer.add_translation(tables[code])
		supported_locales.append(str(code))
	print("[LocalizationManager] Nap %d ngon ngu" % supported_locales.size())


func _load_csv_into(tables: Dictionary, path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		# Trong build EXPORT (.apk/.pck) file .csv gốc chỉ có mặt nếu export preset khai
		# `include_filter`; nếu thiếu thì dùng các file .translation do bộ nhập CSV sinh ra.
		_load_translation_files(tables, path)
		return
	var rows := _parse_csv(file.get_as_text())
	file.close()
	if rows.size() < 2:
		return

	var header: PackedStringArray = rows[0]
	for col in range(1, header.size()):
		var code := header[col].strip_edges()
		if code.is_empty():
			continue
		if not tables.has(code):
			var table := Translation.new()
			table.locale = code
			tables[code] = table

	for row_index in range(1, rows.size()):
		var row: PackedStringArray = rows[row_index]
		if row.size() == 0:
			continue
		var key := row[0].strip_edges()
		if key.is_empty() or key == "id":
			continue
		var last := mini(row.size(), header.size())
		for col in range(1, last):
			var code := header[col].strip_edges()
			if tables.has(code) and not row[col].is_empty():
				tables[code].add_message(key, row[col])


## Dự phòng cho BUILD EXPORT: nạp các file "<tên>.<locale>.translation" nằm cạnh CSV
## (do bộ nhập csv_translation của Godot sinh ra khi import — luôn có trong gói export).
func _load_translation_files(tables: Dictionary, csv_path: String) -> void:
	var dir_path := csv_path.get_base_dir()
	var base := csv_path.get_file().get_basename()
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("[LocalizationManager] Khong mo duoc thu muc %s" % dir_path)
		return
	var loaded := 0
	for file_name in dir.get_files():
		if not file_name.begins_with(base + ".") or not file_name.ends_with(".translation"):
			continue
		var table: Translation = load(dir_path.path_join(file_name)) as Translation
		if table == null or table.locale.is_empty():
			continue
		var code := str(table.locale)
		if tables.has(code):
			_merge_translation(tables[code], table)
		else:
			tables[code] = table
		loaded += 1
	if loaded > 0:
		print("[LocalizationManager] %s: dung %d file .translation (ban export)" % [base, loaded])
	else:
		push_warning("[LocalizationManager] Thieu %s trong goi export — them 'resources/localization/*.csv' vao include_filter" % csv_path.get_file())


## Gộp message từ bảng dự phòng vào bảng đang có (KHÔNG ghi đè key đã có)
func _merge_translation(target: Translation, source: Translation) -> void:
	for key in source.get_message_list():
		if target.get_message(key) == StringName():
			target.add_message(key, str(source.get_message(key)))


## Doc CSV co ho tro o duoc bao trong ngoac kep "..." (co the chua dau phay, dau ngoac kep doi)
func _parse_csv(text: String) -> Array:
	var rows: Array = []
	var row: PackedStringArray = PackedStringArray()
	var field := ""
	var in_quotes := false
	var i := 0
	while i < text.length():
		var ch := text[i]
		if in_quotes:
			if ch == "\"":
				if i + 1 < text.length() and text[i + 1] == "\"":
					field += "\""
					i += 1
				else:
					in_quotes = false
			else:
				field += ch
		else:
			match ch:
				"\"":
					in_quotes = true
				",":
					row.append(field)
					field = ""
				"\n":
					row.append(field)
					rows.append(row)
					row = PackedStringArray()
					field = ""
				"\r":
					pass
				_:
					field += ch
		i += 1
	if not row.is_empty() or not field.is_empty():
		row.append(field)
		rows.append(row)
	return rows


func set_locale(code: String, save := true) -> void:
	if not supported_locales.has(code):
		code = DEFAULT_LOCALE
	current_locale = code
	TranslationServer.set_locale(code)
	locale_changed.emit(code)
	if save:
		var sm: Variant = get_node_or_null("/root/SettingManager")
		if sm != null:
			sm.call("set_setting", "locale", code)


## Chuyển sang ngôn ngữ kế tiếp trong danh sách hỗ trợ
func cycle_locale() -> void:
	var index := supported_locales.find(current_locale)
	var next_index := posmod(index + 1, supported_locales.size())
	set_locale(supported_locales[next_index])


func is_supported(code: String) -> bool:
	return supported_locales.has(code)


## Duong dan icon co cua ngon ngu (svg, khong dung emoji)
func get_flag_path(code: String) -> String:
	return str(get_locale_info(code).get("flag", FLAG_FALLBACK))


## Ten hien thi cua ngon ngu, vd: "Tiếng Việt (VN)"
func get_display_name(code: String) -> String:
	var info := get_locale_info(code)
	return "%s (%s)" % [info["name"], info.get("code", code.to_upper())]


## Thong tin (co, ma quoc gia, ten, phu de) cua mot ngon ngu, fallback ve ma ngon ngu
func get_locale_info(code: String) -> Dictionary:
	var key: String = str(LOCALE_ALIASES.get(code.to_lower(), ""))
	if key.is_empty():
		key = code
	if not LOCALE_INFO.has(key) and LOCALE_ALIASES.has(code):
		key = str(LOCALE_ALIASES[code])
	if LOCALE_INFO.has(key):
		return LOCALE_INFO[key]
	return {"flag": FLAG_FALLBACK, "code": code.to_upper(), "name": code.to_upper(), "sub": ""}


## Wrapper cho tr() để code gọi ngắn gọn: LocalizationManager.t("KEY")
func t(key: String) -> String:
	return tr(key)
