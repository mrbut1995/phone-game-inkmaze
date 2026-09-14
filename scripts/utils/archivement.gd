class_name Archivement
extends RefCounted
## ============================================================================
## Helper tĩnh: truy cập ArchivementManager (autoload) qua /root.
##
## Lý do tồn tại: test runner chạy bằng `godot --script ...` không resolve được
## identifier autoload lúc parse, nên script khác KHÔNG được tham chiếu thẳng
## `ArchivementManager`. Ở đây lấy node động qua /root/ArchivementManager.
## ============================================================================


static func manager() -> Node:
	var tree := _tree()
	if tree != null and tree.root != null:
		return tree.root.get_node_or_null("ArchivementManager")
	return null


## Danh sách danh hiệu đã tính sẵn trạng thái (rỗng = tất cả)
static func entries(category := "") -> Array:
	var m := manager()
	if m == null or not m.has_method("entries"):
		return []
	return m.call("entries", category)


static func claim(id: String) -> bool:
	var m := manager()
	if m == null or not m.has_method("claim"):
		return false
	return bool(m.call("claim", id))


static func refresh() -> void:
	var m := manager()
	if m != null and m.has_method("refresh"):
		m.call("refresh")


static func points() -> int:
	var m := manager()
	return int(m.call("points")) if m != null and m.has_method("points") else 0


static func coins() -> int:
	var m := manager()
	return int(m.get("coins")) if m != null else 0


static func unlocked_count() -> int:
	var m := manager()
	return int(m.call("unlocked_count")) if m != null and m.has_method("unlocked_count") else 0


static func total_count() -> int:
	var m := manager()
	return int(m.call("total_count")) if m != null and m.has_method("total_count") else 0


static func claimed_count() -> int:
	var m := manager()
	return int(m.call("claimed_count")) if m != null and m.has_method("claimed_count") else 0


static func claimable_count() -> int:
	var m := manager()
	return int(m.call("claimable_count")) if m != null and m.has_method("claimable_count") else 0


static func unlocked_percent() -> int:
	var m := manager()
	return int(m.call("unlocked_percent")) if m != null and m.has_method("unlocked_percent") else 0


static func count_in_category(category: String) -> int:
	var m := manager()
	if m == null or not m.has_method("count_in_category"):
		return 0
	return int(m.call("count_in_category", category))


## Game báo kết quả 1 màn/tầng (xem ArchivementManager.notify_run_result)
static func notify_run_result(results: Dictionary) -> void:
	var m := manager()
	if m != null and m.has_method("notify_run_result"):
		m.call("notify_run_result", results)


static func _tree() -> SceneTree:
	var main_loop := Engine.get_main_loop()
	return main_loop as SceneTree if main_loop is SceneTree else null
