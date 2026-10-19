class_name EventCard
extends EventCardBase
## ============================================================================
## Node: EventCard — Thẻ SỰ KIỆN THẬT trên carousel Main Screen
## (nodes/main/event_card.tscn). Thẻ Thử thách hằng ngày tách riêng: `DailyCard`.
##
## Cách dùng:
##   var card = preload("res://nodes/main/event_card.tscn").instantiate()
##   add_child(card)
##   card.setup(event_data)
##
## Thẻ gồm: art nền theme + chip theme + chip đếm ngược + tiêu đề 2 dòng +
## khung tiến độ (2 phần thưởng) + nút CTA.
## ============================================================================

## Node con — bind bằng @onready (không dùng %UniqueName theo §13.10)
@onready var card_lip: Panel = $Content/Background/Lip
@onready var card_frame: Panel = $Content/Background/Frame
@onready var bg_gradient: ColorRect = $Content/Background/ContentMask/BgGradient
@onready var back_art: TextureRect = $Content/Background/ContentMask/BackArt
@onready var front_art: NinePatchRect = $Content/Background/ContentMask/FrontArt
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


func _cta_node() -> BaseButton:
	return cta_button


func _timer_node() -> Timer:
	return timer_node


func _refresh_live() -> void:
	_refresh_timer()
	_refresh_progress()


# ---------------------------------------------------------------------------
# NỘI DUNG
# ---------------------------------------------------------------------------

func _apply_card(data: EventData) -> void:
	_apply_theme(data.theme)
	_apply_texts(data)
	_refresh_progress()
	_refresh_timer()


func _apply_theme(t: EventTheme) -> void:
	if t == null:
		return
	_paint_background(t, bg_gradient, back_art, front_art)
	_paint_card_edges(card_lip, card_frame, t)
	_paint_chip(theme_chip, chip_dot, chip_label, t)
	_paint_chip(timer_chip, null, timer_label, t)
	_paint_title(title_1, t)
	_paint_title(title_2, t)
	if sub_1 != null:
		sub_1.add_theme_color_override("font_color", t.sub_color)
	if sub_2 != null:
		sub_2.add_theme_color_override("font_color", t.sub_color)
	_paint_panel(progress_panel, t)
	if reward_1_label != null:
		reward_1_label.add_theme_color_override("font_color", t.label_color)
	if reward_2_label != null:
		reward_2_label.add_theme_color_override("font_color", t.label_color)
	_paint_cta(cta_button, cta_label, t)


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
	_apply_reward(data.rewards.size() > 0, data.rewards[0] if data.rewards.size() > 0 else null,
		reward_1_icon, reward_1_label)
	_apply_reward(data.rewards.size() > 1, data.rewards[1] if data.rewards.size() > 1 else null,
		reward_2_icon, reward_2_label)


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


# ---------------------------------------------------------------------------
# ĐẾM NGƯỢC
# ---------------------------------------------------------------------------

func _refresh_timer() -> void:
	if _event_data == null or timer_label == null:
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
		em.event_expired.emit(_event_id)
		return
	if secs >= 172800: # >= 48h
		timer_label.text = tr("STR_EVENT_TIMER_DAYS").format([secs / 86400])
	elif secs >= 3600: # >= 1h
		timer_label.text = tr("STR_EVENT_TIMER_HOURS").format([secs / 3600])
	else:
		timer_label.text = tr("STR_EVENT_TIMER_MINUTES").format([ceili(float(secs) / 60.0)])
