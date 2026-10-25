class_name ArchivementCardBig
extends ArchivementCard
## ============================================================================
## Thẻ BÀI LỚN của Sổ tay thành tựu (nodes/archivements/card_big.tscn) — bố cục "G".
## KẾ THỪA ArchivementCard ⇒ dùng lại NGUYÊN `setup(entry)` + 4 trạng thái + nút NHẬN
## (cùng bộ `@export` node, cùng signal `claim_requested`). Chỉ THÊM:
##   · chip phân loại (DAILY / DUNGEON / …)   — entry["category"]
##   · tem số thứ tự "#3 / 28"                 — entry["index"], entry["total"]
## Hai khoá trên do ArchivementScene nhét thêm vào entry; thiếu khoá ⇒ phần đó tự ẩn.
## ============================================================================

@export var cat_chip: Control = null
@export var cat_label: Label = null
@export var index_sticker: Control = null
@export var index_label: Label = null


func setup(entry: Dictionary) -> void:
	super.setup(entry)

	var hidden := bool(entry.get("secret_hidden", false))
	var category := str(entry.get("category", ""))
	if cat_chip != null:
		cat_chip.visible = category != "" and not hidden
		if cat_chip.visible and cat_label != null:
			cat_label.text = _category_text(category)

	var total := int(entry.get("total", 0))
	if index_sticker != null:
		index_sticker.visible = total > 0
		if total > 0 and index_label != null:
			index_label.text = "#%d / %d" % [int(entry.get("index", 1)), total]


func _category_text(category: String) -> String:
	match category:
		"levels":
			return tr("STR_ACH_TAB_LEVELS")
		"dungeon":
			return tr("STR_ACH_TAB_DUNGEON")
		"daily":
			return tr("STR_ACH_TAB_DAILY")
		"special":
			return tr("STR_ACH_TAB_SPECIAL")
		_:
			return category.to_upper()
