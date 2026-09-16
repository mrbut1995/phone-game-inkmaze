extends SceneTree

# Kiem tra nhanh: CSV->translation co nap duoc key STR_GI_* khong.
func _init() -> void:
	var keys := ["STR_GI_PAGE_INDEX", "STR_GI_DUNGEON_CHIP", "STR_GI_DUNGEON_P1_TITLE",
			"STR_GI_X001", "STR_GI_NORMAL_MAZE_P3_R2D"]
	var missing := 0
	for locale in ["vi", "en"]:
		TranslationServer.set_locale(locale)
		for k in keys:
			var v := tr(k)
			print(locale, " ", k, " -> ", v)
			if v == k:
				missing += 1
	# vi du dinh dang
	TranslationServer.set_locale("vi")
	print("format: ", tr("STR_GI_PAGE_INDEX").format([2, 3]))
	TranslationServer.set_locale("en")
	print("format: ", tr("STR_GI_PAGE_INDEX").format([2, 3]))
	print("missing=", missing)
	quit(0 if missing == 0 else 1)
