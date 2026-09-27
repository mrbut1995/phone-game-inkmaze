class_name RankingLayout
extends BaseLayout

@export var btn_back: BaseButton = null
@export var tabs_box: HBoxContainer = null
@export var podium: Control = null
@export var scroll: ScrollContainer = null
@export var rows_box: VBoxContainer = null
@export var my_rank_bar: TextureRect = null


## Cờ quốc gia trên thanh "hạng của bạn" (`Flag` khai trong nodes/ranking/my_rank_bar.tscn).
## Màn Xếp hạng gọi hàm này thay vì tự lấy node con của thanh.
func my_rank_flag() -> TextureRect:
	return my_rank_bar.get_node_or_null("Flag") as TextureRect if my_rank_bar != null else null
