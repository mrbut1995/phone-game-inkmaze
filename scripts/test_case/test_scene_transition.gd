extends SceneTree
## ============================================================================
## Test Case: Kiểm tra SceneTransition, SceneManager & UIAnim
## ============================================================================

const UIAnim := preload("res://scripts/utils/ui_anim.gd")
const SceneTransition := preload("res://scripts/nodes/common/scene_transition.gd")

func _init() -> void:
	print("\n========================================================")
	print("  TEST: SCENE TRANSITIONS & UI ANIMATIONS")
	print("========================================================\n")

	# 1. Test UIAnim helper
	var test_btn := Button.new()
	test_btn.size = Vector2(100, 50)
	root.add_child(test_btn)
	UIAnim.attach_press_down(test_btn)
	assert(test_btn.pivot_offset == Vector2(50, 25), "UIAnim phai tu can pivot offset ve tam")
	print("[CHECK] UIAnim.attach_press_down hoat dong tot.")

	var test_control := Control.new()
	test_control.size = Vector2(200, 100)
	root.add_child(test_control)
	var tw_pop := UIAnim.play_pop_in(test_control, 0.0, 0.8, 0.1)
	assert(tw_pop != null, "UIAnim.play_pop_in phai tra ve Tween hop le")
	var tw_pulse := UIAnim.play_pulse(test_control, 1.05, 0.5)
	assert(tw_pulse != null, "UIAnim.play_pulse phai tao tween loop")
	tw_pulse.kill()
	print("[CHECK] UIAnim pop-in & pulse hoat dong tot.")

	test_btn.queue_free()
	test_control.queue_free()
	await process_frame

	# 2. Test SceneTransition Component — node giao diện KHAI BÁO SẴN trong scenes/loading.tscn
	var packed: PackedScene = load("res://scenes/loading.tscn")
	assert(packed != null, "scenes/loading.tscn phai load duoc")
	var transition: SceneTransition = packed.instantiate()
	root.add_child(transition)
	await process_frame
	assert(transition.layer == 128, "SceneTransition phai o layer 128 de hien tren moi scene")
	assert(transition.process_mode == Node.PROCESS_MODE_ALWAYS, "SceneTransition phai chay process_mode ALWAYS")
	assert(not transition.is_busy(), "Ban dau transition khong duoc o trang thai busy")
	assert(transition.has_ui(), "loading.tscn phai co san node giao dien (khong sinh luc chay)")

	# Các node transition phải tồn tại ngay từ scene loading.tscn
	var ui_paths := [
		"TransitionRoot",
		"TransitionRoot/InputBlocker",
		"TransitionRoot/PaperPage",
		"TransitionRoot/PaperPage/PaperBg",
		"TransitionRoot/PaperPage/ShadowLeft",
		"TransitionRoot/PaperPage/ShadowRight",
		"TransitionRoot/PaperPage/Watermark",
		"TransitionRoot/InkCircleDrawer",
		"TransitionRoot/FadeRect",
	]
	var ui_root: Control = transition.get_node("TransitionRoot")
	for path in ui_paths:
		assert(transition.get_node_or_null(path) != null, "loading.tscn thieu node %s" % path)
	var ui_child_count := ui_root.get_child_count()
	print("[CHECK] loading.tscn co san %d node transition (KHONG sinh luc chay)." % ui_child_count)

	# Script .new() (khong co node giao dien) -> chuyen canh tuc thi, khong crash
	# (script chu dong push_error de canh bao dung sai -> tat tieng on khi test)
	var prev_print_errors := Engine.print_error_messages
	Engine.print_error_messages = false
	var bare := SceneTransition.new()
	root.add_child(bare)
	await process_frame
	assert(not bare.has_ui(), "SceneTransition.new() khong duoc tu sinh node giao dien")
	var bare_called := [false]
	await bare.play_transition("res://scenes/main.tscn", func() -> void: bare_called[0] = true, "page_turn_forward")
	assert(bare_called[0], "Khong co node giao dien thi van phai goi callback doi scene")
	Engine.print_error_messages = prev_print_errors
	print("[CHECK] Thieu node giao dien -> chuyen canh tuc thi (khong crash).")
	bare.queue_free()
	await process_frame

	# 3. Test Transition Execution (Page Turn Forward)
	var callback_called := [false]
	var started_fired := [false]
	var finished_fired := [false]

	var last_style := [""]
	transition.transition_started.connect(func(s: String) -> void:
		started_fired[0] = true
		last_style[0] = s
	)
	transition.transition_finished.connect(func(s: String) -> void:
		finished_fired[0] = true
	)

	# Chạy transition với await
	await transition.play_transition(
		"res://scenes/levels.tscn",
		func() -> void: callback_called[0] = true,
		"page_turn_forward"
	)
	assert(callback_called[0], "Callback doi scene phai duoc goi trong qua trinh transition")
	assert(started_fired[0], "Signal transition_started phai duoc ban")
	assert(finished_fired[0], "Signal transition_finished phai duoc ban")
	assert(not transition.is_busy(), "Sau khi xong, is_busy() phai tro ve false")
	assert(ui_root.get_child_count() == ui_child_count, "Transition khong duoc sinh them node luc chay")
	print("[CHECK] Page Turn Forward chay thanh cong (In -> Callback -> Out).")

	# 4. Test Transition Ink Circle
	var ink_called := [false]
	await transition.play_transition(
		"res://scenes/game.tscn",
		func() -> void: ink_called[0] = true,
		"ink_circle"
	)
	assert(ink_called[0], "Callback ink_circle phai duoc goi")
	assert(not transition.is_busy(), "Sau ink_circle, is_busy() phai ve false")
	assert(ui_root.get_child_count() == ui_child_count, "Ink Circle khong duoc sinh them node luc chay")
	print("[CHECK] Ink Circle Bloom transition chay thanh cong.")

	# 5. Test Transition Paper Fade
	var fade_called := [false]
	await transition.play_transition(
		"res://scenes/settings.tscn",
		func() -> void: fade_called[0] = true,
		"paper_fade"
	)
	assert(fade_called[0], "Callback paper_fade phai duoc goi")
	assert(ui_root.get_child_count() == ui_child_count, "Paper Fade khong duoc sinh them node luc chay")
	print("[CHECK] Paper Fade transition chay thanh cong.")

	transition.queue_free()
	await process_frame

	# 6. Lịch sử điều hướng khi ván chơi KẾT THÚC (lỗi: thắng màn 9 → Chọn màn → Back → lại màn 9)
	await _check_back_after_run()

	print("\n========================================================")
	print("  TAT CA TEST TRANSITIONS & ANIMATIONS DEU PASS!")
	print("========================================================\n")
	quit(0)


## Thắng màn cuối chương ⇒ về Chọn màn phải là thao tác BACK (không đẩy màn CHƠI vào lịch sử,
## gỡ luôn mục "Chọn màn" đã đẩy lúc vào ván) ⇒ Back ở Chọn màn về Main, KHÔNG quay lại ván.
func _check_back_after_run() -> void:
	var sm: Node = root.get_node("SceneManager")
	var screen: Node = root.get_node("ScreenManager")
	var gm: Node = root.get_node("GameManager")
	screen.call("clear_history")

	# Main → Chọn màn (đi TIẾN) → vào ván màn 9
	sm.call("change_scene", "res://scenes/main.tscn")
	await _frames(3)
	gm.call("go_to_levels")
	await _frames(3)
	assert(current_scene.scene_file_path == "res://scenes/levels.tscn", "Phai o man Chon man truoc khi vao van")
	sm.call("change_scene", "res://scenes/game.tscn")
	await _frames(3)
	assert(str(screen.call("peek_history")) == "res://scenes/levels.tscn",
		"Vao van tu Chon man: lich su phai giu man Chon man de Back con dung")

	# Thắng màn cuối chương (nút "CHỌN CHƯƠNG" ⇒ `return_to_levels()`)
	gm.call("return_to_levels")
	await _frames(3)
	assert(current_scene.scene_file_path == "res://scenes/levels.tscn", "return_to_levels phai ve man Chon man")
	assert(str(screen.call("peek_history")) != "res://scenes/game.tscn",
		"Man CHƠI KHONG duoc nam trong lich su sau khi van ket thuc")
	assert(str(screen.call("peek_history")) == "res://scenes/main.tscn",
		"return_to_levels phai go muc 'Chon man' da day luc vao van ⇒ Back con ve Main")
	print("[CHECK] Van ket thuc -> ve Chon man KHONG day man choi vao lich su.")

	# Back ở Chọn màn ⇒ về Main (trước đây quay lại đúng ván vừa chơi)
	screen.call("go_back")
	await _frames(4)
	assert(current_scene.scene_file_path == "res://scenes/main.tscn",
		"Back o man Chon man phai ve Main, KHONG quay lai man vua choi")
	print("[CHECK] Back o man Chon man ve Main (het loi 'quay lai man 9').")

	# Ván Daily kết thúc ⇒ "VỀ DAILY" cũng không được đẩy màn chơi vào lịch sử
	screen.call("clear_history")
	gm.call("go_to_daily")
	await _frames(3)
	sm.call("change_scene", "res://scenes/game.tscn")
	await _frames(3)
	gm.call("return_to_daily")
	await _frames(3)
	assert(current_scene.scene_file_path == "res://scenes/daily.tscn", "return_to_daily phai ve man Daily")
	assert(str(screen.call("peek_history")) == "res://scenes/main.tscn",
		"return_to_daily phai go muc 'Daily' da day luc vao van, chi con man truoc do")
	print("[CHECK] Van Daily ket thuc -> ve Daily khong de lai lich su man choi.")


func _frames(n: int) -> void:
	for i in n:
		await process_frame
