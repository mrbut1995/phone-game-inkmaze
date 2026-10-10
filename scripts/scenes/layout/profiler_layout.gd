class_name ProfilerLayout
extends BaseLayout
## ============================================================================
## Bố cục màn HỒ SƠ CÁ NHÂN (scenes/layout/<hướng>/profiler_popup.tscn)
##
## 2 hướng dùng CHUNG tên node; màn hình bind qua các export dưới đây rồi đọc node
## con theo tên cố định trong từng NHÓM (hero · info_list…) nên thêm/bớt node chỉ cần
## sửa .tscn, không phải sửa code màn.
##
## Tên node con mà màn hình tìm (xem scripts/scenes/profiler.gd):
##   · level_chip : "Text"                      — nhãn "LV. 12"
##   · hero       : Disc · Avatar · Frame · BtnAvatar · NameRow(Name · Pen) · TierChip+Text ·
##                  Exp/ExpValue · ExpSub (NGANG) · Bar/BarFill · Uid · UidBlock/Join (NGANG)
##   · info_scroll: ScrollContainer chứa DANH SÁCH THÔNG TIN — cuộn DỌC ở CẢ 2 hướng
##                  (ngang: Hero nằm CỘT TRÁI, danh sách ở CỘT PHẢI giống mockup); Hero cố định.
##   · info_list  : nơi gắn các nhóm số liệu (nodes/profiler/stat_group.tscn)
## ============================================================================

@export var btn_close: BaseButton = null
@export var lbl_title: Label = null
@export var level_chip: Control = null
@export var hero: Control = null
## Vùng CUỘN của danh sách thông tin (Hero không nằm trong đây)
@export var info_scroll: ScrollContainer = null
## Nơi dựng các nhóm số liệu — VBoxContainer (cuộn DỌC cả 2 hướng)
@export var info_list: BoxContainer = null
## Nhãn "Còn {0} EXP để lên cấp {1}" + ngày tham gia — CHỈ bố cục NGANG có
## (mockup landscape); bản dọc để null, màn hình guard null từng nhãn.
@export var hero_exp_remain: Label = null
@export var hero_join: Label = null
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


## Bố cục NGANG (danh sách nằm trong cột phải "RightCol") — nhận biết từ CHÍNH cây
## layout đang bind, KHÔNG dùng cờ hướng của màn (test gán layout trực tiếp nên cờ có thể sai).
func is_side_layout() -> bool:
	var parent := info_scroll.get_parent() if info_scroll != null else null
	return parent != null and parent.name == &"RightCol"
