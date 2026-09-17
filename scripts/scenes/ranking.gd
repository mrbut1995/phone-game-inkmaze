class_name RankingScene
extends BaseScene
## ============================================================================
## Màn BẢNG XẾP HẠNG — mockup/ranking.svg
##
## Khung/layout khai báo trong scenes/ranking.tscn; phần ĐỘNG dựng bằng code:
##  - 3 tab (Dungeon · Play · Daily) theo RankRow nguồn dữ liệu RankingManager
##  - Bục vinh quang 3 hạng (Gold/Silver/Bronze trong .tscn)
##  - Danh sách cuộn các hạng còn lại (nodes/ranking/rank_row.tscn) — vuốt dọc để cuộn
##    (tự xử lý ở mức `_input` vì hàng xếp hạng là Control "ăn" sự kiện chuột)
##  - Thanh "hạng của bạn" dán đáy + ghi chú chân trang
##
## Dữ liệu & công thức điểm: xem scripts/manager/RankingManager.gd
## ============================================================================

const ROW_SCENE := preload("res://nodes/ranking/rank_row.tscn")
const TAB_ACTIVE_ART := preload("res://assets/images/ranking/tab_active.svg")
const TAB_NORMAL_ART := preload("res://assets/images/ranking/tab_normal.svg")

const TAB_SIZE := Vector2(245, 52)
## Bề rộng từng tab đúng mockup (240 · 235 · 245) — khoảng cách 15
const TAB_WIDTHS := {
	"dungeon": 240.0,
	"play": 235.0,
	"daily": 245.0,
}
const TAB_SEPARATION := 15
const TAB_KEYS := {
	"dungeon": "STR_RANK_TAB_DUNGEON",
	"play": "STR_RANK_TAB_PLAY",
	"daily": "STR_RANK_TAB_DAILY",
}
## Thứ tự bục vinh quang: index 0 = hạng 1
const PODIUM_GROUPS: Array[String] = ["Gold", "Silver", "Bronze"]
const TAB_LABEL_ACTIVE_COLOR := Color(1, 1, 1)
const TAB_LABEL_IDLE_COLOR := Color(0.13333334, 0.29803923, 0.42745098)

## Ngưỡng kéo tối thiểu (px) trước khi coi là VUỐT/CUỘN thay vì chạm
const DRAG_THRESHOLD := 14.0

@onready var btn_back: TextureButton = $TopBar/Back
@onready var tabs_box: HBoxContainer = $Sheet/Tabs
@onready var podium: Control = $Sheet/Podium
@onready var scroll: ScrollContainer = $Sheet/Scroll
@onready var rows_box: VBoxContainer = $Sheet/Scroll/Rows
@onready var my_rank_bar: TextureRect = $Sheet/MyRank

var _board := "dungeon"
var _tab_buttons: Dictionary = {}
var _rows: Array[RankRow] = []

# Trạng thái vuốt/cuộn danh sách (xem _input)
var _drag_active := false
var _drag_axis := 0                 # 0 = chưa rõ · 1 = ngang (bỏ qua) · 2 = dọc (cuộn)
var _drag_start := Vector2.ZERO
var _drag_scroll := 0.0


func _ready() -> void:
	btn_back.pressed.connect(_on_back_pressed)
	UIAnim.attach_press_bounce(btn_back)
	_build_tabs()
	_connect_manager()
	# Làm mới theo khung 10 phút (chỉ dựng lại khi đã sang khung mới)
	Ranking.refresh()
	_show_board(_board)


# ---------------------------------------------------------------------------
# API công khai (test + điều hướng)
# ---------------------------------------------------------------------------
func board() -> String:
	return _board


func row_count() -> int:
	return _rows.size()


func tab_count() -> int:
	return _tab_buttons.size()


## Đổi bảng đang xem (dungeon / play / daily)
func select_board(board: String) -> void:
	_show_board(board)


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_main()


func _on_tab_pressed(board: String) -> void:
	if board == _board:
		return
	Sfx.play(Sfx.BTN_CLICK)
	_show_board(board)


func _connect_manager() -> void:
	var m := Ranking.manager()
	if m != null and m.has_signal("ranking_changed") and not m.is_connected("ranking_changed", _on_ranking_changed):
		m.connect("ranking_changed", _on_ranking_changed)


func _on_ranking_changed(board: String) -> void:
	if board == _board:
		call_deferred("_show_board", _board)


# ---------------------------------------------------------------------------
# Vẽ nội dung
# ---------------------------------------------------------------------------
func _show_board(board: String) -> void:
	_board = board
	_update_tabs()
	_fill_podium(Ranking.podium(board), board)
	_fill_rows(Ranking.rest(board), board)
	_fill_my_rank(board)
	if scroll != null:
		scroll.scroll_vertical = 0


func _build_tabs() -> void:
	for child in tabs_box.get_children():
		child.queue_free()
	_tab_buttons.clear()
	tabs_box.add_theme_constant_override("separation", TAB_SEPARATION)
	for board in Ranking.board_ids():
		var id := str(board)
		var btn := TextureButton.new()
		btn.name = "Tab_" + id
		btn.custom_minimum_size = Vector2(float(TAB_WIDTHS.get(id, 245.0)), TAB_SIZE.y)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_SCALE
		btn.focus_mode = Control.FOCUS_NONE
		btn.texture_normal = TAB_NORMAL_ART
		var label := Label.new()
		label.name = "Label"
		label.text = _tab_title(id)
		label.theme_type_variation = &"RankTabLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(label)
		btn.pressed.connect(_on_tab_pressed.bind(id))
		tabs_box.add_child(btn)
		UIAnim.attach_press_bounce(btn)
		_tab_buttons[id] = btn


func _update_tabs() -> void:
	for id in _tab_buttons:
		var btn := _tab_buttons[id] as TextureButton
		if btn == null:
			continue
		var active: bool = str(id) == _board
		btn.texture_normal = TAB_ACTIVE_ART if active else TAB_NORMAL_ART
		var label := btn.get_node_or_null("Label") as Label
		if label != null:
			label.add_theme_color_override("font_color",
				TAB_LABEL_ACTIVE_COLOR if active else TAB_LABEL_IDLE_COLOR)


func _fill_podium(entries: Array, board: String) -> void:
	for i in PODIUM_GROUPS.size():
		var group := podium.get_node_or_null(PODIUM_GROUPS[i]) as Control
		if group == null:
			continue
		var has_entry := i < entries.size()
		group.visible = has_entry
		if not has_entry:
			continue
		var entry: Dictionary = entries[i]
		_set_label(group, "Name", Ranking.display_name(entry))
		_set_label(group, "Record", Ranking.record_text(board, entry))
		_set_label(group, "Block/Rank", str(int(entry.get("rank", i + 1))))
		_set_label(group, "Block/Points", Ranking.points_text(entry))


func _fill_rows(entries: Array, board: String) -> void:
	for row in _rows:
		if is_instance_valid(row):
			row.queue_free()
	_rows.clear()
	for entry in entries:
		var row: RankRow = ROW_SCENE.instantiate()
		rows_box.add_child(row)
		row.setup(entry, board)
		_rows.append(row)


func _fill_my_rank(board: String) -> void:
	var entry := Ranking.my_entry(board)
	if entry.is_empty():
		return
	var has_record := bool(entry.get("has_record", false))
	_set_label(my_rank_bar, "Rank", Ranking.rank_text(int(entry.get("rank", 0))))
	_set_label(my_rank_bar, "Name", Ranking.display_name(entry))
	# Có kỷ lục: "KỶ LỤC CÁ NHÂN • <tên bảng>"; chưa có: lời nhắc ngắn gọn
	var sub: String = TranslationServer.translate("STR_RANK_NO_RECORD") if not has_record \
		else "%s • %s" % [TranslationServer.translate("STR_RANK_SUBTITLE"), _tab_title(_board)]
	_set_label(my_rank_bar, "Sub", sub)
	_set_label(my_rank_bar, "Record", Ranking.record_text(board, entry))
	_set_label(my_rank_bar, "Points", Ranking.points_text(entry))
	var flag := my_rank_bar.get_node_or_null("Flag") as TextureRect
	if flag != null:
		flag.texture = RankRow.flag_texture(str(entry.get("flag", "generic")))


func _set_label(root: Node, path: String, text: String) -> void:
	var label := root.get_node_or_null(path) as Label
	if label != null:
		label.text = text


# ---------------------------------------------------------------------------
# VUỐT / CUỘN danh sách xếp hạng — tự xử lý ở mức `_input`
# (hàng xếp hạng là Control bắt sự kiện chuột/cảm ứng nên ScrollContainer
# không tự nhận được thao tác kéo; handler ở đây chạy TRƯỚC GUI nên kéo được)
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if scroll == null or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch and event.index == 0:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and event.index == 0:
		_update_drag(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position)
		else:
			_end_drag()
	elif event is InputEventMouseMotion:
		if (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_drag(event.position)


func _begin_drag(pos: Vector2) -> void:
	if scroll == null or not scroll.get_global_rect().has_point(pos):
		return
	_drag_active = true
	_drag_axis = 0
	_drag_start = pos
	_drag_scroll = float(scroll.scroll_vertical)


func _update_drag(pos: Vector2) -> void:
	if not _drag_active:
		return
	var delta := pos - _drag_start
	if _drag_axis == 0:
		if absf(delta.x) < DRAG_THRESHOLD and absf(delta.y) < DRAG_THRESHOLD:
			return
		_drag_axis = 1 if absf(delta.x) > absf(delta.y) else 2
	# Dọc: kéo nội dung theo tay (kéo lên -> xem phần dưới)
	if _drag_axis == 2:
		scroll.scroll_vertical = int(_drag_scroll - delta.y)
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _end_drag() -> void:
	_drag_active = false
	_drag_axis = 0


## Tên bảng theo ngôn ngữ đang chọn ("DUNGEON" · "CHẾ ĐỘ PLAY" · "CHUỖI NGÀY")
func _tab_title(board: String) -> String:
	return TranslationServer.translate(str(TAB_KEYS.get(board, "")))
