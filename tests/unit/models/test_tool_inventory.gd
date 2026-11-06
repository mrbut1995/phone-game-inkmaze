extends TestCase
## Tests for ToolInventory (scripts/models/ToolInventory.gd)

var _last_tool := ""
var _last_left := -1


func _on_changed(tool_id: String, remaining: int) -> void:
	_last_tool = tool_id
	_last_left = remaining


func test_starts_with_initial_uses_for_every_tool() -> void:
	var inv := ToolInventory.new()
	for tool_id in ToolInventory.IDS:
		assert_eq(inv.left(tool_id), ToolInventory.INITIAL_USES, tool_id)


func test_left_of_unknown_tool_is_zero() -> void:
	assert_eq(ToolInventory.new().left("bogus"), 0)


func test_consume_decrements_and_blocks_at_zero() -> void:
	var inv := ToolInventory.new()
	inv.changed.connect(_on_changed)
	assert_true(inv.consume("skip"))
	assert_eq(inv.left("skip"), 2)
	assert_eq(_last_tool, "skip")
	assert_eq(_last_left, 2, "changed phát số dư MỚI")
	inv.set_uses("skip", 0)
	assert_false(inv.consume("skip"), "hết lượt thì không dùng được")
	assert_eq(inv.left("skip"), 0)


func test_grant_requires_valid_source() -> void:
	var inv := ToolInventory.new()
	inv.set_uses("hint", 0)
	assert_false(inv.grant("hint", 1, "bogus"), "nguồn lạ bị từ chối")
	assert_false(inv.grant("hint", 0, "purchase"), "cấp 0 lượt là vô nghĩa")
	assert_false(inv.grant("bogus", 1, "purchase"))
	assert_true(inv.grant("hint", 2, "purchase"))
	assert_eq(inv.left("hint"), 2)


func test_set_uses_clamps_negative_to_zero() -> void:
	var inv := ToolInventory.new()
	inv.set_uses("teleport", -5)
	assert_eq(inv.left("teleport"), 0)


func test_load_state_migrates_legacy_undo_key() -> void:
	var inv := ToolInventory.new()
	inv.load_state({"undo": 4})
	assert_eq(inv.left("teleport"), 4, "save cũ dùng 'undo' phải chuyển sang 'teleport'")


func test_load_state_ignores_unknown_and_accepts_json_floats() -> void:
	var inv := ToolInventory.new()
	inv.load_state({"skip": 2.0, "bogus": 9})
	assert_eq(inv.left("skip"), 2)
	assert_eq(inv.left("bogus"), 0)
