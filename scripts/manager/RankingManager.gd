extends Node
## ============================================================================
## Manager: BẢNG XẾP HẠNG (Ranking) — màn "BẢNG XẾP HẠNG" theo mockup/ranking.svg
##
## 3 bảng (tab): `dungeon` · `play` · `daily`.
## - Kỷ lục của NGƯỜI CHƠI lấy THẬT từ GameManager / DailyManager / ArchivementManager
##   (tầng cao nhất · số màn đã qua · chuỗi ngày...) — xem `_player_entry()`.
## - Các đối thủ còn lại là dữ liệu MÔ PHỎNG (offline): sinh từ `RIVAL_POOL` với seed
##   cố định theo (bảng | tên | khung-thời-gian) nên bảng **ổn định giữa các phiên** và
##   chỉ đổi nhẹ mỗi khung 10 phút (`REFRESH_SECONDS`) — mô phỏng "bảng xếp hạng sống".
##   Khi nối Google Play (xem TODO.txt mục GOOGLE PLAY) chỉ cần thay `_build_board()`.
##
## ĐIỂM XẾP HẠNG (points) là khoá sắp xếp duy nhất; hạng = vị trí sau khi sắp giảm dần:
##   dungeon : best_floor * 620 + best_score / 8
##   play    : levels_cleared * 360 + stars * 40 + max(0, 600 - fastest_clear) * 2
##   daily   : streak * 280 + days * 30 + total_stars * 5
## Đối thủ mô phỏng dùng cùng thang điểm ẩn (`_rival_entry`) nên bảng luôn nhất quán.
## ============================================================================

signal ranking_changed(board: String)

## Bảng tự "làm mới" mỗi 10 phút (ghi chú ở chân trang mockup)
const REFRESH_SECONDS := 600
## Số hạng đầu hiển thị ở bục vinh quang; phần còn lại nằm trong danh sách cuộn
const PODIUM_COUNT := 3

const BOARDS: Array[String] = ["dungeon", "play", "daily"]

## 24 đối thủ mô phỏng: tên · mã cờ (khớp assets/images/icons/flags/flag_<mã>.svg) · sức mạnh 0..100
const RIVAL_POOL: Array[Dictionary] = [
	{"name": "Alex_Maze", "flag": "vi", "power": 97},
	{"name": "Minh_Logic", "flag": "vi", "power": 91},
	{"name": "Hoang_Pro", "flag": "vi", "power": 86},
	{"name": "Dragon_Knight", "flag": "vi", "power": 81},
	{"name": "Kenji_Tokyo", "flag": "ja", "power": 88},
	{"name": "Yuki_Ink", "flag": "ja", "power": 74},
	{"name": "Hana_Maze", "flag": "ja", "power": 63},
	{"name": "Seoul_Gamer", "flag": "ko", "power": 79},
	{"name": "Jiwoo_Path", "flag": "ko", "power": 68},
	{"name": "Min_Solver", "flag": "ko", "power": 55},
	{"name": "Li_Wei_Maze", "flag": "zh_cn", "power": 84},
	{"name": "Chen_Fast", "flag": "zh_cn", "power": 71},
	{"name": "Xiao_Maze", "flag": "zh_cn", "power": 58},
	{"name": "Shadow_Rider", "flag": "en", "power": 76},
	{"name": "InkMaster", "flag": "en", "power": 83},
	{"name": "Paper_Pilot", "flag": "en", "power": 66},
	{"name": "Grid_Walker", "flag": "en", "power": 60},
	{"name": "Luna_Star", "flag": "en", "power": 52},
	{"name": "Nova_Line", "flag": "en", "power": 47},
	{"name": "Maxime_Ink", "flag": "fr", "power": 73},
	{"name": "Claire_Maze", "flag": "fr", "power": 61},
	{"name": "Tien_Solver", "flag": "vi", "power": 57},
	{"name": "Ngoc_Maze", "flag": "vi", "power": 44},
	{"name": "Player_One", "flag": "generic", "power": 35},
]

var _cache: Dictionary = {}          # board -> Array[Dictionary] (đã sắp hạng)
var _epoch: int = -1                 # khung 10 phút hiện tại (RIVAL_POOL sinh theo khung này)


# ---------------------------------------------------------------------------
# API cho UI
# ---------------------------------------------------------------------------
func board_ids() -> Array[String]:
	return BOARDS.duplicate()


## Toàn bộ bảng đã sắp hạng (kèm chính người chơi) — mỗi phần tử:
## { id, name, flag, primary, points, is_player, has_record, rank }
func entries(board: String) -> Array[Dictionary]:
	_ensure_fresh()
	var list: Array = _cache.get(board, [])
	return list.duplicate()


## 3 hạng đầu (bục vinh quang)
func podium(board: String) -> Array[Dictionary]:
	var all := entries(board)
	return all.slice(0, mini(PODIUM_COUNT, all.size()))


## Các hạng còn lại (danh sách cuộn)
func rest(board: String) -> Array[Dictionary]:
	var all := entries(board)
	if all.size() <= PODIUM_COUNT:
		return []
	return all.slice(PODIUM_COUNT, all.size())


## Hạng của người chơi (0 = chưa có kỷ lục nên không xếp hạng)
func my_rank(board: String) -> int:
	for e in entries(board):
		if bool(e.get("is_player", false)):
			return int(e.get("rank", 0))
	return 0


func my_entry(board: String) -> Dictionary:
	for e in entries(board):
		if bool(e.get("is_player", false)):
			return e
	return {}


## Mốc thời gian (unix) của lần "làm mới" gần nhất — hiện ở chân trang
func last_refresh_unix() -> int:
	_ensure_fresh()
	return _epoch * REFRESH_SECONDS


## Làm mới bảng nếu đã sang khung 10 phút mới; `force` = dựng lại ngay.
## Trả về true nếu dữ liệu có thay đổi.
func refresh(force := false) -> bool:
	var epoch := int(Time.get_unix_time_from_system() / float(REFRESH_SECONDS))
	if not force and epoch == _epoch and not _cache.is_empty():
		return false
	_epoch = epoch
	_cache.clear()
	for board in BOARDS:
		_cache[board] = _build_board(board)
	for board in BOARDS:
		ranking_changed.emit(board)
	return true


func _ensure_fresh() -> void:
	if _cache.is_empty():
		refresh()


# ---------------------------------------------------------------------------
# Dựng bảng
# ---------------------------------------------------------------------------
func _build_board(board: String) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for rival in RIVAL_POOL:
		list.append(_rival_entry(board, rival, _epoch))
	list.append(_player_entry(board))
	# Sắp giảm dần theo điểm; bằng điểm thì theo tên để bảng ổn định
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a["points"]) == int(b["points"]):
			return str(a["name"]) < str(b["name"])
		return int(a["points"]) > int(b["points"])
	)
	for i in list.size():
		list[i]["rank"] = i + 1
	return list


## Đối thủ mô phỏng: seed = (bảng | tên | khung thời gian) -> ổn định, chỉ đổi mỗi 10 phút
func _rival_entry(board: String, rival: Dictionary, epoch: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s|%s|%d" % [board, str(rival.get("name", "?")), epoch])
	# Nhiễu nhỏ theo bảng: cùng một đối thủ có thể mạnh/yếu khác nhau ở từng bảng
	var p := clampf(float(rival.get("power", 50)) / 100.0 + rng.randf_range(-0.08, 0.08), 0.05, 1.0)
	var primary := 1
	var points := 0
	match board:
		"dungeon":
			primary = maxi(1, int(round(lerp(2.0, 34.0, pow(p, 1.8)) + rng.randf_range(-2.0, 2.0))))
			points = primary * 620 + int(rng.randf_range(0.0, 700.0))
		"play":
			primary = maxi(1, int(round(lerp(1.0, 27.0, pow(p, 1.8)) + rng.randf_range(-2.0, 2.0))))
			points = primary * 360 + int(rng.randf_range(0.0, 1400.0))
		_:
			primary = maxi(1, int(round(lerp(1.0, 30.0, pow(p, 1.6)) + rng.randf_range(-1.0, 1.0))))
			points = primary * 280 + int(rng.randf_range(0.0, 1200.0))
	return {
		"id": "rival:%s" % str(rival.get("name", "?")),
		"name": str(rival.get("name", "?")),
		"flag": str(rival.get("flag", "generic")),
		"primary": primary,
		"points": points,
		"is_player": false,
		"has_record": true,
	}


## Kỷ lục THẬT của người chơi (0 điểm nếu chưa chơi ván nào)
func _player_entry(board: String) -> Dictionary:
	var stats := _stats()
	var primary := 0
	var points := 0
	var has_record := false
	match board:
		"dungeon":
			var floor := int(stats.get("dungeon_best_floor", 0))
			var best_score := int(stats.get("dungeon_best_score", 0))
			primary = floor
			points = floor * 620 + best_score / 8
			has_record = floor > 0 or best_score > 0
		"play":
			var cleared := int(stats.get("levels_cleared", 0))
			var stars := int(stats.get("level_stars_total", 0))
			var fastest := int(stats.get("fastest_clear", 0))
			primary = cleared
			points = cleared * 360 + stars * 40
			if fastest > 0:
				points += maxi(0, 600 - fastest) * 2
			has_record = cleared > 0
		_:
			var streak := int(stats.get("daily_streak", 0))
			var daily_stars := int(stats.get("daily_stars_total", 0))
			var days := int(stats.get("daily_days", 0))
			primary = streak
			# Bảng Daily ưu tiên chuỗi ngày nhưng vẫn cộng số ngày đã xong + sao kiếm được
			points = streak * 280 + days * 30 + daily_stars * 5
			has_record = days > 0
	return {
		"id": "player",
		"name": "STR_RANK_YOU",
		"flag": _player_flag(),
		"primary": primary,
		"points": points,
		"is_player": true,
		"has_record": has_record,
	}


## Các chỉ số "sống" lấy từ manager khác (qua /root — không tham chiếu identifier autoload).
func _stats() -> Dictionary:
	var out := {}
	var arch := _node("ArchivementManager")
	if arch != null and arch.has_method("stat_value"):
		for key in ["dungeon_best_floor", "dungeon_best_score", "levels_cleared",
				"level_stars_total", "fastest_clear", "daily_streak", "daily_stars_total",
				"daily_days"]:
			out[key] = int(arch.call("stat_value", key))
	return out


## Cờ của người chơi: suy từ ngôn ngữ đang chọn (có sẵn asset), còn lại dùng cờ chung
func _player_flag() -> String:
	var code := "vi"
	var loc := _node("LocalizationManager")
	if loc != null:
		if loc.has_method("current"):
			code = str(loc.call("current"))
		elif loc.get("locale") != null:
			code = str(loc.get("locale"))
	match code:
		"vi", "en", "ja", "ko", "zh_cn", "fr":
			return code
		_:
			return "generic"


func _node(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null(node_name)
	return null
