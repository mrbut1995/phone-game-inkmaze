extends SceneTree
## DEV: chạy TỪNG BÀI tutorial từng bước MỘT (có frame ở giữa) để bắt lỗi runtime
## xảy ra khi chuyển bước (tween · spotlight · auto-step · hiệu ứng).
##   godot --headless --path . --script res://scripts/test_case/dev_probe_tutorial_flow.gd
## (Gộp stderr vào stdout khi chạy để quy đúng lỗi theo marker: `... 2>&1`)

const TUTORIALS := [
	"res://nodes/tutorials/first_time.tscn",
	"res://nodes/tutorials/how_to_play_move.tscn",
	"res://nodes/tutorials/how_to_play_checking_wall.tscn",
	"res://nodes/tutorials/how_to_play_minesweeper.tscn",
	"res://nodes/tutorials/how_to_play_one_stroke.tscn",
	"res://nodes/tutorials/how_to_play_sum_path.tscn",
	"res://nodes/tutorials/how_to_play_wall_builder.tscn",
	"res://nodes/tutorials/how_to_play_countdown_cost.tscn",
	"res://nodes/tutorials/how_to_play_fading_ink.tscn",
	"res://nodes/tutorials/how_to_play_fog_of_war.tscn",
	"res://nodes/tutorials/how_to_play_blind_memory.tscn",
]
const FRAMES_STEP := 6
const FRAMES_TAIL := 10


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _run() -> void:
	TranslationServer.set_locale("vi")
	for path: String in TUTORIALS:
		print("@@@ TUT %s" % path)
		var packed := load(path) as PackedScene
		if packed == null:
			print("@@@ TUT RESULT %s :: LOAD_FAIL" % path)
			continue
		var node := packed.instantiate()
		root.add_child(node)
		current_scene = node
		await _frames(FRAMES_STEP)
		var steps: Array = node.get("steps_data")
		print("@@@ TUT steps=%d" % steps.size())
		for _i in steps.size():
			node.call("next_step")
			await _frames(FRAMES_STEP)
		await _frames(FRAMES_TAIL)
		current_scene = null
		node.queue_free()
		await _frames(2)
	print("@@@ TUT DONE")
	quit(0)
