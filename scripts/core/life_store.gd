class_name LifeStore
extends RefCounted
## ============================================================================
## Sổ LƯỢT CHƠI (life) — tách khỏi `GameManager` (autoload) để mỗi file chỉ một việc.
##
## Quy tắc (Number_Maze_Game_Design.md §5.11):
##   · Tối đa 5 lượt, mỗi 30 phút hồi 1 lượt (kể cả lúc app đóng).
##   · Thua mà KHÔNG thử lại = mất 1 lượt; hết lượt thì không vào được ván nào.
##
## Ai gọi: CHỈ `GameManager` (uỷ thác toàn bộ API công khai `lives_left()` ·
## `consume_life()` · `grant_lives()` …). Không nơi nào khác giữ `LifeStore`.
## ============================================================================

## Phát mỗi khi số lượt ĐỔI (GameManager nối để phát `life_changed` + hẹn lưu)
signal changed(lives: int, max_lives: int)

const MAX_LIVES := 5
## Thời gian hồi 1 lượt (giây) — 30 phút
const RECHARGE_SECONDS := 30 * 60
## Nguồn hợp lệ khi cộng lượt (mua hàng · nhiệm vụ · mốc thưởng Daily · rương mốc chương)
const GRANT_SOURCES: Array[String] = ["purchase", "mission", "daily_milestone", "chapter_chest"]

var lives: int = MAX_LIVES
## Mốc unix (giây) lượt kế tiếp hồi xong; 0 = đang đầy lượt (không đếm ngược)
var next_life_at: int = 0
## [TEST/DEBUG] Ép kết quả `can_start_run()`: 0 = theo lượt · 1 = luôn cho vào · -1 = luôn chặn
var gate_override: int = 0
## [TEST] Cho phép trừ lượt khi chạy test runner tự động
var charge_in_tests := false

## Ván hiện tại đã bị trừ lượt chưa (chống trừ 2 lần khi popup thua mở lại)
var _loss_charged := false


func max_lives() -> int:
	return MAX_LIVES


## Số lượt còn lại (đã tính cả lượt vừa hồi theo thời gian)
func lives_left() -> int:
	refresh()
	return clampi(lives, 0, MAX_LIVES)


func has_life() -> bool:
	return lives_left() > 0


## Giây còn lại tới lượt kế tiếp (0 = đang đầy lượt)
func seconds_to_next_life() -> int:
	refresh()
	if lives >= MAX_LIVES or next_life_at <= 0:
		return 0
	return maxi(next_life_at - _now_seconds(), 0)


## Trừ 1 lượt khi THUA chốt ván. Trả về true nếu vừa trừ.
func consume_life() -> bool:
	if lives_left() <= 0:
		return false
	lives -= 1
	if lives < MAX_LIVES and next_life_at <= 0:
		next_life_at = _now_seconds() + RECHARGE_SECONDS
	changed.emit(lives, MAX_LIVES)
	return true


## Chốt MỘT lần thua cho mỗi ván (bên gọi đã tự loại ván Debug / test tự động).
func charge_loss_once() -> bool:
	if _loss_charged:
		return false
	_loss_charged = true
	return consume_life()


## Ván mới bắt đầu (kể cả bấm Thử lại) ⇒ ván sau lại được trừ lượt khi thua
func begin_run_guard() -> void:
	_loss_charged = false


## Cộng lượt từ nguồn hợp lệ. Trả về false khi nguồn không hợp lệ hoặc đã đầy lượt.
func grant_lives(amount: int, source: String) -> bool:
	if amount <= 0 or not GRANT_SOURCES.has(source):
		return false
	var before := lives_left()
	if before >= MAX_LIVES:
		return false
	lives = mini(before + amount, MAX_LIVES)
	if lives >= MAX_LIVES:
		next_life_at = 0
	changed.emit(lives, MAX_LIVES)
	return true


## Đặt thẳng số lượt (Debug Console)
func set_lives(amount: int) -> void:
	var target := clampi(amount, 0, MAX_LIVES)
	if target == lives:
		return
	lives = target
	if lives >= MAX_LIVES:
		next_life_at = 0
	elif next_life_at <= 0:
		next_life_at = _now_seconds() + RECHARGE_SECONDS
	changed.emit(lives, MAX_LIVES)


## [DEBUG] Đẩy nhanh đồng hồ hồi lượt (giây)
func advance_recharge(seconds: int) -> void:
	if seconds <= 0 or lives >= MAX_LIVES:
		return
	var now := _now_seconds()
	if next_life_at <= 0:
		next_life_at = now + RECHARGE_SECONDS
	next_life_at = maxi(next_life_at - seconds, now)
	refresh()


## Bắt kịp các lượt đã hồi theo đồng hồ thực: mỗi 30 phút +1 lượt.
func refresh() -> void:
	if lives >= MAX_LIVES:
		if next_life_at != 0:
			next_life_at = 0
		return
	if next_life_at <= 0:
		next_life_at = _now_seconds() + RECHARGE_SECONDS
		return
	var now := _now_seconds()
	var gained := 0
	while lives < MAX_LIVES and now >= next_life_at:
		lives += 1
		gained += 1
		next_life_at += RECHARGE_SECONDS
	if lives >= MAX_LIVES:
		next_life_at = 0
	if gained > 0:
		changed.emit(lives, MAX_LIVES)


## Nạp từ blob tiến trình (KHÔNG phát `changed` để bên gọi tự quyết định)
func load_state(saved_lives: Variant, saved_next_at: Variant) -> void:
	lives = clampi(int(saved_lives), 0, MAX_LIVES)
	next_life_at = maxi(int(saved_next_at), 0)
	refresh()


func reset() -> void:
	lives = MAX_LIVES
	next_life_at = 0
	_loss_charged = false


func _now_seconds() -> int:
	return int(Time.get_unix_time_from_system())
