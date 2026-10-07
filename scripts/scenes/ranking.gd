class_name RankingScene
extends BaseScene
## ============================================================================
## Màn BẢNG XẾP HẠNG — mockup/ranking.svg
##
## Khung/layout khai báo trong scenes/ranking.tscn; phần ĐỘNG nạp bằng code:
##  - 3 tab (Dungeon · Play · Daily) KHAI SẴN trong scene bố cục (`Sheet/Tabs/*`), màn chỉ gom lại
##  - Bục vinh quang 3 hạng (Gold/Silver/Bronze trong .tscn)
##  - Danh sách cuộn các hạng còn lại (nodes/ranking/rank_row.tscn) — vuốt dọc để cuộn
##    (tự xử lý ở mức `_input` vì hàng xếp hạng là Control "ăn" sự kiện chuột)
##  - Thanh "hạng của bạn" dán đáy + ghi chú chân trang
##
## Dữ liệu & công thức điểm: xem scripts/manager/RankingManager.gd
## ============================================================================

@export var ROW_SCENE: PackedScene = preload("res://nodes/ranking/rank_row.tscn")

const TAB_KEYS := {
	"dungeon": "STR_RANK_TAB_DUNGEON",
	"play": "STR_RANK_TAB_PLAY",
	"daily": "STR_RANK_TAB_DAILY",
}
## Thứ tự bục vinh quang: index 0 = hạng 1
const PODIUM_GROUPS: Array[String] = ["Gold", "Silver", "Bronze"]

## Ngưỡng kéo tối thiểu (px) trước khi coi là VUỐT/CUỘN thay vì chạm
@export var DRAG_THRESHOLD := 14.0

## Node UI của màn nằm trong BỐ CỤC đang hiển thị (`Portrait` / `Landscape` — 2 hướng dùng
## CÙNG tên node). Các node đã BIND SẴN bằng `@export` trong `scenes/layout/<hướng>/ranking.tscn`
## ⇒ code đọc qua `layout.<tên>`, KHÔNG tra đường dẫn; thêm/đổi node chỉ cần sửa scene + export.
var layout: RankingLayout = null

var _board := "dungeon"
var _tab_buttons: Dictionary = {}
var _rows: Array[RankRow] = []

# Trạng thái vuốt/cuộn danh sách (xem _input)
var _drag_active := false
var _drag_axis := 0                 # 0 = chưa rõ · 1 = ngang (bỏ qua) · 2 = dọc (cuộn)
var _drag_start := Vector2.ZERO
var _drag_scroll := 0.0


func _ready() -> void:
	_bind_refs()
	# Dây nút/tab khai trong `scenes/ranking.tscn` (cả 2 hướng) — guard chỉ nối lại nếu mất
	ensure_signal(layout.btn_back, &"pressed", &"_on_back_pressed")
	if layout.btn_back != null:
		UIAnim.attach_press_bounce(layout.btn_back)
	orientation_changed.connect(_on_orientation_changed)
	_collect_tabs()
	_connect_manager()
	# Làm mới theo khung 10 phút (chỉ dựng lại khi đã sang khung mới)
	Ranking.refresh()
	_show_board(_board)


## Phát lại EnterAnim mỗi khi màn được kích hoạt (quay lại từ màn khác)
func _on_active() -> void:
	UIAnim.play_layout_anim(active_layout(), "EnterAnim", &"enter")


## Gắn node của layout đang hiển thị (2 layout giữ cùng đường dẫn nên dùng `ui_path`)
func _bind_refs() -> void:
	layout = active_layout() as RankingLayout
	if layout == null:
		push_warning("ranking: bố cục chưa gắn RankingLayout — thiếu binding trong scenes/layout/<hướng>/ranking.tscn")


## Xoay màn hình: gắn lại node + gom lại tab của layout mới rồi nạp lại bảng đang xem
func _on_orientation_changed(_is_landscape_now: bool) -> void:
	_rebind_after_orientation.call_deferred()


func _rebind_after_orientation() -> void:
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
	if layout.scroll != null:
		layout.scroll.scroll_vertical = 0


## Gom các tab KHAI SẴN trong scene bố cục (`Sheet/Tabs/*` — dungeon · play · daily, ĐÚNG thứ tự),
## mỗi tab tự khai `board_id` + `label_key` + tự nối `pressed` → `tab_pressed`.
## Màn chỉ gom lại + nối 1 lần ⇒ KHÔNG còn dựng tab bằng code; bề rộng do HBox chia đều.
func _collect_tabs() -> void:
	_tab_buttons.clear()
	if layout == null or layout.tabs_box == null:
		return
	for child in layout.tabs_box.get_children():
		var btn := child as RankTabButton
		if btn == null:
			continue
		ensure_signal(btn, &"tab_pressed", &"_on_tab_pressed")
		_tab_buttons[btn.board_id] = btn
	_update_tabs()


func _update_tabs() -> void:
	for id in _tab_buttons:
		var btn := _tab_buttons[id] as RankTabButton
		if btn != null:
			btn.set_active(str(id) == _board)


func _fill_podium(entries: Array, board: String) -> void:
	for i in PODIUM_GROUPS.size():
		var group := layout.podium.get_node_or_null(PODIUM_GROUPS[i]) as Control
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


## Điền danh sách hạng còn lại. DÙNG LẠI hàng đã có (chỉ thêm/bớt khi số hạng đổi)
## ⇒ đổi bảng không phải instantiate lại cả danh sách.
func _fill_rows(entries: Array, board: String) -> void:
	while _rows.size() > entries.size():
		var extra: RankRow = _rows.pop_back()
		if is_instance_valid(extra):
			layout.rows_box.remove_child(extra)
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
	# Có kỷ lục: "KỶ LỤC CÁ NHÂN • <tên bảng>"; chưa có: lời nhắc ngắn gọn
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
# (hàng xếp hạng là Control bắt sự kiện chuột/cảm ứng nên ScrollContainer
# không tự nhận được thao tác kéo; handler ở đây chạy TRƯỚC GUI nên kéo được)
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if layout.scroll == null or not is_visible_in_tree():
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
	# Dọc: kéo nội dung theo tay (kéo lên -> xem phần dưới)
	if _drag_axis == 2:
		layout.scroll.scroll_vertical = int(_drag_scroll - delta.y)
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _end_drag() -> void:
	_drag_active = false
	_drag_axis = 0


## Tên bảng theo ngôn ngữ đang chọn ("DUNGEON" · "CHẾ ĐỘ PLAY" · "CHUỖI NGÀY")
func _tab_title(board: String) -> String:
	return TranslationServer.translate(str(TAB_KEYS.get(board, "")))
