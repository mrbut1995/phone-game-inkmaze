class_name TutorialScene
extends BaseScene

## ============================================================================
## View Controller: Màn hình Tutorial (hướng dẫn tương tác)
## Kế thừa BaseScene, điều phối chạy các màn tutorial độc lập hoặc theo chuỗi onboarding.
##
## Hai kiểu mở:
##   · ĐỔI SCENE (`Nav.goto_tutorial`): từ Title / Main / Debug — có yêu cầu thì mở bài,
##     KHÔNG có yêu cầu (nút LUẬT CHƠI) thì chỉ HIỆN DANH SÁCH, không tự chạy chuỗi CORE.
##   · LỚP PHỦ (`overlay_mode` — mở từ nút "?" trên màn chơi): scene chơi được GIỮ NGUYÊN
##     và tạm DỪNG (host `process_mode = DISABLED`) ⇒ đóng là về ĐÚNG ván đang chơi.
##
## Danh sách bài: bài ĐÃ XEM = nút ACTIVE · bài CHƯA XEM = nút KHOÁ (mờ) — `_refresh_list_state`.
## ============================================================================

const NavHelper := preload("res://scripts/utils/nav.gd")

@export var tutorial_controller: TutorialController = null

## Mở dạng LỚP PHỦ trên màn chơi (game_controller set TRƯỚC khi add_child — đọc trong _ready)
var overlay_mode := false

var layout: TutorialLayout = null
## Mở 1 bài LẺ (Debug Console) hoặc Test mode ⇒ học xong Ở LẠI màn Tutorial để thử bài khác
var _stay_after_finish := false
## Khi vào tutorial từ màn chơi: quay về game sau khi kết thúc hoặc Back
var _return_to_game := false
## Đang chạy LUỒNG HỌC LẦN ĐẦU (onboarding): học xong bài này thì đi tiếp bước kế của luồng
## (bài học trong màn / màn thực hành) thay vì về Main — xem scripts/manager/TutorialManager.gd
var _in_flow := false

func _ready() -> void:
	if overlay_mode:
		# Lớp phủ phải trùm kín màn chơi bên dưới (root Control của `scenes/base.tscn`)
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bind_refs()
	_wire_buttons()
	orientation_changed.connect(_on_orientation_changed)

	# `tutorial_controller` bind trong `scenes/tutorial.tscn` (không dò đường dẫn trong code)
	# Dây `sequence_finished → _on_sequence_finished` cũng khai trong scene đó.
	if tutorial_controller != null and layout != null:
		tutorial_controller.set_container(layout.tutorial_container)
		_start_requested()
	# Không có bài nào chạy ⇒ DANH SÁCH hiện ra: khoá/mở nút theo tiến trình người chơi
	_refresh_list_state()


## Debug Console có thể yêu cầu mở THẲNG 1 bài (hoặc chạy lại chuỗi CORE) trước khi vào màn
func _start_requested() -> void:
	var requested := _take_tutorial_request()
	_stay_after_finish = _is_test_mode()
	# Kiểm flag quay về game (mở từ nút ? trên màn chơi)
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("take_return_to_game_flag"):
		_return_to_game = bool(gm.call("take_return_to_game_flag"))
	else:
		_return_to_game = false
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
		_stay_after_finish = true
		tutorial_controller.play_single_tutorial(requested)
	# requested RỖNG (nút LUẬT CHƠI ở Main · dòng “Tutorial (menu)” của Debug):
	# KHÔNG tự chạy bài nào — chỉ hiện DANH SÁCH cho người chơi chọn (nút đã xem mới bấm được)


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


func _wire_buttons() -> void:
	if layout == null:
		return

	# Dây nút khai trong `scenes/tutorial.tscn` (cả 2 hướng) — guard chỉ nối lại nếu dây bị mất
	ensure_signal(layout.btn_back, &"pressed", &"_on_back_pressed")

	for tid in _list_buttons():
		var btn: BaseButton = _list_buttons()[tid]
		if btn != null:
			ensure_signal(btn, &"pressed", &"_on_select_tutorial", [tid])


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
	var gm := get_node_or_null("/root/GameManager")
	for tid in _list_buttons():
		var btn: BaseButton = _list_buttons()[tid]
		if btn == null:
			continue
		var seen := true
		if gm != null and gm.has_method("is_tutorial_completed"):
			seen = bool(gm.call("is_tutorial_completed", tid))
		btn.disabled = not seen
		# Giữ NGUYÊN art giấy cho nút khoá (theme mặc định không có style "disabled") rồi LÀM MỜ
		btn.add_theme_stylebox_override("disabled", btn.get_theme_stylebox("normal"))
		btn.modulate = Color(1, 1, 1, 1) if seen else Color(1, 1, 1, 0.45)


func _on_select_tutorial(tid: String) -> void:
	# Nút bài CHƯA XEM đã bị khoá — chặn thêm một lần nữa nếu tín hiệu bị phát bằng tay
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("is_tutorial_completed"):
		if not bool(gm.call("is_tutorial_completed", tid)):
			return
	_stay_after_finish = true
	if tutorial_controller != null:
		tutorial_controller.play_single_tutorial(tid)


func _on_back_pressed() -> void:
	if _return_to_game:
		_finish_and_return()
		return
	NavHelper.goto_main()


## ScreenManager gọi khi Back (nút cứng Android / phím Esc) trong lúc LỚP PHỦ đang mở:
## đóng lớp phủ để quay lại đúng ván đang chơi (giống nút Back trong màn Tutorial)
func close_from_back() -> void:
	if overlay_mode:
		_finish_and_return()
		return
	_on_back_pressed()


func _finish_and_return() -> void:
	# Mở dạng LỚP PHỦ từ màn chơi: chỉ đóng lớp phủ — ván đang chơi GIỮ NGUYÊN trạng thái
	if overlay_mode:
		_close_overlay()
		return
	NavHelper.goto_game()


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
	#    · mở từ DANH SÁCH (nút LUẬT CHƠI) → ở lại màn Tutorial, hiện lại danh sách
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
			_refresh_list_state()
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
	# Thử bài từ Debug Console (bài lẻ / Test mode) hoặc mở từ DANH SÁCH: ở lại màn Tutorial
	if _stay_after_finish:
		_refresh_list_state()
		return
	# Hoàn thành chuỗi (Debug/chuỗi CORE): chuyển sang Màn 1 hoặc về Menu chính
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
	_wire_buttons()
	if tutorial_controller != null and layout != null:
		tutorial_controller.set_container(layout.tutorial_container)
	# Bố cục mới = bộ nút mới ⇒ cập nhật lại trạng thái khoá/mở
	_refresh_list_state()
