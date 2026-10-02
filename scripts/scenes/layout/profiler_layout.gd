class_name ProfilerLayout
extends BaseLayout
## ============================================================================
## Bố cục màn HỒ SƠ CÁ NHÂN (scenes/layout/<hướng>/profiler.tscn)
##
## 2 hướng dùng CHUNG tên node; màn hình bind qua các export dưới đây rồi đọc node
## con theo tên cố định trong từng NHÓM (hero · stat_cards · badges_box · gear_box…)
## nên thêm/bớt node chỉ cần sửa .tscn, không phải sửa code màn.
##
## Tên node con mà màn hình tìm (xem scripts/scenes/profiler.gd):
##   · level_chip : "Text"                      — nhãn "LV. 12"
##   · hero       : Disc · Avatar · Frame · BtnAvatar · NameRow(Name · Pen) · TierChip+Text · ExpValue · BarFill · Uid
##   · stat_cards : Stat1..Stat4 (mỗi thẻ: Name · Value · Icon)
##   · badges_box : Badge1..Badge3 (Icon · Name) · ApText · BtnMore
##   · gear_box   : Card1..Card3 (Icon · Name)
##   · rows_box   : nơi gắn các hàng lịch sử (nodes/profiler/activity_row.tscn)
## ============================================================================

@export var btn_back: BaseButton = null
@export var lbl_title: Label = null
@export var level_chip: Control = null
@export var hero: Control = null
@export var stat_cards: Control = null
@export var badges_box: Control = null
@export var gear_box: Control = null
@export var rows_box: Control = null
@export var btn_edit: BaseButton = null
@export var btn_share: BaseButton = null
@export var stamp: Control = null
@export var hero_btn_avatar : BaseButton = null
@export var hero_avatar : TextureRect = null
@export var hero_frame  : TextureRect = null 
@export var hero_name : Label = null
@export var hero_tier_text: Label = null 
@export var hero_exp_value : Label = null 
@export var hero_uid : Label = null 
@export var hero_track : Control = null 
@export var hero_fill: Control = null

# --- Truy cập node con theo tên (2 hướng khai cùng tên) ---------------------
## Nhãn trong chip cấp độ — `level_chip` có thể bind vào chính Label hoặc vào Control chứa Label "Text"
func chip_text() -> Label:
	if level_chip == null:
		return null
	var direct := level_chip as Label
	if direct != null:
		return direct
	return level_chip.get_node_or_null("Text") as Label


func stat_card(index: int) -> Control:
	return stat_cards.get_node_or_null("Stat%d" % (index + 1)) as Control if stat_cards != null else null


func badge_slot(index: int) -> Control:
	return badges_box.get_node_or_null("Badge%d" % (index + 1)) as Control if badges_box != null else null


func gear_card(index: int) -> Control:
	return gear_box.get_node_or_null("Card%d" % (index + 1)) as Control if gear_box != null else null


## Chip "{n} AP" trên giá huy hiệu (node `ApChip/Text` khai trong .tscn)
func ap_text() -> Label:
	return badges_box.get_node_or_null("ApChip/Text") as Label if badges_box != null else null


## Nút "Xem Sổ Tay" cạnh giá huy hiệu
func btn_more() -> BaseButton:
	return badges_box.get_node_or_null("BtnMore") as BaseButton if badges_box != null else null
