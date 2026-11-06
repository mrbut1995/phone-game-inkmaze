class_name TutorialListLayout
extends BaseLayout

## ============================================================================
## TutorialListLayout: bố cục màn DANH SÁCH bài hướng dẫn
## (`scenes/tutorial_list.tscn` — Portrait & Landscape).
##
## Chỉ chứa TopBar (Back + tiêu đề) + danh sách 6 nút bài học. Bài học thật KHÔNG
## mount ở đây: bấm 1 nút ⇒ mở màn CHI TIẾT `scenes/tutorial.tscn` với yêu cầu
## `GameManager.request_tutorial(id, true)`.
## ============================================================================

## Scene contract
## Exports:  btn_back, lbl_title, mode_list, btn_first_time, btn_move, btn_checking_wall, btn_wall_builder, btn_blind_memory, btn_use_tool
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)

@export var btn_back: BaseButton = null
@export var lbl_title: Label = null
## Node chứa danh sách (ScrollContainer/VBox) — chỉ để canh/ẩn khi cần
@export var mode_list: Control = null

@export_group("Nút bài học")
@export var btn_first_time: BaseButton = null
@export var btn_move: BaseButton = null
@export var btn_checking_wall: BaseButton = null
@export var btn_wall_builder: BaseButton = null
@export var btn_blind_memory: BaseButton = null
@export var btn_use_tool: BaseButton = null
