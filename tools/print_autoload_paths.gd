extends SceneTree
## In ra đường dẫn thật của các autoload dùng uid:// (để tạo Svc chính xác).

func _initialize() -> void:
	for line in FileAccess.get_file_as_string("res://project.godot").split("\n"):
		var t := line.strip_edges()
		if not t.contains("uid://"):
			continue
		var parts := t.split("=")
		if parts.size() != 2:
			continue
		var uid_text := parts[1].strip_edges().trim_prefix("*").trim_prefix("\"").trim_suffix("\"")
		var id := ResourceUID.text_to_id(uid_text)
		print("%-24s %-10s %s" % [parts[0], uid_text, ResourceUID.get_id_path(id)])
	quit()
