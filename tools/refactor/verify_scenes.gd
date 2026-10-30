extends SceneTree
## Nạp + khởi tạo (instantiate) MỌI .tscn trong project rồi báo lỗi.
## Chạy:  godot --headless --path . --script res://tools/verify_scenes.gd
## Exit code 1 nếu có scene không nạp/instantiate được. Dùng sau mỗi phase refactor.

func _init() -> void:
	var failed: Array[String] = []
	var total := 0
	for path in _collect("res://"):
		total += 1
		var res := ResourceLoader.load(path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
		if res == null:
			failed.append("LOAD    " + path)
			continue
		var node: Node = (res as PackedScene).instantiate()
		if node == null:
			failed.append("INSTANT " + path)
			continue
		node.free()
	for f in failed:
		printerr(f)
	print("verify_scenes: %d scene, %d lỗi" % [total, failed.size()])
	quit(1 if failed.size() > 0 else 0)


func _collect(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for d in dir.get_directories():
		if d.begins_with(".") or d in ["addons", "tools_output"]:
			continue
		out.append_array(_collect(dir_path.path_join(d)))
	for f in dir.get_files():
		if f.ends_with(".tscn"):
			out.append(dir_path.path_join(f))
	return out
