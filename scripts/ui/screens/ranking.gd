class_name RankingScene
extends BaseScene
## ============================================================================
## Màn BẢNG XẾP HẠNG — bố cục "tab gáy sổ + top 3 nhà vô địch + dòng kẻ"
##
## Khung/layout khai báo trong scenes/layout/<hướng>/ranking.tscn; phần ĐỘNG nạp bằng code:
##  - 3 tab gáy sổ dọc (Dungeon · Play · Daily) KHAI SẴN trong scene (`Sheet/Tabs/*`), màn chỉ gom lại
##  - Top 3: thẻ Gold (hạng 1, lớn) + thẻ Silver/Bronze (nhỏ) — tìm bằng find_child
##  - Danh sách cuộn các hạng còn lại (nodes/ranking/rank_row.tscn) — vuốt dọc để cuộn
##  - Giấy nhớ "hạng của bạn" ở đáy
##
## ĐỔI TAB có animation: nội dung (`layout.content`) trượt + mờ ra → nạp bảng mới →
## trượt vào từ phía ngược lại, các hàng hiện lần lượt (stagger). Tab được chọn nở ra (xem RankTabButton).
## Dữ liệu & công thức điểm: xem scripts/autoload/RankingManager.gd
## ============================================================================

@export var ROW_SCENE: PackedScene = preload("res://nodes/ranking/rank_row.tscn")

const TAB_KEYS := {
	"dungeon": "STR_RANK_TAB_DUNGEON",
	"play": "STR_RANK_TAB_PLAY",
	"daily": "STR_RANK_TAB_DAILY",
}
## Thứ tự nhóm top 3: index 0 = hạng 1
const PODIUM_GROUPS: Array[String] = ["Gold", "Silver", "Bronze"]

## Ngưỡng kéo tối thiểu (px) trước khi coi là VUỐT/CUỘN thay vì chạm
@export var DRAG_THRESHOLD := 14.0

# --- Animation đổi tab ---
## Thời gian nội dung cũ trượt/mờ ra
@export var OUT_TIME := 0.12
## Thời gian nội dung mới trượt/hiện vào
@export var IN_TIME := 0.24
## Quãng trượt ngang (px)
@export var SLIDE_DISTANCE := 32.0
## Trễ giữa các hàng danh sách khi hiện vào (giây) + số hàng tối đa được stagger
@export var ROW_STAGGER := 0.035
@export var MAX_STAGGER_ROWS := 10

var layout: RankingLayout = null

var _board := "dungeon"
var _tab_buttons: Dictionary = {}
var _tab_order: Array[String] = []
var _rows: Array[RankRow] = []

var _transition: Tween = null
var _rows_tween: Tween = null
var _content_rest := Vector2.ZERO

# Trạng thái vuốt/cuộn danh sách (xem _input)
var _drag_active := false
var _drag_axis := 0                 # 0 = chưa rõ · 1 = ngang (bỏ qua) · 2 = dọc (cuộn)
var _drag_start := Vector2.ZERO
var _drag_scroll := 0.0


func _ready() -> void:
	_bind_refs()
	ensure_signal(layout.btn_back, &"pressed", &"_on_back_pressed")
	if layout.btn_back != null:
		UIAnim.attach_press_down(layout.btn_back)
	orientation_changed.connect(_on_orientation_changed)
	_collect_tabs()
	_connect_manager()
	Ranking.refresh()
	_show_board(_board)


func _on_active() -> void:
	UIAnim.play_layout_anim(active_layout(), "EnterAnim", &"enter")


func _bind_refs() -> void:
	layout = active_layout() as RankingLayout
	if layout == null:
		push_warning("ranking: bố cục chưa gắn RankingLayout — thiếu binding trong scenes/layout/<hướng>/ranking.tscn")


func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_reset_transition()
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
	_rows.clear()   # layout mới có Rows riêng — dựng lại hàng
	_bind_refs()
	_collect_tabs()
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


## Đổi bảng đang xem NGAY, không animation (test/điều hướng)
func select_board(board: String) -> void:
	_reset_transition()
	_show_board(board)


func _on_back_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	Nav.goto_main()


func _on_tab_pressed(board: String) -> void:
	if board == _board:
		return
	Sfx.play(Sfx.BTN_CLICK)
	_transition_to(board)


func _connect_manager() -> void:
	var m := Ranking.manager()
	if m != null and m.has_signal("ranking_changed") and not m.is_connected("ranking_changed", _on_ranking_changed):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		m.connect("ranking_changed", _on_ranking_changed)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh


func _on_ranking_changed(board: String) -> void:
	if board == _board:
		call_deferred("_show_board", _board)


# ---------------------------------------------------------------------------
# Animation đổi tab
# ---------------------------------------------------------------------------
func _transition_to(board: String) -> void:
	if layout == null or layout.content == null or not is_inside_tree():
		_show_board(board)
		return
	_reset_transition()
	var content := layout.content
	_content_rest = content.position
	var dir := signi(_tab_order.find(board) - _tab_order.find(_board))
	if dir == 0:
		dir = 1
	# Tab nở/co NGAY khi bấm; dữ liệu đổi giữa chừng khi nội dung cũ đã mờ hết
	_board = board
	_update_tabs()
	_transition = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
	_transition.tween_property(content, "modulate:a", 0.0, OUT_TIME).set_ease(Tween.EASE_IN)
	_transition.tween_property(content, "position:x", _content_rest.x - dir * SLIDE_DISTANCE, OUT_TIME).set_ease(Tween.EASE_IN)
	_transition.chain().tween_callback(_swap_board.bind(board, dir))
	_transition.chain().tween_property(content, "modulate:a", 1.0, IN_TIME).set_ease(Tween.EASE_OUT)
	_transition.parallel().tween_property(content, "position:x", _content_rest.x, IN_TIME).set_ease(Tween.EASE_OUT)


## Giữa animation: nạp bảng mới, đặt nội dung ở phía ngược lại rồi cho hàng hiện lần lượt
func _swap_board(board: String, dir: int) -> void:
	_show_board(board)
	if layout != null and layout.content != null:
		layout.content.position.x = _content_rest.x + dir * SLIDE_DISTANCE
	_stagger_rows()


func _stagger_rows() -> void:
	_kill_tween(_rows_tween)
	_rows_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for i in mini(_rows.size(), MAX_STAGGER_ROWS):
		var row := _rows[i]
		if not is_instance_valid(row):
			continue
		row.modulate.a = 0.0
		_rows_tween.tween_property(row, "modulate:a", 1.0, IN_TIME).set_delay(ROW_STAGGER * i)


## Huỷ animation đang chạy và trả nội dung về trạng thái nghỉ (gọi trước khi đổi tab/xoay màn)
func _reset_transition() -> void:
	var running := _transition != null and _transition.is_valid()
	_kill_tween(_transition)
	_kill_tween(_rows_tween)
	_transition = null
	_rows_tween = null
	if running and layout != null and layout.content != null and is_instance_valid(layout.content):
		layout.content.position = _content_rest
		layout.content.modulate.a = 1.0
	for row in _rows:
		if is_instance_valid(row):
			row.modulate.a = 1.0


func _kill_tween(tw: Tween) -> void:
	if tw != null and tw.is_valid():
		tw.kill()


# ---------------------------------------------------------------------------
# Vẽ nội dung
# ---------------------------------------------------------------------------
func _show_board(board: String) -> void:
	_board = board
	_update_tabs()
	_fill_podium(Ranking.podium(board), board)
	_fill_rows(Ranking.rest(board), board)
	_fill_my_rank(board)
	if layout.scroll != null:
		layout.scroll.scroll_vertical = 0


## Gom các tab KHAI SẴN trong scene (`Sheet/Tabs/*` — dungeon · play · daily, ĐÚNG thứ tự trên-xuống)
func _collect_tabs() -> void:
	_tab_buttons.clear()
	_tab_order.clear()
	if layout == null or layout.tabs_box == null:
		return
	for child in layout.tabs_box.get_children():
		var btn := child as RankTabButton
		if btn == null:
			continue
		ensure_signal(btn, &"tab_pressed", &"_on_tab_pressed")
		_tab_buttons[btn.board_id] = btn
		_tab_order.append(btn.board_id)
	_update_tabs()


func _update_tabs() -> void:
	for id in _tab_buttons:
		var btn := _tab_buttons[id] as RankTabButton
		if btn != null:
			btn.set_active(str(id) == _board)


## Top 3: Gold (thẻ lớn) · Silver · Bronze. Mỗi nhóm có Name · Record · Points + Trophy (icon cúp, không ghi số)
func _fill_podium(entries: Array, board: String) -> void:
	for i in PODIUM_GROUPS.size():
		var group := layout.podium.find_child(PODIUM_GROUPS[i], true, false) as Control
		if group == null:
			continue
		var has_entry := i < entries.size()
		group.modulate.a = 1.0 if has_entry else 0.0   # giữ chỗ để bố cục không nhảy
		if not has_entry:
			continue
		var entry: Dictionary = entries[i]
		_set_label(group, "Name", Ranking.display_name(entry))
		_set_label(group, "Record", Ranking.record_text(board, entry))
		_set_label(group, "Points", Ranking.points_text(entry))


## Điền danh sách hạng còn lại. DÙNG LẠI hàng đã có (chỉ thêm/bớt khi số hạng đổi)
func _fill_rows(entries: Array, board: String) -> void:
	while _rows.size() > entries.size():
		var extra: RankRow = _rows.pop_back()
		if is_instance_valid(extra):
			extra.get_parent().remove_child(extra)
			extra.queue_free()
	for i in entries.size():
		var row: RankRow = _rows[i] if i < _rows.size() and is_instance_valid(_rows[i]) else null
		if row == null:
			row = ROW_SCENE.instantiate()
			layout.rows_box.add_child(row)
			if i < _rows.size():
				_rows[i] = row
			else:
				_rows.append(row)
		row.setup(entries[i], board)


func _fill_my_rank(board: String) -> void:
	var entry := Ranking.my_entry(board)
	if entry.is_empty():
		return
	var has_record := bool(entry.get("has_record", false))
	_set_label(layout.my_rank_bar, "Rank", Ranking.rank_text(int(entry.get("rank", 0))))
	_set_label(layout.my_rank_bar, "Name", Ranking.display_name(entry))
	var sub: String = TranslationServer.translate("STR_RANK_NO_RECORD") if not has_record \
		else "%s • %s" % [TranslationServer.translate("STR_RANK_SUBTITLE"), _tab_title(_board)]
	_set_label(layout.my_rank_bar, "Sub", sub)
	_set_label(layout.my_rank_bar, "Record", Ranking.record_text(board, entry))
	_set_label(layout.my_rank_bar, "Points", Ranking.points_text(entry))
	var flag := layout.my_rank_flag()
	if flag != null:
		flag.texture = RankRow.flag_texture(str(entry.get("flag", "generic")))


func _set_label(root: Node, path: String, text: String) -> void:
	var label := root.get_node_or_null(path) as Label
	if label != null:
		label.text = text


# ---------------------------------------------------------------------------
# VUỐT / CUỘN danh sách xếp hạng — tự xử lý ở mức `_input`
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if layout == null or layout.scroll == null or not is_visible_in_tree():
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
	if layout.scroll == null or not layout.scroll.get_global_rect().has_point(pos):
		return
	_drag_active = true
	_drag_axis = 0
	_drag_start = pos
	_drag_scroll = float(layout.scroll.scroll_vertical)


func _update_drag(pos: Vector2) -> void:
	if not _drag_active:
		return
	var delta := pos - _drag_start
	if _drag_axis == 0:
		if absf(delta.x) < DRAG_THRESHOLD and absf(delta.y) < DRAG_THRESHOLD:
			return
		_drag_axis = 1 if absf(delta.x) > absf(delta.y) else 2
	if _drag_axis == 2:
		layout.scroll.scroll_vertical = int(_drag_scroll - delta.y)
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _end_drag() -> void:
	_drag_active = false
	_drag_axis = 0


func _tab_title(board: String) -> String:
	return TranslationServer.translate(str(TAB_KEYS.get(board, "")))
