class_name DailyManagerClass
extends Node
## ============================================================================
## Manager: DailyManager — Thử thách hằng ngày (v2.28 "1 Màn + 1 Thử thách").
##
## MỖI NGÀY có 2 hoạt động, mỗi hoạt động cho tối đa 3 SAO:
##   · CHƠI      — 1 màn maze thường: mỗi NHIỆM VỤ hoàn thành = 1 Sao (như màn thường).
##   · THỬ THÁCH — 1 luật Special xoay vòng: luật này KHÔNG có nhiệm vụ ⇒ thắng = +3 Sao.
## ⇒ Tối đa 6 Sao/ngày. Sao tích luỹ theo THÁNG để mở các MỐC THƯỞNG (xem MILESTONES).
##
## Lưu trữ: `months["YYYY_MM"] = { "days": { <ngày>: {"play": 0..3, "challenge": 0..3} },
##                                 "claimed": [<mốc đã nhận>] }` — sang tháng mới là một khoá mới,
## nên "tháng này được bao nhiêu sao" luôn tính đúng mà không cần reset tay.
## Dữ liệu đi qua SaveManager như mọi tiến trình khác (export_progress / import_progress).
## ============================================================================

signal daily_changed
signal stars_changed(day: int)
## Vừa đạt một mốc thưởng tháng (còn chờ người chơi bấm NHẬN)
signal milestone_unlocked(stars: int)
## Vừa bấm NHẬN thưởng một mốc
signal milestone_claimed(stars: int)
## Vừa được cộng Xu từ mốc thưởng
signal coins_awarded(day: int, amount: int)

const CONFIG_PATH := "user://daily.cfg"
const SECTION := "daily"

## CHƠI: tối đa 3 Sao (1 nhiệm vụ = 1 Sao, giống màn thường)
const PLAY_STARS_MAX := 3
## THỬ THÁCH: luật Special không có nhiệm vụ ⇒ thắng là +3 Sao
const CHALLENGE_STARS_MAX := 3
## Tối đa một ngày
const DAY_STARS_MAX := PLAY_STARS_MAX + CHALLENGE_STARS_MAX
## Xu phải trả để MỞ KHOÁ một ngày đã bỏ lỡ
const UNLOCK_COST := 50

## Mốc thưởng THÁNG — đúng như mockup `daily_challenge.svg` (15★ · 30★ · 45★ · 60★).
## `coins`/`hint`/`undo`/`skip` = số lượng thưởng (0 = không thưởng loại đó).
const MILESTONES: Array[Dictionary] = [
	{"stars": 15, "coins": 100, "hint": 0, "undo": 0, "skip": 0},
	{"stars": 30, "coins": 0, "hint": 2, "undo": 0, "skip": 0},
	{"stars": 45, "coins": 250, "hint": 0, "undo": 2, "skip": 0},
	{"stars": 60, "coins": 500, "hint": 3, "undo": 0, "skip": 0},
]

## "YYYY_MM" -> { "days": { ngày: {"play": int, "challenge": int} }, "claimed": Array[int] }
var months: Dictionary = {}
## Ngày (1..31, thuộc tháng hiện tại) đã trả Xu MỞ KHOÁ
var unlocked_days: Array[int] = []


func _ready() -> void:
	_load_completed()


# ---------------------------------------------------------------------------
# NGÀY / THÁNG
# ---------------------------------------------------------------------------

## Ngày hôm nay theo lịch máy (1..31)
func get_today() -> int:
	return int(Time.get_date_dict_from_system().get("day", 1))


func is_today(day: int) -> bool:
	return day == get_today()


## Khoá tháng hiện tại dạng "YYYY_MM"
func month_key() -> String:
	var now := Time.get_date_dict_from_system()
	return "%04d_%02d" % [int(now.get("year", 2026)), int(now.get("month", 1))]


## Khoá tháng của một năm/tháng bất kỳ (test + debug)
func month_key_of(year: int, month: int) -> String:
	return "%04d_%02d" % [year, month]


## Dữ liệu tháng hiện tại (tạo mới nếu chưa có)
func _month() -> Dictionary:
	return month_entry(month_key())


## Dữ liệu một tháng bất kỳ — tạo rỗng nếu chưa có
func month_entry(key: String) -> Dictionary:
	var entry: Variant = months.get(key, null)
	if not (entry is Dictionary):
		entry = {"days": {}, "claimed": []}
		months[key] = entry
	var dict: Dictionary = entry
	if not (dict.get("days") is Dictionary):
		dict["days"] = {}
	if not (dict.get("claimed") is Array):
		dict["claimed"] = []
	return dict


# ---------------------------------------------------------------------------
# SAO CỦA NGÀY
# ---------------------------------------------------------------------------

## Sao của phần CHƠI trong ngày (0..3)
func get_day_play_stars(day: int) -> int:
	var days: Dictionary = _month()["days"]
	var rec: Variant = days.get(day, null)
	if not (rec is Dictionary):
		return 0
	return clampi(int((rec as Dictionary).get("play", 0)), 0, PLAY_STARS_MAX)


## Sao của phần THỬ THÁCH trong ngày (0 hoặc 3)
func get_day_challenge_stars(day: int) -> int:
	var days: Dictionary = _month()["days"]
	var rec: Variant = days.get(day, null)
	if not (rec is Dictionary):
		return 0
	return clampi(int((rec as Dictionary).get("challenge", 0)), 0, CHALLENGE_STARS_MAX)


## Tổng sao của một ngày (0..6)
func get_day_stars(day: int) -> int:
	return get_day_play_stars(day) + get_day_challenge_stars(day)


## Đã chơi màn CHƠI của ngày chưa (dùng cho streak + trạng thái ô lịch)
func has_played(day: int) -> bool:
	return get_day_play_stars(day) > 0


## Ngày đã hoàn thành TRỌN (đủ 6 sao)
func is_completed(day: int) -> bool:
	return get_day_stars(day) >= DAY_STARS_MAX


## Tổng sao đã tích luỹ trong THÁNG hiện tại
func get_month_stars() -> int:
	var total := 0
	var days: Dictionary = _month()["days"]
	for day in days:
		var rec: Variant = days[day]
		if rec is Dictionary:
			total += clampi(int((rec as Dictionary).get("play", 0)), 0, PLAY_STARS_MAX)
			total += clampi(int((rec as Dictionary).get("challenge", 0)), 0, CHALLENGE_STARS_MAX)
	return total


## Ghi nhận thắng một ván Daily. `stars` = số sao ván này đạt (0..3).
## Chỉ GIỮ MỨC CAO NHẤT — chơi lại không mất sao và không cộng trùng.
## Trả về số Sao THỰC SỰ tăng thêm (0 nếu ván này không tốt hơn lần trước).
func record_daily_win(day: int, is_challenge: bool, stars: int) -> int:
	var gained := _apply_stars(day, is_challenge, stars)
	if gained > 0:
		daily_changed.emit()
		_emit_milestones_reached()
	return gained


## Chốt sao vào dữ liệu tháng (không kiểm mốc) — dùng chung cho đường thi đấu và debug
func _apply_stars(day: int, is_challenge: bool, stars: int) -> int:
	if day <= 0:
		return 0
	var days: Dictionary = _month()["days"]
	var raw: Variant = days.get(day, null)
	var rec: Dictionary = {"play": 0, "challenge": 0}
	if raw is Dictionary:
		rec = raw
	var before := clampi(int(rec.get("play", 0)), 0, PLAY_STARS_MAX) \
		+ clampi(int(rec.get("challenge", 0)), 0, CHALLENGE_STARS_MAX)
	var key := "challenge" if is_challenge else "play"
	var cap := CHALLENGE_STARS_MAX if is_challenge else PLAY_STARS_MAX
	rec[key] = maxi(int(rec.get(key, 0)), clampi(stars, 0, cap))
	days[day] = rec
	_save_completed()
	stars_changed.emit(day)
	return get_day_stars(day) - before


## Báo các MỐC vừa đạt được (chưa nhận) để UI bật hiệu ứng
func _emit_milestones_reached() -> void:
	var total := get_month_stars()
	for def in MILESTONES:
		var threshold := int(def.get("stars", 0))
		if threshold <= total and not is_milestone_claimed(threshold):
			milestone_unlocked.emit(threshold)


# ---------------------------------------------------------------------------
# MỐC THƯỞNG THÁNG
# ---------------------------------------------------------------------------

## Danh sách mốc thưởng (bản sao — UI không sửa được hằng số)
func milestone_defs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for def in MILESTONES:
		out.append((def as Dictionary).duplicate(true))
	return out


## Mốc cao nhất của tháng (đích của thanh tiến độ)
func month_star_goal() -> int:
	if MILESTONES.is_empty():
		return DAY_STARS_MAX
	return int((MILESTONES[MILESTONES.size() - 1] as Dictionary).get("stars", DAY_STARS_MAX))


func is_milestone_claimed(threshold: int) -> bool:
	var claimed: Array = _month()["claimed"]
	return claimed.has(threshold)


## Đủ Sao để nhận mốc này chưa
func can_claim_milestone(threshold: int) -> bool:
	return get_month_stars() >= threshold and not is_milestone_claimed(threshold)


## Nhận thưởng mốc (Xu và/hoặc lượt dùng công cụ). Trả true nếu vừa nhận.
func claim_milestone(threshold: int) -> bool:
	if not can_claim_milestone(threshold):
		return false
	var def := milestone_def(threshold)
	if def.is_empty():
		return false
	var claimed: Array = _month()["claimed"]
	claimed.append(threshold)
	_grant(def)
	_save_completed()
	milestone_claimed.emit(threshold)
	daily_changed.emit()
	return true


## Định nghĩa một mốc theo ngưỡng Sao ({} nếu không có)
func milestone_def(threshold: int) -> Dictionary:
	for def in MILESTONES:
		if int(def.get("stars", 0)) == threshold:
			return def
	return {}


## Chuỗi mô tả phần thưởng của một mốc (dùng chung cho mọi UI) — vd "+100 XU" / "Hint ×2"
func reward_text(def: Dictionary) -> String:
	var parts: Array[String] = []
	var coins := int(def.get("coins", 0))
	if coins > 0:
		parts.append(tr("STR_DAILY_REWARD_COINS").format([coins]))
	for tool_id in ["hint", "undo", "skip"]:
		var amount := int(def.get(tool_id, 0))
		if amount > 0:
			parts.append(tr("STR_DAILY_TOOL_%s" % tool_id.to_upper()).format([amount]))
	return " + ".join(parts)


## Trao thưởng của một mốc: Xu (ví chung) + lượt dùng công cụ (GameManager)
func _grant(def: Dictionary) -> void:
	var coins := int(def.get("coins", 0))
	if coins > 0:
		_pay_coins(coins)
		coins_awarded.emit(get_today(), coins)
	var gm: Node = Svc.game()
	if gm == null or not gm.has_method("grant_tool_uses"):
		return
	for tool_id in ["hint", "undo", "skip"]:
		var amount := int(def.get(tool_id, 0))
		if amount > 0:
			gm.call("grant_tool_uses", tool_id, amount, "daily_milestone")


## Cộng Xu vào ví chung (Shop / Achievement dùng cùng ví này)
func _pay_coins(amount: int) -> void:
	if amount <= 0:
		return
	var wallet: Node = Svc.achievement()
	if wallet == null:
		return
	wallet.set("coins", maxi(int(wallet.get("coins")) + amount, 0))
	if wallet.has_method("notify_coins_changed"):
		wallet.call("notify_coins_changed")


## Tổng thưởng Xu của mọi mốc trong tháng (UI hiển thị "tối đa")
func month_coin_total() -> int:
	var total := 0
	for def in MILESTONES:
		total += int(def.get("coins", 0))
	return total


# ---------------------------------------------------------------------------
# CHUỖI NGÀY (streak)
# ---------------------------------------------------------------------------

## Chuỗi ngày liên tiếp có chơi màn CHƠI, tính lùi từ hôm nay (hoặc hôm qua)
func get_streak() -> int:
	var cursor := get_today()
	if not has_played(cursor) and has_played(cursor - 1):
		cursor -= 1
	var streak := 0
	while cursor >= 1 and has_played(cursor):
		streak += 1
		cursor -= 1
	return streak


# ---------------------------------------------------------------------------
# THỬ THÁCH CỦA NGÀY
# ---------------------------------------------------------------------------

## Luật Special xoay vòng của ngày — cùng một ngày luôn ra cùng một luật
func challenge_mode_for_day(day: int) -> String:
	var ids: Array = ChallengeGameMode.CHALLENGE_IDS
	if ids.is_empty():
		return ""
	return str(ids[posmod(maxi(day, 1) - 1, ids.size())])


## Thông tin Thử thách của ngày cho UI: { mode_id, title, subtitle }
func get_daily_challenge_info(day: int) -> Dictionary:
	var mode_id := challenge_mode_for_day(day)
	if mode_id.is_empty():
		return {"mode_id": "", "title": "", "subtitle": ""}
	var name_key := str(ChallengeGameMode.NAME_KEYS.get(mode_id, ""))
	var title := tr(name_key) if not name_key.is_empty() else mode_id
	return {"mode_id": mode_id, "title": title, "subtitle": title}


## Giữ API cũ cho Debug/Test: "kế hoạch game của ngày" — nay là CHƠI + THỬ THÁCH
func get_day_games(day: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.append({"mode": "standard", "challenge_id": ""})
	var mode_id := challenge_mode_for_day(day)
	if not mode_id.is_empty():
		out.append({"mode": "challenge", "challenge_id": mode_id})
	return out


# ---------------------------------------------------------------------------
# MỞ KHOÁ NGÀY BỎ LỠ
# ---------------------------------------------------------------------------

func unlock_cost() -> int:
	return UNLOCK_COST


func is_day_unlocked(day: int) -> bool:
	return unlocked_days.has(day) or has_played(day)


func can_unlock_day(day: int) -> bool:
	if day >= get_today() or day < 1 or is_day_unlocked(day):
		return false
	var wallet: Node = Svc.achievement()
	if wallet == null:
		return false
	return int(wallet.get("coins")) >= UNLOCK_COST


func unlock_day(day: int) -> bool:
	if not can_unlock_day(day):
		return false
	if not _spend_coins(UNLOCK_COST):
		return false
	unlocked_days.append(day)
	_save_completed()
	daily_changed.emit()
	return true


func set_day_unlocked(day: int, value: bool) -> void:
	var had := unlocked_days.has(day)
	if value and not had:
		unlocked_days.append(day)
	elif not value and had:
		unlocked_days.erase(day)
	_save_completed()
	daily_changed.emit()


func _spend_coins(amount: int) -> bool:
	var wallet: Node = Svc.achievement()
	if wallet == null or int(wallet.get("coins")) < amount:
		return false
	wallet.set("coins", maxi(int(wallet.get("coins")) - amount, 0))
	if wallet.has_method("notify_coins_changed"):
		wallet.call("notify_coins_changed")
	return true


# ---------------------------------------------------------------------------
# API TƯƠNG THÍCH (Debug Console / thống kê cũ dùng bitmask nhiệm vụ)
# ---------------------------------------------------------------------------

## Bitmask 4 bit của dữ liệu daily.cfg: bit 0..2 = nhiệm vụ CHƠI đã xong, bit 3 = đã xong THỬ THÁCH
func get_day_mission_mask(day: int) -> int:
	var mask := 0
	for i in get_day_play_stars(day):
		mask |= 1 << clampi(i, 0, PLAY_STARS_MAX - 1)
	if get_day_challenge_stars(day) > 0:
		mask |= 1 << 3
	return mask


## Đặt thẳng số sao CHƠI/THỬ THÁCH của ngày (Debug/Test) — không thưởng gì
func set_day_stars_split(day: int, play: int, challenge: int) -> void:
	var days: Dictionary = _month()["days"]
	days[day] = {
		"play": clampi(play, 0, PLAY_STARS_MAX),
		"challenge": clampi(challenge, 0, CHALLENGE_STARS_MAX),
	}
	_save_completed()
	daily_changed.emit()
	stars_changed.emit(day)


## Đặt số sao CHƠI của ngày, giữ nguyên phần THỬ THÁCH
func set_day_stars(day: int, stars: int) -> void:
	set_day_stars_split(day, stars, get_day_challenge_stars(day))


## Đặt thẳng bitmask (Debug/Test) — không thưởng gì
func set_day_mission_mask(day: int, mask: int) -> void:
	var play := 0
	for i in PLAY_STARS_MAX:
		if (mask & (1 << i)) != 0:
			play += 1
	var challenge := CHALLENGE_STARS_MAX if (mask & (1 << 3)) != 0 else 0
	set_day_stars_split(day, play, challenge)


## Số nhiệm vụ tối đa của phần CHƠI
func mission_count() -> int:
	return PLAY_STARS_MAX


func is_mission_done(day: int, index: int) -> bool:
	if index < 0 or index >= PLAY_STARS_MAX:
		return false
	return get_day_play_stars(day) > index


func get_day_missions(day: int) -> int:
	return get_day_play_stars(day)


func get_task_mask(day: int) -> Array[bool]:
	var out: Array[bool] = []
	for i in PLAY_STARS_MAX:
		out.append(is_mission_done(day, i))
	return out


## API cũ: chốt nhiệm vụ theo cờ (Debug Console). Không còn thưởng Xu ⇒ trả 0.
func complete_day_missions(day: int, flags: Array) -> int:
	var play := 0
	for i in mini(flags.size(), PLAY_STARS_MAX):
		if bool(flags[i]):
			play += 1
	var challenge := CHALLENGE_STARS_MAX if flags.size() > 3 and bool(flags[3]) else 0
	set_day_stars_split(day, maxi(play, get_day_play_stars(day)),
		maxi(challenge, get_day_challenge_stars(day)))
	return 0


## API cũ: chốt 1 nhiệm vụ theo index (>= 3 là THỬ THÁCH)
func complete_day_mission(day: int, index: int) -> int:
	if index >= PLAY_STARS_MAX:
		return CHALLENGE_STARS_MAX if record_daily_win(day, true, CHALLENGE_STARS_MAX) > 0 else 0
	return 1 if record_daily_win(day, false, 1) > 0 else 0


## API cũ (danh hiệu): tổng "nhiệm vụ" = tổng SAO đã đạt trong tháng
func get_total_missions() -> int:
	return get_month_stars()


func get_total_stars() -> int:
	return get_month_stars()


## Số ngày đã hoàn thành TRỌN trong tháng
func get_completed_count() -> int:
	var count := 0
	var days: Dictionary = _month()["days"]
	for day in days:
		if is_completed(int(day)):
			count += 1
	return count


## API cũ: đánh dấu ngày xong trọn (không thưởng)
func mark_completed(day: int) -> void:
	set_day_stars_split(day, PLAY_STARS_MAX, CHALLENGE_STARS_MAX)


## API cũ: Xu thưởng ngày — nay thưởng nằm ở MỐC THÁNG nên luôn 0
func day_reward_max() -> int:
	return 0


func day_reward_of(_day: int) -> int:
	return 0


func day_coins_earned(_day: int) -> int:
	return 0


func mission_reward(_index: int) -> int:
	return 0


# ---------------------------------------------------------------------------
# LƯU / NẠP
# ---------------------------------------------------------------------------

func _save_completed() -> void:
	var save: Node = Svc.save()
	if save != null and save.has_method("queue_save"):
		save.call("queue_save")


func export_progress() -> Dictionary:
	return {
		"months": months.duplicate(true),
		"unlocked_days": unlocked_days.duplicate(),
	}


func import_progress(data: Dictionary) -> void:
	months = {}
	var raw: Variant = data.get("months", null)
	if raw is Dictionary:
		for key in (raw as Dictionary):
			var entry: Variant = (raw as Dictionary)[key]
			if entry is Dictionary:
				months[str(key)] = (entry as Dictionary).duplicate(true)
	unlocked_days.clear()
	var days_raw: Variant = data.get("unlocked_days", null)
	if days_raw is Array:
		for day in (days_raw as Array):
			unlocked_days.append(int(day))
	daily_changed.emit()


func reset_progress() -> void:
	months.clear()
	unlocked_days.clear()
	_save_completed()
	daily_changed.emit()


## Nạp dữ liệu Daily.
## - Dữ liệu chính do SaveManager cấp qua import_progress().
## - File user://daily.cfg là dữ liệu định dạng cũ: chỉ đọc để DI TRÚ sang mô hình Sao.
func _load_completed() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var legacy: Variant = cfg.get_value(SECTION, "day_missions", null)
	var unlocked: Variant = cfg.get_value(SECTION, "unlocked_days", null)
	if unlocked is PackedInt32Array or unlocked is Array:
		for day in unlocked:
			if not unlocked_days.has(int(day)):
				unlocked_days.append(int(day))
	if not (legacy is Dictionary):
		return
	var days: Dictionary = _month()["days"]
	for key in (legacy as Dictionary):
		var mask := int((legacy as Dictionary)[key])
		var play := 0
		for i in PLAY_STARS_MAX:
			if (mask & (1 << i)) != 0:
				play += 1
		days[int(key)] = {
			"play": play,
			"challenge": CHALLENGE_STARS_MAX if (mask & (1 << 3)) != 0 else 0,
		}
	_save_completed()
