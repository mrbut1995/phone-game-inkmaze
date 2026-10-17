class_name DailyLayout
extends BaseLayout
## ============================================================================
## Binding node cho màn Thử thách hằng ngày (scenes/layout/<hướng>/daily.tscn).
##
## Hai hướng (Portrait / Landscape) dùng CÙNG bộ export — màn hình chỉ việc khai
## `node_paths` trong scene. Mọi số đo/bố cục nằm trong scene, không ở script.
## ============================================================================

@export var btn_back: BaseButton = null
@export var calendar: DailyCalendar = null

@export_group("Thanh Sao tháng")
## Số Sao tích luỹ của tháng (chữ to nằm trong ngôi sao lớn)
@export var lbl_star_total: Label = null
## Thanh tiến độ (nền navy + phần đã đạt màu hổ phách)
@export var bar_stars: TextureProgressBar = null
## HBox chứa các huy hiệu mốc thưởng
@export var milestones_host: HBoxContainer = null

@export_group("Thẻ hành động")
@export var play_card: DailyActionCard = null
@export var challenge_card: DailyActionCard = null

@export_group("Khác")
@export var lbl_reset: Label = null
