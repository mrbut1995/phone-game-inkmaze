extends TestCase
## Tests for LifeStore (scripts/models/LifeStore.gd)

var _changes := 0


func _on_changed(_lives: int, _max_lives: int) -> void:
	_changes += 1


func test_starts_full() -> void:
	var store := LifeStore.new()
	assert_eq(store.max_lives(), 5)
	assert_eq(store.lives_left(), 5)
	assert_true(store.has_life())
	assert_eq(store.seconds_to_next_life(), 0, "đầy lượt thì không đếm ngược")


func test_consume_life_starts_recharge_timer() -> void:
	var store := LifeStore.new()
	store.changed.connect(_on_changed)
	assert_true(store.consume_life())
	assert_eq(store.lives_left(), 4)
	assert_eq(_changes, 1, "consume phát changed đúng 1 lần")
	var left := store.seconds_to_next_life()
	assert_true(left > 0 and left <= LifeStore.RECHARGE_SECONDS)


func test_consume_life_fails_when_empty() -> void:
	var store := LifeStore.new()
	store.set_lives(0)
	assert_false(store.has_life())
	assert_false(store.consume_life(), "hết lượt thì không trừ được nữa")


func test_charge_loss_once_only_charges_one_per_run() -> void:
	var store := LifeStore.new()
	assert_true(store.charge_loss_once())
	assert_eq(store.lives_left(), 4)
	assert_false(store.charge_loss_once(), "mở lại popup thua không trừ thêm lượt")
	assert_eq(store.lives_left(), 4)
	store.begin_run_guard()
	assert_true(store.charge_loss_once(), "ván mới (Thử lại) lại bị trừ khi thua")


func test_grant_lives_validates_source_and_cap() -> void:
	var store := LifeStore.new()
	assert_false(store.grant_lives(1, "purchase"), "đang đầy lượt thì không cộng được")
	store.set_lives(3)
	assert_false(store.grant_lives(1, "bogus"), "nguồn lạ bị từ chối")
	assert_false(store.grant_lives(0, "mission"), "cấp 0 lượt là vô nghĩa")
	assert_true(store.grant_lives(1, "purchase"))
	assert_eq(store.lives_left(), 4)
	assert_true(store.grant_lives(5, "mission"))
	assert_eq(store.lives_left(), 5, "cộng vượt trần bị kẹp về MAX_LIVES")
	assert_eq(store.seconds_to_next_life(), 0, "đầy lượt thì tắt đếm ngược")


func test_advance_recharge_grants_one_life_per_window() -> void:
	var store := LifeStore.new()
	store.set_lives(2)
	store.advance_recharge(LifeStore.RECHARGE_SECONDS)
	assert_eq(store.lives_left(), 3, "hết 30 phút thì hồi 1 lượt")
	assert_true(store.seconds_to_next_life() > 0, "vẫn còn nợ lượt kế tiếp")


func test_load_state_clamps_and_reset_restores_full() -> void:
	var store := LifeStore.new()
	store.load_state(2, 0)
	assert_eq(store.lives_left(), 2)
	assert_true(store.seconds_to_next_life() > 0, "thiếu lượt thì luôn có hẹn hồi")
	store.load_state(99, 0)
	assert_eq(store.lives_left(), 5, "save hỏng (vượt trần) bị kẹp")
	store.set_lives(1)
	store.reset()
	assert_eq(store.lives_left(), 5)
	assert_eq(store.seconds_to_next_life(), 0)
