extends SceneTree
## DEV SMOKE: instantiate MỌI scene trong `scenes/` + `nodes/`, chạy vài frame rồi FREE —
## in marker `@@@ SCENE <path>` / `@@@ SCENE RESULT <path> :: ...` để bên ngoài (Python/PowerShell)
## gom lỗi (SCRIPT ERROR…) theo từng scene và biết scene nào crash/lỗi.
##
## Chạy:
##   godot --headless --path . --script res://scripts/test_case/dev_scene_smoke.gd
##   godot --headless --path . --script res://scripts/test_case/dev_scene_smoke.gd -- tutorial
##     (tham số sau `--` là BỘ LỌC CHUỖI ĐƯỜNG DẪN — chỉ chạy scene khớp)

const ROOTS := ["res://scenes", "res://nodes"]
const FRAMES_ALIVE := 6
const FRAMES_AFTER_FREE := 2

var _filters: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_filters.assign(OS.get_cmdline_user_args())
	var scenes: Array[String] = []
	for root_dir in ROOTS:
		_collect(root_dir, scenes)
	scenes.sort()
	var picked: Array[String] = []
	for path in scenes:
		if _filters.is_empty() or _matches(path):
			picked.append(path)
	print("@@@ SMOKE START: %d scene" % picked.size())
	var ok := 0
	var fails: Array[String] = []
	for path in picked:
		var result := await _check_scene(path)
		if result.is_empty():
			ok += 1
		else:
			fails.append("%s -> %s" % [path, result])
	print("@@@ SMOKE DONE: %d/%d OK" % [ok, picked.size()])
	for fail in fails:
		print("@@@ SMOKE FAIL: %s" % fail)
	quit(0)


func _matches(path: String) -> bool:
	for f in _filters:
		if path.contains(f):
			return true
	return false


func _collect(folder: String, out: Array[String]) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(folder.path_join(sub), out)
	for file in dir.get_files():
		if file.get_extension() == "tscn":
			out.append(folder.path_join(file))


func _frames(n: int) -> void:
	for _i in n:
		await process_frame


func _check_scene(path: String) -> String:
	print("@@@ SCENE %s" % path)
	var ps := ResourceLoader.load(path) as PackedScene
	if ps == null:
		print("@@@ SCENE RESULT %s :: LOAD_FAIL" % path)
		await process_frame
		return "LOAD_FAIL"
	var node: Node = ps.instantiate()
	var err := ""
	if node == null:
		err = "INSTANTIATE_NULL"
	else:
		root.add_child(node)
		current_scene = node
		await _frames(FRAMES_ALIVE)
		current_scene = null
		node.queue_free()
		await _frames(FRAMES_AFTER_FREE)
	print("@@@ SCENE RESULT %s :: %s" % [path, "OK" if err.is_empty() else err])
	return err
