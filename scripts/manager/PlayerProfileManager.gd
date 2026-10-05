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

## Cấp độ → khoá danh hiệu (chip cạnh tên trong Profiler)
const TITLE_TIERS := [
	{"min_level": 1, "key": "STR_PROFILE_TIER_1"},
	{"min_level": 5, "key": "STR_PROFILE_TIER_2"},
	{"min_level": 10, "key": "STR_PROFILE_TIER_3"},
	{"min_level": 20, "key": "STR_PROFILE_TIER_4"},
	{"min_level": 30, "key": "STR_PROFILE_TIER_5"},
]

## Catalog AVATAR — 34 mẫu trong assets/images/avatars/ (3 mặc định sở hữu kèm sẵn)
## · id   = khoá lưu save — KHÔNG đổi sau khi phát hành
## · icon = bản PNG trong cây images-png/avatars/ (tên gốc SVG: <id>.svg với '-' thay '_')
const AVATARS := [
	# --- Mặc định sở hữu kèm ---
	{"id": "avatar_baby_child_kid", "name_key": "STR_AVATAR_BABY_CHILD_KID", "icon": AVATAR_DIR + "avatar-baby-child-kid.png", "price": 0},
	{"id": "avatar_boy_kid", "name_key": "STR_AVATAR_BOY_KID", "icon": AVATAR_DIR + "avatar-boy-kid.png", "price": 0},
	{"id": "avatar_child_girl", "name_key": "STR_AVATAR_CHILD_GIRL", "icon": AVATAR_DIR + "avatar-child-girl.png", "price": 0},
	# --- Mua bằng Xu mực ---
	{"id": "avatar_actor_chaplin_comedy", "name_key": "STR_AVATAR_ACTOR_CHAPLIN_COMEDY", "icon": AVATAR_DIR + "avatar-actor-chaplin-comedy.png", "price": 400},
	{"id": "avatar_addicted_draw_love", "name_key": "STR_AVATAR_ADDICTED_DRAW_LOVE", "icon": AVATAR_DIR + "avatar-addicted-draw-love.png", "price": 600},
	{"id": "avatar_afro_avatar_male_2", "name_key": "STR_AVATAR_AFRO_AVATAR_MALE_2", "icon": AVATAR_DIR + "avatar-afro-avatar-male-2.png", "price": 800},
	{"id": "avatar_afro_boy_child", "name_key": "STR_AVATAR_AFRO_BOY_CHILD", "icon": AVATAR_DIR + "avatar-afro-boy-child.png", "price": 400},
	{"id": "avatar_alien_avatar_space", "name_key": "STR_AVATAR_ALIEN_AVATAR_SPACE", "icon": AVATAR_DIR + "avatar-alien-avatar-space.png", "price": 600},
	{"id": "avatar_animal_avatar_bear", "name_key": "STR_AVATAR_ANIMAL_AVATAR_BEAR", "icon": AVATAR_DIR + "avatar-animal-avatar-bear.png", "price": 800},
	{"id": "avatar_animal_avatar_mutton", "name_key": "STR_AVATAR_ANIMAL_AVATAR_MUTTON", "icon": AVATAR_DIR + "avatar-animal-avatar-mutton.png", "price": 400},
	{"id": "avatar_apple_avatar_illness", "name_key": "STR_AVATAR_APPLE_AVATAR_ILLNESS", "icon": AVATAR_DIR + "avatar-apple-avatar-illness.png", "price": 600},
	{"id": "avatar_beard_hipster_male", "name_key": "STR_AVATAR_BEARD_HIPSTER_MALE", "icon": AVATAR_DIR + "avatar-beard-hipster-male.png", "price": 800},
	{"id": "avatar_bug_insect", "name_key": "STR_AVATAR_BUG_INSECT", "icon": AVATAR_DIR + "avatar-bug-insect.png", "price": 400},
	{"id": "avatar_cacti_cactus", "name_key": "STR_AVATAR_CACTI_CACTUS", "icon": AVATAR_DIR + "avatar-cacti-cactus.png", "price": 600},
	{"id": "avatar_christmas_clous_santa", "name_key": "STR_AVATAR_CHRISTMAS_CLOUS_SANTA", "icon": AVATAR_DIR + "avatar-christmas-clous-santa.png", "price": 800},
	{"id": "avatar_cloud_crying", "name_key": "STR_AVATAR_CLOUD_CRYING", "icon": AVATAR_DIR + "avatar-cloud-crying.png", "price": 400},
	{"id": "avatar_coffee_cup", "name_key": "STR_AVATAR_COFFEE_CUP", "icon": AVATAR_DIR + "avatar-coffee-cup.png", "price": 600},
	{"id": "avatar_dead_monster", "name_key": "STR_AVATAR_DEAD_MONSTER", "icon": AVATAR_DIR + "avatar-dead-monster.png", "price": 800},
	{"id": "avatar_elderly_grandma", "name_key": "STR_AVATAR_ELDERLY_GRANDMA", "icon": AVATAR_DIR + "avatar-elderly-grandma.png", "price": 400},
	{"id": "avatar_female_girl", "name_key": "STR_AVATAR_FEMALE_GIRL", "icon": AVATAR_DIR + "avatar-female-girl.png", "price": 600},
	{"id": "avatar_female_portrait_2", "name_key": "STR_AVATAR_FEMALE_PORTRAIT_2", "icon": AVATAR_DIR + "avatar-female-portrait-2.png", "price": 800},
	{"id": "avatar_female_portrait", "name_key": "STR_AVATAR_FEMALE_PORTRAIT", "icon": AVATAR_DIR + "avatar-female-portrait.png", "price": 400},
	{"id": "avatar_indian_male_man", "name_key": "STR_AVATAR_INDIAN_MALE_MAN", "icon": AVATAR_DIR + "avatar-indian-male-man.png", "price": 600},
	{"id": "avatar_indian_man_sikh", "name_key": "STR_AVATAR_INDIAN_MAN_SIKH", "icon": AVATAR_DIR + "avatar-indian-man-sikh.png", "price": 800},
	{"id": "avatar_lazybones_sloth", "name_key": "STR_AVATAR_LAZYBONES_SLOTH", "icon": AVATAR_DIR + "avatar-lazybones-sloth.png", "price": 400},
	{"id": "avatar_male_man_old", "name_key": "STR_AVATAR_MALE_MAN_OLD", "icon": AVATAR_DIR + "avatar-male-man-old.png", "price": 600},
	{"id": "avatar_male_man", "name_key": "STR_AVATAR_MALE_MAN", "icon": AVATAR_DIR + "avatar-male-man.png", "price": 800},
	{"id": "avatar_man_person", "name_key": "STR_AVATAR_MAN_PERSON", "icon": AVATAR_DIR + "avatar-man-person.png", "price": 400},
	{"id": "avatar_nun_sister", "name_key": "STR_AVATAR_NUN_SISTER", "icon": AVATAR_DIR + "avatar-nun-sister.png", "price": 600},
	{"id": "avatar_person_pilot", "name_key": "STR_AVATAR_PERSON_PILOT", "icon": AVATAR_DIR + "avatar-person-pilot.png", "price": 800},
	# --- Khoá theo mốc thành tích ---
	{"id": "avatar_artist_avatar_marilyn", "name_key": "STR_AVATAR_ARTIST_AVATAR_MARILYN", "icon": AVATAR_DIR + "avatar-artist-avatar-marilyn.png",
		"price": 0, "lock_stat": "points", "lock_value": 500},
	{"id": "avatar_builder_helmet_worker", "name_key": "STR_AVATAR_BUILDER_HELMET_WORKER", "icon": AVATAR_DIR + "avatar-builder-helmet-worker.png",
		"price": 0, "lock_stat": "daily_streak", "lock_value": 30},
	{"id": "avatar_einstein_professor", "name_key": "STR_AVATAR_EINSTEIN_PROFESSOR", "icon": AVATAR_DIR + "avatar-einstein-professor.png",
		"price": 0, "lock_stat": "points", "lock_value": 700},
	{"id": "avatar_fighter_luchador_man", "name_key": "STR_AVATAR_FIGHTER_LUCHADOR_MAN", "icon": AVATAR_DIR + "avatar-fighter-luchador-man.png",
		"price": 0, "lock_stat": "dungeon_best_floor", "lock_value": 50},
]

## Catalog VIỀN KHUNG — 8 mẫu trong assets/images/frames/ (3 mặc định sở hữu kèm sẵn)
const FRAMES := [
	{"id": "frame_gear", "name_key": "STR_FRAME_GEAR", "icon": FRAME_DIR + "frame_gear_gold.png", "price": 0},
	{"id": "frame_laurel", "name_key": "STR_FRAME_LAUREL", "icon": FRAME_DIR + "frame_laurel.png", "price": 0},
	{"id": "frame_ink", "name_key": "STR_FRAME_INK", "icon": FRAME_DIR + "frame_ink_double.png", "price": 0},
	{"id": "frame_fire", "name_key": "STR_FRAME_FIRE", "icon": FRAME_DIR + "frame_fire_spike.png",
		"price": 0, "lock_stat": "daily_streak", "lock_value": 30},
	{"id": "frame_iron", "name_key": "STR_FRAME_IRON", "icon": FRAME_DIR + "frame_iron_dark.png",
		"price": 0, "lock_stat": "dungeon_best_floor", "lock_value": 50},
	{"id": "frame_royal", "name_key": "STR_FRAME_ROYAL", "icon": FRAME_DIR + "frame_royal_aura.png", "price": 800},
	{"id": "frame_crystal", "name_key": "STR_FRAME_CRYSTAL", "icon": FRAME_DIR + "frame_crystal.png", "price": 650},
	{"id": "frame_leaf", "name_key": "STR_FRAME_LEAF", "icon": FRAME_DIR + "frame_leaf.png",
		"price": 0, "lock_stat": "points", "lock_value": 700},
]

const DEFAULT_AVATAR := "avatar_baby_child_kid"
const DEFAULT_FRAME := "frame_gear"

# --- Trạng thái lưu save -----------------------------------------------------
var display_name := ""
var avatar_id := DEFAULT_AVATAR
var frame_id := DEFAULT_FRAME
var owned_avatars: Array[String] = ["avatar_baby_child_kid", "avatar_boy_kid", "avatar_child_girl"]
var owned_frames: Array[String] = ["frame_gear", "frame_laurel", "frame_ink"]
var uid_suffix := ""
var joined_date := ""
## Thống kê tích luỹ cho tỉ lệ thắng (chỉ tính các ván ghi từ khi có tính năng)
var runs_played := 0
var runs_won := 0
## Lịch sử ván gần nhất (mới nhất đứng đầu) — xem `record_run`
var recent: Array = []


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
	return _with_state(AVATARS, "avatar")


func frames() -> Array[Dictionary]:
	return _with_state(FRAMES, "frame")


func avatar_entry(avatar_ident: String) -> Dictionary:
	return _entry(AVATARS, avatar_ident, "avatar")


func frame_entry(frame_ident: String) -> Dictionary:
	return _entry(FRAMES, frame_ident, "frame")


func icon_of(kind: String, ident: String) -> String:
	if kind == "avatar":
		return str(avatar_entry(ident).get("icon", AVATAR_DIR + "avatar-baby-child-kid.png"))
	return str(frame_entry(ident).get("icon", FRAME_DIR + "frame_gear_gold.png"))


func owns_avatar(avatar_ident: String) -> bool:
	return owned_avatars.has(avatar_ident) or bool(_entry(AVATARS, avatar_ident, "avatar").get("_free", false))


func owns_frame(frame_ident: String) -> bool:
	return owned_frames.has(frame_ident) or bool(_entry(FRAMES, frame_ident, "frame").get("_free", false))


## Đủ điều kiện mở khoá theo mốc (dungeon/streak/AP)? Trả {} nếu không bị khoá mốc.
func lock_of(kind: String, ident: String) -> Dictionary:
	var catalog: Array = AVATARS if kind == "avatar" else FRAMES
	return _lock_from_raw(_raw_entry(catalog, ident))


func _lock_from_raw(raw: Dictionary) -> Dictionary:
	var stat_key := str(raw.get("lock_stat", ""))
	if stat_key.is_empty():
		return {}
	var need := int(raw.get("lock_value", 0))
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
	return _buy(AVATARS, owned_avatars, avatar_ident, "avatar")


func buy_frame(frame_ident: String) -> bool:
	return _buy(FRAMES, owned_frames, frame_ident, "frame")


func _buy(catalog: Array, owned_list: Array[String], ident: String, _kind: String) -> bool:
	var entry := _entry(catalog, ident, "")
	if entry.is_empty():
		return false
	var price := int(entry.get("price", 0))
	if price <= 0 and owned_list.has(ident):
		return false
	if not lock_of(_kind_from_catalog(catalog), ident).is_empty():
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


func _kind_from_catalog(catalog: Array) -> String:
	return "avatar" if catalog == AVATARS else "frame"


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


func title_key() -> String:
	var lv := level()
	var key := str(TITLE_TIERS[0]["key"])
	for tier in TITLE_TIERS:
		if lv >= int(tier["min_level"]):
			key = str(tier["key"])
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


# ---------------------------------------------------------------------------
# Lịch sử ván (GameController gọi khi kết thúc ván — bỏ qua ván test Debug)
# ---------------------------------------------------------------------------
func record_run(info: Dictionary) -> void:
	var won := bool(info.get("won", false))
	runs_played += 1
	if won:
		runs_won += 1
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
	owned_frames = ["frame_gear", "frame_laurel", "frame_ink"]
	runs_played = 0
	runs_won = 0
	recent = []
	uid_suffix = ""
	joined_date = ""
	_ensure_identity()
	_ensure_valid_selection()
	profile_changed.emit()


func _ready() -> void:
	_ensure_identity()
	_ensure_valid_selection()


## Save cũ có thể còn id avatar/viền đã bị GỠ khỏi catalog (đổi bộ art mới) —
## trả về mặc định + dọn danh sách sở hữu cho khớp catalog hiện tại.
func _ensure_valid_selection() -> void:
	if _raw_entry(AVATARS, avatar_id).is_empty():
		avatar_id = DEFAULT_AVATAR
	if _raw_entry(FRAMES, frame_id).is_empty():
		frame_id = DEFAULT_FRAME
	owned_avatars = _prune_owned(AVATARS, owned_avatars)
	owned_frames = _prune_owned(FRAMES, owned_frames)


func _prune_owned(catalog: Array, owned_list: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for ident in owned_list:
		if not _raw_entry(catalog, ident).is_empty() and not out.has(ident):
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
func _with_state(catalog: Array, kind: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for raw in catalog:
		var entry := _compute_state(raw, kind)
		out.append(entry)
	return out


## Entry THÔ trong catalog (không kèm trạng thái) — tránh đệ quy khi tính khoá
func _raw_entry(catalog: Array, ident: String) -> Dictionary:
	for raw in catalog:
		if str(raw.get("id", "")) == ident:
			return raw
	return {}


func _entry(catalog: Array, ident: String, kind: String) -> Dictionary:
	var raw := _raw_entry(catalog, ident)
	if raw.is_empty() or kind.is_empty():
		return raw
	return _compute_state(raw, kind)


func _compute_state(raw: Dictionary, kind: String) -> Dictionary:
	var entry := raw.duplicate(true)
	var ident := str(entry.get("id", ""))
	var owned_list := owned_avatars if kind == "avatar" else owned_frames
	var equipped := avatar_id if kind == "avatar" else frame_id
	var price := int(entry.get("price", 0))
	var lock := _lock_from_raw(raw)
	entry["kind"] = kind
	entry["_free"] = price <= 0
	entry["equipped"] = ident == equipped
	entry["owned"] = owned_list.has(ident) or price <= 0
	entry["locked"] = not lock.is_empty()
	entry["lock_stat"] = lock.get("stat", "")
	entry["lock_value"] = int(lock.get("value", 0))
	return entry


func _to_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for item in value:
			out.append(str(item))
	return out
