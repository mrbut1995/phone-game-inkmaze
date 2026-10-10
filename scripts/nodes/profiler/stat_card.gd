class_name ProfilerStatCard
extends Control
## ============================================================================
## 1 THẺ số liệu của Hồ sơ: nền giấy + icon + nhãn + đường kẻ đứt + giá trị +
## nét nguệch ngoạc. Scene: `nodes/profiler/stat_card.tscn` (bản DỌC) và
## `stat_card_wide.tscn` (bản NGANG) — do `ProfilerStatGroup` instantiate.
##
## Bề rộng do LƯỚI quyết định (GridContainer chia đều theo expand) nên thẻ chỉ
## khai bề rộng TỐI THIỂU; icon/nhãn/giá trị neo giữa nên tự thích mọi bề rộng.
## Nét nguệch ngoạc theo NHÓM — màn Hồ sơ truyền vào lúc `setup()`.
## (Mẩu WASHI Ở GÓC thẻ đã BỎ theo yêu cầu — không còn node TapeCorner.)
##
## Trạng thái MỜ (`muted`): chế độ chưa từng chơi → làm mờ cả thẻ (modulate).
## ============================================================================

@export var icon: TextureRect = null
@export var name_label: Label = null
@export var value_label: Label = null
@export var squiggle: TextureRect = null


## Nạp 1 thẻ (chuỗi đã dịch sẵn ở nơi gọi; `squiggle_texture` theo nhóm)
func setup(icon_texture: Texture2D, label_text: String, value_text: String,
		squiggle_texture: Texture2D, muted := false) -> void:
	if icon != null:
		icon.texture = icon_texture
	if name_label != null:
		name_label.text = label_text
	if value_label != null:
		value_label.text = value_text
	if squiggle != null:
		squiggle.texture = squiggle_texture
	modulate = Color(1, 1, 1, 0.55) if muted else Color(1, 1, 1, 1)
