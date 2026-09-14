class_name GameState
extends RefCounted
## ============================================================================
## Model: Toàn bộ số liệu ván chơi hiện tại (thuần túy, in-memory).
## ============================================================================

var mode_id: String = "dungeon"
var floor_number: int = 1
var steps_remaining: int = 0
var max_steps: int = 0
var elapsed_time: float = 0.0   # tổng thời gian chơi (stopwatch)
var score: int = 0

var total_moves: int = 0        # tổng số bước đã dùng
var floor_moves: int = 0        # số bước dùng trong floor hiện tại
var floor_wall_hits: int = 0    # số lần đâm tường trong floor hiện tại
var perfect_floor: bool = true  # chưa đâm tường lần nào trong floor
var hints_used: int = 0         # số lần bấm Gợi ý trong floor hiện tại (cho thử thách)
var undos_used: int = 0         # số lần bấm Hoàn tác trong floor hiện tại (cho thử thách)


func begin_run(initial_steps: int, p_mode_id := "dungeon", start_floor := 1) -> void:
	mode_id = p_mode_id
	floor_number = maxi(start_floor, 1)
	steps_remaining = maxi(1, initial_steps)
	max_steps = steps_remaining
	elapsed_time = 0.0
	score = 0
	total_moves = 0
	_begin_floor()


func start_next_floor(bonus_steps: int) -> void:
	floor_number += 1
	steps_remaining += maxi(0, bonus_steps)
	max_steps = maxi(max_steps, steps_remaining)
	_begin_floor()


func restart_floor(initial_steps: int) -> void:
	steps_remaining = maxi(1, initial_steps)
	max_steps = steps_remaining
	_begin_floor()


func _begin_floor() -> void:
	floor_moves = 0
	floor_wall_hits = 0
	perfect_floor = true
	hints_used = 0
	undos_used = 0


func consume_step(amount: int = 1) -> void:
	var actual := maxi(0, amount)
	steps_remaining -= actual
	total_moves += 1
	floor_moves += 1


func refund_step(amount: int = 1) -> void:
	var actual := maxi(0, amount)
	steps_remaining += actual
	total_moves = maxi(0, total_moves - 1)
	floor_moves = maxi(0, floor_moves - 1)


func add_bonus_steps(n: int) -> void:
	steps_remaining += maxi(0, n)
	max_steps = maxi(max_steps, steps_remaining)


func add_score(n: int) -> void:
	score += maxi(0, n)


func record_wall_hit() -> void:
	floor_wall_hits += 1
	perfect_floor = false


func is_out_of_moves() -> bool:
	return steps_remaining <= 0
