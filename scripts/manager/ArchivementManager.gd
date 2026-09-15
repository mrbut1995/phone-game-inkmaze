extends Node
## ============================================================================
## Manager: ArchivementManager (autoload) — "Sổ tay thành tựu" (Danh hiệu).
##
## - Danh sách danh hiệu = các file .tres (ArchivementData) trong `resources/archivements/`
##   -> thêm/bớt danh hiệu chỉ cần thêm/bớt file, không sửa code.
## - Số liệu (stats) chia 2 loại:
##      1) DẪN XUẤT (đọc trực tiếp từ GameManager/DailyManager): số màn đã qua, tổng sao,
##         số màn 3 sao, kỷ lục thời gian, số ngày Daily, chuỗi ngày, tổng sao Daily.
##      2) TÍCH LUỸ (game báo về qua notify_run_result): tầng sâu nhất, tổng tầng đã qua,
##         điểm cao nhất Dungeon, số ván thắng, thắng không gợi ý/hoàn tác, tổng gợi ý/hoàn tác,
##         thắng Hardcore, tổng thời gian chơi.
## - Tiến trình được LƯU cùng SaveManager (export_progress/import_progress).
## - UI chỉ đọc qua facade `Archivement` (scripts/utils/archivement.gd) để tránh tham chiếu
##   autoload trong lúc chạy test `--script`.
## ============================================================================

signal progress_changed                                   # bất kỳ số liệu/trạng thái nào đổi
signal achievement_unlocked(id: String)                    # vừa đủ điều kiện đạt danh hiệu
signal reward_claimed(id: String, coins: int)               # vừa bấm NHẬN thưởng

const DIR := "res://resources/archivements/"

## Các tab phân loại trong Sổ tay (thứ tự hiển thị) — "" = TẤT CẢ
const CATEGORIES := ["levels", "dungeon", "daily", "special"]

## Khoá số liệu tích luỹ (lưu trong blob save) + giá trị mặc định
const STAT_DEFAULTS := {
	"dungeon_best_floor": 0,
	"dungeon_floors_total": 0,
	"dungeon_best_score": 0,
	"wins_total": 0,
	"wins_no_hint": 0,
	"wins_no_undo": 0,
	"hints_total": 0,
	"undos_total": 0,
	"hardcore_wins": 0,
	"play_seconds": 0,
}

var _defs: Array[ArchivementData] = []
var _claimed: Dictionary = {}          # id -> true
var _stats: Dictionary = {}            # số liệu tích luỹ
var _unlocked_seen: Dictionary = {}    # id -> true (đã từng báo "mở khoá")
var coins := 0                         # xu đã nhận từ danh hiệu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stats = STAT_DEFAULTS.duplicate()
	_load_catalog()


# ---------------------------------------------------------------------------
# Nạp danh sách danh hiệu
# ---------------------------------------------------------------------------
func _load_catalog() -> void:
	_defs.clear()
	var dir := DirAccess.open(DIR)
	if dir == null:
		push_warning("[ArchivementManager] Khong mo duoc thu muc %s" % DIR)
		return

	var files := dir.get_files()
	files.sort()
	for file_name in files:
		if not file_name.ends_with(".tres"):
			continue
		var data := load(DIR + file_name) as ArchivementData
		if data == null:
			push_warning("[ArchivementManager] Bo qua file loi: %s" % file_name)
			continue
		if not data.is_valid():
			push_warning("[ArchivementManager] Bo qua danh hieu thieu id/stat/target: %s" % file_name)
			continue
		if _find_index(data.id) >= 0:
			push_warning("[ArchivementManager] Trung id '%s' (%s) - bo qua" % [data.id, file_name])
			continue
		_defs.append(data)


## Nạp lại danh sách (dùng cho test hoặc khi thêm file .tres lúc chạy)
func reload_catalog() -> void:
	_load_catalog()
	_unlocked_seen.clear()
	refresh()


func _find_index(id: String) -> int:
	for i in _defs.size():
		if _defs[i].id == id:
			return i
	return -1


func data_of(id: String) -> ArchivementData:
	var index := _find_index(id)
	return _defs[index] if index >= 0 else null


func all() -> Array[ArchivementData]:
	return _defs.duplicate()


func total_count() -> int:
	return _defs.size()


func count_in_category(category: String) -> int:
	var total := 0
	for data in _defs:
		if category.is_empty() or data.category == category:
			total += 1
	return total


# ---------------------------------------------------------------------------
# Số liệu (stats)
# ---------------------------------------------------------------------------
## Đọc lại số liệu + kiểm tra mở khoá (UI gọi khi mở Sổ tay).
## KHÔNG phát `progress_changed` để việc mở UI không kích hoạt autosave.
func refresh() -> void:
	_check_unlocks()


## Số liệu hiện tại của 1 khoá (0 nếu chưa biết)
func stat_value(key: String) -> int:
	match key:
		"levels_cleared":
			return _count_levels(true)
		"level_stars_total":
			return _sum_level_stars()
		"level_perfect":
			return _count_levels(false, 3)
		"fastest_clear":
			return _fastest_clear()
		"daily_days":
			return _daily_count()
		"daily_streak":
			return _daily_streak()
		"daily_stars_total":
			return _daily_stars()
		"claimed_count":
			return _claimed.size()
	return int(_stats.get(key, 0))


func _level_stars_dict() -> Dictionary:
	var gm: Node = _game_manager()
	var stars: Variant = gm.get("level_stars") if gm != null else null
	return stars if stars is Dictionary else {}


func _count_levels(cleared_only: bool, exact_stars := -1) -> int:
	var total := 0
	for value in _level_stars_dict().values():
		var stars := int(value)
		if cleared_only and stars <= 0:
			continue
		if exact_stars >= 0 and stars != exact_stars:
			continue
		total += 1
	return total


func _sum_level_stars() -> int:
	var total := 0
	for value in _level_stars_dict().values():
		total += maxi(int(value), 0)
	return total


func _fastest_clear() -> int:
	var gm: Node = _game_manager()
	var times: Variant = gm.get("level_best_time") if gm != null else null
	if not (times is Dictionary) or (times as Dictionary).is_empty():
		return 0
	var best := 0
	for value in (times as Dictionary).values():
		var seconds := int(round(float(value)))
		if seconds <= 0:
			continue
		if best == 0 or seconds < best:
			best = seconds
	return best


func _daily_count() -> int:
	var dm: Node = _daily_manager()
	if dm != null and dm.has_method("get_completed_count"):
		return int(dm.call("get_completed_count"))
	return 0


func _daily_streak() -> int:
	var dm: Node = _daily_manager()
	if dm != null and dm.has_method("get_streak"):
		return int(dm.call("get_streak"))
	return 0


func _daily_stars() -> int:
	var dm: Node = _daily_manager()
	if dm != null and dm.has_method("get_total_stars"):
		return int(dm.call("get_total_stars"))
	return 0


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _daily_manager() -> Node:
	return get_node_or_null("/root/DailyManager")


# ---------------------------------------------------------------------------
# Game báo kết quả 1 màn/tầng -> cập nhật số liệu tích luỹ
# ---------------------------------------------------------------------------
## `results` = { mode_id, won, endless, floor, score, elapsed, wall_hits, hints_used, undos_used, hardcore }
func notify_run_result(results: Dictionary) -> void:
	var won := bool(results.get("won", false))
	var endless := bool(results.get("endless", false))
	var floor := maxi(int(results.get("floor", 1)), 1)
	var hints := maxi(int(results.get("hints_used", 0)), 0)
	var undos := maxi(int(results.get("undos_used", 0)), 0)

	_bump("hints_total", hints)
	_bump("undos_total", undos)
	_bump("play_seconds", int(round(float(results.get("elapsed", 0.0)))))

	if endless:
		# Tầng sâu nhất ĐÃ TỚI: thắng tầng N nghĩa là đã tới tầng N+1
		var reached := floor + (1 if won else 0)
		_stats["dungeon_best_floor"] = maxi(int(_stats.get("dungeon_best_floor", 0)), reached)
		_stats["dungeon_best_score"] = maxi(int(_stats.get("dungeon_best_score", 0)),
			int(results.get("score", 0)))
		if won:
			_bump("dungeon_floors_total", 1)

	if won:
		_bump("wins_total", 1)
		if hints == 0:
			_bump("wins_no_hint", 1)
		if undos == 0:
			_bump("wins_no_undo", 1)
		if bool(results.get("hardcore", false)):
			_bump("hardcore_wins", 1)

	_check_unlocks()
	progress_changed.emit()


func _bump(key: String, amount: int) -> void:
	if amount == 0:
		return
	_stats[key] = int(_stats.get(key, 0)) + amount


# ---------------------------------------------------------------------------
# Tiến trình từng danh hiệu
# ---------------------------------------------------------------------------
func progress_of(id: String) -> int:
	var data := data_of(id)
	if data == null:
		return 0
	return mini(stat_value(data.stat), data.target)


func is_unlocked(id: String) -> bool:
	var data := data_of(id)
	if data == null:
		return false
	return stat_value(data.stat) >= data.target


func is_claimed(id: String) -> bool:
	return bool(_claimed.get(id, false))


func is_claimable(id: String) -> bool:
	return is_unlocked(id) and not is_claimed(id)


func claim(id: String) -> bool:
	if not is_claimable(id):
		return false
	var data := data_of(id)
	_claimed[id] = true
	var reward := maxi(data.reward_coins, 0)
	coins += reward
	reward_claimed.emit(id, reward)
	progress_changed.emit()
	return true


## Ví Xu vừa đổi từ nơi khác (ShopManager mua / nạp Xu) -> phát tín hiệu để UI + autosave theo
func notify_coins_changed() -> void:
	progress_changed.emit()


## Trừ Xu khi tiêu (mua hàng). Trả về true nếu ví đủ và đã trừ.
func spend_coins(amount: int) -> bool:
	if amount <= 0:
		return true
	if coins < amount:
		return false
	coins -= amount
	notify_coins_changed()
	return true


## Tổng điểm danh hiệu (AP) = tổng điểm của các danh hiệu ĐÃ ĐẠT
func points() -> int:
	var total := 0
	for data in _defs:
		if is_unlocked(data.id):
			total += maxi(data.points, 0)
	return total


func unlocked_count() -> int:
	var total := 0
	for data in _defs:
		if is_unlocked(data.id):
			total += 1
	return total


func claimed_count() -> int:
	return _claimed.size()


func claimable_count() -> int:
	var total := 0
	for data in _defs:
		if is_claimable(data.id):
			total += 1
	return total


## % đã mở khoá (0..100) — dùng cho thanh tiến độ ở thẻ tổng kết
func unlocked_percent() -> int:
	var total := _defs.size()
	if total <= 0:
		return 0
	return int(round(100.0 * float(unlocked_count()) / float(total)))


## Danh sách cho UI, đã tính sẵn trạng thái từng mục
func entries(category := "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for data in _defs:
		if not category.is_empty() and data.category != category:
			continue
		out.append(entry_for(data.id))
	return out


## 1 mục đã tính sẵn trạng thái để UI vẽ
func entry_for(id: String) -> Dictionary:
	var data := data_of(id)
	if data == null:
		return {}
	var progress := progress_of(id)
	var unlocked := is_unlocked(id)
	return {
		"id": data.id,
		"category": data.category,
		"title": data.display_title(),
		"desc": data.display_description(),
		"icon": data.icon,
		"progress": progress,
		"target": data.target,
		"unit": data.unit,
		"pct": int(round(100.0 * float(progress) / float(maxi(data.target, 1)))),
		"unlocked": unlocked,
		"claimed": is_claimed(id),
		"claimable": is_unlocked(id) and not is_claimed(id),
		"coins": data.reward_coins,
		"points": data.points,
		"secret_hidden": data.secret and not unlocked,
	}


## Báo "vừa mở khoá" cho các danh hiệu mới đạt (UI có thể hiện toast sau này)
func _check_unlocks() -> void:
	for data in _defs:
		if is_unlocked(data.id) and not bool(_unlocked_seen.get(data.id, false)):
			_unlocked_seen[data.id] = true
			achievement_unlocked.emit(data.id)


# ---------------------------------------------------------------------------
# Lưu trữ (SaveManager provider)
# ---------------------------------------------------------------------------
func export_progress() -> Dictionary:
	return {
		"coins": coins,
		"claimed": _claimed.keys(),
		"stats": _stats.duplicate(),
	}


func import_progress(data: Dictionary) -> void:
	coins = maxi(int(data.get("coins", 0)), 0)
	_claimed.clear()
	var claimed: Variant = data.get("claimed", [])
	if claimed is Array:
		for id in claimed:
			_claimed[str(id)] = true

	_stats = STAT_DEFAULTS.duplicate()
	var stats: Variant = data.get("stats", {})
	if stats is Dictionary:
		for key in (stats as Dictionary).keys():
			_stats[str(key)] = int((stats as Dictionary)[key])

	_unlocked_seen.clear()
	_check_unlocks()
	progress_changed.emit()


func reset_progress() -> void:
	coins = 0
	_claimed.clear()
	_stats = STAT_DEFAULTS.duplicate()
	_unlocked_seen.clear()
	progress_changed.emit()


# ---------------------------------------------------------------------------
# Tiện ích cho test
# ---------------------------------------------------------------------------
## Ghi đè 1 số liệu tích luỹ (test dựng tình huống)
func set_stat_for_test(key: String, value: int) -> void:
	_stats[key] = value
	_check_unlocks()
	progress_changed.emit()
