class_name RankingLayout
extends BaseLayout

@export var btn_back: BaseButton = null
## Cột tab gáy sổ dọc (VBox) — 3 RankTabButton khai sẵn trong scene
@export var tabs_box: BoxContainer = null
## Chứa 3 nhóm Gold · Silver · Bronze (tìm bằng find_child nên đặt sâu bao nhiêu cũng được)
@export var podium: Control = null
@export var scroll: ScrollContainer = null
@export var rows_box: VBoxContainer = null
@export var my_rank_bar: TextureRect = null
## Node bao toàn bộ nội dung đổi theo tab (Sheet/Body) — dùng cho animation chuyển tab
@export var content: Control = null


## Cờ quốc gia trên giấy nhớ "hạng của bạn" (`Flag` là con trực tiếp của my_rank_bar).
func my_rank_flag() -> TextureRect:
	return my_rank_bar.get_node_or_null("Flag") as TextureRect if my_rank_bar != null else null
