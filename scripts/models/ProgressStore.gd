class_name ProgressStore
extends RefCounted
## ============================================================================
## TIẾN TRÌNH MÀN/CHƯƠNG: Sao từng màn · thời gian tốt nhất · màn đã mở · chương đã mở.
##
## Tách khỏi `GameManager` (autoload) — đây là dữ liệu THUẦN, không phụ thuộc UI:
## chỉ đọc bảng chương/màn từ `LevelManager` (qua `Svc.level()`).
##
## Ai gọi: CHỈ `GameManager` (giữ property cùng tên để code cũ đọc/ghi như trước).
## ============================================================================

## Màn cao nhất đã mở (màn có id ≤ giá trị này mới chơi được)
var unlocked_levels: int = 1
## level_id -> stars (1-3)
var level_stars: Dictionary = { 1: 0 }
## level_id -> seconds (thời gian hoàn thành tốt nhất)
var level_best_time: Dictionary = {}
## Chương đã mở (chương 1 luôn mở)
var unlocked_chapters: Array[int] = [1]
## Chương đang xem ở màn Chọn màn
var current_chapter: int = 1


## Tổng Sao đã đạt trong TOÀN BỘ màn (dùng làm điều kiện mở khoá chương)
func total_stars() -> int:
	var total := 0
	for value in level_stars.values():
		total += int(value)
	return total


## Chương 1 luôn mở; các chương khác phải được mở bằng Sao
func is_chapter_unlocked(chapter_id: int) -> bool:
	if chapter_id <= 1:
		return true
	return unlocked_chapters.has(chapter_id)


## Số Sao cần để mở chương này (0 = không cần điều kiện)
func chapter_star_cost(chapter_id: int) -> int:
	var lm := Svc.level()
	if lm == null or not lm.has_method("get_chapter"):
		return 0
	var data: Variant = lm.call("get_chapter", chapter_id)
	return maxi(int(data.get("star_cost")) if data != null else 0, 0)


## Đủ Sao để mở chưa (chương đã mở cũng coi như đủ)
func can_unlock_chapter(chapter_id: int) -> bool:
	if is_chapter_unlocked(chapter_id):
		return true
	return total_stars() >= chapter_star_cost(chapter_id)


## Mở khoá chương bằng Sao — trả về true nếu VỪA mở
func unlock_chapter(chapter_id: int) -> bool:
	if is_chapter_unlocked(chapter_id) or not can_unlock_chapter(chapter_id):
		return false
	unlocked_chapters.append(chapter_id)
	# Điểm có CỔNG: mở khoá xong thì màn ĐẦU của chương phải SÁNG ngay, nếu không cả chương
	# vẫn hiện xám vì `unlocked_levels` còn dừng ở màn cuối chương trước.
	var lm := Svc.level()
	if lm != null and lm.has_method("levels_in_chapter"):
		var ids: Array[int] = []
		ids.assign(lm.call("levels_in_chapter", chapter_id))
		if not ids.is_empty():
			unlocked_levels = maxi(unlocked_levels, ids.min())
	return true


## Đổi chương đang xem ở màn Chọn màn
func set_chapter(chapter_id: int) -> void:
	current_chapter = maxi(chapter_id, 1)


## Chương chứa màn này (1 nếu không có LevelManager)
func chapter_of_level(level_id: int) -> int:
	var lm := Svc.level()
	if lm != null and lm.has_method("chapter_of_level"):
		return maxi(int(lm.call("chapter_of_level", level_id)), 1)
	return 1


## Màn kế tiếp TRONG CÙNG CHƯƠNG (-1 nếu đây là màn cuối của chương)
## Màn chọn màn / popup thắng dựa vào đây để KHÔNG nhảy sang chương khác.
func next_level_in_chapter(level_id: int) -> int:
	var lm := Svc.level()
	if lm == null or not lm.has_method("levels_in_chapter"):
		return level_id + 1 if level_id < 9 else -1
	var ids: Array = lm.call("levels_in_chapter", chapter_of_level(level_id))
	var index := ids.find(level_id)
	if index < 0 or index + 1 >= ids.size():
		return -1
	return int(ids[index + 1])


## Màn này có bấm chơi được ngay không: file tồn tại + chương đã MỞ + đã mở theo tiến trình
func can_play_level(level_id: int) -> bool:
	if level_id < 1 or not is_chapter_unlocked(chapter_of_level(level_id)):
		return false
	var lm := Svc.level()
	if lm != null and lm.has_method("has_level") and not bool(lm.call("has_level", level_id)):
		return false
	return level_id <= unlocked_levels


## Có chương nào ĐỦ Sao để mở mà chưa mở không (màn Chọn màn nhấp nháy banner báo tin)
func has_unlockable_chapter() -> bool:
	var lm := Svc.level()
	if lm == null or not lm.has_method("get_chapters"):
		return false
	for chapter in lm.call("get_chapters"):
		var chapter_id := maxi(int(chapter.get("chapter_id")), 1)
		if not is_chapter_unlocked(chapter_id) and can_unlock_chapter(chapter_id):
			return true
	return false


## Ghi nhận hoàn thành 1 màn: giữ Sao CAO NHẤT và thời gian TỐT NHẤT
func record_clear(level_id: int, stars: int, clear_time: float) -> void:
	var prev_stars: int = level_stars.get(level_id, 0)
	if stars > prev_stars:
		level_stars[level_id] = stars

	var prev_time: float = level_best_time.get(level_id, 999999.0)
	if clear_time < prev_time:
		level_best_time[level_id] = clear_time

	if level_id >= unlocked_levels:
		# Mở khoá màn kế tiếp nếu màn đó THẬT SỰ tồn tại VÀ thuộc chương ĐÃ MỞ
		# (tránh nhảy sang màn của chương chưa unlock khi màn cuối chương vừa hoàn thành)
		var next_id := level_id + 1
		var lm := Svc.level()
		var has_next := true
		if lm != null and lm.has_method("has_level"):
			has_next = bool(lm.call("has_level", next_id))
		else:
			has_next = next_id <= 9
		if has_next and is_chapter_unlocked(chapter_of_level(next_id)):
			unlocked_levels = maxi(unlocked_levels, next_id)


func reset() -> void:
	unlocked_levels = 1
	level_stars = { 1: 0 }
	level_best_time.clear()
	unlocked_chapters = [1]
	current_chapter = 1
