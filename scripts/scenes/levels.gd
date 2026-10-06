class_name LevelScenes
extends BaseScene
## ============================================================================
## View Controller: Màn hình Chọn Màn chơi (Level Selection) — Bản đồ road map
## · Hiển thị bản đồ dọc `LevelMap` (thay cho lưới thẻ phân trang cũ).
## · Bản đồ là node dùng chung cho cả 2 hướng, đặt trong khung `MapArea` (có cắt biên
##   + 2 dải mờ trên/dưới) nên nút màn không lọt lên che header/banner.
## · Người chơi kéo lên/xuống để đi trên bản đồ; bản đồ phát tiến độ cuộn cho nền giấy
##   parallax (`Background`) trượt nhẹ theo.
## · Header giữ nguyên: nút Back, tổng Sao, banner chương, nút Tiếp Tục.
##
## Quy ước của project (xem `scenes/levels.tscn`):
##   · Node UI bind bằng `@export` (`map`, `background`, `LevelsLayout`) — script KHÔNG tra đường dẫn.
##   · Dây tới node TRONG `scenes/levels.tscn` (LevelMap) khai bằng `[connection]`.
##   · Dây tới nút NẰM TRONG 2 bố cục (Portrait/Landscape là scene instance — Godot KHÔNG
##     tạo được `[connection]` xuyên vào node bên trong instance) nối bằng `ensure_signal`
##     có guard `is_connected` — gọi lại được mỗi lần đổi hướng.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
## Banner chương: bản thường + bản "focus" (có chương đủ Sao để mở)
const BANNER_NORMAL := preload("res://assets/images-png/level_selector/chapter_banner.png")
const BANNER_FOCUS  := preload("res://assets/images-png/level_selector/chapter_banner_focus.png")

## Bố cục đang hiển thị (Portrait / Landscape) — gắn lại mỗi lần ĐỔI HƯỚNG
var layout: LevelsLayout = null
## Bản đồ + nền giấy — bind trong `scenes/levels.tscn`
@export var map: LevelMap = null
@export var background: SceneBackground = null

var _level_ids: Array[int] = []
var _level_data: Dictionary = {}   # level_id -> LevelData (chỉ các file có thật)
var _banner_focus := false


func _ready() -> void:
	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)
	_build_map()
	_refresh_header()


## Phát lại EnterAnim mỗi khi màn được kích hoạt (quay lại từ màn khác)
func _on_active() -> void:
	UIAnim.play_layout_anim(active_layout(), "EnterAnim", &"enter")


## Gắn node UI từ BỐ CỤC đang hiển thị (2 bố cục là 2 scene riêng nhưng CÙNG script
## `LevelsLayout`) — mọi node đã bind bằng `@export` trong .tscn.
func _bind_refs() -> void:
	layout = active_layout() as LevelsLayout
	if layout == null:
		push_warning("LevelScenes: bố cục chưa gắn LevelsLayout")
	if map == null:
		push_warning("LevelScenes: thiếu binding `map` (MapArea/LevelMap)")


## Nối dây cho nút TRONG bố cục + gắn hiệu ứng "sống" (nhún khi bấm, nút Tiếp tục "thở").
## Nút nằm trong scene instance nên KHÔNG khai `[connection]` trong .tscn được — dùng
## `ensure_signal` (guard `is_connected`) để gọi lại an toàn mỗi lần đổi hướng.
func _wire_buttons() -> void:
	if layout == null:
		return
	ensure_signal(layout.btn_back, &"pressed", &"_on_back_pressed")
	ensure_signal(layout.btn_continue, &"pressed", &"_on_continue_pressed")
	if layout.banner != null:
		layout.banner.mouse_filter = Control.MOUSE_FILTER_STOP
		ensure_signal(layout.banner, &"gui_input", &"_on_banner_input")
	for button: BaseButton in [layout.btn_back, layout.btn_continue]:
		if button == null or button.has_meta("bounce_attached"):
			continue
		button.set_meta("bounce_attached", true)
		UIAnim.attach_press_bounce(button)
	if layout.btn_continue != null:
		if not UIAnim.play_layout_anim(layout, "PulseAnim", &"pulse_continue", layout.btn_continue):
			UIAnim.play_pulse(layout.btn_continue, 1.03, 1.8)


# ---------------------------------------------------------------------------
# Bản đồ
# ---------------------------------------------------------------------------
func _build_map() -> void:
	_load_level_ids()
	if map == null:
		return
	map.build(_level_ids, _stars_dict(), _unlocked_level(), chapter_continue_level())


## Kéo bản đồ ⇒ nền giấy trượt theo (tỉ lệ cố định theo từng lớp, đúng nhịp tay kéo)
func _on_map_scrolled(delta_y: float) -> void:
	if background != null:
		background.set_scroll_delta(delta_y)


## Danh sách level_id có file .tres thật (LevelManager quét resources/levels)
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

	if _level_ids.is_empty():
		# Fallback: không có LevelManager (test / --script)
		for level_id in range(1, 10):
			_level_ids.append(level_id)


## Chỉ giữ các màn thuộc CHƯƠNG đang chơi
func _filter_by_chapter() -> void:
	var chapter := _current_chapter()
	if chapter <= 0:
		return
	var filtered: Array[int] = []
	for level_id in _level_ids:
		if _chapter_of(level_id) == chapter:
			filtered.append(level_id)
	if not filtered.is_empty():
		_level_ids = filtered


func _current_chapter() -> int:
	var gm := _game_manager()
	if gm == null:
		return 0
	var value: Variant = gm.get("current_chapter")
	return maxi(int(value), 0) if value != null else 0


func chapter_title() -> String:
	var chapter := _chapter_data()
	if chapter == null:
		return ""
	return TranslationServer.translate("STR_CHAPTER_TITLE_FORMAT").format([chapter.chapter_id, chapter.display_title()])


func _chapter_data() -> ChapterData:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_chapter"):
		return null
	var chapter := _current_chapter()
	if chapter <= 0:
		chapter = 1
	return lm.call("get_chapter", chapter) as ChapterData


func _chapter_of(level_id: int) -> int:
	var data: LevelData = _level_data.get(level_id, null)
	return maxi(data.chapter, 1) if data != null else 1


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


## Tất cả màn trong chương đã hoàn thành
func chapter_cleared() -> bool:
	var stars := _stars_dict()
	for level_id in _level_ids:
		if int(stars.get(level_id, 0)) <= 0:
			return false
	return not _level_ids.is_empty()


func _stars_dict() -> Dictionary:
	var gm := _game_manager()
	var stars: Variant = gm.get("level_stars") if gm != null else null
	return stars if stars is Dictionary else {}


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


# ---------------------------------------------------------------------------
# Orientation / resize
# ---------------------------------------------------------------------------
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	_wire_buttons()
	_refresh_header()
	# Bản đồ tự dựng lại khi khung đổi cỡ (LevelMap nghe `size_changed` của viewport)


# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
func _refresh_header() -> void:
	if layout == null:
		return
	var chapter := _chapter_data()
	var own := 0
	var total := maxi(_level_ids.size(), 1) * 3
	var stars := _stars_dict()
	var lm: Node = get_node_or_null("/root/LevelManager")
	if chapter != null and lm != null and lm.has_method("chapter_stars"):
		own   = int(lm.call("chapter_stars", chapter.chapter_id))
		total = maxi(int(lm.call("chapter_star_total", chapter.chapter_id)), 1)
	else:
		for value in stars.values():
			own += int(value)

	if layout.lbl_stars != null:
		layout.lbl_stars.text = str(own)
	if layout.lbl_stars_total != null:
		layout.lbl_stars_total.text = tr("STR_STARS_TOTAL_FORMAT").format([total])
	if layout.lbl_chapter != null:
		var title := chapter_title()
		if not title.is_empty():
			layout.lbl_chapter.text = title
	_refresh_chapter_banner()
	if layout.lbl_continue != null:
		layout.lbl_continue.text = TranslationServer.translate("STR_CHAPTER_SCREEN_TITLE") if chapter_cleared() \
			else tr("STR_BTN_CONTINUE_LEVEL").format([chapter_continue_level()])


func _refresh_chapter_banner() -> void:
	if layout == null:
		return
	var gm := _game_manager()
	var unlockable := gm != null and gm.has_method("has_unlockable_chapter") \
		and bool(gm.call("has_unlockable_chapter"))
	if unlockable != _banner_focus:
		_banner_focus = unlockable
		if layout.banner != null:
			var art: Texture2D = layout.banner_focus if unlockable else layout.banner_normal
			layout.banner.texture = art if art != null else (BANNER_FOCUS if unlockable else BANNER_NORMAL)
		if layout.lbl_change_chapter != null:
			layout.lbl_change_chapter.theme_type_variation = &"LevelsChangeChapterFocus" if unlockable \
				else &"LevelsChangeChapter"
		if unlockable and layout.banner != null:
			if not UIAnim.play_layout_anim(layout, "PulseAnim", &"pulse_banner", layout.banner):
				UIAnim.play_pulse(layout.banner, 1.02, 1.6)
	if layout.lbl_change_chapter != null:
		layout.lbl_change_chapter.text = TranslationServer.translate(
			"STR_CHAPTER_UNLOCKABLE" if unlockable else "STR_CHANGE_CHAPTER")


# ---------------------------------------------------------------------------
# Events (dây signal khai trong `scenes/levels.tscn`)
# ---------------------------------------------------------------------------
func _on_banner_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		Nav.goto_chapters()


func _on_level_selected(level_id: int) -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", level_id)
	else:
		Nav.goto_game()


func _on_continue_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	var gm := _game_manager()
	if chapter_cleared():
		Nav.goto_chapters()
		return
	var level_id := chapter_continue_level()
	if gm != null and level_id <= _unlocked_level() and gm.has_method("start_level"):
		gm.call("start_level", level_id)
	elif gm != null:
		Nav.goto_chapters()
	else:
		Nav.goto_game()


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	Nav.goto_main()


# ---------------------------------------------------------------------------
# Public API (tương thích ngược nếu cần)
# ---------------------------------------------------------------------------
func level_ids() -> Array[int]:
	return _level_ids.duplicate()
