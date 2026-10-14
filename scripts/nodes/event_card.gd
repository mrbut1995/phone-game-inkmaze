class_name EventCard
extends AspectRatioContainer
## ============================================================================
## Node: EventCard — Thẻ sự kiện tỷ lệ aspect ratio (mặc định 0.8) trong carousel Main Screen.
##
## Cách dùng:
##   var card = preload("res://nodes/main/event_card.tscn").instantiate()
##   add_child(card)
##   card.setup(event_data)
##
## Không tạo node mới lúc chạy (§13.15 GDD). Mọi node con khai sẵn trong scene.
## ============================================================================

signal card_pressed(event_id: StringName)

## Node con — bind bằng @onready (không dùng %UniqueName theo §13.10)
@onready var bg_gradient: ColorRect = $Content/Background/BgGradient
@onready var back_art: TextureRect = $Content/Background/BackArt
@onready var front_art: NinePatchRect = $Content/Background/FrontArt
@onready var theme_chip: PanelContainer = $Content/Chips/ThemeChip
@onready var chip_label: Label = $Content/Chips/ThemeChip/Content/ChipLabel
@onready var chip_dot: ColorRect = $Content/Chips/ThemeChip/Content/ChipDot
@onready var timer_chip: PanelContainer = $Content/Chips/TimerChip
@onready var timer_label: Label = $Content/Chips/TimerChip/Content/TimerLabel
@onready var title_1: Label = $Content/Text/Title/Title1
@onready var title_2: Label = $Content/Text/Title/Title2
@onready var sub_1: Label = $Content/Sub1
@onready var sub_2: Label = $Content/Sub2
@onready var progress_panel: Panel = $Content/Information/ProgressPanel
@onready var reward_1_icon: Control = $Content/Information/ProgressPanel/Rewards/Reward1/Icon
@onready var reward_1_label: Label = $Content/Information/ProgressPanel/Rewards/Reward1/RewardLabel
@onready var reward_2_icon: Control = $Content/Information/ProgressPanel/Rewards/Reward2/Icon
@onready var reward_2_label: Label = $Content/Information/ProgressPanel/Rewards/Reward2/RewardLabel
@onready var daily_date: Control = $Content/Text/DailyDate
@onready var daily_month: Label = $Content/Text/DailyDate/Month
@onready var daily_day: Label = $Content/Text/DailyDate/Day
@onready var daily_weekday: Label = $Content/Text/DailyDate/Weekday
@onready var cta_button: Button = $Content/Information/CtaButton
@onready var cta_label: Label = $Content/Information/CtaButton/CtaLabel
@onready var timer_node: Timer = $Content/CountdownTimer
@onready var completed_overlay: ColorRect = $Content/CompletedOverlay

## Ảnh icon phần thưởng theo `EventReward.Kind` (nạp 1 lần)
const REWARD_ICONS := {
	EventReward.Kind.COIN: "res://assets/images-png/icons/icon_coin.png",
	EventReward.Kind.COIN_MULTIPLIER: "res://assets/images-png/icons/icon_coin_t3.png",
	EventReward.Kind.PEN_SKIN: "res://assets/images-png/icons/icon_pen.png",
	EventReward.Kind.AVATAR_FRAME: "res://assets/images-png/frames/frame_bronze.png",
}

## Gradient texture động (tạo lúc setup để không hardcode màu)
var _event_data: EventData = null
var _event_id: StringName = &""
var _preview_mode: bool = false
var _card_press_active := false
var _card_press_position := Vector2.ZERO

const CARD_CLICK_DRAG_THRESHOLD := 12.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_aspect_width()


func _update_aspect_width() -> void:
	if size.y > 0.0:
		var target_w := roundf(size.y * ratio)
		if not is_equal_approx(custom_minimum_size.x, target_w):
			custom_minimum_size.x = target_w


func _ready() -> void:
	if cta_button != null:
		cta_button.pressed.connect(_on_cta_pressed)
	# Thẻ bấm bất kỳ chỗ nào đều phát signal
	gui_input.connect(_on_card_gui_input)


## Thiết lập thẻ từ dữ liệu EventData
func setup(data: EventData, preview_mode: bool = false) -> void:
	_event_data = data
	_event_id = data.id
	_preview_mode = preview_mode
	_apply_theme(data.theme)
	_apply_texts(data)
	_apply_daily_date(data)
	_refresh_progress()
	_refresh_timer()
	if timer_node != null:
		timer_node.wait_time = 45.0
		timer_node.timeout.connect(_on_timer_tick)
		timer_node.start()


## Daily: lá lịch lấy NGÀY/THÁNG/THỨ từ giờ máy (Label động — không nhúng vào art)
func _apply_daily_date(data: EventData) -> void:
	var is_daily := data.type == EventData.Type.DAILY
	if daily_date != null:
		daily_date.visible = is_daily
	if not is_daily:
		return
	var now := Time.get_datetime_dict_from_system()
	if daily_month != null:
		daily_month.text = tr("STR_MONTH_%02d" % int(now.get("month", 1)))
	if daily_day != null:
		daily_day.text = str(int(now.get("day", 1)))
	if daily_weekday != null:
		daily_weekday.text = tr(_WEEKDAY_KEYS[clampi(int(now.get("weekday", 0)), 0, 6)])
	if title_1 != null:
		title_1.add_theme_font_size_override("font_size",16)
	if title_2 != null:
		title_2.add_theme_font_size_override("font_size",16)


## Khoá dịch thứ trong tuần (Time.weekday: 0 = Chủ nhật … 6 = Thứ Bảy)
const _WEEKDAY_KEYS := [
	"STR_WEEKDAY_SUN", "STR_WEEKDAY_MON", "STR_WEEKDAY_TUE", "STR_WEEKDAY_WED",
	"STR_WEEKDAY_THU", "STR_WEEKDAY_FRI", "STR_WEEKDAY_SAT",
]


# ---------------------------------------------------------------------------
# THEME
# ---------------------------------------------------------------------------

func _apply_theme(t: EventTheme) -> void:
	if t == null:
		return
	# Nền: ColorRect lót dưới art (dùng màu đầu của gradient) — art (nếu có) phủ lên trên
	if bg_gradient != null and t.bg_stops.size() > 0:
		bg_gradient.color = t.bg_stops[0]
	# Art
	if back_art != null:
		back_art.texture = t.back_art
		back_art.visible = t.back_art != null
		back_art.position.y = t.art_offset_y
	if front_art != null:
		front_art.texture = t.front_art
		front_art.visible = t.front_art != null
		front_art.position.y = t.art_offset_y
	# Chip
	if chip_dot != null:
		chip_dot.color = t.accent
	if chip_label != null:
		chip_label.add_theme_color_override("font_color", t.chip_text)
	if theme_chip != null:
		var style := StyleBoxFlat.new()
		style.bg_color = t.chip_fill
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_bottom_left = 8
		theme_chip.add_theme_stylebox_override("panel", style)
	# Timer chip
	if timer_label != null:
		timer_label.add_theme_color_override("font_color", t.chip_text)
	if timer_chip != null:
		var ts := StyleBoxFlat.new()
		ts.bg_color = t.chip_fill
		ts.corner_radius_top_left = 8
		ts.corner_radius_top_right = 8
		ts.corner_radius_bottom_right = 8
		ts.corner_radius_bottom_left = 8
		timer_chip.add_theme_stylebox_override("panel", ts)
	# Tiêu đề
	if title_1 != null:
		title_1.add_theme_color_override("font_color", t.title_color)
		title_1.add_theme_color_override("font_outline_color", t.title_outline)
	if title_2 != null:
		title_2.add_theme_color_override("font_color", t.title_color)
		title_2.add_theme_color_override("font_outline_color", t.title_outline)

	# Phụ đề
	if sub_1 != null:
		sub_1.add_theme_color_override("font_color", t.sub_color)
	if sub_2 != null:
		sub_2.add_theme_color_override("font_color", t.sub_color)
	# Panel tiến độ
	if progress_panel != null:
		var ps := StyleBoxFlat.new()
		ps.bg_color = t.panel_color
		ps.border_color = t.panel_stroke
		ps.border_width_top = 1
		ps.border_width_right = 1
		ps.border_width_bottom = 1
		ps.border_width_left = 1
		ps.corner_radius_top_left = 10
		ps.corner_radius_top_right = 10
		ps.corner_radius_bottom_right = 10
		ps.corner_radius_bottom_left = 10
		progress_panel.add_theme_stylebox_override("panel", ps)
	if reward_1_label != null:
		reward_1_label.add_theme_color_override("font_color", t.label_color)
	if reward_2_label != null:
		reward_2_label.add_theme_color_override("font_color", t.label_color)
	# Nút CTA
	if cta_button != null:
		var cs := StyleBoxFlat.new()
		cs.bg_color = t.cta_fill
		cs.border_color = t.cta_stroke
		cs.border_width_top = 1.5
		cs.border_width_right = 1.5
		cs.border_width_bottom = 1.5
		cs.border_width_left = 1.5
		cs.corner_radius_top_left = 10
		cs.corner_radius_top_right = 10
		cs.corner_radius_bottom_right = 10
		cs.corner_radius_bottom_left = 10
		cta_button.add_theme_stylebox_override("normal", cs)
		cta_button.add_theme_stylebox_override("hover", cs)
		var csp := cs.duplicate() as StyleBoxFlat
		if csp != null:
			csp.bg_color = t.cta_stroke
			cta_button.add_theme_stylebox_override("pressed", csp)
	if cta_label != null:
		cta_label.add_theme_color_override("font_color", t.cta_text)


func _build_gradient(stops: PackedColorArray) -> Gradient:
	var g := Gradient.new()
	g.colors = stops
	if stops.size() == 2:
		g.offsets = PackedFloat32Array([0.0, 1.0])
	elif stops.size() == 3:
		g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	return g
# ---------------------------------------------------------------------------
# NỘI DUNG CHỮ
# ---------------------------------------------------------------------------

func _apply_texts(data: EventData) -> void:
	if chip_label != null:
		chip_label.text = tr(str(data.chip_key))
		if theme_chip != null:
			theme_chip.size.x = maxf(chip_label.get_minimum_size().x + 19.0, 40.0)
	if title_1 != null:
		title_1.text = tr(str(data.title_key_1))
	if title_2 != null:
		title_2.text = tr(str(data.title_key_2))
	if sub_1 != null:
		sub_1.text = tr(str(data.sub_key_1))
	if sub_2 != null:
		sub_2.text = tr(str(data.sub_key_2))
	if cta_label != null:
		cta_label.text = tr(str(data.cta_key))
	# Phần thưởng (tối đa 2)
	var has_rewards := data.rewards.size() > 0
	_apply_reward(data.rewards.size() > 0, data.rewards[0] if data.rewards.size() > 0 else null,
		reward_1_icon, reward_1_label)
	_apply_reward(data.rewards.size() > 1, data.rewards[1] if data.rewards.size() > 1 else null,
		reward_2_icon, reward_2_label)
	#if progress_panel != null:
		#if not has_rewards:
			#progress_panel.offset_bottom = progress_panel.offset_top + 26.0
			#if cta_button != null:
				#cta_button.offset_top = 205.0
				#cta_button.offset_bottom = 229.0
		#else:
			#progress_panel.offset_bottom = progress_panel.offset_top + 44.0
			#if cta_button != null:
				#cta_button.offset_top = 221.0
				#cta_button.offset_bottom = 245.0



func _apply_reward(show_reward: bool, reward: EventReward, icon: Control, lbl: Label) -> void:
	if lbl == null:
		return
	lbl.get_parent().visible = show_reward
	if reward == null:
		return
	if not reward.label_key.is_empty():
		lbl.text = tr(str(reward.label_key))
	var icon_rect := icon as TextureRect
	if icon_rect != null:
		var path := str(REWARD_ICONS.get(reward.kind, ""))
		if not path.is_empty():
			icon_rect.texture = load(path) as Texture2D


# ---------------------------------------------------------------------------
# TIẾN ĐỘ
# ---------------------------------------------------------------------------

func _refresh_progress() -> void:
	if _event_data == null:
		return
	var em := _get_event_manager()
	if em == null:
		return
	var prog: Dictionary = em.get_progress(_event_id)
	if prog.is_empty():
		return
	var done: int = prog.get("done", 0)
	var total: int = prog.get("total", 1)
	var unit: StringName = prog.get("unit_key", &"STR_EVENT_UNIT_LEVELS")
	var completed: bool = prog.get("completed", false)
	var claimed: bool = prog.get("claimed", false)
	# Trạng thái CTA
	if cta_label != null:
		if claimed:
			cta_label.text = tr("STR_EVENT_CTA_CLAIMED")
			if cta_button != null:
				cta_button.disabled = true
		elif completed:
			cta_label.text = tr("STR_EVENT_CTA_CLAIM")
		else:
			cta_label.text = tr(str(_event_data.cta_key))
	# Overlay mờ khi đã nhận quà
	if completed_overlay != null:
		completed_overlay.visible = claimed


# ---------------------------------------------------------------------------
# ĐẾM NGƯỢC
# ---------------------------------------------------------------------------

func _refresh_timer() -> void:
	if _event_data == null or timer_label == null:
		return
	if _event_data.type == EventData.Type.DAILY:
		# Daily: hiển thị giờ còn lại đến 00:00
		var now := Time.get_datetime_dict_from_system()
		var h: int = 23 - int(now.get("hour", 0))
		var m: int = 59 - int(now.get("minute", 0))
		var remaining_secs := h * 3600 + m * 60
		if remaining_secs < 3600:
			timer_label.text = tr("STR_EVENT_TIMER_MINUTES").format([ceili(float(remaining_secs) / 60.0)])
		else:
			timer_label.text = tr("STR_EVENT_TIMER_HOURS").format([h + 1])
		return
	var em := _get_event_manager()
	if em == null:
		return
	if _preview_mode and not _event_data.is_active_now(int(em.call("now_utc"))):
		if timer_chip != null:
			timer_chip.hide()
		return
	if timer_chip != null:
		timer_chip.show()
	var secs: int = em.seconds_left(_event_id)
	if secs <= 0:
		if _preview_mode:
			if timer_chip != null:
				timer_chip.hide()
			if timer_node != null:
				timer_node.stop()
			return
		# Hết hạn — phát signal và làm mờ thẻ
		modulate = Color(1, 1, 1, 0.4)
		if timer_node != null:
			timer_node.stop()
		var em_expired := _get_event_manager()
		if em_expired != null:
			em_expired.event_expired.emit(_event_id)
		return
	if secs >= 172800: # >= 48h
		var days := secs / 86400
		timer_label.text = tr("STR_EVENT_TIMER_DAYS").format([days])
	elif secs >= 3600: # >= 1h
		var hours := secs / 3600
		timer_label.text = tr("STR_EVENT_TIMER_HOURS").format([hours])
	else:
		var mins := ceili(float(secs) / 60.0)
		timer_label.text = tr("STR_EVENT_TIMER_MINUTES").format([mins])


func _on_timer_tick() -> void:
	_refresh_timer()
	_refresh_progress()


# ---------------------------------------------------------------------------
# INPUT
# ---------------------------------------------------------------------------

func _on_cta_pressed() -> void:
	if _event_data == null:
		return
	var em := _get_event_manager()
	var prog: Dictionary = em.get_progress(_event_id) if em != null else {}
	var completed: bool = prog.get("completed", false)
	var claimed: bool = prog.get("claimed", false)
	if claimed:
		return
	if completed and em != null:
		em.claim_reward(_event_id)
		_refresh_progress()
		return
	card_pressed.emit(_event_id)


func _on_card_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_card_press_active = cta_button == null or not cta_button.get_global_rect().has_point(mb.global_position)
			#_card_press_position = mb.global_position
			return
		if not _card_press_active:
			return
		_card_press_active = false
		if _card_press_position.distance_to(mb.global_position) < CARD_CLICK_DRAG_THRESHOLD:
			card_pressed.emit(_event_id)


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

func _get_event_manager() -> Node:
	return get_node_or_null("/root/EventManager")
