class_name LevelScenes
extends BaseScene
## ============================================================================
## View Controller: Màn hình Chọn Màn chơi (Level Selection) — Bản đồ road map
## · Hiển thị bản đồ dọc `LevelMap` (thay cho lưới thẻ phân trang cũ).
## · Bản đồ là node dùng chung cho cả 2 hướng, đặt trong khung `MapArea` (có cắt biên
##   + 2 dải mờ trên/dưới) nên nút màn không lọt lên che header/banner.
## · Người chơi kéo lên/xuống để đi trên bản đồ; bản đồ phát tiến độ cuộn cho nền giấy
##   parallax (`Background`) trượt nhẹ theo.
## · Header: nút Back + 2 chip (xu/bút chì) · hàng TAB chương · thẻ chương · thanh thưởng
##   · thẻ "MÀN TIẾP THEO" · khung "chương đang khoá". Bản NGANG dùng chung bản đồ: `MapArea`
##   được kéo về khớp khung `map_slot` của bố cục ngang (xem `_fit_map_area`).
##
## Quy ước của project (xem `scenes/levels.tscn`):
##   · Node UI bind bằng `@export` (`map`, `background`, `LevelsLayout`) — script KHÔNG tra đường dẫn.
##   · TOÀN BỘ dây signal khai bằng `[connection]` trong `scenes/levels.tscn` — kể cả nút
##     nằm trong 2 bố cục (Portrait/Landscape): `[connection]` trỏ vào node bên trong
##     scene instance hoạt động bình thường (giống các màn shop / chapters / settings…).
##   · Script chỉ còn phần ĐỘNG: hiệu ứng nút (nhún/thở) + dữ liệu bản đồ.
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
## Bố cục đang hiển thị (Portrait / Landscape) — gắn lại mỗi lần ĐỔI HƯỚNG
var layout: LevelsLayout = null
## Bản đồ + nền giấy — bind trong `scenes/levels.tscn`
@export var map: LevelMap = null
@export var background: SceneBackground = null

var _level_ids: Array[int] = []
var _level_data: Dictionary = {}   # level_id -> LevelData (chỉ các file có thật)
var _last_slot_rect := Rect2()
var _fitted_wide := false


func _ready() -> void:
	_bind_refs()
	_setup_button_effects()
	orientation_changed.connect(_on_orientation_changed)
	_connect_locale_signal()
	_build_map()
	_refresh_header()
	_wire_progress()
	_refresh_progress()
	_wire_chapter_ui()
	_refresh_chapter_ui()


## `MapArea` (nằm ngoài bố cục) phải khớp khung `map_slot` của bố cục đang hiện (dọc hoặc ngang) —
## khung này đổi theo cỡ cửa sổ / `FitStage` ⇒ kiểm tra mỗi frame (chỉ tốn khi rect đổi).
func _process(_delta: float) -> void:
	_fit_map_area()


## Kéo `MapArea` về đúng ô `map_slot` của bố cục đang hiện; không có ô ⇒ trả về neo mặc định (31%–82% cao).
func _fit_map_area() -> void:
	var area := map.get_parent() as Control if map != null else null
	if area == null or layout == null:
		return
	var slot := layout.map_slot
	if slot == null or not slot.is_visible_in_tree():
		if _fitted_wide:
			_fitted_wide = false
			_last_slot_rect = Rect2()
			area.anchor_left = 0.0
			area.anchor_right = 1.0
			area.anchor_top = 0.31
			area.anchor_bottom = 0.82
			area.offset_left = 0.0
			area.offset_right = 0.0
			area.offset_top = 0.0
			area.offset_bottom = 0.0
		return
	var rect := slot.get_global_rect()
	# So với rect THẬT của MapArea (không dùng cache): `base.gd` có thể đặt lại neo/cỡ của MapArea
	# SAU lần xoay màn hình (cảnh báo "_after_responsive_layout") ⇒ phải áp lại nếu nó bị đè.
	if _fitted_wide and area.get_global_rect().is_equal_approx(rect):
		return
	_fitted_wide = true
	_last_slot_rect = rect
	area.set_anchors_preset(Control.PRESET_TOP_LEFT)
	area.global_position = rect.position
	area.size = rect.size


## Đổi ngôn ngữ ⇒ viết lại mọi nhãn của màn (banner · tab · thẻ chương · thẻ màn kế · rail).
## Bảng dịch có thể nạp XONG sau `_ready()` của màn nên phải nghe cả tín hiệu này.
func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	if layout == null:
		return
	_refresh_header()
	_refresh_progress()
	_refresh_chapter_ui()


## Phát lại EnterAnim mỗi khi màn được kích hoạt (quay lại từ màn khác)
func _on_active() -> void:
	UIAnim.play_layout_anim(active_layout(), "EnterAnim", &"enter")
	# Thắng/thua màn xong quay lại đây ⇒ số Sao có thể đã đổi ⇒ vẽ lại thanh + rương + thẻ
	_refresh_header()
	_refresh_progress()
	_refresh_chapter_ui()


## Gắn node UI từ BỐ CỤC đang hiển thị (2 bố cục là 2 scene riêng nhưng CÙNG script
## `LevelsLayout`) — mọi node đã bind bằng `@export` trong .tscn.
func _bind_refs() -> void:
	layout = active_layout() as LevelsLayout
	if layout == null:
		push_warning("LevelScenes: bố cục chưa gắn LevelsLayout")
	if map == null:
		push_warning("LevelScenes: thiếu binding `map` (MapArea/LevelMap)")


## Hiệu ứng "nhún khi bấm" cho nút Back. DÂY SIGNAL khai trong `scenes/levels.tscn` bằng
## `[connection]` — hàm này chạy lại mỗi lần đổi hướng (mỗi bố cục có nút riêng).
func _setup_button_effects() -> void:
	if layout == null:
		return
	var button: BaseButton = layout.btn_back
	if button != null and not button.has_meta("bounce_attached"):
		button.set_meta("bounce_attached", true)
		UIAnim.attach_press_down(button)


# ---------------------------------------------------------------------------
# Bản đồ
# ---------------------------------------------------------------------------
func _build_map() -> void:
	_load_level_ids()
	if map == null:
		return
	map.build(_level_ids, _stars_dict(), _unlocked_level(), chapter_continue_level(), bonus_level_ids())


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
	else:
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
	# Chương KHÔNG có màn nào ⇒ danh sách rỗng (không mượn màn chương khác)
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


## Màn BONUS = các màn SAU `ChapterData.main_level_count` màn đầu của chương (xem LevelManager)
func _is_bonus(level_id: int) -> bool:
	var lm: Node = get_node_or_null("/root/LevelManager")
	return lm != null and lm.has_method("is_bonus_level") and bool(lm.call("is_bonus_level", level_id))


## Các màn CHÍNH của chương (bỏ BONUS)
func main_level_ids() -> Array[int]:
	var ids: Array[int] = []
	for level_id in _level_ids:
		if not _is_bonus(level_id):
			ids.append(level_id)
	return ids


## Các màn BONUS của chương (nằm cuối bản đồ)
func bonus_level_ids() -> Array[int]:
	var ids: Array[int] = []
	for level_id in _level_ids:
		if _is_bonus(level_id):
			ids.append(level_id)
	return ids


## Tất cả màn CHÍNH trong chương đã hoàn thành (BONUS không bắt buộc)
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


# ---------------------------------------------------------------------------
# Orientation / resize
# ---------------------------------------------------------------------------
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_bind_refs()
	_setup_button_effects()
	_refresh_header()
	_wire_progress()
	_refresh_progress()
	_wire_chapter_ui()
	_refresh_chapter_ui()
	# Bản đồ tự dựng lại khi khung đổi cỡ (LevelMap nghe `size_changed` của viewport)


# ---------------------------------------------------------------------------
# TAB CHƯƠNG · THẺ CHƯƠNG · THẺ "MÀN TIẾP THEO" · KHUNG CHƯƠNG KHOÁ
# (cả bản dọc lẫn bản ngang; màn Chapters cũ không còn được mở từ đây)
# ---------------------------------------------------------------------------
## Nối dây cho bộ UI mới (gọi lại mỗi lần đổi hướng vì mỗi layout có node riêng)
func _wire_chapter_ui() -> void:
	if layout == null:
		return
	if layout.tabs != null:
		if not layout.tabs.chapter_selected.is_connected(_on_chapter_tab_selected):
			layout.tabs.chapter_selected.connect(_on_chapter_tab_selected)
		if not layout.tabs.locked_chapter_requested.is_connected(_on_locked_chapter_requested):
			layout.tabs.locked_chapter_requested.connect(_on_locked_chapter_requested)
	if layout.next_card != null:
		if not layout.next_card.play_requested.is_connected(_on_continue_pressed):
			layout.next_card.play_requested.connect(_on_continue_pressed)
		if not layout.next_card.next_chapter_requested.is_connected(_on_next_chapter_requested):
			layout.next_card.next_chapter_requested.connect(_on_next_chapter_requested)
	if layout.lock_sheet != null:
		if not layout.lock_sheet.unlock_requested.is_connected(_on_unlock_chapter_requested):
			layout.lock_sheet.unlock_requested.connect(_on_unlock_chapter_requested)
		# Lưới an toàn: dây `pressed` của nút ✕ / nền mờ đã khai trong scene
		if not layout.lock_sheet.closed.is_connected(_on_lock_sheet_closed):
			layout.lock_sheet.closed.connect(_on_lock_sheet_closed)


## Vẽ lại tab chương + thẻ chương + thẻ "màn tiếp theo" theo chương đang chọn
func _refresh_chapter_ui() -> void:
	if layout == null:
		return
	var chapter := _chapter_data()
	var have_stars := _total_stars()
	var show_tabs := layout.tabs != null
	if show_tabs:
		layout.tabs.setup(_chapters(), _current_chapter())
	# Thẻ chương (bản dọc): tên · mô tả · "x / y SAO" · "(x/y màn) · cỡ bàn"
	if layout.card_subtitle != null:
		layout.card_subtitle.text = chapter.display_subtitle() if chapter != null else ""
	if layout.card_stars != null:
		var own := _chapter_stars(_current_chapter())
		var total := _chapter_star_total(_current_chapter())
		layout.card_stars.text = tr("STR_CHAPTER_STARS_FORMAT").format([own, total])
	if layout.card_levels != null:
		var cleared := _levels_cleared(_current_chapter())
		var total := main_level_ids().size()
		var size_text := chapter.display_size() if chapter != null else ""
		var line := tr("STR_CHAPTER_LEVELS_FORMAT").format([cleared, total])
		if not size_text.is_empty():
			line = "%s · %s" % [line, size_text]
		layout.card_levels.text = line
	# Thẻ chân màn "MÀN TIẾP THEO" / "HOÀN THÀNH CHƯƠNG"
	if layout.next_card != null:
		var cleared_chapter := chapter_cleared()
		var next_level := chapter_continue_level()
		var stars: Dictionary = _stars_dict()
		layout.next_card.setup(next_level, int(stars.get(next_level, 0)), cleared_chapter,
			_next_chapter_id() > 0)


## Chương ĐANG CHỌN (theo tab / `GameManager.current_chapter`)
func _chapters() -> Array:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("get_chapters"):
		return []
	return lm.call("get_chapters")


func _total_stars() -> int:
	var gm := _game_manager()
	return int(gm.call("total_stars")) if gm != null and gm.has_method("total_stars") else 0


func _levels_cleared(chapter_id: int) -> int:
	var lm: Node = get_node_or_null("/root/LevelManager")
	return int(lm.call("chapter_cleared_count", chapter_id)) if lm != null \
		and lm.has_method("chapter_cleared_count") else 0


## Mã chương KẾ TIẾP trong danh sách (0 = không còn chương nào)
func _next_chapter_id() -> int:
	var chapters := _chapters()
	var current := _current_chapter()
	for chapter_v in chapters:
		var chapter := chapter_v as ChapterData
		if chapter != null and chapter.chapter_id > current and _chapter_has_levels(chapter.chapter_id):
			return chapter.chapter_id
	return 0


func _chapter_has_levels(chapter_id: int) -> bool:
	var lm: Node = get_node_or_null("/root/LevelManager")
	if lm == null or not lm.has_method("levels_in_chapter"):
		return true
	return not (lm.call("levels_in_chapter", chapter_id) as Array).is_empty()


## Bấm TAB chương ĐÃ MỞ: đổi chương TẠI CHỖ (không đổi scene, không ghi lịch sử)
func _on_chapter_tab_selected(chapter_id: int) -> void:
	var gm := _game_manager()
	if gm == null or chapter_id == _current_chapter():
		return
	gm.call("set_chapter", chapter_id)
	_rebuild_for_chapter()


## Bấm TAB chương KHOÁ / ĐỦ SAO: mở khung "chương đang khoá" (KHÔNG đổi chương)
func _on_locked_chapter_requested(chapter_id: int) -> void:
	if layout != null and layout.lock_sheet != null:
		layout.lock_sheet.open_chapter(chapter_id)


## Bấm MỞ KHOÁ trong khung: đủ Sao thì mở + chuyển sang chương đó, thiếu thì kêu 1 tiếng
func _on_unlock_chapter_requested(chapter_id: int) -> void:
	var gm := _game_manager()
	if gm == null:
		return
	if bool(gm.call("unlock_chapter", chapter_id)):
		Sfx.play(Sfx.ACHIEVEMENT)
		if layout != null and layout.lock_sheet != null:
			layout.lock_sheet.close_sheet()
		gm.call("set_chapter", chapter_id)
		_rebuild_for_chapter()
	else:
		Sfx.play(Sfx.BTN_CLICK)


func _on_lock_sheet_closed() -> void:
	pass


## Bấm "CHƯƠNG TIẾP ›" ở thẻ chân màn khi chương đã xong
func _on_next_chapter_requested() -> void:
	var next_id := _next_chapter_id()
	if next_id <= 0:
		return
	var gm := _game_manager()
	var unlocked := gm != null and bool(gm.call("is_chapter_unlocked", next_id))
	if not unlocked:
		_on_locked_chapter_requested(next_id)
		return
	gm.call("set_chapter", next_id)
	_rebuild_for_chapter()


## Dựng lại bản đồ + mọi số liệu sau khi đổi chương (dùng chung cho tab / mở khoá / chương tiếp)
func _rebuild_for_chapter() -> void:
	_build_map()
	_refresh_header()
	_refresh_progress()
	_refresh_chapter_ui()


## Khung chương khoá đang mở (màn Chọn màn chặn Back đóng scene khi sheet còn mở)
func is_sheet_open() -> bool:
	return layout != null and layout.lock_sheet != null and layout.lock_sheet.is_open()


## Back cứng / Esc: đang mở khung chương khoá ⇒ chỉ đóng khung (như bảng lịch của màn Daily)
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if is_sheet_open():
		layout.lock_sheet.close_sheet()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------------------
# Thanh tiến độ Sao + 3 RƯƠNG MỐC thưởng của CHƯƠNG đang chơi
# ---------------------------------------------------------------------------
## Nối dây "bấm rương" của widget (gọi lại mỗi lần đổi hướng vì mỗi bố cục có widget riêng)
func _wire_progress() -> void:
	var bar := layout.reward_bar() if layout != null else null
	if bar == null:
		return
	if not bar.claim_requested.is_connected(_on_chest_claim_requested):
		bar.claim_requested.connect(_on_chest_claim_requested)


## Đổ số Sao của chương đang chơi vào thanh thưởng + trạng thái 3 rương
func _refresh_progress() -> void:
	var bar := layout.reward_bar() if layout != null else null
	if bar == null:
		return
	var chapter := _chapter_data()
	var chapter_id := chapter.chapter_id if chapter != null else maxi(_current_chapter(), 1)
	bar.set_meta("chapter_id", chapter_id)
	bar.setup(_chapter_stars(chapter_id), _chapter_star_total(chapter_id))


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


## Bấm RƯƠNG MỐC trên thanh tiến độ: trao thưởng (một lần/chương) rồi mở popup rương.
## Dùng lại popup mốc Daily (`nodes/popups/daily_milestone.tscn`) để có sẵn animation rương.
func _on_chest_claim_requested(index: int) -> void:
	var gm := _game_manager()
	if gm == null or not gm.has_method("claim_chapter_chest"):
		return
	var chapter := _chapter_data()
	var chapter_id := chapter.chapter_id if chapter != null else maxi(_current_chapter(), 1)
	var def: Dictionary = gm.call("claim_chapter_chest", chapter_id, index,
		_chapter_stars(chapter_id), _chapter_star_total(chapter_id))
	if def.is_empty():
		Sfx.play(Sfx.BTN_CLICK)
		return
	Sfx.play(Sfx.ACHIEVEMENT)
	_show_chest_reward(chapter_id, def)
	_refresh_header()
	_refresh_progress()


## Popup báo phần thưởng rương vừa nhận (dùng lại popup rương của Daily)
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


## API cho test: widget thanh thưởng của bố cục đang hiển thị
func progress_widget() -> ChapterProgress:
	return layout.reward_bar() if layout != null else null


# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
func _refresh_header() -> void:
	if layout == null:
		return
	var chapter := _chapter_data()
	var own := 0
	var total := maxi(main_level_ids().size(), 1) * 3
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
	if layout.lbl_chapter != null and chapter != null:
		layout.lbl_chapter.text = chapter.display_title()


# ---------------------------------------------------------------------------
# Events (dây signal khai trong `scenes/levels.tscn`; widget mới nối trong `_wire_chapter_ui`)
# ---------------------------------------------------------------------------
func _on_level_selected(level_id: int) -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", level_id)
	else:
		Nav.goto_game()


## Bấm CHƠI ở thẻ "MÀN TIẾP THEO" (thẻ tự phát tiếng bấm)
func _on_continue_pressed() -> void:
	var gm := _game_manager()
	var level_id := chapter_continue_level()
	if gm != null and level_id <= _unlocked_level() and gm.has_method("start_level"):
		gm.call("start_level", level_id)
	else:
		Nav.goto_game()


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	# Khung "chương đang khoá" đang mở ⇒ Back chỉ ĐÓNG KHUNG (không rời màn)
	if is_sheet_open():
		layout.lock_sheet.close_sheet()
		return
	# Lùi về màn TRƯỚC (thường là Main, hoặc Chọn Chương nếu vào từ đó) và KHÔNG ghi thêm
	# lịch sử — ghi thêm sẽ khiến Back ở màn sau nhảy ngược về đây.
	var screen := get_node_or_null("/root/ScreenManager")
	if screen != null and screen.has_method("go_back") and bool(screen.call("go_back")):
		return
	Nav.back_to_main()


# ---------------------------------------------------------------------------
# Public API (tương thích ngược nếu cần)
# ---------------------------------------------------------------------------
func level_ids() -> Array[int]:
	return _level_ids.duplicate()
