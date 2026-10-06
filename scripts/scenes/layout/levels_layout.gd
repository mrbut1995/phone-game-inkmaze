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
## Art banner theo trạng thái — bản dọc khai bộ riêng (có sẵn art focus)
@export var banner_normal: Texture2D = null
@export var banner_focus: Texture2D = null
## Tham chiếu đến LevelMap — lấy từ instance trong `scenes/levels.tscn`
@export var level_map: LevelMap = null