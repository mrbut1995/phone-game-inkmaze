extends SceneTree
## Dev (không thuộc suite): render từng màn tutorial ở 2 tỉ lệ để SOI BỐ CỤC.
##   & <godot> --path . --rendering-driver opengl3 -s res://scripts/test_case/dev_tutorial_shots.gd
## Ảnh lưu ở `tmp_tut/<size>/<id>_step0.png` và `…_stepN.png` (N = bước tương tác).

const TUTORIAL_IDS := [
	"first_time",
	"how_to_play_move",
	"how_to_play_checking_wall",
	"how_to_play_minesweeper",
	"how_to_play_one_stroke",
	"how_to_play_sum_path",
	"how_to_play_wall_builder",
]
## Bước cần chụp thêm (bước cho người chơi thao tác — nơi lộ bàn mini + tay chỉ + bóng sáng)
const EXTRA_STEP := {
	"first_time": 1,
	"how_to_play_move": 1,
	"how_to_play_checking_wall": 1,
	"how_to_play_minesweeper": 0,
	"how_to_play_one_stroke": 3,
	"how_to_play_sum_path": 1,
	"how_to_play_wall_builder": 3,
}
const SIZES := [Vector2i(1080, 1920), Vector2i(1920, 1080)]


func _init() -> void:
	await _frames(2)
	TranslationServer.set_locale("vi")
	for size: Vector2i in SIZES:
		DisplayServer.window_set_size(size)
		await _frames(4)
		print("── %dx%d" % [size.x, size.y])
		for tid: String in TUTORIAL_IDS:
			await _shoot(tid, int(EXTRA_STEP.get(tid, 0)), size)
	quit(0)


func _shoot(tid: String, extra_step: int, size: Vector2i) -> void:
	var packed := load("res://scenes/tutorial.tscn") as PackedScene
	if packed == null:
		print("  [LOI] khong load duoc scenes/tutorial.tscn")
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	current_scene = scene
	await _frames(12)
	var controller: Node = scene.get("tutorial_controller")
	if controller == null:
		print("  [LOI] %s: chua bind TutorialController" % tid)
		scene.queue_free()
		return
	controller.call("play_single_tutorial", tid)
	await _frames(30)      # chờ hoạt cảnh mở bài (nền · thẻ thoại · ô so le) chạy xong
	var overlay: Node = _find_overlay(root)
	if overlay == null:
		print("  [LOI] %s: khong thay overlay BaseTutorial" % tid)
		scene.queue_free()
		return
	await _save(overlay, tid, 0, size)
	for i in extra_step:
		overlay.call("next_step")
		await _frames(14)
	await _save(overlay, tid, extra_step, size)
	scene.queue_free()
	await _frames(2)


func _find_overlay(from_node: Node) -> Node:
	for child in from_node.find_children("*", "BaseTutorial", true, false):
		return child
	return null


func _save(overlay: Node, tid: String, step: int, size: Vector2i) -> void:
	await _frames(4)
	var img := root.get_texture().get_image()
	if img == null:
		print("  [LOI] %s: khong chup duoc anh" % tid)
		return
	img.resize(maxi(int(img.get_width() * 0.5), 1), maxi(int(img.get_height() * 0.5), 1), Image.INTERPOLATE_LANCZOS)
	var dir := "res://tmp_tut/%dx%d" % [size.x, size.y]
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png("%s/%s_step%d.png" % [dir, tid, step])
	print("   [shot] %-28s step %d | steps=%d | o=%d" % [
		tid, step, (overlay.get("steps_data") as Array).size(), _count_cells(overlay)])


func _count_cells(overlay: Node) -> int:
	return overlay.find_children("*", "TutorialCell", true, false).size()


func _frames(n: int) -> void:
	for i in n:
		await process_frame
