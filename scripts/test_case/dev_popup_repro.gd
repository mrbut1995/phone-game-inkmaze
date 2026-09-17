extends SceneTree
## ============================================================================
## DEV TOOL: tái hiện & đo popup + màn loading ở tỉ lệ TABLET (cần render thật):
##
##   godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_popup_repro.gd
##
## Với mỗi cỡ cửa sổ (2560×1600 ngang · 1600×2560 dọc):
##   · Màn game (play) → thua ván → popup game_over_level: đo rect + chụp ảnh
##   · Mở popup next_floor (dungeon): đo rect + chụp ảnh
##   · Lớp chuyển cảnh loading.tscn: chụp ảnh giữa hiệu ứng
## Ảnh lưu vào tmp_popup/<WxH>_<id>.png (nửa phân giải).
## ============================================================================

const SIZES := [Vector2i(2560, 1600), Vector2i(1600, 2560)]


func _init() -> void:
	print("\n=== POPUP REPRO ===")
	await process_frame
	TranslationServer.set_locale("vi")
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("unlocked_levels", 99)
	DirAccess.make_dir_recursive_absolute("res://tmp_popup")
	for size in SIZES:
		DisplayServer.window_set_size(size)
		await _frames(5)
		print("\n─── cửa sổ %dx%d  canvas %s" % [size.x, size.y, str(root.get_visible_rect().size)])
		await _case_game_over()
		await _case_next_floor()
		await _case_loading(size)
	quit(0)


func _case_game_over() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "play")
		gm.set("current_level", 1)
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(12)
	var controller: Node = scene.get("game_controller")
	controller.call("_game_over")
	await _frames(40)
	_dump("game_over_level")
	_shot("game_over")
	Popups.close_all()
	await _frames(8)
	scene.queue_free()
	await _frames(2)


func _case_next_floor() -> void:
	var gm: Node = root.get_node_or_null("GameManager")
	if gm != null:
		gm.set("current_mode", "dungeon")
		gm.set("current_level", 1)
	var scene: Node = (load("res://scenes/game.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	await _frames(12)
	Popups.open(Popups.NEXT_FLOOR, {
		"floor": 1, "next_floor": 2, "steps_bonus": 8, "base_score": 50,
		"move_bonus": 130, "perfect_bonus": 100, "total_score": 752,
	})
	await _frames(40)
	_dump("next_floor")
	_shot("next_floor")
	Popups.close_all()
	await _frames(8)
	scene.queue_free()
	await _frames(2)


func _case_loading(size: Vector2i) -> void:
	var layer: CanvasLayer = (load("res://scenes/loading.tscn") as PackedScene).instantiate() as CanvasLayer
	root.add_child(layer)
	await _frames(4)
	var transition := layer as Node
	transition.call("play_transition", "res://scenes/main.tscn", func() -> void: pass, "page_turn_forward")
	await _frames(14)          # giữa hiệu ứng lật trang
	_shot("loading_mid_%dx%d" % [size.x, size.y])
	_transition_dump(transition)
	await _frames(40)
	layer.queue_free()
	await _frames(2)


func _transition_dump(transition: Node) -> void:
	var tr := transition.get_node_or_null("TransitionRoot") as Control
	if tr == null:
		print("   [FAIL] thiếu TransitionRoot")
		return
	var canvas := root.get_visible_rect().size
	print("   loading: TransitionRoot rect=%s (canvas %s)" % [
		str(Rect2(tr.global_position, tr.size)), str(canvas)])
	var page := tr.get_node_or_null("PaperPage") as Control
	var bg := tr.get_node_or_null("PaperPage/PaperBg") as Control
	var wm := tr.get_node_or_null("PaperPage/Watermark") as Control
	if page != null:
		print("   loading: PaperPage rect=%s" % str(Rect2(page.global_position, page.size)))
	if bg != null:
		print("   loading: PaperBg rect=%s" % str(Rect2(bg.global_position, bg.size)))
	if wm != null:
		print("   loading: Watermark rect=%s" % str(Rect2(wm.global_position, wm.size)))


## In toạ độ popup đang mở trên cùng
func _dump(id: String) -> void:
	var canvas := root.get_visible_rect().size
	var pop := Popups.top()
	if pop == null:
		print("   [FAIL] %s: KHÔNG có popup nào mở" % id)
		return
	var rect := Rect2(pop.global_position, pop.size)
	var dim := pop.get_node_or_null("Dim") as Control
	var panel := pop.get_node_or_null("Panel") as Control
	print("   %s: root=%s visible=%s dim=%s" % [
		id, str(rect), str(pop.visible),
		str(Rect2(dim.global_position, dim.size) if dim != null else Rect2())])
	if panel != null:
		var pr := Rect2(panel.global_position, panel.size)
		var center_ok := absf(pr.position.x + pr.size.x * 0.5 - canvas.x * 0.5)
		var bottom_ok := canvas.y - (pr.position.y + pr.size.y)
		print("      Panel=%s  center_lệch_x=%.1f  đáy_còn=%.1f  trong_canvas=%s" % [
			str(pr), center_ok, bottom_ok, str(Rect2(Vector2.ZERO, canvas).grow(2).encloses(pr))])


func _shot(id: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		return
	img.resize(maxi(int(img.get_width() * 0.5), 1), maxi(int(img.get_height() * 0.5), 1), Image.INTERPOLATE_LANCZOS)
	img.save_png("res://tmp_popup/%s.png" % id)


func _frames(n: int) -> void:
	for i in n:
		await process_frame
