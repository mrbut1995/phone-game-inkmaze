class_name WinningDailyPopup
extends BasePopup
## ============================================================================
## Popup: Kết quả ván DAILY (nodes/popups/winning_daily.tscn)
##
## Khác popup thắng thường (winning.tscn):
## - KHÔNG có nút "MÀN KẾ TIẾP" — thay bằng nút "VỀ DAILY" (quay lại màn Daily).
## - Thưởng hiển thị bằng XU (không còn Sao).
## - Con dấu ghi số NHIỆM VỤ đã xong trong ngày (x/4) + tổng Xu kiếm được trong ngày.
##
## Dữ liệu GameController truyền qua open({...}):
##   daily_day, daily_variant ("classic"/"special"), daily_mode_id,
##   daily_coins (Xu ván này), daily_day_coins, daily_day_reward_max,
##   daily_missions_done, daily_missions_total, time, steps_used, steps_max, wall_hits
## ============================================================================

signal replay_requested
signal daily_requested

@onready var label_subtitle: Label = piece("Subtitle")
@onready var value_time: Label = piece("StatValue1")
@onready var value_steps: Label = piece("StatValue2")
@onready var value_walls: Label = piece("StatValue3")
@onready var coin_icon: TextureRect = piece("CoinArea/CoinIcon")
@onready var value_coins: Label = piece("CoinArea/CoinValue")
@onready var label_total: Label = piece("TotalLabel")
@onready var value_total: Label = piece("TotalValue")


func _on_open() -> void:
	if data.is_empty():
		return

	label_subtitle.text = tr("STR_DAILY_WIN_SUBTITLE").format([
		int(data.get("daily_day", 1)),
		_days_in_month(),
		_maze_label(),
	])

	var seconds := float(data.get("time", 0.0))
	value_time.text = "%02d:%02ds" % [int(seconds) / 60, int(seconds) % 60]

	var used := int(data.get("steps_used", 0))
	var max_steps := int(data.get("steps_max", 0))
	value_steps.text = tr("STR_STEPS_LEFT_FORMAT").format([used, max_steps, maxi(max_steps - used, 0)])

	var hits := int(data.get("wall_hits", 0))
	value_walls.text = tr("STR_WALL_HITS_FORMAT").format([hits, tr("STR_PERFECT_TAG")]) if hits == 0 \
		else tr("STR_WALL_HITS_FORMAT").format([hits, ""]).strip_edges()
	value_walls.theme_type_variation = &"PopupStatValueGood" if hits == 0 else &"PopupStatValueBad"

	# Xu kiếm được trong VÁN NÀY (to, cạnh icon đồng xu)
	if value_coins != null:
		value_coins.text = tr("STR_DAILY_REWARD_COINS").format([int(data.get("daily_coins", 0))])

	# Tổng Xu kiếm được trong NGÀY (bao gồm các ván trước)
	if label_total != null:
		label_total.text = tr("STR_DAILY_WIN_TOTAL_TODAY")
	if value_total != null:
		value_total.text = tr("STR_DAILY_COINS_TOTAL").format([
			int(data.get("daily_day_coins", 0)),
			int(data.get("daily_day_reward_max", 0)),
		])

	_fill_stamp()
	bind_button("Panel/Content/ReplayBtn", _on_replay_pressed)
	bind_button("Panel/Content/DailyBtn", _on_daily_pressed)
	# Gán chữ cho nút bằng code (rõ ràng hơn auto_translate, test đọc được chuỗi đã dịch)
	var daily_btn := piece("DailyBtn") as TextureButton
	if daily_btn != null:
		var daily_label := daily_btn.get_node_or_null("Label") as Label
		if daily_label != null:
			daily_label.text = TranslationServer.translate("STR_BTN_BACK_DAILY")

	_pop_coin()


## Nhãn mê cung của ván vừa thắng: "MAZE THƯỜNG" hoặc tên mode đặc biệt của ngày
func _maze_label() -> String:
	if str(data.get("daily_variant", "")) == "classic":
		return tr("STR_DAILY_WIN_CLASSIC")
	var mode_id := str(data.get("daily_mode_id", ""))
	if mode_id.is_empty():
		return str(data.get("daily_mode_name", ""))
	return tr("STR_MODE_%s" % mode_id.to_upper())


func _days_in_month() -> int:
	var now := Time.get_date_dict_from_system()
	return DailyCalendar.days_in_month(int(now.get("year", 2026)), int(now.get("month", 1)))


## Con dấu đỏ: "n / 4 NHIỆM VỤ" + "+Xu hôm nay"
func _fill_stamp() -> void:
	var title := piece("Stamp/StampTitle") as Label
	if title != null:
		title.text = tr("STR_DAILY_WIN_STAMP_TITLE").format([
			int(data.get("daily_missions_done", 0)),
			int(data.get("daily_missions_total", 4)),
		])
	var sub := piece("Stamp/StampSub") as Label
	if sub != null:
		sub.text = tr("STR_DAILY_WIN_STAMP_SUB").format([int(data.get("daily_day_coins", 0))])


## Đồng xu nảy nhẹ khi popup mở (thay cho chuỗi 3 ngôi sao của popup thường)
func _pop_coin() -> void:
	if coin_icon == null or DisplayServer.get_name() == "headless":
		return
	coin_icon.pivot_offset = coin_icon.size * 0.5
	coin_icon.scale = Vector2.ONE * 0.5
	var tw := create_tween()
	tw.tween_interval(0.22)
	tw.tween_property(coin_icon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: Sfx.play(Sfx.STAR_POP))


func _on_replay_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	replay_requested.emit()
	close()


func _on_daily_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	daily_requested.emit()
	close()
