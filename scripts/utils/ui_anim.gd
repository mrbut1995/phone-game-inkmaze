class_name UIAnim
extends RefCounted
## ============================================================================
## Helper tĩnh: Quản lý các hiệu ứng tương tác (Micro-interactions) và animation
## giao diện (UI) cho phong cách Sổ tay & Mực của InkMaze.
## ============================================================================

## Gắn hiệu ứng nhấn nảy đàn hồi (squash & bounce) cho bất kỳ nút bấm nào
static func attach_press_bounce(btn: BaseButton, scale_down := 0.94, duration := 0.1) -> void:
	if btn == null or not is_instance_valid(btn):
		return
	
	# Đảm bảo điểm neo phóng to/thu nhỏ luôn nằm chính giữa nút
	_update_pivot(btn)
	if not btn.resized.is_connected(_on_btn_resized.bind(btn)):
		btn.resized.connect(_on_btn_resized.bind(btn))

	var press_state := {"tween": null}

	btn.button_down.connect(func() -> void:
		if press_state["tween"] != null and is_instance_valid(press_state["tween"]):
			(press_state["tween"] as Tween).kill()
		_update_pivot(btn)
		var tw := btn.create_tween()
		press_state["tween"] = tw
		tw.tween_property(btn, "scale", Vector2.ONE * scale_down, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)

	var release_action := func() -> void:
		if press_state["tween"] != null and is_instance_valid(press_state["tween"]):
			(press_state["tween"] as Tween).kill()
		_update_pivot(btn)
		var tw := btn.create_tween()
		press_state["tween"] = tw
		tw.tween_property(btn, "scale", Vector2.ONE * 1.035, duration * 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, duration * 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	btn.button_up.connect(release_action)
	btn.mouse_exited.connect(func() -> void:
		if btn.button_pressed or btn.scale != Vector2.ONE:
			if press_state["tween"] != null and is_instance_valid(press_state["tween"]):
				(press_state["tween"] as Tween).kill()
			var tw := btn.create_tween()
			press_state["tween"] = tw
			tw.tween_property(btn, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)


## Hiệu ứng hiện hình mờ dần (Fade-in) an toàn tuyệt đối cho node con trong Container
static func play_fade_in(node: Control, delay := 0.0, duration := 0.25) -> Tween:
	if node == null or not is_instance_valid(node):
		return null
	node.modulate.a = 0.0
	var tw := node.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw


## Hiệu ứng xuất hiện nảy nhẹ (Pop-in)
static func play_pop_in(node: Control, delay := 0.0, from_scale := 0.85, duration := 0.24) -> Tween:
	if node == null or not is_instance_valid(node):
		return null
	_update_pivot(node)
	node.scale = Vector2.ONE * from_scale
	node.modulate.a = 0.0
	var tw := node.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(node, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw


## Hiệu ứng trượt nhẹ kết hợp hiện hình (Slide-in)
## LƯU Ý: Không dùng cho node con trực tiếp của Container (VBox/HBox/Grid) vì Container tự kiểm soát position.
static func play_slide_in(node: Control, offset := Vector2(0, 35), delay := 0.0, duration := 0.28) -> Tween:
	if node == null or not is_instance_valid(node):
		return null
	# Bảo vệ an toàn: nếu node nằm trong Container thì tự động fallback sang fade_in
	if node.get_parent() is Container:
		return play_fade_in(node, delay, duration)

	var target_pos := node.position
	node.position = target_pos + offset
	node.modulate.a = 0.0
	var tw := node.create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.set_parallel(true)
	tw.tween_property(node, "position", target_pos, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "modulate:a", 1.0, duration * 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw


## Hiệu ứng nhịp thở thu hút sự chú ý (Pulse / Breathing)
static func play_pulse(node: Control, max_scale := 1.035, cycle_duration := 1.6) -> Tween:
	if node == null or not is_instance_valid(node):
		return null
	_update_pivot(node)
	var tw := node.create_tween().set_loops()
	var half_dur := cycle_duration * 0.5
	tw.tween_property(node, "scale", Vector2.ONE * max_scale, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, half_dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


## Hiệu ứng bồng bềnh nhẹ (Floating idle) cho Logo hoặc huy hiệu
static func play_float_idle(node: Control, distance_y := 6.0, cycle_duration := 2.4) -> Tween:
	if node == null or not is_instance_valid(node):
		return null
	var initial_y := node.position.y
	var tw := node.create_tween().set_loops()
	var quarter := cycle_duration * 0.25
	tw.tween_property(node, "position:y", initial_y - distance_y, quarter * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position:y", initial_y, quarter * 2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return tw


static func _update_pivot(control: Control) -> void:
	if control != null and is_instance_valid(control) and control.size.length_squared() > 0:
		control.pivot_offset = control.size * 0.5


static func _on_btn_resized(control: Control) -> void:
	_update_pivot(control)


## Hiệu ứng nhãn chữ nổi bay lên và mờ dần (Floating Ink Text, ví dụ: +5, BONUS, PERFECT)
static func spawn_floating_text(parent: Node, text: String, world_pos: Vector2, color := Color(0.133, 0.298, 0.427, 1.0), duration := 0.65) -> Label:
	if parent == null or not is_instance_valid(parent):
		return null
	var label := Label.new()
	label.text = text
	label.modulate = color
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = world_pos - Vector2(60, 20)
	label.size = Vector2(120, 40)
	label.pivot_offset = Vector2(60, 20)
	label.scale = Vector2(0.5, 0.5)

	parent.add_child(label)

	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "position:y", world_pos.y - 55.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2(1.15, 1.15), duration * 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2(1.0, 1.0), duration * 0.35).set_delay(duration * 0.25)
	tw.tween_property(label, "modulate:a", 0.0, duration * 0.4).set_delay(duration * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(label.queue_free)
	return label


## Hiệu ứng cuộn số tăng dần (Number Roll-up) cho điểm số hoặc bước đi
static func animate_counter(label: Label, from_val: int, to_val: int, duration := 0.45, prefix := "", suffix := "") -> Tween:
	if label == null or not is_instance_valid(label):
		return null
	var proxy := {"val": float(from_val)}
	var tw := label.create_tween()
	tw.tween_method(func(v: float) -> void:
		if is_instance_valid(label):
			var current_int := int(round(v))
			label.text = "%s%d%s" % [prefix, current_int, suffix],
		float(from_val),
		float(to_val),
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tw
