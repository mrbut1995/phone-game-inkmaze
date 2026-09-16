extends Node
## ============================================================================
## Manager: DailyManager - Thử thách hằng ngày (Daily Challenge).
## - Xác định "hôm nay" là ngày nào (1..31) theo lịch máy.
## - MỖI NGÀY có 2 mê cung: MAZE THƯỜNG (classic) + MAZE ĐẶC BIỆT (mode xoay vòng).
## - 4 NHIỆM VỤ mỗi ngày: index 0..2 = 3 thử thách của maze thường,
##   index 3 = nhiệm vụ của maze đặc biệt.
## - Hoàn thành nhiệm vụ thưởng XU (ví dùng chung với Shop/Archivement), KHÔNG thưởng Sao nữa.
## - Lưu tiến độ qua SaveManager; user://daily.cfg chỉ còn để DI TRÚ.
## ============================================================================

signal daily_completed(day: int)
signal daily_changed
signal coins_awarded(day: int, amount: int)

const CONFIG_PATH := "user://daily.cfg"
const SECTION := "daily"

## Số nhiệm vụ mỗi ngày: 3 nhiệm vụ maze thường (0..2) + 1 nhiệm vụ maze đặc biệt (3)
const MAX_MISSIONS_PER_DAY := 4
## Xu thưởng cho từng nhiệm vụ (index 0..3) — tổng 50 Xu/ngày
const MISSION_REWARDS: Array[int] = [10, 10, 15, 15]
const ALL_MISSIONS_MASK := 0b1111
## Xu phải trả để MỞ KHOÁ một ngày đã bỏ lỡ (ngày trước hôm nay chưa chơi gì)
const UNLOCK_COST := 50

var completed_days: Array[int] = []
## day (1..31) -> bitmask 4 nhiệm vụ đã xong (bit 0..2 = maze thường, bit 3 = maze đặc biệt)
var day_missions: Dictionary = {}
## day (1..31) -> tổng Xu đã thưởng trong ngày (chống trả thưởng trùng khi chơi lại)
var day_coins: Dictionary = {}
## day (1..31) -> đã trả Xu để MỞ KHOÁ (ngày bỏ lỡ được chơi lại như bình thường)
var unlocked_days: Array[int] = []


func _ready() -> void:
	_load_completed()


## Ngày hôm nay theo lịch máy (1..31)
func get_today() -> int:
	return int(Time.get_date_dict_from_system().get("day", 1))


func is_today(day: int) -> bool:
	return day == get_today()


func is_completed(day: int) -> bool:
	return get_day_mission_mask(day) == ALL_MISSIONS_MASK


## Đánh dấu ngày đã xong HẾT nhiệm vụ (không thưởng Xu — dùng cho dữ liệu cũ/debug)
func mark_completed(day: int) -> void:
	if is_completed(day):
		return
	day_missions[day] = ALL_MISSIONS_MASK
	if not completed_days.has(day):
		completed_days.append(day)
	_save_completed()
	daily_completed.emit(day)
	daily_changed.emit()


# ---------------------------------------------------------------------------
# NHIỆM VỤ TRONG NGÀY (4 nhiệm vụ · thưởng Xu)
# ---------------------------------------------------------------------------
## Số nhiệm vụ của một ngày (hằng số tiện cho UI)
func mission_count() -> int:
	return MAX_MISSIONS_PER_DAY


## Xu thưởng của nhiệm vụ theo index (0..3)
func mission_reward(index: int) -> int:
	if index < 0 or index >= MISSION_REWARDS.size():
		return 0
	return MISSION_REWARDS[index]


## Tổng Xu thưởng tối đa một ngày
func day_reward_max() -> int:
	var total := 0
	for reward in MISSION_REWARDS:
		total += int(reward)
	return total


## Bitmask 4 nhiệm vụ đã xong của một ngày
func get_day_mission_mask(day: int) -> int:
	return int(day_missions.get(day, 0))


## Số nhiệm vụ (0..4) đã xong của một ngày
func get_day_missions(day: int) -> int:
	var mask := get_day_mission_mask(day)
	var count := 0
	for i in MAX_MISSIONS_PER_DAY:
		if (mask & (1 << i)) != 0:
			count += 1
	return count


func is_mission_done(day: int, index: int) -> bool:
	if index < 0 or index >= MAX_MISSIONS_PER_DAY:
		return false
	return (get_day_mission_mask(day) & (1 << index)) != 0


## Tổng Xu ĐÃ THƯỞNG của một ngày (chỉ tăng, không trả lại khi chơi lại)
func day_coins_earned(day: int) -> int:
	return int(day_coins.get(day, 0))


## Tổng Xu thưởng của các nhiệm vụ ĐÃ XONG trong ngày (khớp day_coins_earned sau khi chơi thật)
func day_reward_of(day: int) -> int:
	var total := 0
	var mask := get_day_mission_mask(day)
	for i in MAX_MISSIONS_PER_DAY:
		if (mask & (1 << i)) != 0:
			total += mission_reward(i)
	return total


## Chốt nhiệm vụ sau một ván chơi. `flags[i] = true` = nhiệm vụ i vừa hoàn thành.
## Trả về số XU vừa được thưởng (0 nếu không có gì mới).
func complete_day_missions(day: int, flags: Array) -> int:
	var mask := get_day_mission_mask(day)
	var updated := mask
	for i in mini(flags.size(), MAX_MISSIONS_PER_DAY):
		if bool(flags[i]):
			updated |= (1 << i)
	if updated == mask:
		return 0

	# Chỉ trả Xu cho nhiệm vụ MỚI xong (nhiệm vụ xong từ trước không thưởng lại)
	var awarded := 0
	for i in MAX_MISSIONS_PER_DAY:
		var bit := 1 << i
		if (updated & bit) != 0 and (mask & bit) == 0:
			awarded += mission_reward(i)

	day_missions[day] = updated
	if awarded > 0:
		day_coins[day] = day_coins_earned(day) + awarded
		_pay_coins(awarded)

	var just_completed := updated == ALL_MISSIONS_MASK and not completed_days.has(day)
	if just_completed:
		completed_days.append(day)
	_save_completed()

	if awarded > 0:
		coins_awarded.emit(day, awarded)
	if just_completed:
		daily_completed.emit(day)
	daily_changed.emit()
	return awarded


## Chốt 1 nhiệm vụ đơn lẻ (dùng cho maze đặc biệt)
func complete_day_mission(day: int, index: int) -> int:
	var flags: Array[bool] = []
	for i in MAX_MISSIONS_PER_DAY:
		flags.append(i == index)
	return complete_day_missions(day, flags)


# ---------------------------------------------------------------------------
# MỞ KHOÁ NGÀY BỎ LỠ (trả Xu)
# ---------------------------------------------------------------------------
## Giá mở khoá một ngày bỏ lỡ (Xu)
func unlock_cost() -> int:
	return UNLOCK_COST


## Ngày đã được trả Xu mở khoá?
func is_day_unlocked(day: int) -> bool:
	return unlocked_days.has(day)


## Ngày bỏ lỡ CÓ THỂ mở khoá? = ngày đã qua + chưa chơi nhiệm vụ nào + chưa mở khoá
func can_unlock_day(day: int) -> bool:
	if day <= 0 or day >= get_today():
		return false
	if is_day_unlocked(day):
		return false
	return get_day_mission_mask(day) == 0


## Trả Xu để mở khoá ngày bỏ lỡ. Trả về true nếu mở khoá thành công.
func unlock_day(day: int) -> bool:
	if not can_unlock_day(day):
		return false
	if not _spend_coins(UNLOCK_COST):
		return false
	unlocked_days.append(day)
	_save_completed()
	daily_changed.emit()
	return true


## Đặt cờ mở khoá (test/debug khôi phục trạng thái), KHÔNG trừ Xu
func set_day_unlocked(day: int, value: bool) -> void:
	var had := unlocked_days.has(day)
	if value and not had:
		unlocked_days.append(day)
	elif not value and had:
		unlocked_days.erase(day)
	_save_completed()
	daily_changed.emit()


## Trừ Xu từ ví chung (Shop/Archivement dùng cùng ví này). false = ví không đủ.
func _spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	var wallet: Node = get_node_or_null("/root/ArchivementManager")
	if wallet == null:
		return false
	if int(wallet.get("coins")) < amount:
		return false
	if wallet.has_method("spend_coins"):
		return bool(wallet.call("spend_coins", amount))
	wallet.set("coins", int(wallet.get("coins")) - amount)
	if wallet.has_method("notify_coins_changed"):
		wallet.call("notify_coins_changed")
	return true


## Cộng Xu vào ví chung (Shop/Archivement dùng cùng ví này)
func _pay_coins(amount: int) -> void:
	if amount <= 0:
		return
	var wallet: Variant = get_node_or_null("/root/ArchivementManager")
	if wallet == null:
		return
	wallet.set("coins", maxi(int(wallet.get("coins")) + amount, 0))
	if wallet.has_method("notify_coins_changed"):
		wallet.call("notify_coins_changed")


## Tương thích API cũ: số sao = số nhiệm vụ đã xong
func get_day_stars(day: int) -> int:
	return get_day_missions(day)


## Tương thích API cũ (Debug/Test): đặt nhanh số nhiệm vụ đã xong, KHÔNG thưởng Xu
func set_day_stars(day: int, stars: int) -> void:
	var count := clampi(stars, 0, MAX_MISSIONS_PER_DAY)
	var mask := 0
	for i in count:
		mask |= 1 << i
	set_day_mission_mask(day, mask)


## Đặt thẳng mask nhiệm vụ (test/debug khôi phục trạng thái chính xác), KHÔNG thưởng Xu
func set_day_mission_mask(day: int, mask: int) -> void:
	var value := mask & ALL_MISSIONS_MASK
	day_missions[day] = value
	if value == ALL_MISSIONS_MASK and not completed_days.has(day):
		completed_days.append(day)
	elif value != ALL_MISSIONS_MASK and completed_days.has(day):
		completed_days.erase(day)
	_save_completed()
	daily_changed.emit()


## Tổng số nhiệm vụ đã hoàn thành trong tháng (thay cho "tổng sao" ngày xưa)
func get_total_missions() -> int:
	var total := 0
	for day in day_missions:
		total += get_day_missions(int(day))
	return total


## Tương thích API cũ — giờ trả về TỔNG NHIỆM VỤ (không còn sao)
func get_total_stars() -> int:
	return get_total_missions()


## Chuỗi ngày liên tiếp đã hoàn thành (đủ 4/4 nhiệm vụ), tính lùi từ hôm nay (hoặc hôm qua)
func get_streak() -> int:
	var today := get_today()
	var cursor := today
	if not completed_days.has(today) and completed_days.has(today - 1):
		cursor = today - 1
	var streak := 0
	while cursor >= 1 and completed_days.has(cursor):
		streak += 1
		cursor -= 1
	return streak


## Danh sách 4 nhiệm vụ đã xong của một ngày
func get_task_mask(day: int) -> Array[bool]:
	var out: Array[bool] = []
	for i in MAX_MISSIONS_PER_DAY:
		out.append(is_mission_done(day, i))
	return out


## Mode xoay vòng cho 1 ngày (1 -> mode đầu tiên trong danh sách)
func get_mode_for_day(day: int) -> String:
	var modes := GameManagerClass.DAILY_MODES
	if modes.is_empty():
		return ""
	var index := posmod(day - 1, modes.size())
	return modes[index]


func get_completed_count() -> int:
	return completed_days.size()


## Ghi dữ liệu Daily: từ nay đi qua SaveManager (local, sẵn sàng cloud sau này).
## File user://daily.cfg cũ chỉ còn để DI TRÚ (đọc ở _load_completed).
func _save_completed() -> void:
	Save.queue_save()


# --- Tích hợp SaveManager -------------------------------------------------

func export_progress() -> Dictionary:
	return {
		"completed_days": completed_days.duplicate(),
		"day_missions": day_missions.duplicate(),
		"day_coins": day_coins.duplicate(),
		"unlocked_days": unlocked_days.duplicate(),
	}


func import_progress(data: Dictionary) -> void:
	if data.is_empty():
		return
	completed_days.clear()
	day_missions.clear()
	day_coins.clear()
	unlocked_days.clear()
	var days: Variant = data.get("completed_days", null)
	if days is Array:
		for day in (days as Array):
			completed_days.append(int(day))
	var missions: Variant = data.get("day_missions", null)
	if missions is Dictionary:
		for day in (missions as Dictionary):
			day_missions[int(str(day))] = int((missions as Dictionary)[day])
	var coins: Variant = data.get("day_coins", null)
	if coins is Dictionary:
		for day in (coins as Dictionary):
			day_coins[int(str(day))] = int((coins as Dictionary)[day])
	var unlocked: Variant = data.get("unlocked_days", null)
	if unlocked is Array:
		for day in (unlocked as Array):
			unlocked_days.append(int(day))
	# DI TRÚ blob cũ: chỉ có "day_stars" (0..3 sao) -> coi như số nhiệm vụ đã xong
	if day_missions.is_empty():
		var stars: Variant = data.get("day_stars", null)
		if stars is Dictionary:
			for day in (stars as Dictionary):
				day_missions[int(str(day))] = _stars_to_mask(int((stars as Dictionary)[day]))
	daily_changed.emit()


func reset_progress() -> void:
	completed_days.clear()
	day_missions.clear()
	day_coins.clear()
	unlocked_days.clear()
	daily_changed.emit()


## 0..3 sao (dữ liệu cũ) -> bitmask nhiệm vụ (bit 0..n-1)
static func _stars_to_mask(stars: int) -> int:
	var mask := 0
	for i in clampi(stars, 0, MAX_MISSIONS_PER_DAY):
		mask |= 1 << i
	return mask


## Nạp dữ liệu Daily.
## - Dữ liệu chính do SaveManager cấp qua import_progress().
## - File user://daily.cfg là dữ liệu cũ: chỉ đọc để DI TRÚ sang SaveManager.
func _load_completed() -> void:
	completed_days.clear()
	day_missions.clear()
	day_coins.clear()
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	var saved: Variant = cfg.get_value(SECTION, "completed_days", PackedInt32Array())
	if saved is PackedInt32Array or saved is Array:
		for day in saved:
			completed_days.append(int(day))
			day_missions[int(day)] = ALL_MISSIONS_MASK
	var stars: Variant = cfg.get_value(SECTION, "day_stars", {})
	if stars is Dictionary:
		for day in stars:
			day_missions[int(day)] = _stars_to_mask(int(stars[day]))
