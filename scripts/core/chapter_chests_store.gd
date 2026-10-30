class_name ChapterChestsStore
extends RefCounted
## ============================================================================
## RƯƠNG MỐC THƯỞNG CỦA CHƯƠNG — trạng thái "đã nhận" + phần tính ngưỡng Sao.
##
## · 3 rương nằm trên thanh tiến độ ở màn Chọn chương, mốc theo TỈ LỆ Sao của chương
##   (33% · 67% · 100% ⇒ chương 27★ được 9★/18★/27★).
## · Mỗi rương nhận ĐÚNG MỘT LẦN cho mỗi chương (idempotent, không farm bằng chơi lại).
##
## Ai gọi: CHỈ `GameManager` — nó giữ phần TRAO THƯỞNG (Xu · công cụ · lượt chơi),
## phát signal `chapter_chest_claimed` và hẹn lưu.
## ============================================================================

const RATIOS: Array[float] = [0.33, 0.67, 1.0]
## Thưởng theo planning §2 (Xu · lượt công cụ · 1 lượt chơi ở rương cuối)
const REWARDS: Array[Dictionary] = [
	{"coins": 50},
	{"hint": 2, "undo": 1},
	{"coins": 150, "life": 1},
]

## chapter_id -> Array[int] các mốc (0..2) đã nhận
var claimed: Dictionary = {}


## 3 định nghĩa rương của một chương có `stars_total` Sao tối đa.
## Mỗi phần tử: `{ index, stars, coins, hint, undo, skip, life }` (`stars` = ngưỡng Sao cần).
func defs(stars_total: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var total := maxi(stars_total, 0)
	for i in REWARDS.size():
		var def: Dictionary = (REWARDS[i] as Dictionary).duplicate(true)
		def["index"] = i
		def["stars"] = threshold(RATIOS[i], total)
		out.append(def)
	return out


## Các mốc đã nhận của chương (bản sao — UI không sửa được dữ liệu gốc)
func claimed_of(chapter_id: int) -> Array[int]:
	var out: Array[int] = []
	var saved: Variant = claimed.get(chapter_id, null)
	if saved is Array:
		for item in saved:
			out.append(int(item))
	return out


func is_claimed(chapter_id: int, index: int) -> bool:
	return claimed_of(chapter_id).has(index)


## Đủ Sao + chưa nhận ⇒ nhận được rương này
func can_claim(chapter_id: int, index: int, stars_own: int, stars_total: int) -> bool:
	var list := defs(stars_total)
	if chapter_id < 1 or index < 0 or index >= list.size():
		return false
	if is_claimed(chapter_id, index):
		return false
	return stars_own >= int((list[index] as Dictionary).get("stars", 0))


## Đánh dấu đã nhận (gọi TRƯỚC khi trao thưởng để bấm liên tiếp không nhận 2 lần)
func mark_claimed(chapter_id: int, index: int) -> void:
	var list := claimed_of(chapter_id)
	list.append(index)
	claimed[chapter_id] = list


## Nạp từ blob tiến trình. JSON biến khoá số thành CHUỖI và phần tử thành float ⇒ ép kiểu lại.
func load_state(value: Variant) -> void:
	claimed.clear()
	if not (value is Dictionary):
		return
	for key in (value as Dictionary):
		var chapter_id := int(str(key))
		if chapter_id < 1:
			continue
		var saved: Variant = (value as Dictionary)[key]
		var indices: Array[int] = []
		if saved is Array:
			for item in saved:
				var index := int(item)
				if index >= 0 and not indices.has(index):
					indices.append(index)
		claimed[chapter_id] = indices


func reset() -> void:
	claimed.clear()


## Ngưỡng Sao của một mốc = `ratio × tổng Sao chương` (làm tròn), kẹp trong [1, tổng].
## Chương 27★: 33% → 9★ · 67% → 18★ · 100% → 27★ (đúng tinh thần mốc 10/20/30 của planning).
static func threshold(ratio: float, stars_total: int) -> int:
	if stars_total <= 0:
		return 0
	if ratio >= 1.0:
		return stars_total
	return clampi(roundi(stars_total * ratio), 1, stars_total)
