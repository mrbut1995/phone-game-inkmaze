extends SceneTree
## ============================================================================
## Khôi phục `.translation` từ CSV (khi bộ nhập csv_translation của editor
## không sinh lại được — file .import/.translation thiếu hoặc hỏng).
##
##   godot --headless --path . --script res://scripts/tool/gen_csv_translation.gd
##
## Với MỖI file CSV trong `resources/localization/*.csv`:
##   · cột 1 = khoá (id) · các cột còn lại = mã ngôn ngữ (en, vi, …)
##   · ghi lại "<tên>.<mã>.translation" bằng Translation THƯỜNG (không nén)
##     — cùng định dạng với bộ nhập CSV của Godot (compress=0).
##
## Lưu ý: chỉ chạy khi file .translation bị mất; bình thường editor tự sinh khi
## import CSV (String.csv.import / String_extra.csv.import).
## ============================================================================

const LOCALIZATION_DIR := "res://resources/localization"


func _init() -> void:
	var dir := DirAccess.open(LOCALIZATION_DIR)
	if dir == null:
		push_error("[gen_csv_translation] Khong mo duoc %s" % LOCALIZATION_DIR)
		quit(1)
		return
	var total := 0
	for file_name in dir.get_files():
		if not file_name.ends_with(".csv"):
			continue
		total += _generate(LOCALIZATION_DIR.path_join(file_name))
	if total == 0:
		print("[gen_csv_translation] Khong sinh duoc file .translation nao")
	quit(0 if total > 0 else 1)


## Trả về số file .translation ghi được cho 1 CSV
func _generate(csv_path: String) -> int:
	var file := FileAccess.open(csv_path, FileAccess.READ)
	if file == null:
		push_error("[gen_csv_translation] Khong doc duoc %s" % csv_path)
		return 0
	var rows := _parse_csv(file.get_as_text())
	file.close()
	if rows.size() < 2:
		return 0
	var header: PackedStringArray = rows[0]
	var base := csv_path.get_basename()
	var written := 0
	for col in range(1, header.size()):
		var code := header[col].strip_edges()
		if code.is_empty():
			continue
		var table := Translation.new()
		table.locale = code
		for row_index in range(1, rows.size()):
			var row: PackedStringArray = rows[row_index]
			if row.size() <= col:
				continue
			var key := row[0].strip_edges()
			if key.is_empty():
				continue
			table.add_message(key, row[col])
		var out_path := "%s.%s.translation" % [base, code]
		var err := ResourceSaver.save(table, out_path)
		print("[gen_csv_translation] %s: %d khoa (%s)"
			% [out_path.get_file(), table.get_message_list().size(),
			"OK" if err == OK else "LOI %d" % err])
		if err == OK:
			written += 1
	return written


## Đọc CSV có ô bọc trong ngoặc kép (đồng bộ với LocalizationManager._parse_csv)
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
