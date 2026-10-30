class_name ProfilerStatGroup
extends VBoxContainer
## ============================================================================
## 1 NHÓM số liệu của Hồ sơ (theo mockup): BĂNG WASHi tiêu đề + lưới thẻ số liệu.
## Scene: `nodes/profiler/stat_group.tscn`.
##
## 2 KIỂU BỐ CỤC — màn Hồ sơ chọn qua tham số `wide` lúc `setup()`:
##   · DỌC (portrait): băng washi CĂN GIỮA; thẻ ĐỨNG `ProfilerStatCard` (icon trên,
##     số dưới + nét nguệch ngoạc); lưới 3/2/3/4/3 cột.
##   · NGANG (landscape — mockup profiler_landscape): băng washi DÁN TRÁI + đường
##     gạch nối kéo hết bề rộng (đầu nhóm vẫn là băng washi kiểu bản dọc); thẻ NGANG
##     `ProfilerStatCardWide` (icon trái, số phải — TO hơn bản dọc cho dễ nhìn);
##     danh sách cuộn DỌC.
##
## Số CỘT do màn quyết định; riêng bố cục NGANG: nhóm CHỈ 1 HÀNG mà còn trống ngang
## (≤ 4 thẻ) được giãn đúng bằng số thẻ cho kín hàng (2 thẻ = nửa bề rộng…), nhóm
## nhiều hàng giữ lưới 4 cột. Băng washi rộng cố định (190) giữa nhóm; lưới chừa
## 8px hai bên cho thoáng.
## ============================================================================

const CARD_SCENE := preload("res://nodes/profiler/stat_card.tscn")
const CARD_WIDE_SCENE := preload("res://nodes/profiler/stat_card_wide.tscn")

@export var tape_bg: TextureRect = null
@export var tape_label: Label = null
@export var header_row: HBoxContainer = null
@export var header_dash: TextureRect = null
@export var cards_grid: GridContainer = null


## Dựng nhóm: `entries` = [{ "icon": Texture2D, "label": String, "value": String, "muted"?: bool }, …]
func setup(title_text: String, tape_texture: Texture2D, squiggle_texture: Texture2D,
		entries: Array, columns: int, wide := false) -> void:
	if tape_bg != null:
		tape_bg.texture = tape_texture
	if tape_label != null:
		tape_label.text = title_text
	if header_dash != null:
		header_dash.visible = wide
	if header_row != null:
		header_row.alignment = BoxContainer.ALIGNMENT_BEGIN if wide else BoxContainer.ALIGNMENT_CENTER
	if cards_grid != null:
		cards_grid.columns = maxi(columns, 1)
	clear_cards()
	if cards_grid == null:
		return
	var card_scene := CARD_WIDE_SCENE if wide else CARD_SCENE
	for entry_v in entries:
		var entry: Dictionary = entry_v
		var card := card_scene.instantiate() as ProfilerStatCard
		cards_grid.add_child(card)
		card.setup(entry.get("icon"), str(entry.get("label", "")), str(entry.get("value", "")),
			squiggle_texture, bool(entry.get("muted", false)))


## Xoá sạch các thẻ (giữ băng tiêu đề) — xoá NGAY để lần dựng kế tiếp không thấy rác
func clear_cards() -> void:
	if cards_grid == null:
		return
	for child in cards_grid.get_children():
		cards_grid.remove_child(child)
		child.queue_free()
