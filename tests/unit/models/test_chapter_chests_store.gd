extends TestCase
## Tests for ChapterChestsStore (scripts/models/ChapterChestsStore.gd)


func test_threshold_percent_of_total_stars() -> void:
	assert_eq(ChapterChestsStore.threshold(0.33, 27), 9)
	assert_eq(ChapterChestsStore.threshold(0.67, 27), 18)
	assert_eq(ChapterChestsStore.threshold(1.0, 27), 27)


func test_threshold_clamps_to_valid_range() -> void:
	assert_eq(ChapterChestsStore.threshold(0.33, 0), 0, "chương chưa có Sao thì không có ngưỡng")
	assert_eq(ChapterChestsStore.threshold(0.33, 1), 1, "ngưỡng nhỏ nhất là 1 Sao")
	assert_eq(ChapterChestsStore.threshold(2.0, 10), 10, "tỉ lệ > 1 bị kẹp về tổng Sao")


func test_defs_has_three_chests_with_index_and_reward() -> void:
	var defs := ChapterChestsStore.new().defs(30)
	assert_eq(defs.size(), 3)
	assert_eq(int(defs[0]["index"]), 0)
	assert_eq(int(defs[2]["index"]), 2)
	assert_eq(int(defs[0]["stars"]), 10)
	assert_eq(int(defs[2]["stars"]), 30)
	assert_eq(int(defs[2]["coins"]), 150)
	assert_eq(int(defs[2]["life"]), 1)


func test_can_claim_requires_enough_stars() -> void:
	var store := ChapterChestsStore.new()
	assert_false(store.can_claim(1, 0, 8, 27), "8 Sao chưa đủ mốc 9")
	assert_true(store.can_claim(1, 0, 9, 27), "đúng mốc thì nhận được")
	assert_false(store.can_claim(0, 0, 27, 27), "chapter_id < 1 là không hợp lệ")
	assert_false(store.can_claim(1, 3, 27, 27), "chỉ có 3 rương (index 0..2)")


func test_mark_claimed_blocks_second_claim() -> void:
	var store := ChapterChestsStore.new()
	store.mark_claimed(2, 1)
	assert_true(store.is_claimed(2, 1))
	assert_false(store.can_claim(2, 1, 27, 27), "đã nhận rồi thì không nhận lại")
	assert_eq(store.claimed_of(2).size(), 1)


func test_claimed_of_returns_copy() -> void:
	var store := ChapterChestsStore.new()
	store.mark_claimed(1, 0)
	var copy := store.claimed_of(1)
	copy.append(2)
	assert_false(store.is_claimed(1, 2), "sửa bản sao không được đổi dữ liệu gốc")


func test_load_state_coerces_json_types() -> void:
	var store := ChapterChestsStore.new()
	store.load_state({"1": [0.0, 2.0], "0": [1], "x": [1]})
	assert_true(store.is_claimed(1, 0), "khoá/phần tử do JSON sinh ra là chuỗi/float")
	assert_true(store.is_claimed(1, 2))
	assert_eq(store.claimed_of(1).size(), 2)
	assert_eq(store.claimed_of(0).size(), 0, "chapter_id < 1 bị bỏ")


func test_load_state_ignores_garbage_and_reset_clears() -> void:
	var store := ChapterChestsStore.new()
	store.mark_claimed(3, 0)
	store.load_state("hỏng")
	assert_eq(store.claimed_of(3).size(), 0)
	store.mark_claimed(1, 1)
	store.reset()
	assert_eq(store.claimed_of(1).size(), 0)
