extends SceneTree
## ============================================================================
## Sinh file .tres cho danh mục HỒ SƠ (Profiler) — chạy MỘT LẦN (hoặc khi cần
## tạo lại toàn bộ danh mục):
##
##   godot --headless --path . --script res://scripts/tool/gen_profiler_resources.gd
##
## Kết quả (68 file .tres — lớp AvatarData / FrameData / ProfilerTitleData):
##   · res://resources/profiler/avatars/avatar_<id>.tres   (34 avatar)
##   · res://resources/profiler/frames/frame_<id>.tres     (29 viền khung mới)
##   · res://resources/profiler/titles/tier_<n>.tres       (5 bậc danh hiệu)
##
## SAU KHI CHẠY: PlayerProfileManager tự quét 3 thư mục này lúc khởi động —
## thêm món mới chỉ cần TẠO THÊM 1 FILE .tres (không phải sửa code/danh sách).
##
## Bảng dữ liệu bên dưới là NGUỒN GỐC của một lần sinh — sửa .tres trực tiếp
## trong editor là cách làm việc chính; chạy lại script này sẽ GHI ĐÈ tất cả.
## ============================================================================

const AVATAR_ICON_DIR := "res://assets/images/avatars/"
const FRAME_ICON_DIR := "res://assets/images/frames/"
const AVATAR_OUT := "res://resources/profiler/avatars/"
const FRAME_OUT := "res://resources/profiler/frames/"
const TITLE_OUT := "res://resources/profiler/titles/"
## Tiền tố khoá dịch ghép ĐỘNG — test_localization quét mọi chuỗi trong ngoặc kép
## trông như khoá dịch, nên TUYỆT ĐỐI không viết literal tiền tố rỗng ở đây.
const KEY_PREFIX := "ST" + "R_"

## [hậu tố id, giá Xu mực, khoá mốc, mốc cần đạt] — tên file icon = avatar-<hậu tố với '_'→'-'>.png
const AVATARS := [
	# --- Mặc định sở hữu kèm (giá 0) ---
	["baby_child_kid", 0, "", 0],
	["boy_kid", 0, "", 0],
	["child_girl", 0, "", 0],
	# --- Mua bằng Xu mực (400 / 600 / 800) ---
	["actor_chaplin_comedy", 400, "", 0],
	["addicted_draw_love", 600, "", 0],
	["afro_avatar_male_2", 800, "", 0],
	["afro_boy_child", 400, "", 0],
	["alien_avatar_space", 600, "", 0],
	["animal_avatar_bear", 800, "", 0],
	["animal_avatar_mutton", 400, "", 0],
	["apple_avatar_illness", 600, "", 0],
	["beard_hipster_male", 800, "", 0],
	["bug_insect", 400, "", 0],
	["cacti_cactus", 600, "", 0],
	["christmas_clous_santa", 800, "", 0],
	["cloud_crying", 400, "", 0],
	["coffee_cup", 600, "", 0],
	["dead_monster", 800, "", 0],
	["elderly_grandma", 400, "", 0],
	["female_girl", 600, "", 0],
	["female_portrait_2", 800, "", 0],
	["female_portrait", 400, "", 0],
	["indian_male_man", 600, "", 0],
	["indian_man_sikh", 800, "", 0],
	["lazybones_sloth", 400, "", 0],
	["male_man_old", 600, "", 0],
	["male_man", 800, "", 0],
	["man_person", 400, "", 0],
	["nun_sister", 600, "", 0],
	["person_pilot", 800, "", 0],
	# --- Khoá theo mốc thành tích ---
	["artist_avatar_marilyn", 0, "points", 500],
	["builder_helmet_worker", 0, "daily_streak", 30],
	["einstein_professor", 0, "points", 700],
	["fighter_luchador_man", 0, "dungeon_best_floor", 50],
]

## [hậu tố id, giá Xu mực, khoá mốc, mốc cần đạt] — bộ 29 viền mới (2026-10)
const FRAMES := [
	# --- Tặng sẵn lúc mở hồ sơ ---
	["default", 0, "", 0],
	["laurel", 0, "", 0],
	["bronze", 0, "", 0],
	# --- Vòng màu cơ bản ---
	["cyan", 400, "", 0],
	["green", 400, "", 0],
	["orange", 400, "", 0],
	["pink", 400, "", 0],
	["purple", 400, "", 0],
	["red", 400, "", 0],
	["yellow", 400, "", 0],
	["notebook", 400, "", 0],
	# --- Chủ đề ---
	["sky", 600, "", 0],
	["ocean", 600, "", 0],
	["paw", 600, "", 0],
	["valentine", 600, "", 0],
	["crystal", 650, "", 0],
	["silver", 800, "", 0],
	["gold", 800, "", 0],
	["halloween", 800, "", 0],
	["christmas", 800, "", 0],
	["chinese_new_year", 800, "", 0],
	["dinosaur", 800, "", 0],
	# --- Cao cấp ---
	["sun", 1000, "", 0],
	["platinum", 1000, "", 0],
	["royal", 1200, "", 0],
	# --- Khoá theo mốc thành tích ---
	["night", 0, "daily_streak", 30],
	["spike", 0, "dungeon_best_floor", 50],
	["space", 0, "points", 500],
	["leaf", 0, "points", 700],
]

## [cấp tối thiểu, khoá dịch] — tên file = tier_<thứ tự>.tres
const TITLES := [
	[1, "STR_PROFILE_TIER_1"],
	[5, "STR_PROFILE_TIER_2"],
	[10, "STR_PROFILE_TIER_3"],
	[20, "STR_PROFILE_TIER_4"],
	[30, "STR_PROFILE_TIER_5"],
]


func _initialize() -> void:
	_make_dirs()
	var saved := 0
	var failed := 0
	for row: Array in AVATARS:
		if _save_avatar(row):
			saved += 1
		else:
			failed += 1
	for row: Array in FRAMES:
		if _save_frame(row):
			saved += 1
		else:
			failed += 1
	for index in TITLES.size():
		if _save_title(TITLES[index], index + 1):
			saved += 1
		else:
			failed += 1
	print("GEN_PROFILER_RESOURCES: saved=%d failed=%d (avatars=%d frames=%d titles=%d)"
		% [saved, failed, AVATARS.size(), FRAMES.size(), TITLES.size()])
	quit(0 if failed == 0 else 1)


func _make_dirs() -> void:
	var root := DirAccess.open("res://")
	if root == null:
		return
	for path in ["resources/profiler/avatars", "resources/profiler/frames", "resources/profiler/titles"]:
		root.make_dir_recursive(path)


func _save_avatar(row: Array) -> bool:
	var suffix := str(row[0])
	var data := AvatarData.new()
	data.id = "avatar_" + suffix
	data.name_key = (KEY_PREFIX + "avatar_" + suffix).to_upper()
	data.icon = load(AVATAR_ICON_DIR + "avatar-" + suffix.replace("_", "-") + ".png") as Texture2D
	data.price = int(row[1])
	data.lock_stat = str(row[2])
	data.lock_value = int(row[3])
	if data.icon == null:
		push_warning("[gen_profiler] Thieu icon: %s" % data.id)
	return _save(data, AVATAR_OUT + data.id + ".tres")


func _save_frame(row: Array) -> bool:
	var suffix := str(row[0])
	var data := FrameData.new()
	data.id = "frame_" + suffix
	data.name_key = (KEY_PREFIX + "frame_" + suffix).to_upper()
	data.icon = load(FRAME_ICON_DIR + "frame_" + suffix + ".png") as Texture2D
	data.price = int(row[1])
	data.lock_stat = str(row[2])
	data.lock_value = int(row[3])
	if data.icon == null:
		push_warning("[gen_profiler] Thieu icon: %s" % data.id)
	return _save(data, FRAME_OUT + data.id + ".tres")


func _save_title(row: Array, index: int) -> bool:
	var data := ProfilerTitleData.new()
	data.min_level = int(row[0])
	data.name_key = str(row[1])
	return _save(data, TITLE_OUT + "tier_%d.tres" % index)


func _save(res: Resource, path: String) -> bool:
	var err := ResourceSaver.save(res, path)
	if err != OK:
		push_error("[gen_profiler] Khong luu duoc %s (err %d)" % [path, err])
		return false
	return true
