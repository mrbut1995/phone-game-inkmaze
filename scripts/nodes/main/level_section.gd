class_name LevelSection
extends Control
## ============================================================================
## Component: LevelSection — KHỐI BẢN ĐỒ MÀN CHƠI nhúng trong màn Main (nodes/main/level_section.tscn).
##
## Đây là phần LOGIC của màn Levels cũ (scripts/scenes/levels.gd) được tách thành component để
## Main hiển thị thẳng bản đồ (màn Levels bị gỡ). Mỗi bố cục (Portrait / Landscape) của Main có
## MỘT LevelSection riêng; bản đang ẩn không dựng bản đồ (xem `_dirty`).
##
## Gồm: `MapArea` (clip) + `LevelMap` · `ChapterChip` (‹ CHƯƠNG n ›) · `ChapterChestWidget` (rương mốc)
## · `DungeonPill` (nút Dungeon nổi). Khung "chương đang khoá" (`ChapterLockSheet`) nằm trong
## bố cục Main (phủ cả màn) và được bind qua `lock_sheet`.
##
## Quy ước: node UI bind bằng `@export`; dây signal nội bộ khai bằng `[connection]` trong
## nodes/main/level_section.tscn; script chỉ lo DỮ LIỆU (GameManager / LevelManager API như levels.gd).
## ============================================================================

## Kéo bản đồ ⇒ Main chuyển cho nền giấy parallax trượt theo
signal scrolled(delta_y: float)
## Vừa nhận rương ⇒ Main cập nhật ví Xu / tổng Sao
signal chest_claimed

@export var map: LevelMap = null
@export var chapter_chip: ChapterChip = null
@export var chest: ChapterChestWidget = null
@export var dungeon_pill: DungeonPill = null
## Khung chương khoá (NodePath ghi đè trong bố cục Main)
@export var lock_sheet: ChapterLockSheet = null

var _level_ids: Array[int] = []
var _level_data: Dictionary = {}   # level_id -> LevelData
var _dirty := true


func _ready() -> void:
	_wire_lock_sheet()
	_connect_locale_signal()
	_connect_save_signal()
	visibility_changed.connect(_on_visibility_changed)
	refresh()


## Dựng lại bản đồ + chip chương + rương (gọi khi màn active lại, đổi hướng, đổi ngôn ngữ).
## Bố cục ĐANG ẨN thì chỉ đánh dấu `_dirty` (LevelMap cần khung có cỡ thật để dựng).
func refresh() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	_dirty = false
	_wire_lock_sheet()
	_build_map()
	_refresh_chapter_chip()
	_refresh_chest()


## Chỉ làm mới SỐ LIỆU (Sao/rương) — không dựng lại bản đồ, không cuộn lại
func refresh_progress() -> void:
	if not is_visible_in_tree():
		_dirty = true
		return
	_refresh_chapter_chip()
	_refresh_chest()


func _on_visibility_changed() -> void:
	if is_visible_in_tree() and _dirty:
		# Chờ 1 frame để khung đã có cỡ thật rồi mới dựng
		await get_tree().process_frame
		if is_inside_tree():
			refresh()


func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


## Tiến trình người chơi có thể nạp XONG sau khi bản đồ đã dựng (mở Main sớm, test harness):
## lúc đó `GameManager.current_chapter`/`level_stars` mới đúng ⇒ phải DỰNG LẠI, nếu không
## bản đồ hiển thị chương mặc định (1) và nút "màn nên chơi tiếp" không ở trạng thái CURRENT.
func _connect_save_signal() -> void:
	var save: Node = get_node_or_null("/root/SaveManager")
	if save != null and save.has_signal("data_loaded") \
			and not save.is_connected("data_loaded", _on_data_loaded):
		save.connect("data_loaded", _on_data_loaded)


func _on_data_loaded(_source: String) -> void:
	_dirty = true
	refresh()


func _on_locale_changed(_locale: String) -> void:
	refresh_progress()


# ---------------------------------------------------------------------------
# Khung "chương đang khoá"
# ---------------------------------------------------------------------------
func _wire_lock_sheet() -> void:
	if lock_sheet == null:
		return
	if not lock_sheet.unlock_requested.is_connected(_on_unlock_chapter_requested):
		lock_sheet.unlock_requested.connect(_on_unlock_chapter_requested)


func is_sheet_open() -> bool:
	return lock_sheet != null and lock_sheet.is_open()


func close_sheet() -> void:
	if lock_sheet != null:
		lock_sheet.close_sheet()


func _on_unlock_chapter_requested(chapter_id: int) -> void:
	var gm := _game_manager()
	if gm == null:
		return
	if bool(gm.call("unlock_chapter", chapter_id)):
		Sfx.play(Sfx.ACHIEVEMENT)
		close_sheet()
		gm.call("set_chapter", chapter_id)
		_rebuild_for_chapter()
	else:
		Sfx.play(Sfx.BTN_CLICK)


# ---------------------------------------------------------------------------
# Bản đồ (port từ levels.gd)
# ---------------------------------------------------------------------------
func _build_map() -> void:
	_load_level_ids()
	if map == null:
		return
	map.build(_level_ids, _stars_dict(), _unlocked_level(), chapter_continue_level(), bonus_level_ids())


func _on_map_scrolled(delta_y: float) -> void:
	scrolled.emit(delta_y)


func _on_level_selected(level_id: int) -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", level_id)
	else:
		Nav.goto_game()


func _load_level_ids() -> void:
	_level_ids.clear()
	_level_data.clear()
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm != null and lm.has_method("get_level_ids"):
		for level_id in lm.call("get_level_ids"):
			_level_ids.append(int(level_id))
		for level_id in _level_ids:
			_level_data[level_id] = lm.call("load_level", level_id)
		_filter_by_chapter()
	else:
		for level_id in range(1, 10):
			_level_ids.append(level_id)


func _filter_by_chapter() -> void:
	var chapter := _current_chapter()
	if chapter <= 0:
		return
	var filtered: Array[int] = []
	for level_id in _level_ids:
		if _chapter_of(level_id) == chapter:
			filtered.append(level_id)
	_level_ids = filtered


func _chapter_of(level_id: int) -> int:
	var data: LevelData = _level_data.get(level_id, null)
	return maxi(data.chapter, 1) if data != null else 1


func _current_chapter() -> int:
	var gm := _game_manager()
	if gm == null:
		return 0
	var value: Variant = gm.get("current_chapter")
	return maxi(int(value), 0) if value != null else 0


func _chapter_id() -> int:
	return maxi(_current_chapter(), 1)


func _unlocked_level() -> int:
	var gm := _game_manager()
	return maxi(int(gm.get("unlocked_levels")), 1) if gm != null else 1


## Màn "nên chơi tiếp" TRONG chương: màn CHƯA đạt sao đầu tiên
func chapter_continue_level() -> int:
	var stars := _stars_dict()
	for level_id in _level_ids:
		if int(stars.get(level_id, 0)) <= 0:
			return level_id
	return _level_ids[_level_ids.size() - 1] if not _level_ids.is_empty() else 1


func _is_bonus(level_id: int) -> bool:
	var lm: Node = get_node_or_null("/root/LevelManager")
	return lm != null and lm.has_method("is_bonus_level") and bool(lm.call("is_bonus_level", level_id))


func main_level_ids() -> Array[int]:
	var ids: Array[int] = []
	for level_id in _level_ids:
		if not _is_bonus(level_id):
			ids.append(level_id)
	return ids


func bonus_level_ids() -> Array[int]:
	var ids: Array[int] = []
	for level_id in _level_ids:
		if _is_bonus(level_id):
			ids.append(level_id)
	return ids


## Tất cả màn CHÍNH của chương đã xong (BONUS không bắt buộc)
func chapter_cleared() -> bool:
	var stars := _stars_dict()
	var main_ids := main_level_ids()
	for level_id in main_ids:
		if int(stars.get(level_id, 0)) <= 0:
			return false
	return not main_ids.is_empty()


func _stars_dict() -> Dictionary:
	var gm := _game_manager()
	var stars: Variant = gm.get("level_stars") if gm != null else null
	return stars if stars is Dictionary else {}


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func level_ids() -> Array[int]:
	return _level_ids.duplicate()


# ---------------------------------------------------------------------------
# Chương: chip ‹ CHƯƠNG n › + chuyển chương
# ---------------------------------------------------------------------------
func _chapters() -> Array:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_chapters"):
		return []
	return lm.call("get_chapters")


## Mã các chương CÓ màn, tăng dần
func _chapter_ids() -> Array[int]:
	var ids: Array[int] = []
	var lm: Node = get_node_or_null("/root/LevelManager")
	for chapter_v in _chapters():
		var chapter := chapter_v as ChapterData
		if chapter == null:
			continue
		if lm != null and lm.has_method("levels_in_chapter") \
				and (lm.call("levels_in_chapter", chapter.chapter_id) as Array).is_empty():
			continue
		ids.append(chapter.chapter_id)
	ids.sort()
	return ids


## Chương liền kề: `dir` = -1 (trước) / +1 (sau); 0 = không có
func _neighbor_chapter(dir: int) -> int:
	var current := _chapter_id()
	var best := 0
	for chapter_id in _chapter_ids():
		if dir < 0 and chapter_id < current:
			best = chapter_id   # lấy chương lớn nhất nhỏ hơn hiện tại
		elif dir > 0 and chapter_id > current:
			return chapter_id
	return best


func _refresh_chapter_chip() -> void:
	if chapter_chip == null:
		return
	chapter_chip.setup(_chapter_id(), _neighbor_chapter(-1) > 0, _neighbor_chapter(1) > 0,
		chapter_cleared())


func _on_prev_chapter() -> void:
	_go_chapter(_neighbor_chapter(-1))


func _on_next_chapter() -> void:
	_go_chapter(_neighbor_chapter(1))


## Sang chương `chapter_id`: đã mở ⇒ đổi TẠI CHỖ (không đổi scene) · khoá ⇒ mở khung chương khoá
func _go_chapter(chapter_id: int) -> void:
	if chapter_id <= 0 or chapter_id == _chapter_id():
		return
	var gm := _game_manager()
	if gm == null:
		return
	if not bool(gm.call("is_chapter_unlocked", chapter_id)):
		if lock_sheet != null:
			lock_sheet.open_chapter(chapter_id)
		return
	gm.call("set_chapter", chapter_id)
	_rebuild_for_chapter()


func _rebuild_for_chapter() -> void:
	_build_map()
	_refresh_chapter_chip()
	_refresh_chest()


# ---------------------------------------------------------------------------
# Rương mốc thưởng của chương
# ---------------------------------------------------------------------------
func _chapter_stars(chapter_id: int) -> int:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm != null and lm.has_method("chapter_stars"):
		return int(lm.call("chapter_stars", chapter_id))
	var own := 0
	for value in _stars_dict().values():
		own += int(value)
	return own


func _chapter_star_total(chapter_id: int) -> int:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm != null and lm.has_method("chapter_star_total"):
		return maxi(int(lm.call("chapter_star_total", chapter_id)), 1)
	return maxi(main_level_ids().size(), 1) * 3


func _refresh_chest() -> void:
	if chest == null:
		return
	var gm := _game_manager()
	if gm == null or not gm.has_method("chapter_chest_defs"):
		chest.visible = false
		return
	var chapter_id := _chapter_id()
	var total := _chapter_star_total(chapter_id)
	var defs: Array = gm.call("chapter_chest_defs", total)
	var claimed: Array = []
	for i in defs.size():
		var is_claimed := gm.has_method("is_chapter_chest_claimed") \
			and bool(gm.call("is_chapter_chest_claimed", chapter_id, i))
		claimed.append(is_claimed)
	chest.setup(defs, _chapter_stars(chapter_id), total, claimed)


## Bấm rương (đủ Sao): trao thưởng 1 lần/chương rồi mở popup rương (dùng lại popup mốc Daily)
func _on_chest_claim_requested(index: int) -> void:
	var gm := _game_manager()
	if gm == null or not gm.has_method("claim_chapter_chest"):
		return
	var chapter_id := _chapter_id()
	var def: Dictionary = gm.call("claim_chapter_chest", chapter_id, index,
		_chapter_stars(chapter_id), _chapter_star_total(chapter_id))
	if def.is_empty():
		Sfx.play(Sfx.BTN_CLICK)
		return
	Sfx.play(Sfx.ACHIEVEMENT)
	_show_chest_reward(chapter_id, def)
	_refresh_chest()
	chest_claimed.emit()


func _show_chest_reward(chapter_id: int, def: Dictionary) -> void:
	var gm := _game_manager()
	var reward_text := ""
	if gm != null and gm.has_method("chapter_chest_reward_text"):
		reward_text = str(gm.call("chapter_chest_reward_text", def))
	Popups.open(Popups.DAILY_MILESTONE, {
		"stars": int(def.get("stars", 0)),
		"reward": def,
		"reward_text": reward_text,
		"title_text": TranslationServer.translate("STR_CHAPTER_CHEST_POPUP_TITLE").format([
			chapter_id, int(def.get("stars", 0))]),
		"sub_text": TranslationServer.translate("STR_CHAPTER_CHEST_POPUP_SUB"),
	})
