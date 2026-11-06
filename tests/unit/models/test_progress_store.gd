extends TestCase
## Tests for ProgressStore (scripts/models/ProgressStore.gd)


func test_total_stars_sums_every_level() -> void:
	var store := ProgressStore.new()
	store.level_stars = {1: 3, 2: 1, 3: 0}
	assert_eq(store.total_stars(), 4)


func test_record_clear_keeps_best_stars_and_best_time() -> void:
	var store := ProgressStore.new()
	store.record_clear(1, 2, 40.0)
	assert_eq(int(store.level_stars[1]), 2)
	assert_almost_eq(float(store.level_best_time[1]), 40.0)
	store.record_clear(1, 1, 55.0)
	assert_eq(int(store.level_stars[1]), 2, "Sao thấp hơn không ghi đè")
	assert_almost_eq(float(store.level_best_time[1]), 40.0, 0.001, "thời gian tệ hơn không ghi đè")
	store.record_clear(1, 3, 25.5)
	assert_eq(int(store.level_stars[1]), 3)
	assert_almost_eq(float(store.level_best_time[1]), 25.5)


func test_chapter_one_is_always_unlocked() -> void:
	var store := ProgressStore.new()
	assert_true(store.is_chapter_unlocked(1))
	assert_true(store.is_chapter_unlocked(0), "dữ liệu rác vẫn quy về chương 1")
	assert_false(store.is_chapter_unlocked(2), "chương 2 phải mở bằng Sao")


func test_set_chapter_never_below_one() -> void:
	var store := ProgressStore.new()
	store.set_chapter(4)
	assert_eq(store.current_chapter, 4)
	store.set_chapter(-3)
	assert_eq(store.current_chapter, 1)


func test_chapter_of_level_falls_back_to_chapter_one() -> void:
	var store := ProgressStore.new()
	assert_eq(store.chapter_of_level(0), 1)


func test_reset_restores_defaults() -> void:
	var store := ProgressStore.new()
	store.record_clear(1, 3, 10.0)
	store.set_chapter(3)
	store.reset()
	assert_eq(store.unlocked_levels, 1)
	assert_eq(store.total_stars(), 0)
	assert_eq(store.current_chapter, 1)
	assert_false(store.level_best_time.has(1))
