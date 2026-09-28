class_name TutorialLayout
extends BaseLayout

## ============================================================================
## TutorialLayout: Layout nền tảng cho màn hình Tutorial (Portrait & Landscape).
## Bố cục chứa TopBar (Back + Title) và Container để mount các Tutorial node.
## ============================================================================

@export var btn_back: BaseButton = null
@export var lbl_title: Label = null
@export var tutorial_container: Control = null
@export var mode_list: Control = null

@export var btn_first_time: BaseButton = null
@export var btn_move: BaseButton = null
@export var btn_checking_wall: BaseButton = null
@export var btn_minesweeper: BaseButton = null
@export var btn_one_stroke: BaseButton = null
@export var btn_sum_path: BaseButton = null
@export var btn_wall_builder: BaseButton = null
