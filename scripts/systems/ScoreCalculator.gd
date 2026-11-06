class_name ScoreCalculator
extends RefCounted
## ============================================================================
## Model / Service: Tính toán điểm thưởng và bước thưởng (Pure Business Logic).
## ============================================================================

const BASE_SCORE_PER_FLOOR := 50
const MOVE_BONUS_MULTIPLIER := 10
const TIME_BONUS_THRESHOLD_SEC := 240.0
const TIME_BONUS_MULTIPLIER := 2
const PERFECT_BONUS_SCORE := 100
const MIN_BONUS_STEPS := 4


## Tính toán chi tiết điểm số khi hoàn thành một floor / màn chơi.
static func calculate_floor_score(
	floor_number: int,
	steps_remaining: int,
	floor_elapsed: float,
	is_perfect_floor: bool
) -> Dictionary:
	var base_score := floor_number * BASE_SCORE_PER_FLOOR
	var move_bonus := steps_remaining * MOVE_BONUS_MULTIPLIER
	var time_bonus := int(maxf(0.0, TIME_BONUS_THRESHOLD_SEC - floor_elapsed)) * TIME_BONUS_MULTIPLIER
	var perfect_bonus := PERFECT_BONUS_SCORE if is_perfect_floor else 0
	var total_gained := base_score + move_bonus + time_bonus + perfect_bonus

	return {
		"base_score": base_score,
		"move_bonus": move_bonus,
		"time_bonus": time_bonus,
		"perfect_bonus": perfect_bonus,
		"total_gained": total_gained
	}


## Tính số bước thưởng cộng thêm cho floor tiếp theo.
static func calculate_bonus_steps(steps_remaining: int) -> int:
	return maxi(MIN_BONUS_STEPS, int(floor(steps_remaining * 0.5)) + 2)
