class_name AnchorController
extends RefCounted
## ============================================================================
## Controller: Quản lý logic nối các Anchor và trạng thái Tường Nghi Ngờ.
## Tuân thủ SRP: Tách biệt logic quản lý trạng thái Tường Nghi Ngờ ra khỏi View.
## ============================================================================

signal suspected_wall_toggled(is_h: bool, lattice: Vector2i, active: bool)

var _suspected_walls: Dictionary = {}  # "h,x,y" / "v,x,y" -> bool


func reset() -> void:
	_suspected_walls.clear()


## Xử lý thao tác kéo nối giữa 2 góc anchor.
## Trả về true nếu là cạnh hợp lệ (kề nhau 1 ô).
func handle_anchor_connection(corner_a: Vector2i, corner_b: Vector2i) -> bool:
	var edge := get_edge_between(corner_a, corner_b)
	if edge.is_empty():
		return false
	
	var is_h: bool = edge[0]
	var lattice: Vector2i = edge[1]
	var key := _lattice_key(is_h, lattice)
	var new_state: bool = not bool(_suspected_walls.get(key, false))
	_suspected_walls[key] = new_state
	
	suspected_wall_toggled.emit(is_h, lattice, new_state)
	return true


func set_suspected(is_h: bool, lattice: Vector2i, active: bool) -> void:
	var key := _lattice_key(is_h, lattice)
	_suspected_walls[key] = active
	suspected_wall_toggled.emit(is_h, lattice, active)


func is_suspected(is_h: bool, lattice: Vector2i) -> bool:
	return bool(_suspected_walls.get(_lattice_key(is_h, lattice), false))


static func get_edge_between(a: Vector2i, b: Vector2i) -> Array:
	if a == b:
		return []
	if a.x == b.x and absi(a.y - b.y) == 1:
		return [false, Vector2i(a.x, mini(a.y, b.y))]
	if a.y == b.y and absi(a.x - b.x) == 1:
		return [true, Vector2i(mini(a.x, b.x), a.y)]
	return []


static func _lattice_key(is_h: bool, lattice: Vector2i) -> String:
	return ("h,%d,%d" if is_h else "v,%d,%d") % [lattice.x, lattice.y]
