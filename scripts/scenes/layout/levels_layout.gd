class_name LevelsLayout
extends BaseLayout

@export var btn_back: BaseButton = null
@export var btn_continue: BaseButton = null
@export var lbl_continue: Label = null
## Dòng thứ 2 trong nút TIẾP TỤC ("CHƯƠNG 1: NHẬP MÔN ›")
@export var lbl_continue_sub: Label = null
@export var lbl_stars: Label = null
## Tổng Sao tối đa của chương (".../ 27 SAO") — cùng hàng với `lbl_stars`
@export var lbl_stars_total: Label = null
@export var lbl_chapter: Label = null
@export var lbl_change_chapter: Label = null
## Chip kích thước bàn + mô tả ngắn của chương
@export var lbl_banner_size: Label = null
@export var lbl_banner_sub: Label = null
@export var banner: Control = null
## Art banner theo trạng thái (bản dọc 970x140)
@export var banner_normal: Texture2D = null
@export var banner_focus: Texture2D = null
@export var scroll: ScrollContainer = null
@export var pages_host: HBoxContainer = null
@export var dots_box: HBoxContainer = null
