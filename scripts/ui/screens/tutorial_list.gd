class_name TutorialListScene
extends BaseScene

## ============================================================================
## View Controller: màn DANH SÁCH bài hướng dẫn (`scenes/tutorial_list.tscn`)
##
## Danh sách và bài học là 2 MÀN RIÊNG (bài học không mount đè lên danh sách):
##   · `tutorial_list` (màn này) — chỉ hiện danh sách, KHÔNG mount bài nào.
##   · `tutorial` (`scenes/tutorial.tscn`) — màn CHI TIẾT, mount đúng bài người chơi chọn.
##
## Bấm 1 bài ⇒ đặt yêu cầu `GameManager.request_tutorial(id, true)` rồi mở màn chi tiết;
## cờ `from_list = true` để màn chi tiết biết Back/quay về DANH SÁCH (không về Main).
##
## Bài ĐÃ XEM = nút ACTIVE · bài CHƯA XEM = nút KHOÁ (mờ, không bấm được) — `_refresh_list_state`.
## ============================================================================

const NavHelper := preload("res://scripts/utils/nav.gd")

var layout: TutorialListLayout = null


func _ready() -> void:
	_bind_refs()
	_apply_texts()
	_connect_locale_signal()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)
	_refresh_list_state()


## Tiêu đề màn — gán bằng `tr()` thay vì để `.tscn` giữ nguyên khoá thô
## (`TopBar` là instance của `base_layout` nên không tự dịch như Label khai trong layout con).
func _apply_texts() -> void:
	if layout != null and layout.lbl_title != null:
		layout.lbl_title.text = tr("STR_TUT_COMMON_TITLE")  # keep-code: chữ theo dữ liệu (runtime)


## Bảng dịch nạp XONG SAU `_ready()` (LoadingManager hoãn ~200 ms) ⇒ phải viết lại nhãn
## khi `LocalizationManager` phát `locale_changed`, nếu không tiêu đề sẽ hiện khoá thô.
func _connect_locale_signal() -> void:
	var loc: Node = Svc.loc()
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh
		loc.connect("locale_changed", _on_locale_changed)  # keep-code: signal của AUTOLOAD / node sinh lúc chạy — không phải node tĩnh


func _on_locale_changed(_locale: String) -> void:
	_apply_texts()


func _bind_refs() -> void:
	layout = active_layout() as TutorialListLayout
	if layout == null:
		push_warning("tutorial_list: active_layout chua phai TutorialListLayout")


## Dây nút khai trong `scenes/tutorial_list.tscn` (cả 2 hướng) — guard chỉ nối lại nếu dây bị mất
func _wire_buttons() -> void:
	if layout == null:
		return
	ensure_signal(layout.btn_back, &"pressed", &"_on_back_pressed")
	for tid in _list_buttons():
		ensure_signal(_list_buttons()[tid], &"pressed", &"_on_select_tutorial", [tid])


## Nút của DANH SÁCH bài học ở bố cục hiện tại (id → nút) — dùng chung cho nối dây + khoá/mở
func _list_buttons() -> Dictionary:
	if layout == null:
		return {}
	return {
		"first_time": layout.btn_first_time,
		"how_to_play_move": layout.btn_move,
		"how_to_play_checking_wall": layout.btn_checking_wall,
		"how_to_play_minesweeper": layout.btn_minesweeper,
		"how_to_play_one_stroke": layout.btn_one_stroke,
		"how_to_play_sum_path": layout.btn_sum_path,
		"how_to_play_wall_builder": layout.btn_wall_builder,
		"how_to_play_countdown_cost": layout.btn_countdown_cost,
		"how_to_play_fading_ink": layout.btn_fading_ink,
		"how_to_play_fog_of_war": layout.btn_fog_of_war,
		"how_to_play_blind_memory": layout.btn_blind_memory,
		"how_to_use_tool": layout.btn_use_tool,
	}


## DANH SÁCH: bài ĐÃ XEM → nút ACTIVE · bài CHƯA XEM → nút KHOÁ (mờ, không bấm được)
func _refresh_list_state() -> void:
	var gm := Svc.game()
	var buttons := _list_buttons()
	for tid in buttons:
		var btn: BaseButton = buttons[tid]
		if btn == null:
			continue
		var seen := true
		if gm != null and gm.has_method("is_tutorial_completed"):
			seen = bool(gm.call("is_tutorial_completed", tid))
		btn.disabled = not seen
		# Giữ NGUYÊN art giấy cho nút khoá (theme mặc định không có style "disabled") rồi LÀM MỜ
		btn.add_theme_stylebox_override("disabled", btn.get_theme_stylebox("normal"))
		btn.modulate = Color(1, 1, 1, 1) if seen else Color(1, 1, 1, 0.45)


## Bấm 1 bài ĐÃ XEM ⇒ mở màn CHI TIẾT với đúng bài đó
func _on_select_tutorial(tid: String) -> void:
	# Nút bài CHƯA XEM đã bị khoá — chặn thêm một lần nữa nếu tín hiệu bị phát bằng tay
	if not _is_seen(tid):
		return
	var gm := Svc.game()
	if gm != null and gm.has_method("request_tutorial"):
		gm.call("request_tutorial", tid, true)
	NavHelper.goto_tutorial()


func _is_seen(tid: String) -> bool:
	var gm := Svc.game()
	if gm == null or not gm.has_method("is_tutorial_completed"):
		return true
	return bool(gm.call("is_tutorial_completed", tid))


func _on_back_pressed() -> void:
	NavHelper.go_back()


## ScreenManager gọi khi Back (nút cứng Android / phím Esc): về màn ĐÃ MỞ danh sách
## (Main hoặc Cài đặt — xem `Nav.goto_tutorial_list()` gọi từ `settings.gd`)
func close_from_back() -> void:
	NavHelper.go_back()


func _on_orientation_changed(_is_land: bool) -> void:
	_bind_refs()
	_apply_texts()
	_wire_buttons()
	# Bố cục mới = bộ nút mới ⇒ cập nhật lại trạng thái khoá/mở
	_refresh_list_state()
