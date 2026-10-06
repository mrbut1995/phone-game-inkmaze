class_name LevelsLayout
extends BaseLayout

@export var btn_back: BaseButton = null
@export var btn_continue: BaseButton = null
@export var lbl_continue: Label = null
@export var lbl_stars: Label = null
## Tổng Sao tối đa của chương (".../27") — cùng hàng với `lbl_stars`
@export var lbl_stars_total: Label = null
@export var lbl_chapter: Label = null
@export var lbl_change_chapter: Label = null
@export var banner: Control = null
## Art banner theo trạng thái — mỗi hướng khai bộ riêng (bản dọc có sẵn art focus)
@export var banner_normal: Texture2D = null
@export var banner_focus: Texture2D = null
## Tham chiếu đến LevelMap — dùng chung 1 instance từ scenes/levels.tscn
## (portrait & landscape đều trỏ vào cùng node)
@export var level_map: LevelMap = null
