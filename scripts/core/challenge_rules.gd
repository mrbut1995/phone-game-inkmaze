class_name ChallengeRules
extends RefCounted
## ============================================================================
## LUẬT CỦA CHẾ ĐỘ THỬ THÁCH (Challenge Mode) — tách khỏi `GameController`.
##
## 8 luật nằm trong `ChallengeGameMode`; file này chỉ SOI vi phạm và trả về id luật
## (chuỗi rỗng = không vi phạm). `GameController` quyết định khi nào soi + mở popup thua.
##
## Luật có ĐỒNG HỒ: đếm ngược tổng · "mỗi bước trong X giây".
## KHÔNG dùng `TimerController.is_countdown` (đổi nghĩa `floor_elapsed`, phá Nhiệm vụ) —
## chỉ so `floor_elapsed` với hạn mức trong lúc đồng hồ vẫn chạy bình thường.
##
## Luật theo NƯỚC ĐI: vượt số bước · đi lại trên đường đã đi · quay đầu quá số lượt.
## Ai gọi: CHỈ `GameController`.
## ============================================================================

## Mốc thời gian (giây, `TimerController.floor_elapsed`) của bước vừa rồi
var step_start := 0.0
## Số lần QUAY ĐẦU đã đếm trong màn (luật BACKTRACK_LIMIT)
var backtracks := 0


## Màn mới / ván mới: cấp lại đồng hồ con "mỗi bước" + lượt quay đầu
func reset() -> void:
	step_start = 0.0
	backtracks = 0


## Bắt đầu tính hạn mức "mỗi bước trong X giây" từ mốc `elapsed`
func begin_step(elapsed: float) -> void:
	step_start = elapsed


## Soi 2 luật có ĐỒNG HỒ mỗi khung hình. Trả về id luật bị vi phạm ("" = ổn).
func tick(ch: ChallengeGameMode, elapsed: float) -> String:
	if ch == null:
		return ""
	if ch.challenge_id == ChallengeGameMode.COUNTDOWN and elapsed >= float(ch.challenge_param):
		return ch.challenge_id
	if ch.challenge_id == ChallengeGameMode.STEP_TIMER \
			and elapsed - step_start >= float(ch.challenge_param):
		return ch.challenge_id
	return ""


## Soi 3 luật theo NƯỚC ĐI (gọi ngay sau khi bước thành công — `path` đã có vị trí mới).
func after_step(ch: ChallengeGameMode, path: Array[Vector2i], moves: int) -> String:
	if ch == null:
		return ""
	match ch.challenge_id:
		ChallengeGameMode.MOVE_LIMIT:
			if moves > ch.challenge_param:
				return ch.challenge_id
		ChallengeGameMode.NO_MOVE_OVERLAPPED:
			if not path.is_empty() and path.count(path[path.size() - 1]) > 1:
				return ch.challenge_id
		ChallengeGameMode.BACKTRACK_LIMIT:
			if path.size() >= 3 and path[path.size() - 1] == path[path.size() - 3]:
				backtracks += 1
				if backtracks > ch.challenge_param:
					return ch.challenge_id
	return ""


## Dữ liệu khối THỜI GIAN cho ChallengeHUD (rỗng nếu ván này không có thử thách)
func hud_state(ch: ChallengeGameMode, elapsed: float, moves: int) -> Dictionary:
	if ch == null:
		return {}
	return ch.hud_state(
		float(ch.challenge_param) - elapsed,
		moves,
		float(ch.challenge_param) - (elapsed - step_start),
		ch.challenge_param - backtracks
	)
