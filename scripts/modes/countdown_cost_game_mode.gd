class_name CountdownCostGameMode
extends BaseGameMode
## ============================================================================
## Mode: Countdown Cost (số trên ô = CHI PHÍ BƯỚC, ĐỘC LẬP với tường).
## - Số ghi trên mỗi ô (trừ S/F) là **chi phí bước khi bước vào ô đó**.
##   Con số này KHÔNG liên quan tới số tường quanh ô (khác Play/Dungeon/Fog of War).
## - Chi phí sinh theo độ khó: easy 1..2 · medium 1..3 · hard 1..4 (mọi ô >= 1).
## - Bước vào ô nào thì trừ đúng chi phí của ô đó.
## - Đâm tường: về S và trừ chi phí của ô đích vừa đâm vào.
## - Ngân sách bước luôn >= chi phí của đường đi RẺ NHẤT + dự phòng theo độ khó
##   => luôn thắng được nếu chọn đúng đường ít tốn kém.
## ============================================================================

## Khoảng chi phí theo độ khó (x = min, y = max)
const COST_RANGE := {
	"easy": Vector2i(1, 2),
	"medium": Vector2i(1, 3),
	"hard": Vector2i(1, 4),
}

## Số bước dự phòng cộng thêm ngoài đường đi rẻ nhất
const BUDGET_SLACK := {
	"easy": 6,
	"medium": 4,
	"hard": 3,
}

## Ngân sách tối thiểu (không bao giờ thấp hơn mức này)
const BUDGET_FLOOR := {
	"easy": 12,
	"medium": 14,
	"hard": 15,
}

## Chi phí từng ô: Vector2i -> int (ô S/F không có chi phí)
var _costs: Dictionary = {}


func _init(p_difficulty := "medium") -> void:
	mode_id = "countdown_cost"
	mode_name = "Countdown Cost"
	mode_description = "Mỗi ô ghi một con số = chi phí bước khi bước vào ô đó (không liên quan tới tường). Chọn đường rẻ nhất để tới F!"
	is_endless = false
	instant_game_over_on_hazard = false
	difficulty = p_difficulty
	_apply_difficulty()


func _apply_difficulty() -> void:
	match difficulty:
		"easy":
			initial_steps = 12
		"hard":
			initial_steps = 15
		_:
			difficulty = "medium"
			initial_steps = 14


func setup_floor(_floor_number: int) -> MazeData:
	var size := 4
	var ratio := 0.35
	match difficulty:
		"easy":
			size = 3
			ratio = 0.5
		"hard":
			size = 5
			ratio = 0.2
		_:
			size = 4
			ratio = 0.35

	var maze := MazeData.new()
	maze.generate(size, size, ratio)
	_generate_costs(maze)
	_ensure_budget(maze)
	return maze


# --- Sinh chi phí cho từng ô (trừ S/F): con số KHÔNG liên quan tới tường ---
func _generate_costs(maze: MazeData) -> void:
	var cost_range: Vector2i = COST_RANGE.get(difficulty, Vector2i(1, 3))
	_costs.clear()
	for y in maze.height:
		for x in maze.width:
			var pos := Vector2i(x, y)
			if pos == maze.get_start() or pos == maze.get_end():
				continue
			_costs[pos] = randi_range(cost_range.x, cost_range.y)


# --- Bảo đảm ngân sách đủ cho đường đi rẻ nhất ---
func _ensure_budget(maze: MazeData) -> void:
	var cheapest := cheapest_path_cost(maze)
	var slack: int = BUDGET_SLACK.get(difficulty, 4)
	var floor_steps: int = BUDGET_FLOOR.get(difficulty, 14)
	initial_steps = maxi(floor_steps, cheapest + slack)


## Khoảng chi phí ô của độ khó hiện tại (HUD hiện chip "1-2: RẺ" / "3-4: ĐẮT")
func cost_range() -> Vector2i:
	return COST_RANGE.get(difficulty, Vector2i(1, 3))


## Số bước dự phòng cộng thêm ngoài đường đi rẻ nhất (HUD hiện "Dự phòng: +N bước")
func budget_reserve() -> int:
	return int(BUDGET_SLACK.get(difficulty, 4))


# --- Chi phí nhỏ nhất để đi từ S tới F (Dijkstra, trọng số = chi phí ô đích) ---
func cheapest_path_cost(maze: MazeData) -> int:
	if maze == null:
		return 0
	var start := maze.get_start()
	var end := maze.get_end()
	var dist: Dictionary = {start: 0}
	var pending: Array[Vector2i] = [start]

	while not pending.is_empty():
		# Mê cung nhỏ (<= 5x5) nên quét tuyến tính để lấy nút gần nhất là đủ
		var best_index := 0
		var best_dist: int = int(dist[pending[0]])
		for i in range(1, pending.size()):
			var candidate: int = int(dist[pending[i]])
			if candidate < best_dist:
				best_dist = candidate
				best_index = i
		var cur: Vector2i = pending.pop_at(best_index)
		if cur == end:
			return best_dist

		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var nxt := cur + step
			if not maze.is_in_bounds(nxt) or maze.has_wall(cur, nxt):
				continue
			var cost := best_dist + get_cell_cost(nxt)
			if not dist.has(nxt) or cost < int(dist[nxt]):
				dist[nxt] = cost
				pending.append(nxt)

	return int(dist.get(end, 0))


# --- API ---
## Chi phí bước khi bước vào ô `pos` (0 nếu là S/F hoặc ngoài lưới)
func get_cell_cost(pos: Vector2i) -> int:
	return int(_costs.get(pos, 0))


func get_cell_text(pos: Vector2i, maze: MazeData) -> String:
	if maze == null:
		return ""
	if pos == maze.get_start():
		return "S"
	if pos == maze.get_end():
		return "F"
	if not _costs.has(pos):
		return ""
	return str(get_cell_cost(pos))


func get_step_cost(_from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> int:
	if maze == null:
		return 1
	return get_cell_cost(to_pos)


func evaluate_move(from_pos: Vector2i, to_pos: Vector2i, maze: MazeData) -> Dictionary:
	var base_eval := super.evaluate_move(from_pos, to_pos, maze)
	if not base_eval.get("allowed", false):
		return base_eval

	if maze.has_wall(from_pos, to_pos):
		maze.reveal_wall(from_pos, to_pos)
		return {
			"allowed": false,
			"is_hazard": true,
			"hazard_type": "wall",
			"from": from_pos,
			"to": to_pos
		}

	return {
		"allowed": true,
		"is_hazard": false,
		"hazard_type": "none"
	}


func get_hud_extra_info() -> String:
	# Ngắn gọn như các mode khác: ngân sách bước đã có sẵn ở HUD (steps_left / steps_max)
	var cost_range: Vector2i = COST_RANGE.get(difficulty, Vector2i(1, 3))
	return "CHI PHÍ Ô: %d-%d BƯỚC" % [cost_range.x, cost_range.y]
