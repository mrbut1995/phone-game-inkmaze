extends Node
## ============================================================================
## Manager: PlayerProfileManager — HỒ SƠ NGƯỜI CHƠI (Profiler)
##
## Gom dữ liệu rải rác từ các manager khác thành 1 hồ sơ hiển thị được:
##   · Tên hiển thị · Avatar · Viền khung (đổi trong popup "DIỆN MẠO HỒ SƠ")
##   · EXP = AP danh hiệu + Sao (mỗi Sao = 25 EXP, mỗi 200 EXP = 1 Cấp)
##   · Thống kê: Sao · Kỷ lục Dungeon · Chuỗi Daily · Tỉ lệ thắng
##   · Lịch sử 10 ván gần nhất (GameController gọi `record_run` khi kết thúc ván)
##
## Danh mục Avatar / Viền khung / Bậc danh hiệu = các file .tres
## (AvatarData / FrameData / ProfilerTitleData) trong `res://resources/profiler/` —
## quét thư mục lúc khởi động, THÊM món mới chỉ cần tạo file .tres trong editor.
##
## Lưu save qua SaveManager (provider "PlayerProfileManager", autosave theo signal).
## Đọc chéo manager khác QUA /root (không dùng identifier autoload — test --script
## không resolve được identifier autoload lúc parse).
## ============================================================================

signal profile_changed

const AVATAR_DIR := "res://assets/images-png/avatars/"
const FRAME_DIR := "res://assets/images-png/frames/"
const MAX_RECENT := 10
## Mỗi 200 EXP = 1 Cấp; mỗi Sao = 25 EXP
const EXP_PER_LEVEL := 200
const EXP_PER_STAR := 25

## Danh mục nạp từ .tres lúc _ready (xem scripts/resources/avatar_data.gd…):
##   resources/profiler/avatars/avatar_<id>.tres   (AvatarData)
##   resources/profiler/frames/frame_<id>.tres     (FrameData)
##   resources/profiler/titles/tier_<n>.tres       (ProfilerTitleData)
const AVATAR_RES_DIR := "res://resources/profiler/avatars/"
const FRAME_RES_DIR := "res://resources/profiler/frames/"
const TITLE_RES_DIR := "res://resources/profiler/titles/"

## Danh mục đã nạp — thứ tự hiển thị: tặng sẵn → giá tăng dần → khoá mốc
## (công cụ sinh file: scripts/tool/gen_profiler_resources.gd)
var _avatars: Array[AvatarData] = []
var _frames: Array[FrameData] = []
var _titles: Array[ProfilerTitleData] = []

## Catalog AVATAR/VIỀN — nay nằm trong `resources/profiler/` (34 avatar + 29 viền):
##   · avatar_<id>.tres / frame_<id>.tres — xem gen_profiler_resources.gd
const DEFAULT_AVATAR := "avatar_baby_child_kid"
## Viền mặc định = món tặng sẵn trong catalog (frame_default.tres)
const DEFAULT_FRAME := "frame_default"

# --- Trạng thái lưu save -----------------------------------------------------
var display_name := ""
var avatar_id := DEFAULT_AVATAR
var frame_id := DEFAULT_FRAME
var owned_avatars: Array[String] = ["avatar_baby_child_kid", "avatar_boy_kid", "avatar_child_girl"]
var owned_frames: Array[String] = ["frame_default", "frame_laurel", "frame_bronze"]
var uid_suffix := ""
var joined_date := ""
## Thống kê tích luỹ cho tỉ lệ thắng (chỉ tính các ván ghi từ khi có tính năng)
var runs_played := 0
var runs_won := 0
## Lịch sử ván gần nhất (mới nhất đứng đầu) — xem `record_run`
var recent: Array = []

## --- Số liệu MỞ RỘNG cho bản Hồ sơ mới (Profiler) — tích luỹ theo save ---
## Play Stats (ván MÀN = chơi từ màn Chọn màn, cờ `GameManager.level_run`)
var level_plays := 0            # số ván MÀN đã chơi
var level_wins := 0             # số ván MÀN thắng
var first_try_wins := 0         # thắng màn ngay LẦN ĐẦU tiên chơi màn đó
var win_streak := 0             # chuỗi ván MÀN thắng LIÊN TIẾP hiện tại
var level_attempts: Dictionary = {}   # level_id -> số lần đã chơi (để tính First Try)
## Game Mode Stats
var mode_plays: Dictionary = {}       # mode_id -> số lần chơi
## Dungeon Stats
var dungeon_wall_hits := 0      # tổng va chạm tường ở các ván Dungeon
## In Game / Time Stats (mọi chế độ)
var runs_total := 0             # tổng số ván đã ghi
var moves_total := 0            # tổng số bước
var time_total := 0.0           # tổng thời gian (giây, mọi ván)
var level_time_total := 0.0     # tổng thời gian các ván MÀN (giây)
var undos_total := 0            # tổng lượt Hoàn tác
var wall_draws_total := 0       # tổng lượt VẼ tường nghi ngờ
var wall_erases_total := 0      # tổng lượt GỠ tường đã vẽ (Revert)
var skips_total := 0            # tổng lượt SKIP màn


# ---------------------------------------------------------------------------
# Truy cập manager khác qua /root
# ---------------------------------------------------------------------------
func _achievements() -> Node:
	return get_node_or_null("/root/ArchivementManager")


func _levels() -> Node:
	return get_node_or_null("/root/LevelManager")


func _gm() -> Node:
	return get_node_or_null("/root/GameManager")


## Số liệu Sổ tay (dungeon_best_floor / daily_streak / level_stars_total / points…)
func _stat(key: String) -> int:
	var m := _achievements()
	if m == null or not m.has_method("stat_value"):
		return 0
	return int(m.call("stat_value", key))


# ---------------------------------------------------------------------------
# Danh mục avatar / viền khung
# ---------------------------------------------------------------------------
## entries = mỗi món kèm trạng thái tính sẵn: owned · equipped · locked · price
func avatars() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for data in _avatars:
		out.append(_state_of(data, "avatar"))
	return out


func frames() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for data in _frames:
		out.append(_state_of(data, "frame"))
	return out


func avatar_entry(avatar_ident: String) -> Dictionary:
	var data := _find_avatar(avatar_ident)
	return _state_of(data, "avatar") if data != null else {}


func frame_entry(frame_ident: String) -> Dictionary:
	var data := _find_frame(frame_ident)
	return _state_of(data, "frame") if data != null else {}


## Đường dẫn PNG của avatar/viền — UI tự `load()` (giữ API chuỗi như trước)
func icon_of(kind: String, ident: String) -> String:
	var data: Resource = _find_avatar(ident) if kind == "avatar" else _find_frame(ident)
	if data == null or data.get("icon") == null:
		if kind == "avatar":
			return AVATAR_DIR + "avatar-baby-child-kid.png"
		return FRAME_DIR + "frame_default.png"
	var icon := data.get("icon") as Texture2D
	return icon.resource_path


func owns_avatar(avatar_ident: String) -> bool:
	var data := _find_avatar(avatar_ident)
	if data != null and data.price <= 0:
		return true
	return owned_avatars.has(avatar_ident)


func owns_frame(frame_ident: String) -> bool:
	var data := _find_frame(frame_ident)
	if data != null and data.price <= 0:
		return true
	return owned_frames.has(frame_ident)


## Đủ điều kiện mở khoá theo mốc (dungeon/streak/AP)? Trả {} nếu không bị khoá mốc.
func lock_of(kind: String, ident: String) -> Dictionary:
	return _lock_from(_find_avatar(ident) if kind == "avatar" else _find_frame(ident))


## Khoá mốc của 1 món (rỗng = không khoá mốc; ĐÃ ĐẠT mốc ⇒ cũng trả rỗng = mở khoá)
func _lock_from(data: Resource) -> Dictionary:
	if data == null:
		return {}
	var stat_key := str(data.get("lock_stat"))
	if stat_key.is_empty():
		return {}
	var need := int(data.get("lock_value"))
	if _stat(stat_key) >= need:
		return {}
	return {"stat": stat_key, "value": need}


func equip_avatar(avatar_ident: String) -> bool:
	if not owns_avatar(avatar_ident):
		return false
	avatar_id = avatar_ident
	_notify()
	return true


func equip_frame(frame_ident: String) -> bool:
	if not owns_frame(frame_ident):
		return false
	frame_id = frame_ident
	_notify()
	return true


## Mua avatar bằng Xu mực (đủ tiền + chưa sở hữu + không khoá mốc)
func buy_avatar(avatar_ident: String) -> bool:
	return _buy(_find_avatar(avatar_ident), owned_avatars)


func buy_frame(frame_ident: String) -> bool:
	return _buy(_find_frame(frame_ident), owned_frames)


## Mua 1 món trong catalog — Xu mực lấy từ kho danh hiệu (ArchivementManager.spend_coins)
func _buy(data: Resource, owned_list: Array[String]) -> bool:
	if data == null:
		return false
	var ident := str(data.get("id"))
	var price := int(data.get("price"))
	if price <= 0 and owned_list.has(ident):
		return false
	if not _lock_from(data).is_empty():
		return false
	var wallets := _achievements()
	if wallets == null or not wallets.has_method("spend_coins"):
		return false
	if int(wallets.get("coins")) < price:
		return false
	if not bool(wallets.call("spend_coins", price)):
		return false
	owned_list.append(ident)
	_notify()
	return true


func set_display_name(new_name: String) -> bool:
	var clean := new_name.strip_edges()
	if clean.is_empty() or clean == display_name:
		return false
	# Giới hạn 16 ký tự như ghi chú trong popup
	display_name = clean.substr(0, 16)
	_notify()
	return true


## Tên hiển thị (rỗng = tên mặc định theo khoá dịch)
func display_name_text() -> String:
	if not display_name.is_empty():
		return display_name
	return "MazeWalker #%s" % uid_suffix


# ---------------------------------------------------------------------------
# Thống kê hồ sơ
# ---------------------------------------------------------------------------
func total_stars() -> int:
	return _stat("level_stars_total")


func max_stars() -> int:
	var lm := _levels()
	if lm == null or not lm.has_method("get_level_count"):
		return 0
	return int(lm.call("get_level_count")) * 3


func dungeon_floor() -> int:
	return _stat("dungeon_best_floor")


func streak() -> int:
	return _stat("daily_streak")


func points() -> int:
	var m := _achievements()
	if m == null or not m.has_method("points"):
		return 0
	return int(m.call("points"))


func exp_total() -> int:
	return points() + total_stars() * EXP_PER_STAR


func level() -> int:
	return 1 + exp_total() / EXP_PER_LEVEL


func exp_in_level() -> int:
	return exp_total() % EXP_PER_LEVEL


func exp_level_step() -> int:
	return EXP_PER_LEVEL


## Bậc danh hiệu theo cấp hồ sơ — catalog `resources/profiler/titles/` (sắp theo min_level)
func title_key() -> String:
	if _titles.is_empty():
		return "STR_PROFILE_TIER_1"
	var lv := level()
	var key := str(_titles[0].get("name_key"))
	for tier in _titles:
		if lv >= int(tier.get("min_level")):
			key = str(tier.get("name_key"))
	return key


## Tỉ lệ thắng 0..100, -1 = chưa có ván nào
func win_rate() -> float:
	if runs_played <= 0:
		return -1.0
	return float(runs_won) / float(runs_played) * 100.0


func stats() -> Dictionary:
	return {
		"stars": total_stars(),
		"stars_max": max_stars(),
		"dungeon_floor": dungeon_floor(),
		"streak": streak(),
		"win_rate": win_rate(),
		"points": points(),
		"exp": exp_total(),
		"exp_in_level": exp_in_level(),
		"exp_step": exp_level_step(),
		"level": level(),
		"title_key": title_key(),
	}


## Số liệu MỞ RỘNG cho bản Hồ sơ mới (5 nhóm: Play · Dungeon · Time · Game Mode · In Game).
## Giá trị thô (chưa format) — màn Hồ sơ tự định dạng/thêm khoá dịch.
func deep_stats() -> Dictionary:
	var winrate := float(level_wins) / float(level_plays) * 100.0 if level_plays > 0 else 0.0
	var avg_level_time := level_time_total / float(level_plays) if level_plays > 0 else 0.0
	var avg_time_move := time_total / float(moves_total) if moves_total > 0 else 0.0
	var avg_move := float(moves_total) / float(runs_total) if runs_total > 0 else 0.0
	return {
		# Play Stats
		"level_plays": level_plays,
		"level_wins": level_wins,
		"level_winrate": winrate,
		"first_try_wins": first_try_wins,
		"win_streak": win_streak,
		"daily_days": _daily_completed_days(),
		# Dungeon Stats
		"highest_floor": dungeon_floor(),
		"dungeon_wall_hits": dungeon_wall_hits,
		# Time Stats
		"avg_level_time": avg_level_time,
		"total_level_time": level_time_total,
		"avg_time_move": avg_time_move,
		# Game Mode Stats (mode_id -> số lần chơi)
		"mode_plays": mode_plays.duplicate(),
		# In Game Stats
		"avg_move": avg_move,
		"moves_total": moves_total,
		"wall_draws": wall_draws_total,
		"wall_erases": wall_erases_total,
		"undos_total": undos_total,
		"skips_total": skips_total,
	}


## Số NGÀY đã hoàn thành Daily Challenge (DailyManager giữ danh sách completed_days)
func _daily_completed_days() -> int:
	var dm := get_node_or_null("/root/DailyManager")
	if dm == null or not dm.has_method("get_completed_count"):
		return 0
	return int(dm.call("get_completed_count"))


# ---------------------------------------------------------------------------
# Lịch sử ván (GameController gọi khi kết thúc ván — bỏ qua ván test Debug)
# ---------------------------------------------------------------------------
func record_run(info: Dictionary) -> void:
	var won := bool(info.get("won", false))
	runs_played += 1
	if won:
		runs_won += 1
	# --- Số liệu mở rộng (Profiler mới) ---
	runs_total += 1
	moves_total += maxi(int(info.get("moves", 0)), 0)
	var elapsed := maxf(float(info.get("elapsed", 0.0)), 0.0)
	time_total += elapsed
	var mode_id := str(info.get("mode_id", ""))
	if not mode_id.is_empty():
		mode_plays[mode_id] = int(mode_plays.get(mode_id, 0)) + 1
	if bool(info.get("endless", false)):
		dungeon_wall_hits += maxi(int(info.get("wall_hits", 0)), 0)
	undos_total += maxi(int(info.get("undos", 0)), 0)
	wall_draws_total += maxi(int(info.get("wall_draws", 0)), 0)
	wall_erases_total += maxi(int(info.get("wall_erases", 0)), 0)
	skips_total += maxi(int(info.get("skips", 0)), 0)
	if bool(info.get("level_run", false)):
		level_plays += 1
		level_time_total += elapsed
		var level_id := maxi(int(info.get("level_id", 0)), 0)
		if level_id > 0:
			level_attempts[level_id] = int(level_attempts.get(level_id, 0)) + 1
		if won:
			level_wins += 1
			win_streak += 1
			if level_id > 0 and int(level_attempts.get(level_id, 0)) == 1:
				first_try_wins += 1
		else:
			win_streak = 0
	var row := {
		"won": won,
		"mode_id": str(info.get("mode_id", "")),
		"endless": bool(info.get("endless", false)),
		"daily": bool(info.get("daily", false)),
		"floor": int(info.get("floor", 1)),
		"elapsed": float(info.get("elapsed", 0.0)),
		"score": int(info.get("score", 0)),
		"moves": int(info.get("moves", 0)),
		"wall_hits": int(info.get("wall_hits", 0)),
		"width": int(info.get("width", 0)),
		"height": int(info.get("height", 0)),
		"stars": int(info.get("stars", 0)),
	}
	recent.push_front(row)
	while recent.size() > MAX_RECENT:
		recent.pop_back()
	_notify()


## Lịch sử gần đây (mới nhất trước)
func recent_activity(limit: int = 3) -> Array:
	var out: Array = []
	for i in mini(limit, recent.size()):
		out.append(recent[i])
	return out


# ---------------------------------------------------------------------------
# Save / load
# ---------------------------------------------------------------------------
func export_progress() -> Dictionary:
	return {
		"display_name": display_name,
		"avatar_id": avatar_id,
		"frame_id": frame_id,
		"owned_avatars": owned_avatars,
		"owned_frames": owned_frames,
		"uid_suffix": uid_suffix,
		"joined_date": joined_date,
		"runs_played": runs_played,
		"runs_won": runs_won,
		"recent": recent.duplicate(true),
		# --- Số liệu mở rộng (Profiler mới) ---
		"level_plays": level_plays,
		"level_wins": level_wins,
		"first_try_wins": first_try_wins,
		"win_streak": win_streak,
		"level_attempts": level_attempts.duplicate(),
		"mode_plays": mode_plays.duplicate(),
		"dungeon_wall_hits": dungeon_wall_hits,
		"runs_total": runs_total,
		"moves_total": moves_total,
		"time_total": time_total,
		"level_time_total": level_time_total,
		"undos_total": undos_total,
		"wall_draws_total": wall_draws_total,
		"wall_erases_total": wall_erases_total,
		"skips_total": skips_total,
	}


func import_progress(data: Dictionary) -> void:
	display_name = str(data.get("display_name", ""))
	avatar_id = str(data.get("avatar_id", DEFAULT_AVATAR))
	frame_id = str(data.get("frame_id", DEFAULT_FRAME))
	owned_avatars = _to_string_array(data.get("owned_avatars", owned_avatars))
	owned_frames = _to_string_array(data.get("owned_frames", owned_frames))
	uid_suffix = str(data.get("uid_suffix", ""))
	joined_date = str(data.get("joined_date", ""))
	runs_played = int(data.get("runs_played", 0))
	runs_won = int(data.get("runs_won", 0))
	# --- Số liệu mở rộng (Profiler mới) ---
	level_plays = int(data.get("level_plays", 0))
	level_wins = int(data.get("level_wins", 0))
	first_try_wins = int(data.get("first_try_wins", 0))
	win_streak = int(data.get("win_streak", 0))
	level_attempts = _to_int_dict(data.get("level_attempts", {}))
	mode_plays = _to_string_key_dict(data.get("mode_plays", {}))
	dungeon_wall_hits = int(data.get("dungeon_wall_hits", 0))
	runs_total = int(data.get("runs_total", 0))
	moves_total = int(data.get("moves_total", 0))
	time_total = float(data.get("time_total", 0.0))
	level_time_total = float(data.get("level_time_total", 0.0))
	undos_total = int(data.get("undos_total", 0))
	wall_draws_total = int(data.get("wall_draws_total", 0))
	wall_erases_total = int(data.get("wall_erases_total", 0))
	skips_total = int(data.get("skips_total", 0))
	var rows: Variant = data.get("recent", [])
	recent = rows if rows is Array else []
	_ensure_identity()
	_ensure_valid_selection()
	profile_changed.emit()


func reset_progress() -> void:
	display_name = ""
	avatar_id = DEFAULT_AVATAR
	frame_id = DEFAULT_FRAME
	owned_avatars = ["avatar_baby_child_kid", "avatar_boy_kid", "avatar_child_girl"]
	owned_frames = ["frame_default", "frame_laurel", "frame_bronze"]
	runs_played = 0
	runs_won = 0
	recent = []
	# --- Số liệu mở rộng (Profiler mới) ---
	level_plays = 0
	level_wins = 0
	first_try_wins = 0
	win_streak = 0
	level_attempts = {}
	mode_plays = {}
	dungeon_wall_hits = 0
	runs_total = 0
	moves_total = 0
	time_total = 0.0
	level_time_total = 0.0
	undos_total = 0
	wall_draws_total = 0
	wall_erases_total = 0
	skips_total = 0
	uid_suffix = ""
	joined_date = ""
	_ensure_identity()
	_ensure_valid_selection()
	profile_changed.emit()


func _ready() -> void:
	_load_catalog()
	_ensure_identity()
	_ensure_valid_selection()


## Nạp lại danh mục từ .tres (dùng cho test hoặc khi thêm file lúc chạy)
func reload_catalog() -> void:
	_load_catalog()
	_ensure_valid_selection()
	profile_changed.emit()


## Quét 3 thư mục resources/profiler/ (giống ArchivementManager quét danh hiệu)
func _load_catalog() -> void:
	_load_avatars()
	_load_frames()
	_load_titles()


func _load_avatars() -> void:
	_avatars.clear()
	for resource_name in _tres_files(AVATAR_RES_DIR):
		var data := load(AVATAR_RES_DIR + resource_name) as AvatarData
		if data == null or not data.is_valid():
			push_warning("[PlayerProfileManager] Bo qua avatar thieu du lieu: %s" % resource_name)
			continue
		if _find_avatar(data.id) != null:
			push_warning("[PlayerProfileManager] Trung id avatar '%s' (%s) - bo qua" % [data.id, resource_name])
			continue
		_avatars.append(data)
	_avatars.sort_custom(_entry_before)


func _load_frames() -> void:
	_frames.clear()
	for resource_name in _tres_files(FRAME_RES_DIR):
		var data := load(FRAME_RES_DIR + resource_name) as FrameData
		if data == null or not data.is_valid():
			push_warning("[PlayerProfileManager] Bo qua vien khung thieu du lieu: %s" % resource_name)
			continue
		if _find_frame(data.id) != null:
			push_warning("[PlayerProfileManager] Trung id vien khung '%s' (%s) - bo qua" % [data.id, resource_name])
			continue
		_frames.append(data)
	_frames.sort_custom(_entry_before)


func _load_titles() -> void:
	_titles.clear()
	for resource_name in _tres_files(TITLE_RES_DIR):
		var data := load(TITLE_RES_DIR + resource_name) as ProfilerTitleData
		if data == null or not data.is_valid():
			push_warning("[PlayerProfileManager] Bo qua bac danh hieu thieu du lieu: %s" % resource_name)
			continue
		_titles.append(data)
	_titles.sort_custom(_title_before)


## File .tres trong 1 thư mục danh mục. Bản EXPORT chuyển .tres sang binary kèm
## file "<ten>.tres.remap" -> bỏ đuôi .remap mới thấy đúng tên tài nguyên.
func _tres_files(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("[PlayerProfileManager] Khong mo duoc thu muc %s" % dir_path)
		return out
	for file_name in dir.get_files():
		var base := file_name.trim_suffix(".remap")
		if base.ends_with(".tres") and not out.has(base):
			out.append(base)
	out.sort()
	return out


## Thứ tự hiển thị: món tặng sẵn (0) → bán bằng Xu (1, giá tăng dần) → khoá mốc (2)
func _entry_before(a: Resource, b: Resource) -> bool:
	var group_a := _sort_group(a)
	var group_b := _sort_group(b)
	if group_a != group_b:
		return group_a < group_b
	var price_a := int(a.get("price"))
	var price_b := int(b.get("price"))
	if price_a != price_b:
		return price_a < price_b
	return str(a.get("id")) < str(b.get("id"))


func _sort_group(data: Resource) -> int:
	if not str(data.get("lock_stat")).is_empty():
		return 2
	return 1 if int(data.get("price")) > 0 else 0


func _title_before(a: Resource, b: Resource) -> bool:
	return int(a.get("min_level")) < int(b.get("min_level"))


## Save cũ có thể còn id avatar/viền đã bị GỠ khỏi catalog (đổi bộ art mới) —
## trả về mặc định + dọn danh sách sở hữu cho khớp catalog hiện tại.
func _ensure_valid_selection() -> void:
	if _find_avatar(avatar_id) == null:
		avatar_id = DEFAULT_AVATAR
	if _find_frame(frame_id) == null:
		frame_id = DEFAULT_FRAME
	owned_avatars = _prune_owned(true, owned_avatars)
	owned_frames = _prune_owned(false, owned_frames)


func _prune_owned(for_avatars: bool, owned_list: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for ident in owned_list:
		var exists := _find_avatar(ident) != null if for_avatars else _find_frame(ident) != null
		if exists and not out.has(ident):
			out.append(ident)
	return out


## UID + ngày tham gia sinh 1 lần rồi giữ nguyên (mockup: "UID: #IM-8842 • 08/2026")
func _ensure_identity() -> void:
	if uid_suffix.is_empty():
		uid_suffix = "%04d" % (1000 + int(Time.get_unix_time_from_system()) % 9000)
	if joined_date.is_empty():
		var now := Time.get_date_dict_from_system()
		joined_date = "%02d/%04d" % [int(now.get("month", 1)), int(now.get("year", 2026))]


func _notify() -> void:
	profile_changed.emit()


# ---------------------------------------------------------------------------
# Nội bộ
# ---------------------------------------------------------------------------
func _find_avatar(ident: String) -> AvatarData:
	for data in _avatars:
		if data.id == ident:
			return data
	return null


func _find_frame(ident: String) -> FrameData:
	for data in _frames:
		if data.id == ident:
			return data
	return null


## 1 món kèm trạng thái tính sẵn cho UI: owned · equipped · locked · price · icon (đường dẫn)
func _state_of(data: Resource, kind: String) -> Dictionary:
	if data == null:
		return {}
	var ident := str(data.get("id"))
	var owned_list := owned_avatars if kind == "avatar" else owned_frames
	var equipped := avatar_id if kind == "avatar" else frame_id
	var price := int(data.get("price"))
	var lock := _lock_from(data)
	var icon := data.get("icon") as Texture2D
	return {
		"kind": kind,
		"id": ident,
		"name_key": str(data.get("name_key")),
		"icon": icon.resource_path if icon != null else "",
		"price": price,
		"_free": price <= 0,
		"equipped": ident == equipped,
		"owned": owned_list.has(ident) or price <= 0,
		"locked": not lock.is_empty(),
		"lock_stat": str(lock.get("stat", "")),
		"lock_value": int(lock.get("value", 0)),
	}


func _to_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out


## Dữ liệu lưu dạng Dictionary (level_attempts / mode_plays) — ép về khoá int + giá trị int
func _to_int_dict(value: Variant) -> Dictionary:
	var out := {}
	if value is Dictionary:
		for key in value:
			out[int(key)] = int(value[key])
	return out


## Như `_to_int_dict` nhưng giữ khoá STRING (mode_plays: mode_id -> số lần chơi)
func _to_string_key_dict(value: Variant) -> Dictionary:
	var out := {}
	if value is Dictionary:
		for key in value:
			out[str(key)] = int(value[key])
	return out
