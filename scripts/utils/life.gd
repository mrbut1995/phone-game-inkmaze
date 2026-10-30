class_name Life
extends RefCounted
## ============================================================================
## Facade tĩnh cho LƯỢT CHƠI (life) — đọc/ghi qua autoload GameManager.
##
## Vì sao không gọi thẳng `GameManager.lives_left()`?
##   Test runner chạy bằng `godot --script ...` -> identifier autoload không
##   resolve được lúc parse (giống Shop/Nav/Save/Popups).
##
## Quy tắc (xem Number_Maze_Game_Design.md §5.11):
##   · Tối đa 5 lượt, mỗi 30 phút hồi 1 lượt.
##   · Thua mà KHÔNG thử lại = mất 1 lượt; hết lượt thì không vào được ván nào.
## ============================================================================

const MAX := 5
const RECHARGE_SECONDS := 30 * 60


static func manager() -> Node:
	return Svc.game()


static func available() -> bool:
	var node := manager()
	return node != null and node.has_method("lives_left")


static func count() -> int:
	var node := manager()
	return int(node.call("lives_left")) if node != null and node.has_method("lives_left") else 0


static func max_count() -> int:
	var node := manager()
	return int(node.call("max_lives")) if node != null and node.has_method("max_lives") else MAX


static func has_life() -> bool:
	return count() > 0


static func is_full() -> bool:
	return count() >= max_count()


## Giây còn lại tới lượt kế tiếp (0 = đầy lượt)
static func seconds_to_next() -> int:
	var node := manager()
	if node == null or not node.has_method("seconds_to_next_life"):
		return 0
	return int(node.call("seconds_to_next_life"))


## 754 -> "12:34" (dùng cho chip + popup "hết lượt")
static func clock_text(seconds: int) -> String:
	var total := maxi(seconds, 0)
	return "%02d:%02d" % [total / 60, total % 60]


## "3/5" — nhãn trên LifeChip
static func chip_text() -> String:
	return "%d/%d" % [count(), max_count()]


## Cộng lượt từ nguồn hợp lệ: purchase · mission · daily_milestone
static func grant(amount: int, source: String) -> bool:
	var node := manager()
	if node == null or not node.has_method("grant_lives"):
		return false
	return bool(node.call("grant_lives", amount, source))
