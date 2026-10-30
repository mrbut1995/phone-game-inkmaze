class_name ToolInventory
extends RefCounted
## ============================================================================
## KHO DỤNG CỤ (skip · undo · hint) — tách khỏi `GameManager` (autoload).
##
## Số lượt dùng là TÀI NGUYÊN TOÀN CỤC: không cấp lại theo màn/tầng, chỉ tăng khi
## mua ở Cửa hàng / thưởng nhiệm vụ / mốc thưởng Daily / rương mốc chương.
##
## Ai gọi: CHỈ `GameManager` (uỷ thác `tool_uses_left()` · `consume_tool_use()` ·
## `grant_tool_uses()` · `debug_set_tool_uses()`).
## ============================================================================

## Phát khi số dư của một công cụ đổi (GameManager nối để phát `tool_inventory_changed`)
signal changed(tool_id: String, remaining: int)

const SKIP := "skip"
const UNDO := "undo"
const HINT := "hint"
const IDS: Array[String] = [SKIP, UNDO, HINT]
const INITIAL_USES := 3
## Nguồn hợp lệ khi cấp lượt dùng: mua ở Shop · thưởng nhiệm vụ · thưởng mốc Sao Daily · rương chương
const GRANT_SOURCES: Array[String] = ["purchase", "mission", "daily_milestone", "chapter_chest"]

var uses: Dictionary = {
	SKIP: INITIAL_USES,
	UNDO: INITIAL_USES,
	HINT: INITIAL_USES,
}


## Số lượt dùng còn lại (0 khi id không hợp lệ)
func left(tool_id: String) -> int:
	if not IDS.has(tool_id):
		return 0
	return maxi(int(uses.get(tool_id, 0)), 0)


## Tiêu thụ một lượt dùng. Trả false khi công cụ không hợp lệ hoặc đã hết lượt.
func consume(tool_id: String) -> bool:
	if not IDS.has(tool_id) or left(tool_id) <= 0:
		return false
	uses[tool_id] = left(tool_id) - 1
	changed.emit(tool_id, left(tool_id))
	return true


## Cấp lượt từ nguồn mua hàng/nhiệm vụ/mốc thưởng Daily.
func grant(tool_id: String, amount: int, source: String) -> bool:
	if not IDS.has(tool_id) or amount <= 0 or not GRANT_SOURCES.has(source):
		return false
	return set_uses(tool_id, left(tool_id) + amount)


## Đặt lại số dư (Debug Console hoặc nạp save); giá trị được lưu như tiến trình người chơi.
func set_uses(tool_id: String, amount: int) -> bool:
	if not IDS.has(tool_id):
		push_warning("[ToolInventory] Cong cu khong hop le: '%s'" % tool_id)
		return false
	var remaining := maxi(amount, 0)
	if left(tool_id) == remaining:
		return true
	uses[tool_id] = remaining
	changed.emit(tool_id, remaining)
	return true


## Nạp từ blob tiến trình (JSON biến số thành float ⇒ ép int; bỏ id lạ)
func load_state(value: Variant) -> void:
	if not (value is Dictionary):
		return
	var saved: Dictionary = value
	for tool_id in IDS:
		if saved.has(tool_id):
			uses[tool_id] = maxi(int(saved[tool_id]), 0)
