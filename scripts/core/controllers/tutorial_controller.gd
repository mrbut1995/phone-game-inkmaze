class_name TutorialController
extends Node

## ============================================================================
## TutorialController: Điều phối luồng chạy Tutorial tương tác.
## Quản lý trình tự các scene (first_time -> how_to_play_move -> ...),
## mount/unmount node vào container và cập nhật cờ tutorial_progress.
## ============================================================================

signal tutorial_started(tutorial_id: String)
signal tutorial_finished(tutorial_id: String)
signal sequence_finished()

const TUTORIAL_SCENES := {
	"first_time": "res://nodes/tutorials/first_time.tscn",
	"how_to_play_move": "res://nodes/tutorials/how_to_play_move.tscn",
	"how_to_play_checking_wall": "res://nodes/tutorials/how_to_play_checking_wall.tscn",
	"how_to_play_minesweeper": "res://nodes/tutorials/how_to_play_minesweeper.tscn",
	"how_to_play_one_stroke": "res://nodes/tutorials/how_to_play_one_stroke.tscn",
	"how_to_play_sum_path": "res://nodes/tutorials/how_to_play_sum_path.tscn",
	"how_to_play_wall_builder": "res://nodes/tutorials/how_to_play_wall_builder.tscn",
}

const CORE_SEQUENCE := [
	"first_time",
	"how_to_play_move",
	"how_to_play_checking_wall"
]

## Yêu cầu đặc biệt từ Debug Console: chạy lại CHUỖI CORE thay vì 1 bài
const REQUEST_CORE := "__core__"

var active_tutorial_node: BaseTutorial = null
var current_tutorial_id: String = ""
var sequence_queue: Array[String] = []
var container_node: Control = null


func set_container(container: Control) -> void:
	container_node = container


func start_sequence(sequence: Array = []) -> void:
	sequence_queue.clear()
	if sequence.is_empty():
		for id in CORE_SEQUENCE:
			sequence_queue.append(id)
	else:
		for id in sequence:
			sequence_queue.append(str(id))

	_play_next_in_queue()


func play_single_tutorial(tutorial_id: String) -> void:
	sequence_queue.clear()
	sequence_queue.append(tutorial_id)
	_play_next_in_queue()


func _play_next_in_queue() -> void:
	if sequence_queue.is_empty():
		sequence_finished.emit()
		return

	var next_id: String = sequence_queue.pop_front()
	load_tutorial(next_id)


func load_tutorial(tutorial_id: String) -> BaseTutorial:
	if not TUTORIAL_SCENES.has(tutorial_id):
		push_warning("TutorialController: khong tim thay tutorial '%s'" % tutorial_id)
		return null

	if active_tutorial_node != null and is_instance_valid(active_tutorial_node):
		active_tutorial_node.queue_free()
		active_tutorial_node = null

	var scene_path: String = TUTORIAL_SCENES[tutorial_id]
	var scene_res := load(scene_path) as PackedScene
	if scene_res == null:
		push_error("TutorialController: khong load duoc scene '%s'" % scene_path)
		return null

	var inst := scene_res.instantiate() as BaseTutorial
	if inst == null:
		push_error("TutorialController: scene '%s' khong phai BaseTutorial" % scene_path)
		return null

	inst.tutorial_id = tutorial_id
	inst.tutorial_completed.connect(_on_tutorial_completed)
	inst.tutorial_skipped.connect(_on_tutorial_skipped)

	active_tutorial_node = inst
	current_tutorial_id = tutorial_id

	if container_node != null:
		container_node.add_child(inst)

	tutorial_started.emit(tutorial_id)
	return inst


func _on_tutorial_completed(tutorial_id: String) -> void:
	_save_progress(tutorial_id)
	tutorial_finished.emit(tutorial_id)

	if not sequence_queue.is_empty():
		_play_next_in_queue()
	else:
		sequence_finished.emit()


func _on_tutorial_skipped(tutorial_id: String, all: bool) -> void:
	if all:
		sequence_queue.clear()
		_save_core_completed()
		sequence_finished.emit()
	else:
		_save_progress(tutorial_id)
		tutorial_finished.emit(tutorial_id)
		if not sequence_queue.is_empty():
			_play_next_in_queue()
		else:
			sequence_finished.emit()


func _save_progress(tutorial_id: String) -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("set_tutorial_completed") and not _is_debug_run(gm):
		gm.call("set_tutorial_completed", tutorial_id, true)
	_flush_save()


## Ván TEST (Debug Console bật “Test mode”): KHÔNG ghi tiến trình tutorial
func _is_debug_run(gm: Node) -> bool:
	return bool(gm.get("debug_run"))


func _save_core_completed() -> void:
	var gm := _game_manager()
	if gm != null and gm.has_method("mark_core_tutorials_completed") and not _is_debug_run(gm):
		gm.call("mark_core_tutorials_completed")
	_flush_save()


func _game_manager() -> Node:
	if get_tree() != null and get_tree().root != null:
		return get_tree().root.get_node_or_null("GameManager")
	return null


func _flush_save() -> void:
	var sm := get_tree().root.get_node_or_null("SaveManager") if get_tree() != null and get_tree().root != null else null
	if sm != null and sm.has_method("save_now"):
		sm.call("save_now")
