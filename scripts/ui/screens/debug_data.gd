class_name DebugData
extends RefCounted
## Truy vấn CHỈ-ĐỌC cho màn Debug (không dựng UI, không ghi trạng thái).
##
## Tách khỏi `debug.gd` để phần "đọc số liệu → chuỗi hiển thị" nằm riêng, không phụ thuộc
## các helper dựng giao diện của màn. Mọi hàm đều an toàn khi manager chưa sẵn sàng (trả "-"/0).


# ---------------------------------------------------------------- Sao Daily

## Sao phần CHƠI của hôm nay (0..3)
static func play_stars_today() -> int:
	var daily := Svc.daily()
	if daily == null:
		return 0
	return int(daily.call("get_day_play_stars", int(daily.call("get_today"))))


## Sao tối đa của phần CHƠI (3)
static func play_stars_max() -> int:
	var daily := Svc.daily()
	if daily == null:
		return 3
	return int(daily.get("PLAY_STARS_MAX"))


## Sao CHƠI + THỬ THÁCH đã đạt của hôm nay (0..6)
static func stars_today() -> int:
	var daily := Svc.daily()
	if daily == null:
		return 0
	return int(daily.call("get_day_stars", int(daily.call("get_today"))))


## Tổng Sao tối đa của một ngày (6 — lấy từ DailyManager)
static func stars_max() -> int:
	var daily := Svc.daily()
	if daily == null:
		return 6
	return int(daily.get("DAY_STARS_MAX"))


## Mốc kế tiếp chưa đạt — "N★ (còn X★)" hoặc "đã đạt hết"
static func next_milestone_text() -> String:
	var daily := Svc.daily()
	if daily == null or not daily.has_method("milestone_defs"):
		return "-"
	var stars := int(daily.call("get_month_stars"))
	for def in daily.call("milestone_defs"):
		var threshold := int((def as Dictionary).get("stars", 0))
		if stars < threshold:
			return "%d★ (còn %d★)" % [threshold, threshold - stars]
	return "đã đạt hết"


## Số mốc đã nhận / tổng số mốc của tháng
static func claimed_milestones_text() -> String:
	var daily := Svc.daily()
	if daily == null or not daily.has_method("milestone_defs"):
		return "-"
	var total := 0
	var claimed := 0
	for def in daily.call("milestone_defs"):
		total += 1
		if bool(daily.call("is_milestone_claimed", int((def as Dictionary).get("stars", 0)))):
			claimed += 1
	return "%d / %d" % [claimed, total]


## Trạng thái ngày HÔM QUA: đã chơi/mở khoá hay còn BỎ LỠ
static func yesterday_state_text() -> String:
	var daily := Svc.daily()
	if daily == null:
		return "-"
	var day := int(daily.call("get_today")) - 1
	if day < 1:
		return "- (hôm nay là ngày 01)"
	if int(daily.call("get_day_stars", day)) > 0 or bool(daily.call("is_day_unlocked", day)):
		return "ngày %d: đã chơi / đã mở khoá" % day
	return "ngày %d: BỎ LỠ (cần quảng cáo)" % day


## Trạng thái AdsManager (placeholder hay đã tắt)
static func ads_state_text() -> String:
	var ads := Svc.ads()
	if ads == null:
		return "không có"
	var ready := false
	if ads.has_method("is_rewarded_ready"):
		ready = bool(ads.call("is_rewarded_ready"))
	return "placeholder BẬT" if ready else "TẮT (show_rewarded trả false)"


# ---------------------------------------------------------------- Tutorial

## Danh sách ID bài tutorial theo đúng thứ tự chạy
static func tutorial_ids() -> Array[String]:
	var ids: Array[String] = []
	for id in TutorialController.TUTORIAL_SCENES:
		ids.append(str(id))
	return ids


## Cờ hoàn thành tutorial (rỗng nếu GameManager chưa sẵn sàng)
static func tutorial_progress() -> Dictionary:
	var gm := Svc.game()
	if gm == null:
		return {}
	var progress: Variant = gm.get("tutorial_progress")
	return progress if progress is Dictionary else {}


## Bài tutorial đã xong chưa
static func tutorial_flag(tutorial_id: String) -> bool:
	return bool(tutorial_progress().get(tutorial_id, false))


## Số bài tutorial đã xong
static func tutorial_done_count() -> int:
	var done := 0
	for id in tutorial_ids():
		if tutorial_flag(id):
			done += 1
	return done
