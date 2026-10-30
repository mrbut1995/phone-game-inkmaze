class_name DailyScene
extends BaseScene
## ============================================================================
## View Controller: Màn hình Thử thách hằng ngày (scenes/daily.tscn)
##
## Bố cục dọc (bản D "Đường mốc"): TopBar · banner tiêu đề · DẢI TUẦN (+ nút mở lịch tháng) ·
## ĐƯỜNG PHẦN THƯỞNG (sao tổng → 4 rương) · 2 thẻ hành động (CHƠI / THỬ THÁCH).
## Bố cục ngang giữ bản cũ: thanh Sao + lịch tháng luôn hiện (cùng bộ `@export` của DailyLayout).
##
## Mô hình Sao (v2.28):
##   · CHƠI      — 1 màn maze thường, mỗi NHIỆM VỤ xong = 1 Sao (tối đa 3)
##   · THỬ THÁCH — 1 maze luật Special, thắng = +3 Sao
##   ⇒ tối đa 6 Sao/ngày; Sao tích luỹ theo tháng để mở MỐC THƯỞNG
##     (`DailyManager.MILESTONES`: Xu + lượt dùng công cụ).
##
## Mọi số đo/bố cục nằm trong SCENE (`scenes/layout/<hướng>/daily.tscn` +
## `nodes/daily/*.tscn`); script chỉ đọc/ghi dữ liệu qua `@export` của layout.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
## Id "phần thưởng" gửi cho AdsManager khi mở khoá ngày bỏ lỡ bằng quảng cáo
const ADS_REWARD_ID := "daily_unlock"
## Thẻ mốc thưởng (instantiate cho MỌI mốc trong `DailyManager.MILESTONES`)
@export var MILESTONE_CHIP: PackedScene = preload("res://nodes/daily/milestone_chip.tscn")
## Bong bóng thông tin phần thưởng (hiện khi NHẤN GIỮ chip mốc)
@export var REWARD_TIP: PackedScene = preload("res://nodes/daily/reward_tip.tscn")
## Hiệu ứng trang trí thanh Sao (đầu thanh sáng + dải sáng quét)
@export var STAR_BAR_FX: PackedScene = preload("res://nodes/daily/star_bar_fx.tscn")

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node) và đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/daily.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn.
var layout: DailyLayout = null

var _chips: Array[DailyMilestoneChip] = []
var _tip: DailyRewardTip = null
var _daily: Node = null
## Đang chờ quảng cáo: true = sau khi xem xong vào THỬ THÁCH, false = vào CHƠI
var _ad_challenge_pending := false
## Ngày đang chọn (mặc định hôm nay). Bấm ngày khác trên lịch = xem/ chơi ngày đó.
var _selected_day := 1
## Ván Daily VỪA THẮNG (đọc 1 lần từ GameManager) + trạng thái hiệu ứng Sao bay.
## Trong lúc `_celebrating`, thanh Sao/chip mốc hiện số Sao CŨ (`_hold_stars` = tổng tháng trước ván)
## cho tới khi sao bay tới nơi — nếu không thanh sẽ "nhảy" tới số mới trước cả khi sao bay.
var _celebrate_info: Dictionary = {}
var _celebrating := false
var _hold_stars := 0


func _ready() -> void:
	_daily = Svc.daily()
	_selected_day = _today()
	_take_celebrate_info()

	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)

	_build_milestones()
	_refresh()
	_layout_stage.call_deferred()
	_celebrate_daily_win.call_deferred()
	var vp := get_viewport()
	if vp != null and not vp.size_changed.is_connected(_layout_stage):
		vp.size_changed.connect(_layout_stage)


## Đọc 1 LẦN trạng thái "vừa thắng ván Daily" từ GameManager (phải gọi TRƯỚC `_refresh()` đầu tiên
## để thanh Sao hiện số cũ). `gained` > 0 ⇒ chạy hiệu ứng Sao bay.
func _take_celebrate_info() -> void:
	_celebrate_info = {}
	_celebrating = false
	var gm: Node = Svc.game()
	if gm == null or not gm.has_method("take_daily_celebrate"):
		return
	_celebrate_info = gm.call("take_daily_celebrate")
	var gained := int(_celebrate_info.get("gained", 0))
	if gained > 0:
		_hold_stars = maxi(_month_stars() - gained, 0)
		_celebrating = true


## Hiệu ứng "vừa hoàn thành ván Daily": ĐÚNG thẻ vừa chơi (CHƠI hoặc THỬ THÁCH) nảy các sao đã
## đạt, rồi các sao MỚI bay lên Sao lớn trên thanh Sao (animation khai trong scene:
## `action_card.tscn` `celebrate_1..3`, layout `VfxAnim/fly` + `ArriveAnim/arrive`).
func _celebrate_daily_win() -> void:
	var info := _celebrate_info
	_celebrate_info = {}
	if info.is_empty():
		return
	var day := int(info.get("day", 0))
	if day > 0 and day != _selected_day:
		select_day(day)
	var gained := int(info.get("gained", 0))
	var is_challenge := bool(info.get("challenge", false))
	# Chờ EnterAnim của layout chạy xong rồi mới chạy hiệu ứng (tránh chồng hiệu ứng)
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree() or layout == null:
		return
	var card := layout.challenge_card if is_challenge else layout.play_card
	var flying := false
	if card != null and _celebrating:
		# Lấy toạ độ sao TRƯỚC khi thẻ nảy sao (sao bay xuất phát đúng chỗ ngôi sao vừa đạt)
		flying = layout.play_star_gain(card, gained, _hold_stars, _hold_stars + gained)
	if card != null:
		card.play_celebrate()
	if not flying:
		_end_celebrate()


## Sao bay xong + thanh Sao chạy đủ (signal của DailyLayout, dây nối trong `_wire_buttons`)
func _on_star_gain_finished() -> void:
	_end_celebrate(true)


## Kết thúc hiệu ứng: hiện số liệu thật; `play_fx` = bật hiệu ứng cho chip mốc VỪA ĐẠT
func _end_celebrate(play_fx := false) -> void:
	if not _celebrating:
		return
	var before := _hold_stars
	_celebrating = false
	_refresh()
	if not play_fx:
		return
	var now := _month_stars()
	for chip in _chips:
		if chip.threshold > before and chip.threshold <= now:
			chip.play_unlock()


## Đặt khung thiết kế (`Panel/Stage`) vào giữa canvas và PHÓNG/THU ĐỀU theo canvas.
## Nhờ vậy bố cục giữ ĐÚNG tỉ lệ mockup ở mọi cỡ màn hình (không kéo méo art).
func _layout_stage() -> void:
	if layout == null or not is_inside_tree():
		return
	var stage := layout.get_node_or_null("Panel/Stage") as Control
	if stage == null:
		return
	var design := stage.custom_minimum_size
	if design.x <= 0.0 or design.y <= 0.0:
		design = stage.size
	var canvas := get_viewport_rect().size
	if design.x <= 0.0 or design.y <= 0.0 or canvas.x <= 0.0:
		return
	var factor := minf(canvas.x / design.x, canvas.y / design.y)
	stage.scale = Vector2(factor, factor)
	stage.position = ((canvas - design * factor) * 0.5).floor()
	# Stage đổi cỡ ⇒ vị trí chip đổi ⇒ đo lại để thanh Sao vẫn khớp các chip
	_hide_tip(true)
	layout.refresh_bar.call_deferred()


## Phát lại EnterAnim mỗi khi màn được kích hoạt (quay lại từ màn khác)
func _on_active() -> void:
	UIAnim.play_layout_anim(active_layout(), "EnterAnim", &"enter")


## Gắn node của layout đang hiển thị (bản ngang đổi cấu trúc cột nên tra theo TÊN)
func _bind_refs() -> void:
	layout = active_layout() as DailyLayout
	if layout == null:
		push_warning("daily: bố cục chưa gắn DailyLayout — thiếu binding trong scenes/layout/<hướng>/daily.tscn")


## Nối signal + hiệu ứng (dây NÚT khai trong `scenes/daily.tscn` — guard chỉ nối lại nếu mất dây)
func _wire_buttons() -> void:
	ensure_signal(layout, &"star_gain_finished", &"_on_star_gain_finished")
	ensure_signal(layout.btn_back, &"pressed", &"_on_back_pressed")
	ensure_signal(layout.calendar, &"day_selected", &"_on_day_selected")
	ensure_signal(layout.week_strip, &"day_selected", &"_on_day_selected")
	ensure_signal(layout.week_strip, &"month_requested", &"_on_month_requested")
	ensure_signal(layout.play_card, &"pressed", &"_on_play_pressed")
	ensure_signal(layout.challenge_card, &"pressed", &"_on_challenge_pressed")
	if layout.btn_back != null and not layout.btn_back.has_meta("bounce_attached"):
		layout.btn_back.set_meta("bounce_attached", true)
		UIAnim.attach_press_down(layout.btn_back)
	if layout.play_card != null and not layout.play_card.has_meta("bounce_attached"):
		layout.play_card.set_meta("bounce_attached", true)
		# "Thở" nhẹ để hút mắt vào thẻ CHƠI — animation "pulse" của layout (PulseAnim)
		if not UIAnim.play_layout_anim(layout, "PulseAnim", &"pulse", layout.play_card):
			UIAnim.play_pulse(layout.play_card, 1.02, 2.0)
	if _daily != null and _daily.has_signal("daily_changed") \
			and not _daily.is_connected("daily_changed", _refresh):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		_daily.connect("daily_changed", _refresh)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh


## Cập nhật số Xu trên ví (ví dùng chung `ArchivementManager.coins` với Main Screen)
func _refresh_wallet() -> void:
	if layout != null and layout.coin_chip != null:
		layout.coin_chip.set_value(Shop.coins())


## Xoay màn hình: layout khác cấu trúc ⇒ gắn lại node + dựng lại chip mốc
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	if _celebrating:
		# Đổi hướng giữa lúc sao đang bay: bố cục cũ không còn hiển thị ⇒ dừng hiệu ứng, hiện số liệu thật
		if layout != null:
			layout.stop_star_gain()
		_celebrating = false
	_hide_tip(true)
	_tip = null
	if layout != null:
		layout.clear_bar_fx()
	_bind_refs()
	_wire_buttons()
	_build_milestones()
	_refresh()
	_layout_stage()


## Dựng lại các chip MỐC THƯỞNG vào `milestones_host` của layout đang hiển thị
func _build_milestones() -> void:
	_chips.clear()
	_ensure_bar_fx()
	var host := layout.milestones_host
	if host == null:
		return
	for child in host.get_children():
		child.queue_free()
	if _daily == null or not _daily.has_method("milestone_defs"):
		return
	var defs: Array = _daily.call("milestone_defs")
	for i in defs.size():
		var def: Dictionary = defs[i]
		var scene: PackedScene = layout.chip_scene if layout.chip_scene != null else MILESTONE_CHIP
		var chip: DailyMilestoneChip = scene.instantiate()
		host.add_child(chip)
		chip.claim_requested.connect(_on_milestone_claim)
		chip.hold_started.connect(_on_chip_hold_started)
		chip.hold_ended.connect(_hide_tip)
		_chips.append(chip)
	var thresholds: Array = []
	for def in defs:
		thresholds.append(int((def as Dictionary).get("stars", 0)))
	layout.set_milestone_thresholds(thresholds)


## Gắn hiệu ứng thanh Sao vào layout đang hiển thị (1 lần cho mỗi layout)
func _ensure_bar_fx() -> void:
	if layout == null or STAR_BAR_FX == null or layout.bar_stars == null or layout.has_bar_fx():
		return
	var fx := STAR_BAR_FX.instantiate() as StarBarFx
	if fx != null:
		layout.attach_bar_fx(fx)


## Nhấn giữ chip ⇒ hiện bóng thông tin phần thưởng của mốc đó
func _on_chip_hold_started(chip: DailyMilestoneChip) -> void:
	if _daily == null or layout == null or chip == null:
		return
	var stage := layout.get_node_or_null("Panel/Stage") as Control
	if stage == null or not _ensure_tip(stage):
		return
	var def: Dictionary = _daily.call("milestone_def", chip.threshold) if _daily.has_method("milestone_def") else {}
	if def.is_empty():
		def = {"stars": chip.threshold}
	var shown := _hold_stars if _celebrating else _month_stars()
	var claimed := bool(_daily.call("is_milestone_claimed", chip.threshold))
	_tip.popup_at(chip, def, shown, claimed, stage, chip.ring)


func _ensure_tip(stage: Control) -> bool:
	if _tip != null and is_instance_valid(_tip) and _tip.get_parent() == stage:
		stage.move_child(_tip, stage.get_child_count() - 1)
		return true
	if REWARD_TIP == null:
		return false
	_tip = REWARD_TIP.instantiate() as DailyRewardTip
	if _tip == null:
		return false
	stage.add_child(_tip)
	return true


func _hide_tip(immediately := false) -> void:
	if _tip == null or not is_instance_valid(_tip):
		return
	if immediately:
		_tip.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)
		_tip.dismiss()
	else:
		_tip.dismiss()


# --- API cho test -----------------------------------------------------------

## Ngày đang chọn trên lịch
func selected_day() -> int:
	return _selected_day


## Đổi ngày đang chọn (không nhảy vào màn chơi)
func select_day(day: int) -> void:
	if day <= 0:
		return
	_selected_day = day
	_refresh()


## Số chip mốc thưởng đang hiển thị
func milestone_count() -> int:
	return _chips.size()


func milestone_chip_at(index: int) -> DailyMilestoneChip:
	if index < 0 or index >= _chips.size():
		return null
	return _chips[index]


## Thẻ CHƠI của ngày đang chọn (test đọc trạng thái Sao)
func play_card() -> DailyActionCard:
	return layout.play_card


## Thẻ THỬ THÁCH của ngày đang chọn
func challenge_card() -> DailyActionCard:
	return layout.challenge_card


# ---------------------------------------------------------------------------
# Dữ liệu
# ---------------------------------------------------------------------------
## Cập nhật toàn bộ nội dung theo ngày đang chọn
func _refresh() -> void:
	if _daily == null or layout == null:
		return
	var day := _selected_day
	var month_stars := _month_stars()
	# Đang chờ sao bay: hiện số Sao CŨ (trước ván); xong hiệu ứng mới hiện số thật
	var shown_stars := _hold_stars if _celebrating else month_stars
	var goal := _month_goal()

	# Trong lúc sao bay, số/thanh Sao do DailyLayout điều khiển từng bước — không ghi đè
	if not layout.is_star_gain_playing():
		layout.show_stars(float(mini(shown_stars, maxi(goal, 1))))
	if layout.lbl_reset != null:
		layout.lbl_reset.text = tr("STR_DAILY_RESET_IN").format([_reset_countdown()])

	_refresh_wallet()
	_refresh_cards(day)
	_refresh_milestones(shown_stars)
	_refresh_road_hint(shown_stars)

	# Dải tuần (bản đường mốc): 7 ngày của tuần chứa ngày đang chọn
	if layout.week_strip != null:
		layout.week_strip.rebuild(_selected_day)

	# Ô ngày trên lịch đổi viền trạng thái ("ĐÃ MỞ") + vòng sáng ô ĐANG CHỌN
	if layout.calendar != null:
		layout.calendar.rebuild()
		layout.calendar.set_selected_day(_selected_day)


## Nội dung 2 thẻ hành động: CHƠI (3 Sao theo nhiệm vụ) + THỬ THÁCH (3 Sao khi thắng)
func _refresh_cards(day: int) -> void:
	var play_stars := _day_play_stars(day)
	var challenge_stars := _day_challenge_stars(day)
	var info := _challenge_info(day)
	var playable := _is_day_playable(day)

	if layout.play_card != null:
		var sub := tr("STR_DAILY_PLAY_SUB_TODAY").format([day])
		var cta := "STR_DAILY_CARD_PLAY_BTN"
		if play_stars > 0:
			cta = "STR_DAILY_CARD_PLAY_BTN_AGAIN"
		layout.play_card.setup("STR_DAILY_CARD_PLAY", sub, cta, false, play_stars)
		layout.play_card.set_meta("locked", not playable)

	if layout.challenge_card != null:
		var rule := str(info.get("title", ""))
		var cta := "STR_DAILY_CARD_CHALLENGE_BTN"
		if challenge_stars > 0:
			cta = "STR_DAILY_CARD_CHALLENGE_BTN_AGAIN"
		layout.challenge_card.setup("STR_DAILY_CARD_CHALLENGE", rule, cta, true, challenge_stars)
		layout.challenge_card.set_meta("locked", not playable)


## Cập nhật trạng thái 4 chip mốc thưởng theo tổng Sao tháng
func _refresh_milestones(month_stars: int) -> void:
	var defs: Array = _daily.call("milestone_defs") if _daily != null else []
	for i in _chips.size():
		if i >= defs.size():
			continue
		var def: Dictionary = defs[i]
		var threshold := int(def.get("stars", 0))
		var claimed := bool(_daily.call("is_milestone_claimed", threshold))
		_chips[i].setup(def, month_stars, claimed)


## Dòng gợi ý dưới sao tổng: còn bao nhiêu Sao tới rương kế tiếp (hoặc đã mở hết)
func _refresh_road_hint(shown_stars: int) -> void:
	if layout.lbl_road_hint == null or _daily == null or not _daily.has_method("milestone_defs"):
		return
	var text := tr("STR_DAILY_ROAD_ALL")
	for def in _daily.call("milestone_defs"):
		var threshold := int((def as Dictionary).get("stars", 0))
		if threshold > shown_stars:
			text = tr("STR_DAILY_ROAD_NEXT").format([threshold - shown_stars, threshold])
			break
	layout.set_road_hint(text)


## Đồng hồ đếm ngược tới 00:00 (mốc làm mới ngày) dạng HH:MM:SS
func _reset_countdown() -> String:
	var t := Time.get_time_dict_from_system()
	var left := 24 * 3600 - (int(t.get("hour", 0)) * 3600 + int(t.get("minute", 0)) * 60
		+ int(t.get("second", 0)))
	return "%02d:%02d:%02d" % [left / 3600, (left / 60) % 60, left % 60]


# --- Tiện ích đọc dữ liệu DailyManager --------------------------------------

func _today() -> int:
	return int(_daily.call("get_today")) if _daily != null else 1


func _month_stars() -> int:
	return int(_daily.call("get_month_stars")) if _daily != null else 0


func _month_goal() -> int:
	return int(_daily.call("month_star_goal")) if _daily != null else 6


func _day_play_stars(day: int) -> int:
	return int(_daily.call("get_day_play_stars", day)) if _daily != null else 0


func _day_challenge_stars(day: int) -> int:
	return int(_daily.call("get_day_challenge_stars", day)) if _daily != null else 0


func _challenge_info(day: int) -> Dictionary:
	if _daily != null and _daily.has_method("get_daily_challenge_info"):
		return _daily.call("get_daily_challenge_info", day)
	return {}


## Ngày chơi được: hôm nay, ngày đã có tiến độ, hoặc ngày đã mở khoá (bằng quảng cáo)
func _is_day_playable(day: int) -> bool:
	return day == _today() or _day_play_stars(day) > 0 or _day_challenge_stars(day) > 0 \
		or _is_day_unlocked(day)


## Ngày đã được trả Xu mở khoá
func _is_day_unlocked(day: int) -> bool:
	if _daily != null and _daily.has_method("is_day_unlocked"):
		return bool(_daily.call("is_day_unlocked", day))
	return false


func _streak() -> int:
	return int(_daily.call("get_streak")) if _daily != null else 0


func _current_year() -> int:
	return int(Time.get_date_dict_from_system().get("year", 2026))


func _current_month() -> int:
	return int(Time.get_date_dict_from_system().get("month", 1))


# --- Sự kiện ----------------------------------------------------------------

## Timer 1 giây của scene → cập nhật đồng hồ đếm ngược làm mới
func _on_reset_timer_timeout() -> void:
	if layout != null and layout.lbl_reset != null:
		layout.lbl_reset.text = tr("STR_DAILY_RESET_IN").format([_reset_countdown()])


## Bấm 1 ngày trên lịch: CHỈ đổi ngày đang chọn (không nhảy thẳng vào màn chơi)
func _on_day_selected(day: int) -> void:
	select_day(day)
	# Chọn ngày trong bảng lịch tháng xong thì đóng bảng
	if layout != null:
		layout.close_month_sheet()


## Bấm nút lịch ở dải tuần: mở bảng lịch tháng
func _on_month_requested() -> void:
	if layout != null:
		layout.open_month_sheet()


## Thẻ CHƠI: vào màn maze thường của ngày
func _on_play_pressed() -> void:
	_enter_day(false)


## Thẻ THỬ THÁCH: vào maze luật Special của ngày
func _on_challenge_pressed() -> void:
	_enter_day(true)


## Vào 1 hoạt động của ngày đang chọn.
## Ngày BỎ LỠ (đã qua, chưa chơi, chưa mở khoá): xem QUẢNG CÁO (AdsManager) rồi mới vào —
## KHÔNG còn trả Xu. Ngày tương lai thì chưa mở được.
func _enter_day(is_challenge: bool) -> void:
	var day := _selected_day
	if _is_day_playable(day):
		_start_day(day, is_challenge)
		return
	if day < _today():
		_request_ad_then_play(is_challenge)
		return
	Sfx.play(Sfx.WALL_HIT)


## Chạy quảng cáo thưởng để MỞ KHOÁ ngày bỏ lỡ; xem xong mới vào màn.
## AdsManager hiện là PLACEHOLDER: khi chưa gắn SDK nó giả lập "xem xong" ngay.
func _request_ad_then_play(is_challenge: bool) -> void:
	var ads: Node = Svc.ads()
	if ads == null or not ads.has_method("show_rewarded"):
		# Không có hệ thống quảng cáo (bản test): mở khoá luôn để không chặn người chơi
		_grant_day_unlock()
		_start_day(_selected_day, is_challenge)
		return
	if not ads.is_connected("rewarded_completed", _on_ad_rewarded):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		ads.connect("rewarded_completed", _on_ad_rewarded)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
	_ad_challenge_pending = is_challenge
	if not bool(ads.call("show_rewarded", ADS_REWARD_ID)):
		_ad_challenge_pending = false
		Sfx.play(Sfx.WALL_HIT)


## Quảng cáo xong → mở khoá ngày (MIỄN PHÍ) rồi vào đúng hoạt động vừa bấm
func _on_ad_rewarded(reward_id: String) -> void:
	if reward_id != ADS_REWARD_ID:
		return
	var is_challenge := _ad_challenge_pending
	_ad_challenge_pending = false
	_grant_day_unlock()
	_start_day(_selected_day, is_challenge)


## Mở khoá ngày đang chọn (không trừ Xu) — dùng sau khi xem quảng cáo
func _grant_day_unlock() -> void:
	if _daily == null or not _daily.has_method("set_day_unlocked"):
		return
	_daily.call("set_day_unlocked", _selected_day, true)
	Sfx.play(Sfx.STAMP_IMPACT)


func _start_day(day: int, is_challenge: bool) -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var gm: Node = Svc.game()
	var method := "start_daily_challenge" if is_challenge else "start_daily_play"
	if gm != null and gm.has_method(method):
		gm.call(method, day)
	else:
		Nav.goto_game()


## Bấm NHẬN thưởng một mốc Sao → mở popup nhỏ báo phần thưởng vừa nhận
func _on_milestone_claim(threshold: int) -> void:
	if _daily == null or not _daily.has_method("claim_milestone"):
		return
	if bool(_daily.call("claim_milestone", threshold)):
		Sfx.play(Sfx.STAMP_IMPACT)
		_show_milestone_reward(threshold)
		_refresh.call_deferred()
	else:
		Sfx.play(Sfx.WALL_HIT)


## Popup nhỏ "đã nhận thưởng mốc" (nodes/popups/daily_milestone.tscn)
func _show_milestone_reward(threshold: int) -> void:
	var def: Dictionary = {}
	if _daily != null and _daily.has_method("milestone_def"):
		def = _daily.call("milestone_def", threshold)
	Popups.open(Popups.DAILY_MILESTONE, {"stars": threshold, "reward": def})


func _on_back_pressed() -> void:
	# Đang mở bảng lịch tháng: Back chỉ đóng bảng
	if layout != null and layout.is_month_sheet_open():
		layout.close_month_sheet()
		return
	# SFX: gõ thẻ giấy cho nút phụ (Back)
	Sfx.play(Sfx.BTN_WOOD_TAP)
	var gm: Node = Svc.game()
	if gm != null:
		gm.go_to_main_menu()
	else:
		Nav.goto_main()
