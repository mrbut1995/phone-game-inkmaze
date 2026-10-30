class_name TutorialListLayout
extends BaseLayout

## ============================================================================
## TutorialListLayout: bố cục màn DANH SÁCH bài hướng dẫn
## (`scenes/tutorial_list.tscn` — Portrait & Landscape).
##
## Chỉ chứa TopBar (Back + tiêu đề) + danh sách 12 nút bài học. Bài học thật KHÔNG
## mount ở đây: bấm 1 nút ⇒ mở màn CHI TIẾT `scenes/tutorial.tscn` với yêu cầu
## `GameManager.request_tutorial(id, true)`.
## ============================================================================

@export var btn_back: BaseButton = null
@export var lbl_title: Label = null
## Node chứa danh sách (ScrollContainer/VBox) — chỉ để canh/ẩn khi cần
@export var mode_list: Control = null

@export_group("Nút bài học")
@export var btn_first_time: BaseButton = null
@export var btn_move: BaseButton = null
@export var btn_checking_wall: BaseButton = null
@export var btn_minesweeper: BaseButton = null
@export var btn_one_stroke: BaseButton = null
@export var btn_sum_path: BaseButton = null
@export var btn_wall_builder: BaseButton = null
@export var btn_countdown_cost: BaseButton = null
@export var btn_fading_ink: BaseButton = null
@export var btn_fog_of_war: BaseButton = null
@export var btn_blind_memory: BaseButton = null
@export var btn_use_tool: BaseButton = null
