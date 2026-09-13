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
	UIAnim.attach_press_bounce(test_btn)
	assert(test_btn.pivot_offset == Vector2(50, 25), "UIAnim phai tu can pivot offset ve tam")
	print("[CHECK] UIAnim.attach_press_bounce hoat dong tot.")

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

	# 2. Test SceneTransition Component
	var transition := SceneTransition.new()
	root.add_child(transition)
	assert(transition.layer == 128, "SceneTransition phai o layer 128 de hien tren moi scene")
	assert(transition.process_mode == Node.PROCESS_MODE_ALWAYS, "SceneTransition phai chay process_mode ALWAYS")
	assert(not transition.is_busy(), "Ban dau transition khong duoc o trang thai busy")
	print("[CHECK] SceneTransition khoi tao dung thong so (Layer 128, ProcessMode ALWAYS).")

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
	print("[CHECK] Ink Circle Bloom transition chay thanh cong.")

	# 5. Test Transition Paper Fade
	var fade_called := [false]
	await transition.play_transition(
		"res://scenes/settings.tscn",
		func() -> void: fade_called[0] = true,
		"paper_fade"
	)
	assert(fade_called[0], "Callback paper_fade phai duoc goi")
	print("[CHECK] Paper Fade transition chay thanh cong.")

	transition.queue_free()
	await process_frame

	print("\n========================================================")
	print("  TAT CA TEST TRANSITIONS & ANIMATIONS DEU PASS!")
	print("========================================================\n")
	quit(0)
