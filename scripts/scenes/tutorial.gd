class_name TutorialScene
extends BaseScene

## ============================================================================
## View Controller: màn CHI TIẾT bài hướng dẫn (`scenes/tutorial.tscn`)
##
## Chỉ lo ĐÚNG 1 VIỆC: mount bài người chơi đã chọn (hoặc chuỗi bài) vào
## `TutorialContainer` — danh sách bài nay nằm ở màn riêng `scenes/tutorial_list.tscn`.
##
## Ba kiểu mở:
##   · TỪ DANH SÁCH (`Nav.goto_tutorial` sau `GameManager.request_tutorial(id, true)`):
##     học xong / Back ⇒ về lại DANH SÁCH.
##   · LUỒNG HỌC LẦN ĐẦU (TutorialManager) hoặc Debug Console: học xong ⇒ đi tiếp luồng
##     (hoặc về DANH SÁCH nếu là bài lẻ Debug).
##   · LỚP PHỦ (`overlay_mode` — nút "?" trên màn chơi): ván chơi GIỮ NGUYÊN và tạm DỪNG
##     (host `process_mode = DISABLED`) ⇒ đóng là về ĐÚNG ván đang chơi.
## ============================================================================

const NavHelper := preload("res://scripts/utils/nav.gd")

@export var tutorial_controller: TutorialController = null

## Mở dạng LỚP PHỦ trên màn chơi (game_controller set TRƯỚC khi add_child — đọc trong _ready)
var overlay_mode := false

var layout: TutorialLayout = null
## Mở 1 bài LẺ (Debug Console) hoặc Test mode ⇒ học xong về DANH SÁCH bài học
var _stay_after_finish := false
## Khi vào tutorial từ màn chơi: quay về game sau khi kết thúc hoặc Back
var _return_to_game := false
## Mở từ DANH SÁCH bài học (`scenes/tutorial_list.tscn`) ⇒ Back/quay về đó, KHÔNG về Main
var _return_to_list := false
## Đang chạy LUỒNG HỌC LẦN ĐẦU (onboarding): học xong bài này thì đi tiếp bước kế của luồng
## (bài học trong màn / màn thực hành) thay vì về Main — xem scripts/manager/TutorialManager.gd
var _in_flow := false


func _ready() -> void:
	if overlay_mode:
		# Lớp phủ phải trùm kín màn chơi bên dưới (root Control của `scenes/base.tscn`)
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bind_refs()
	_apply_texts()
	_connect_locale_signal()
	orientation_changed.connect(_on_orientation_changed)

	# `tutorial_controller` bind trong `scenes/tutorial.tscn` (không dò đường dẫn trong code)
	# Dây `sequence_finished → _on_sequence_finished` cũng khai trong scene đó.
	if tutorial_controller != null and layout != null:
		tutorial_controller.set_container(layout.tutorial_container)
		_start_requested()


## Debug Console / danh sách / luồng học lần đầu: mở đúng bài (hoặc chuỗi) đã yêu cầu
func _start_requested() -> void:
	var requested := _take_tutorial_request()
	_stay_after_finish = _is_test_mode()
	# Kiểm flag quay về game (mở từ nút ? trên màn chơi)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("take_return_to_game_flag"):
		_return_to_game = bool(gm.call("take_return_to_game_flag"))
	else:
		_return_to_game = false
	if gm != null and gm.has_method("take_return_to_list_flag"):
		_return_to_list = bool(gm.call("take_return_to_list_flag"))
	else:
		_return_to_list = false
	if _return_to_game:
		# requested là danh sách id nối bằng dấu phẩy (do game_controller thiết lập)
		var ids := requested.split(",", false)
		if ids.size() > 1:
			var arr: Array[String] = []
			for s in ids:
				arr.append(s.strip_edges())
			tutorial_controller.start_sequence(arr)
		elif ids.size() == 1:
			tutorial_controller.play_single_tutorial(ids[0].strip_edges())
		else:
			_finish_and_return()
		return
	if requested == TutorialController.REQUEST_CORE:
		# Debug Console: chạy lại CHUỖI CORE (first_time → move → checking_wall)
		tutorial_controller.start_sequence()
	elif _is_flow_tutorial(requested):
		# Bước hiện tại của LUỒNG HỌC LẦN ĐẦU: học xong sẽ đi tiếp luồng (không về Main)
		_in_flow = true
		tutorial_controller.play_single_tutorial(requested)
	elif not requested.is_empty():
		tutorial_controller.play_single_tutorial(requested)
	else:
		# Không có yêu cầu (mở thẳng màn chi tiết, hoặc save cũ mất yêu cầu):
		# ⇒ về DANH SÁCH để người chơi chọn bài, không để màn trống.
		_go_to_list()


## Bài này có phải bước hiện tại của luồng onboarding không
func _is_flow_tutorial(tutorial_id: String) -> bool:
	var tm := _tutorial_manager()
	if tm == null or not tm.has_method("is_flow_tutorial"):
		return false
	return bool(tm.call("is_flow_tutorial", tutorial_id))


## Ván TEST (Debug Console bật “Test mode”): không ghi tiến trình, không tự nhảy màn
func _is_test_mode() -> bool:
	var gm := get_node_or_null("/root/GameManager")
	return bool(gm.get("debug_run")) if gm != null else false


## Đọc yêu cầu từ GameManager (lấy động qua /root — xem chú thích ở `utils/nav.gd`)
func _take_tutorial_request() -> String:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("take_tutorial_request"):
		return str(gm.call("take_tutorial_request"))
	return ""


## Manager điều phối luồng học lần đầu (lấy động qua /root như mọi autoload khác)
func _tutorial_manager() -> Node:
	return get_node_or_null("/root/TutorialManager")


func _bind_refs() -> void:
	layout = active_layout() as TutorialLayout
	if layout == null:
		push_warning("tutorial: active_layout chua phai TutorialLayout")


## Tiêu đề màn (chỉ thấy khi CHƯA mount bài nào) — gán bằng `tr()` thay vì để `.tscn`
## giữ khoá thô, vì `TopBar` là instance của `base_layout` nên không tự dịch.
func _apply_texts() -> void:
	if layout != null and layout.lbl_title != null:
		layout.lbl_title.text = tr("STR_TUT_COMMON_TITLE")


## Bảng dịch nạp XONG SAU `_ready()` (LoadingManager hoãn ~200 ms) ⇒ viết lại nhãn khi
## `LocalizationManager` phát `locale_changed`, nếu không tiêu đề hiện khoá thô.
func _connect_locale_signal() -> void:
	var loc: Node = get_node_or_null("/root/LocalizationManager")
	if loc != null and loc.has_signal("locale_changed") \
			and not loc.is_connected("locale_changed", _on_locale_changed):
		loc.connect("locale_changed", _on_locale_changed)


func _on_locale_changed(_locale: String) -> void:
	_apply_texts()


func _on_back_pressed() -> void:
	if _return_to_game:
		_finish_and_return()
		return
	if _return_to_list or _stay_after_finish:
		_go_to_list()
		return
	NavHelper.goto_main()


## ScreenManager gọi khi Back (nút cứng Android / phím Esc) trong lúc LỚP PHỦ đang mở:
## đóng lớp phủ để quay lại đúng ván đang chơi (giống nút Back trong màn Tutorial)
func close_from_back() -> void:
	if overlay_mode:
		_finish_and_return()
		return
	_on_back_pressed()


## Về màn DANH SÁCH bài học (không ghi lịch sử — đây là "Back" nghiệp vụ)
func _go_to_list() -> void:
	NavHelper.back_to_tutorial_list()


func _finish_and_return() -> void:
	# Mở dạng LỚP PHỦ từ màn chơi: chỉ đóng lớp phủ — ván đang chơi GIỮ NGUYÊN trạng thái
	if overlay_mode:
		_close_overlay()
		return
	# Mở từ màn chơi bằng ĐỔI SCENE (bài học của chế độ, `pending_return_to_game`) ⇒ vào lại ván
	if _return_to_game:
		NavHelper.goto_game()
		return
	_go_to_list()


## Đóng LỚP PHỦ Tutorial: trả quyền xử lý cho màn chơi bên dưới + chạy lại đồng hồ đang dừng
func _close_overlay() -> void:
	var host := get_parent()
	if host != null and is_instance_valid(host):
		host.process_mode = Node.PROCESS_MODE_INHERIT
		if host.has_method("resume_after_tutorial"):
			host.call("resume_after_tutorial")
	queue_free()


func _on_sequence_finished() -> void:
	# ── “BỎ QUA TẤT CẢ”: điều hướng theo NGUỒN đã mở màn Tutorial ──
	#    · mở từ MÀN CHƠI (nút "?") → ĐÓNG lớp phủ ⇒ về lại đúng ván đang chơi (giữ nguyên trạng thái)
	#    · đang trong LUỒNG HỌC LẦN ĐẦU → kết thúc luồng rồi về MÀN HÌNH CHÍNH
	#    · mở từ DANH SÁCH / Debug → về lại DANH SÁCH bài học
	if tutorial_controller != null and bool(tutorial_controller.get("skipped_all")):
		if _return_to_game:
			if _in_flow:
				var tm_skip := _tutorial_manager()
				if tm_skip != null:
					tm_skip.call("abort_flow")
			_finish_and_return()
		elif _in_flow:
			var tm_flow := _tutorial_manager()
			if tm_flow != null:
				tm_flow.call("abort_flow")
			NavHelper.goto_main()
		else:
			_go_to_list()
		return
	# Quay về game sau khi xem tutorial từ nút "?"
	if _return_to_game:
		# …nhưng nếu LUỒNG HỌC LẦN ĐẦU đang chờ 1 BÀI HỌC thì chạy tiếp NGAY trong màn này
		# (không nhảy về màn chơi: màn chơi sẽ bị khởi động lại từ đầu + nháy màn hình).
		if _resume_flow_after_practice():
			return
		_finish_and_return()
		return
	if _in_flow:
		_continue_flow()
		return
	# Bài lẻ (Debug/test) hoặc mở từ DANH SÁCH: học xong ⇒ về DANH SÁCH bài học
	if _stay_after_finish or _return_to_list:
		_go_to_list()
		return
	# Hoàn thành chuỗi (chuỗi CORE của Debug Console): chuyển sang Màn 1 hoặc về Menu chính
	_enter_first_level()


## Học xong 1 bài của luồng onboarding: chạy tiếp bài kế (trong màn) · màn thực hành ·
## hoặc kết thúc luồng. (Nhánh “Bỏ qua tất cả” xử lý riêng ở `_on_sequence_finished`.)
func _continue_flow() -> void:
	var tm := _tutorial_manager()
	if tm == null:
		NavHelper.goto_main()
		return
	var result: Dictionary = tm.call("continue_flow_inplace")
	var next_id := str(result.get("next", ""))
	if not next_id.is_empty():
		tutorial_controller.play_single_tutorial(next_id)
		return
	if result.has("level"):
		return                              # đang chuyển sang màn chơi — scene này sắp bị thay
	NavHelper.goto_main()                  # luồng đã kết thúc


## Vừa học xong bài mở từ nút "?" của màn chơi: nếu bước hiện tại của luồng onboarding là
## 1 BÀI HỌC thì chạy tiếp luôn trong màn này và chuyển sang chế độ “đang chạy luồng”.
## Trả true = đã mở bài kế (KHÔNG quay về màn chơi).
func _resume_flow_after_practice() -> bool:
	var tm := _tutorial_manager()
	if tm == null or not tm.has_method("resume_flow_lesson"):
		return false
	var next_id := str(tm.call("resume_flow_lesson"))
	# Bài luồng trả về có thể CHÍNH LÀ bài vừa học (ván TEST không ghi tiến trình, save lệch…) —
	# lúc đó không mở lại nữa để tránh lặp vô tận.
	if next_id.is_empty() or next_id == str(tutorial_controller.current_tutorial_id):
		return false
	_return_to_game = false
	_in_flow = true
	tutorial_controller.play_single_tutorial(next_id)
	return true


## Vào thẳng Màn 1 (chuỗi CORE của Debug Console học xong)
func _enter_first_level() -> void:
	var gm := get_tree().root.get_node_or_null("GameManager") if get_tree() != null and get_tree().root != null else null
	if gm != null and gm.has_method("start_level"):
		gm.call("start_level", 1)
	else:
		NavHelper.goto_main()


func _on_orientation_changed(_is_land: bool) -> void:
	_bind_refs()
	_apply_texts()
	if tutorial_controller != null and layout != null:
		tutorial_controller.set_container(layout.tutorial_container)
