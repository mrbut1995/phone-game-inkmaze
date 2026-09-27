class_name DailyLayout
extends BaseLayout

@export var btn_back: BaseButton = null
@export var calendar: DailyCalendar = null
@export var missions: Control = null
@export var lbl_streak: Label = null
@export var lbl_date: Label = null
@export var lbl_mode: Label = null
@export var lbl_reward: Label = null
@export var rows_host: Control = null
@export var lbl_progress: Label = null
@export var bar_progress: TextureProgressBar = null
@export var lbl_claim: Label = null
@export var btn_play: BaseButton = null
@export var lbl_play: Label = null
@export var icon_play: TextureRect = null
@export var streak_badge: Control = null


## Khay của hàng nhiệm vụ thứ `index` (`Slot1..Slot4` khai trong scene dưới `rows_host`).
## Màn Daily gọi hàm này thay vì tự lấy node con của bảng nhiệm vụ.
func mission_slot(index: int) -> Control:
	if rows_host == null:
		return null
	return rows_host.get_node_or_null("Slot%d" % (index + 1)) as Control
