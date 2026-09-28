extends SceneTree
## PROBE DEV (ngoai suite): file .translation co KHOP voi CSV khong?
##   - So khoa (get_message_list) vs so dong CSV
##   - Khoa la (co trong .translation nhung khong co trong CSV)
##   - Vai khoa mau: gia tri .translation vs gia tri CSV (cot vi/en)
## Chay: godot --headless --path . -s res://scripts/test_case/dev_probe_translation.gd

const PAIRS := [
	["res://resources/localization/string.csv", "vi", 0, 2],
	["res://resources/localization/string.csv", "en", 0, 1],
	["res://resources/localization/string_extra.csv", "vi", 0, 2],
	["res://resources/localization/string_extra.csv", "en", 0, 1],
]

var _fail := 0


func _init() -> void:
	for pair in PAIRS:
		var csv_path: String = pair[0]
		var locale: String = pair[1]
		var col_key: int = pair[2]
		var col_val: int = pair[3]
		var csv := {}
		for row in _parse_csv(_read(csv_path)):
			if row.size() <= col_val:
				continue
			csv[row[col_key]] = row[col_val]
		var base := csv_path.get_file().get_basename()
		var tr_path := "%s/%s.%s.translation" % [csv_path.get_base_dir(), base, locale]
		var diff := ""
		if not ResourceLoader.exists(tr_path):
			diff = "(khong co file)"
		else:
			var tr := load(tr_path) as Translation
			if tr == null:
				diff = "(load tra null)"
			else:
				var keys := tr.get_message_list()
				var extra: Array[String] = []
				var mismatch := 0
				for k in keys:
					if not csv.has(k):
						extra.append(k)
					elif str(csv[k]) != tr.get_message(k):
						mismatch += 1
				var missing := 0
				for k in csv.keys():
					if not (k in keys):
						missing += 1
				diff = "khoa file=%d · CSV=%d · thua=%d · thieu=%d · lech gia tri=%d" % [
					keys.size(), csv.size(), extra.size(), missing, mismatch]
				if not extra.is_empty():
					diff += "\n     thua: %s" % str(extra.slice(0, 6))
				if extra.size() + missing + mismatch > 0:
					_fail += 1
		print("%-34s %-3s  %s" % [base, locale, diff])
	print("\nKET QUA: %s" % ("KHOP HET" if _fail == 0 else "%d file LECH" % _fail))
	quit(0)


func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var text := f.get_as_text()
	f.close()
	return text


## Parser CSV toi gian (ho tro o co ngoac kep) — cung kieu voi LocalizationManager._parse_csv
func _parse_csv(text: String) -> Array:
	var rows: Array = []
	var row: PackedStringArray = PackedStringArray()
	var cell := ""
	var quoted := false
	var i := 0
	while i < text.length():
		var c := text[i]
		if quoted:
			if c == "\"":
				if i + 1 < text.length() and text[i + 1] == "\"":
					cell += "\""
					i += 1
				else:
					quoted = false
			else:
				cell += c
		elif c == "\"":
			quoted = true
		elif c == ",":
			row.append(cell)
			cell = ""
		elif c == "\n":
			row.append(cell)
			cell = ""
			rows.append(row)
			row = PackedStringArray()
		elif c == "\r":
			pass
		else:
			cell += c
		i += 1
	if not cell.is_empty() or row.size() > 0:
		row.append(cell)
		rows.append(row)
	return rows
