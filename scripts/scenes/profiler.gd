class_name ProfilerScene
extends BaseUI
## ============================================================================
## NỘI DUNG HỒ SƠ CÁ NHÂN (nodes/popups/profiler_content.tscn) — mockup/profiler.svg.
##
## Scene ĐỘC LẬP kế thừa `BaseUI` (nhận biết hướng + đổi layout Portrait ⇄ Landscape),
## KHÔNG kế thừa `BaseScene` — vì đây là NỘI DUNG nằm trong popup chứ không phải màn hình:
## nó được instantiate vào `Panel/Content/Profiler` của `nodes/popups/profiler_popup.tscn`
## và phủ kín vùng nội dung popup (BaseUI CHỈ đổi layout khi có node Portrait/Landscape).
## Nút Back đóng popup qua `owner_popup`; popup Edit Profile mở chồng LÊN TRÊN.
##
## Nguồn dữ liệu: PlayerProfileManager (qua facade `Profile`) — toàn bộ số liệu
## tích luỹ nằm trong `Profile.deep_stats()` (5 nhóm: Play · Dungeon · Time · Game Mode · In Game).
##
## DANH SÁCH THÔNG TIN (theo mockup): 5 nhóm, mỗi nhóm = băng washi dán tiêu đề +
## lưới THẺ số liệu (`ProfilerStatCard`) có ICON:
##   · Icon tách từ mockup → `assets/images/profiler/ic_*.svg` (21 icon)
##   · Chế độ đặc biệt không có icon trong mockup → dùng icon sẵn có của game (`icons/`)
##   · Icon + màu washi/đầu nhóm theo nhóm (xem `TAPES`/`SQUIGGLES`)
## Bố cục DỌC: thẻ đứng (icon trên, số dưới + nét nguệch ngoạc), lưới 3/2/3/4/3 cột.
## Bố cục NGANG (mockup profiler_landscape): Hero nằm CỘT TRÁI, danh sách ở CỘT PHẢI cuộn DỌC
## với thẻ NGANG (icon trái, số phải), lưới 4 cột; đầu nhóm = băng washi dán trái + đường gạch nối.
## Hero card GIỮ CỐ ĐỊNH ngoài vùng cuộn ở cả 2 hướng (KHÔNG còn nút Đổi avatar/Chia sẻ —
## bấm avatar hoặc icon bút cạnh tên để mở popup Diện mạo).
##
## Layout tĩnh (vị trí/kích thước/dây nút) khai trong
## `scenes/layout/portrait|landscape/profiler_popup.tscn`; ở đây chỉ ĐỔ DỮ LIỆU.
## ============================================================================

## Scene 1 NHÓM số liệu (băng washi + lưới thẻ) — dựng vào `layout.info_list`
const GROUP_SCENE := preload("res://nodes/profiler/stat_group.tscn")

## Icon từng ô số liệu: 21 icon tách từ mockup + 7 icon có sẵn của game
## (các CHẾ ĐỘ ĐẶC BIỆT không xuất hiện trong mockup: mìn, tổng đường, đếm ngược…)
const ICONS := {
	"play": preload("res://assets/images/profiler/ic_play.svg"),
	"trophy": preload("res://assets/images/profiler/ic_trophy.svg"),
	"pie": preload("res://assets/images/profiler/ic_pie.svg"),
	"target": preload("res://assets/images/profiler/ic_target.svg"),
	"flame": preload("res://assets/images/profiler/ic_flame.svg"),
	"calendar": preload("res://assets/images/profiler/ic_calendar.svg"),
	"castle": preload("res://assets/images/profiler/ic_castle.svg"),
	"wall": preload("res://assets/images/profiler/ic_wall.svg"),
	"stopwatch": preload("res://assets/images/profiler/ic_stopwatch.svg"),
	"hourglass": preload("res://assets/images/profiler/ic_hourglass.svg"),
	"bolt": preload("res://assets/images/profiler/ic_bolt.svg"),
	"feet": preload("res://assets/images/profiler/ic_feet.svg"),
	"route": preload("res://assets/images/profiler/ic_route.svg"),
	"pencil": preload("res://assets/images/profiler/ic_pencil.svg"),
	"revert": preload("res://assets/images/profiler/ic_revert.svg"),
	"undo": preload("res://assets/images/profiler/ic_undo.svg"),
	"skip": preload("res://assets/images/profiler/ic_skip.svg"),
	"maze": preload("res://assets/images/profiler/ic_maze.svg"),
	"gate": preload("res://assets/images/profiler/ic_gate.svg"),
	"sun": preload("res://assets/images/profiler/ic_sun.svg"),
	"rocket": preload("res://assets/images/profiler/ic_rocket.svg"),
	"bomb": preload("res://assets/images/icons/icon_bomb.svg"),
	"logic": preload("res://assets/images/icons/icon_logic.svg"),
	"tool_time": preload("res://assets/images/icons/icon_tool_time.svg"),
	"bulb": preload("res://assets/images/icons/icon_bulb.svg"),
	"cloud": preload("res://assets/images/icons/icon_cloud.svg"),
	"ink": preload("res://assets/images/icons/icon_ink.svg"),
	"pen": preload("res://assets/images/icons/icon_pen.svg"),
}

## Băng washi tiêu đề theo nhóm (màu lấy đúng mockup)
const TAPES := {
	"play": preload("res://assets/images/profiler/tape_play.svg"),
	"dungeon": preload("res://assets/images/profiler/tape_dungeon.svg"),
	"time": preload("res://assets/images/profiler/tape_time.svg"),
	"mode": preload("res://assets/images/profiler/tape_mode.svg"),
	"ingame": preload("res://assets/images/profiler/tape_ingame.svg"),
}

## Nét nguệch ngoạc dưới số liệu theo nhóm
const SQUIGGLES := {
	"play": preload("res://assets/images/profiler/squiggle_play.svg"),
	"dungeon": preload("res://assets/images/profiler/squiggle_dungeon.svg"),
	"time": preload("res://assets/images/profiler/squiggle_time.svg"),
	"mode": preload("res://assets/images/profiler/squiggle_mode.svg"),
	"ingame": preload("res://assets/images/profiler/squiggle_ingame.svg"),
}

## Nhóm "GAME MODE STATS": mỗi THẺ = 1 chế độ (SỐ LẦN CHƠI) + icon riêng;
## `ids` = các mode_id cộng dồn vào thẻ đó; `icon` = khoá trong `ICONS`
const MODE_ROWS: Array = [
	{"key": "STR_MODE_PLAY_NAME", "ids": ["play"], "icon": "maze"},
	{"key": "STR_MODE_DUNGEON_NAME", "ids": ["dungeon"], "icon": "gate"},
	{"key": "STR_MODE_DAILY_CLASSIC_NAME", "ids": ["daily_classic"], "icon": "sun"},
	{"key": "STR_MODE_DAILY_CHALLENGE_NAME", "ids": ["daily_challenge"], "icon": "calendar"},
	{"key": "STR_MODE_CHALLENGE_NAME", "ids": ["challenge"], "icon": "rocket"},
	{"key": "STR_MODE_MINESWEEPER", "ids": ["minesweeper"], "icon": "bomb"},
	{"key": "STR_MODE_SUM_PATH", "ids": ["sum_path"], "icon": "logic"},
	{"key": "STR_MODE_COUNTDOWN_COST", "ids": ["countdown_cost"], "icon": "tool_time"},
	{"key": "STR_MODE_BLIND_MEMORY", "ids": ["blind_memory"], "icon": "bulb"},
	{"key": "STR_MODE_FOG_OF_WAR", "ids": ["fog_of_war"], "icon": "cloud"},
	{"key": "STR_MODE_FADING_INK", "ids": ["fading_ink"], "icon": "ink"},
	{"key": "STR_MODE_ONE_STROKE", "ids": ["one_stroke"], "icon": "pen"},
	{"key": "STR_MODE_WALL_BUILDER", "ids": ["wall_builder"], "icon": "wall"},
]

## Chiều rộng 1 nhóm ở bố cục NGANG — danh sách chiếm hết cột phải nên không cần nữa

## Layout đang hiển thị (Portrait / Landscape — cùng tên node, bind qua @export)
var layout: ProfilerLayout = null

## Popup đang chứa nội dung này (ProfilerPopup gán lúc mở) — nút Back sẽ ĐÓNG popup
## thay vì điều hướng màn hình. Chạy độc lập (test/harness) thì về Màn hình chính như cũ.
var owner_popup: BasePopup = null


func _ready() -> void:
	_bind_refs()
	# Dây nút khai trong `nodes/popups/profiler_content.tscn` (cả 2 hướng) — guard chỉ nối lại nếu mất
	if layout != null:
		ensure_signal(layout.btn_close, &"pressed", &"_on_close_pressed")
		var hero_btn := layout.hero_btn_avatar as BaseButton
		ensure_signal(hero_btn, &"pressed", &"_on_edit_pressed")
	orientation_changed.connect(_on_orientation_changed)
	_connect_manager()
	refresh()


func _bind_refs() -> void:
	layout = active_layout() as ProfilerLayout
	if layout == null:
		push_warning("profiler: bố cục chưa gắn ProfilerLayout — thiếu binding trong scenes/layout/<hướng>/profiler_popup.tscn")


func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	refresh()


func _connect_manager() -> void:
	var m := Profile.manager()
	if m != null and m.has_signal("profile_changed") and not m.is_connected("profile_changed", _on_profile_changed):
		m.connect("profile_changed", _on_profile_changed)


func _on_profile_changed() -> void:
	refresh()


# ---------------------------------------------------------------------------
# API công khai (test)
# ---------------------------------------------------------------------------
## Nạp lại toàn bộ số liệu hồ sơ lên layout đang hiển thị
func refresh() -> void:
	if layout == null:
		return
	Archivement.refresh()
	_refresh_header()
	_refresh_hero()
	_refresh_info()


## Số NHÓM thông tin đang hiển thị (test) — mỗi nhóm là 1 nodes/profiler/stat_group.tscn
func info_group_count() -> int:
	if layout == null or layout.info_list == null:
		return 0
	var count := 0
	for child in layout.info_list.get_children():
		if child is ProfilerStatGroup:
			count += 1
	return count


# ---------------------------------------------------------------------------
# Nút
# ---------------------------------------------------------------------------
func _on_close_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	if owner_popup != null and is_instance_valid(owner_popup):
		owner_popup.close()
		return
	Nav.goto_main()


func _on_edit_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Popups.open(Popups.EDIT_PROFILE)


# ---------------------------------------------------------------------------
# Nạp dữ liệu từng khu
# ---------------------------------------------------------------------------
func _refresh_header() -> void:
	var chip := layout.chip_text()
	if chip != null:
		chip.text = tr("STR_PROFILE_LEVEL_FORMAT").format([Profile.level()])
	if layout.lbl_title != null:
		layout.lbl_title.text = tr("STR_PROFILE_TITLE")


func _refresh_hero() -> void:
	_set_texture(layout.hero_avatar, Profile.avatar_icon(Profile.avatar_id()))
	_set_texture(layout.hero_frame, Profile.frame_icon(Profile.frame_id()))
	# Các nhãn thẻ hero: bind thẳng trong .tscn (2 hướng khai cùng tên)
	if layout.hero_name != null:
		layout.hero_name.text = Profile.display_name()
	if layout.hero_tier_text != null:
		layout.hero_tier_text.text = tr(Profile.title_key())
	if layout.hero_exp_value != null:
		layout.hero_exp_value.text = tr("STR_PROFILE_EXP_FORMAT").format([Profile.exp_in_level(), Profile.exp_step()])
	if layout.hero_uid != null:
		# Bố cục NGANG (mockup mới) tách "UID" và "THAM GIA" thành 2 khối riêng → giá trị trần;
		# bố cục dọc giữ 1 dòng "UID: #IM-xxxx • 10/2026" như cũ.
		if layout.hero_join != null:
			layout.hero_uid.text = Profile.uid_code()
		else:
			layout.hero_uid.text = tr("STR_PROFILE_UID_FORMAT").format([Profile.uid_text()])
	if layout.hero_join != null:
		layout.hero_join.text = Profile.joined_date_text()
	if layout.hero_exp_remain != null:
		var remain := maxi(Profile.exp_step() - Profile.exp_in_level(), 0)
		layout.hero_exp_remain.text = tr("STR_PROFILE_EXP_REMAIN").format([remain, Profile.level() + 1])
	_fill_bar()


## Thanh EXP: bề rộng phần tô theo tỉ lệ EXP trong cấp
## (BarFill khai neo "left-wide" trong .tscn nên bề rộng = offset_right,
##  chiều cao do neo quyết định — đặt thẳng `size` sẽ bị hệ layout ghi đè)
func _fill_bar() -> void:
	var track := layout.hero_track
	var fill := layout.hero_fill
	if track == null or fill == null:
		return
	var step := maxi(Profile.exp_step(), 1)
	var ratio := clampf(float(Profile.exp_in_level()) / float(step), 0.0, 1.0)
	fill.offset_right = fill.offset_left + maxf(roundf(track.size.x * ratio), 4.0)


# ---------------------------------------------------------------------------
# Danh sách thông tin — 5 nhóm THẺ có icon, cuộn DỌC ở cả 2 hướng
# ---------------------------------------------------------------------------
func _refresh_info() -> void:
	if layout.info_list == null:
		return
	for child in layout.info_list.get_children():
		layout.info_list.remove_child(child)
		child.queue_free()
	var data := Profile.deep_stats()
	var mode_counts: Dictionary = data.get("mode_plays", {})

	# 1. PLAY STATS — 6 thẻ (3 cột × 2 hàng)
	_add_info_group("play", tr("STR_PROFILE_GROUP_PLAY"), 3, [
		_card("play", "STR_PROFILE_STAT_LEVEL_PLAY", str(int(data.get("level_plays", 0)))),
		_card("trophy", "STR_PROFILE_STAT_LEVEL_WIN", str(int(data.get("level_wins", 0)))),
		_card("pie", "STR_PROFILE_STAT_WINRATE",
			tr("STR_PROFILE_STAT_WINRATE_VALUE").format(["%.1f" % float(data.get("level_winrate", 0.0))])),
		_card("target", "STR_PROFILE_STAT_FIRST_TRY", str(int(data.get("first_try_wins", 0)))),
		_card("flame", "STR_PROFILE_STAT_STREAK_NOW", str(int(data.get("win_streak", 0)))),
		_card("calendar", "STR_PROFILE_STAT_DAILY_DAYS", str(int(data.get("daily_days", 0)))),
	])

	# 2. DUNGEON STATS — 2 thẻ rộng (2 cột)
	_add_info_group("dungeon", tr("STR_PROFILE_GROUP_DUNGEON"), 2, [
		_card("castle", "STR_PROFILE_STAT_HIGHEST_FLOOR", str(int(data.get("highest_floor", 0)))),
		_card("wall", "STR_PROFILE_STAT_WALL_COLLISIONS", str(int(data.get("dungeon_wall_hits", 0)))),
	])

	# 3. TIME STATS — 3 thẻ (3 cột)
	_add_info_group("time", tr("STR_PROFILE_GROUP_TIME"), 3, [
		_card("stopwatch", "STR_PROFILE_STAT_AVG_LEVEL_TIME", _fmt_time(float(data.get("avg_level_time", 0.0)))),
		_card("hourglass", "STR_PROFILE_STAT_TOTAL_LEVEL_TIME", _fmt_time(float(data.get("total_level_time", 0.0)))),
		_card("bolt", "STR_PROFILE_STAT_AVG_TIME_MOVE",
			tr("STR_PROFILE_TIME_SEC").format(["%.1f" % float(data.get("avg_time_move", 0.0))])),
	])

	# 4. GAME MODE STATS — SỐ LẦN CHƠI TỪNG CHẾ ĐỘ (13 thẻ, 4 cột; chưa chơi → thẻ mờ)
	var mode_cards: Array = []
	for entry_v in MODE_ROWS:
		var entry: Dictionary = entry_v
		var count := 0
		for mode_id in entry.get("ids", []):
			count += int(mode_counts.get(str(mode_id), 0))
		mode_cards.append(_card(str(entry.get("icon", "")), str(entry.get("key", "")), str(count), count == 0))
	_add_info_group("mode", tr("STR_PROFILE_GROUP_MODES"), 4, mode_cards)

	# 5. IN GAME STATS — 6 thẻ (3 cột × 2 hàng)
	_add_info_group("ingame", tr("STR_PROFILE_GROUP_INGAME"), 3, [
		_card("route", "STR_PROFILE_STAT_AVG_MOVE", "%.1f" % float(data.get("avg_move", 0.0))),
		_card("feet", "STR_PROFILE_STAT_TOTAL_MOVE", str(int(data.get("moves_total", 0)))),
		_card("pencil", "STR_PROFILE_STAT_WALL_DRAW", str(int(data.get("wall_draws", 0)))),
		_card("revert", "STR_PROFILE_STAT_REVERT_USED", str(int(data.get("wall_erases", 0)))),
		_card("undo", "STR_PROFILE_STAT_UNDO_USED", str(int(data.get("undos_total", 0)))),
		_card("skip", "STR_PROFILE_STAT_SKIP_USED", str(int(data.get("skips_total", 0)))),
	])


## Dựng 1 nhóm vào `layout.info_list`. Bố cục NGANG (danh sách ở CỘT PHẢI): thẻ NGANG
## (icon trái, số phải), đầu nhóm dán trái + đường gạch nối — xem `ProfilerStatGroup.setup`.
## Nhóm NGANG CHỈ 1 HÀNG mà thừa bề ngang (≤ 4 thẻ) được giãn ĐÚNG số thẻ cho kín hàng
## (VD Dungeon 2 thẻ → mỗi thẻ nửa bề rộng) — nhóm nhiều hàng giữ lưới 4 cột.
func _add_info_group(tape_key: String, title: String, columns: int, entries: Array) -> void:
	var group := GROUP_SCENE.instantiate() as ProfilerStatGroup
	layout.info_list.add_child(group)
	var wide := layout.is_side_layout()
	var cols := columns
	if wide:
		cols = entries.size() if entries.size() <= 4 else 4
	group.setup(title, TAPES[tape_key], SQUIGGLES[tape_key], entries, cols, wide)


## 1 thẻ số liệu: icon (khoá `ICONS`) + nhãn (khoá dịch) + giá trị đã định dạng
func _card(icon_key: String, label_key: String, value: String, muted := false) -> Dictionary:
	return {
		"icon": ICONS.get(icon_key),
		"label": tr(label_key),
		"value": value,
		"muted": muted,
	}


## Thời gian: "45s" · "12m 05s" · "1h 02m"
func _fmt_time(seconds: float) -> String:
	var s := maxi(roundi(seconds), 0)
	if s < 60:
		return tr("STR_PROFILE_TIME_SEC").format([s])
	if s < 3600:
		return tr("STR_PROFILE_TIME_MIN").format([s / 60, "%02d" % (s % 60)])
	return tr("STR_PROFILE_TIME_HOUR").format([s / 3600, "%02d" % ((s % 3600) / 60)])


# ---------------------------------------------------------------------------
# Tiện ích
# ---------------------------------------------------------------------------
func _set_texture(node: Control, path: String) -> void:
	var rect := node as TextureRect
	if rect == null or path.is_empty():
		return
	rect.texture = load(path) as Texture2D
