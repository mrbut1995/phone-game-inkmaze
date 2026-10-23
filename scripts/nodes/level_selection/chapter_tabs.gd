class_name ChapterTabs
extends Control
## ============================================================================
## Component: HÀNG TAB CHƯƠNG trên màn Chọn màn (nodes/level_selection/chapter_tabs.tscn)
##
## Thay cho băng "ĐỔI CHƯƠNG ›" cũ: 4+ chương nằm ngay trên màn Level.
##   · Bấm tab ĐÃ MỞ  ⇒ phát `chapter_selected(id)` (màn Level đổi chương TẠI CHỖ)
##   · Bấm tab KHOÁ/ĐỦ SAO ⇒ phát `locked_chapter_requested(id)` (màn Level mở khung khoá)
##   · Chương chưa có màn nào ⇒ tab COMING, không bấm được
##
## Danh sách tab nằm trong `ScrollContainer` ngang nên 1..99 chương đều dùng được;
## tab đang chọn luôn được cuộn vào giữa tầm nhìn (khi nhiều hơn 4 tab).
##
## Trạng thái từng tab do `GameManager` + `LevelManager` quyết định — widget này không
## tự đọc dữ liệu, chỉ nhận `chapters` + `selected_id` từ màn Level.
## ============================================================================

signal chapter_selected(chapter_id: int)
signal locked_chapter_requested(chapter_id: int)

@export var tab_scene: PackedScene = preload("res://nodes/level_selection/chapter_tab.tscn")
## Node chứa tab (HBoxContainer bên trong ScrollContainer) — bind trong .tscn
@export var tab_host: Container = null
## ScrollContainer bao ngoài (dùng để cuộn tab đang chọn vào giữa)
@export var scroller: ScrollContainer = null

@export_group("Cỡ tab (ghi đè — 0 = dùng cỡ mặc định của chapter_tab.tscn)")
@export var tab_width_selected := 0.0
@export var tab_width_normal := 0.0
@export var tab_height_selected := 0.0
@export var tab_height_normal := 0.0
@export var tab_font_selected := 0
@export var tab_font_normal := 0

var _tabs: Array[ChapterTab] = []


func _ready() -> void:
	_connect_locale_signal()


## Đổi ngôn ngữ ⇒ chỉ cần viết lại nhãn từng tab (không dựng lại node)
func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	for tab in _tabs:
		if is_instance_valid(tab):
			tab.apply_locale()
	_scroll_selected_into_view()


## `chapters` = Array[ChapterData]; `selected_id` = chương đang xem
func setup(chapters: Array, selected_id: int) -> void:
	_clear()
	if tab_host == null:
		return
	var gm := _game_manager()
	var lm := _level_manager()
	var have_stars := int(gm.call("total_stars")) if gm != null and gm.has_method("total_stars") else 0
	for chapter_v in chapters:
		var chapter := chapter_v as ChapterData
		if chapter == null:
			continue
		var tab := tab_scene.instantiate() as ChapterTab
		if tab == null:
			continue
		_apply_size_overrides(tab)
		tab_host.add_child(tab)
		var chapter_id := chapter.chapter_id
		var state := _state_for(chapter_id, selected_id, have_stars, chapter, gm, lm)
		tab.setup({
			"chapter_id": chapter_id,
			"state": state,
			"star_cost": chapter.star_cost,
			"stars_have": have_stars,
		})
		tab.tab_pressed.connect(_on_tab_pressed)
		tab.locked_pressed.connect(_on_tab_locked_pressed)
		_tabs.append(tab)
	_scroll_selected_into_view.call_deferred()


## Bản NGANG dùng tab nhỏ hơn: ghi đè cỡ trước khi tab tự dựng (xem `ChapterTab.setup`)
func _apply_size_overrides(tab: ChapterTab) -> void:
	if tab_width_selected > 0.0:
		tab.width_selected = tab_width_selected
	if tab_width_normal > 0.0:
		tab.width_normal = tab_width_normal
	if tab_height_selected > 0.0:
		tab.height_selected = tab_height_selected
	if tab_height_normal > 0.0:
		tab.height_normal = tab_height_normal
	if tab_font_selected > 0:
		tab.font_size_selected = tab_font_selected
	if tab_font_normal > 0:
		tab.font_size_normal = tab_font_normal


## Tính trạng thái 1 tab theo dữ liệu thật (đủ Sao để mở hay chưa, có màn hay không)
func _state_for(chapter_id: int, selected_id: int, have_stars: int, chapter: ChapterData,
		gm: Node, lm: Node) -> ChapterTab.State:
	var has_levels := true
	if lm != null and lm.has_method("levels_in_chapter"):
		has_levels = not (lm.call("levels_in_chapter", chapter_id) as Array).is_empty()
	var unlocked := chapter_id <= 1
	if gm != null and gm.has_method("is_chapter_unlocked"):
		unlocked = bool(gm.call("is_chapter_unlocked", chapter_id))
	if chapter_id == selected_id and unlocked:
		return ChapterTab.State.SELECTED
	if unlocked:
		return ChapterTab.State.OPEN if has_levels else ChapterTab.State.COMING
	if not has_levels:
		return ChapterTab.State.COMING
	if have_stars >= chapter.star_cost:
		return ChapterTab.State.READY
	return ChapterTab.State.LOCKED


## Cuộn tab đang chọn vào giữa tầm nhìn (chỉ khi hàng tab dài hơn khung)
func _scroll_selected_into_view() -> void:
	if scroller == null:
		return
	var selected: ChapterTab = null
	for tab in _tabs:
		if tab.is_selected():
			selected = tab
			break
	if selected == null:
		return
	var view_width := scroller.size.x
	var content_width := tab_host.size.x if tab_host != null else 0.0
	if content_width <= view_width:
		return
	var target := selected.position.x + selected.size.x * 0.5 - view_width * 0.5
	scroller.scroll_horizontal = int(roundf(clampf(target, 0.0, content_width - view_width)))


func tab_count() -> int:
	return _tabs.size()


func tab_for(chapter_id: int) -> ChapterTab:
	for tab in _tabs:
		if tab.chapter_id == chapter_id:
			return tab
	return null


## Mã chương của tab đang chọn (0 = không có tab nào được chọn)
func selected_id() -> int:
	for tab in _tabs:
		if tab.is_selected():
			return tab.chapter_id
	return 0


func _clear() -> void:
	_tabs.clear()
	if tab_host == null:
		return
	for child in tab_host.get_children():
		tab_host.remove_child(child)
		child.queue_free()


func _on_tab_pressed(chapter_id: int) -> void:
	Sfx.play(Sfx.BTN_CLICK)
	chapter_selected.emit(chapter_id)


func _on_tab_locked_pressed(chapter_id: int) -> void:
	Sfx.play(Sfx.BTN_CLICK)
	locked_chapter_requested.emit(chapter_id)


func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


func _level_manager() -> Node:
	return get_node_or_null("/root/LevelManager")
