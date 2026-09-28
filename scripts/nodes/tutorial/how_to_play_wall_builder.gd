class_name HowToPlayWallBuilderTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayWallBuilderTutorial: Chế độ Xây Tường (Planning.md §3.8)
## Dùng BoardTutorial: bàn 2×2, 2 đoạn tường NGANG cần được neo bởi anchor.
## Người chơi kéo neo để bật tường, rồi bấm GỬI BÀI.
## ============================================================================

@export var board_tutorial: BoardTutorial = null
@export var lbl_hud_counter: Label = null
@export var btn_submit: Button = null

const WALL_TARGETS: Array[String] = []
const TARGET_COUNT := 2

var _built_count: int = 0


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_wall_builder"
	if board_tutorial != null:
		# Bàn 2×2 không có S/F, số trên ô = số tường cần dựng quanh nó
		board_tutorial.setup_tutorial(
			2, 2,
			{
				Vector2i(0, 0): "1",
				Vector2i(1, 0): "1",
				Vector2i(0, 1): "1",
				Vector2i(1, 1): "1"
			},
			[],
			false,    # không hiển thị cursor (Wall Builder không đi)
			Vector2i(0, 0),
			Vector2i(1, 1),
			true      # bật anchors
		)
		board_tutorial.wall_toggled.connect(_on_wall_toggled)
	_update_wall_counter()

	var steps: Array = [
		{
			"message_key": "STR_TUT_WB_01",
			"fallback_text": "Chế độ này không di chuyển — bạn sẽ TỰ VẼ TƯỜNG để khớp với các con số.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_02",
			"fallback_text": "Mỗi con số là số tường cần có quanh ô đó — từ 0 tới 4.",
			"advance_mode": "MANUAL",
			"spotlight_cell": Vector2i(0, 0)
		},
		{
			"message_key": "STR_TUT_WB_03",
			"fallback_text": "Chạm vào các cặp điểm neo liền kề để bật đoạn tường.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_04",
			"fallback_text": "Khung đếm phía trên cho biết bạn cần vẽ bao nhiêu đoạn tường.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_WB_05",
			"fallback_text": "Hãy bật đủ 2 đoạn tường ngang rồi bấm GỬI nhé!",
			"advance_mode": "AUTO",
			"required_action": "SUBMIT"
		},
		{
			"message_key": "STR_TUT_WB_06",
			"fallback_text": "Chính xác! Mọi con số đã khớp hết rồi.",
			"advance_mode": "MANUAL",
		}
	]
	setup_steps(steps)


func _on_wall_toggled(_wall_key: String, _active: bool) -> void:
	if board_tutorial == null:
		return
	_built_count = board_tutorial.get_built_wall_keys().size()
	_update_wall_counter()


func _update_wall_counter() -> void:
	if lbl_hud_counter == null:
		return
	var fmt := str(tr("STR_TUT_WB_COUNTER_FORMAT"))
	if fmt == "STR_TUT_WB_COUNTER_FORMAT":
		fmt = "Đã vẽ: {0} / {1} đoạn"
	lbl_hud_counter.text = fmt.format([_built_count, TARGET_COUNT])
	UIAnim.play_pop_in(lbl_hud_counter, 0.0, 0.9, 0.22)


func _on_submit_pressed() -> void:
	if current_step_index < 4:
		return
	if board_tutorial == null:
		return

	if _built_count == TARGET_COUNT:
		Sfx.play(Sfx.STAMP_IMPACT)
		play_cells_win()
		show_success_feedback("STR_TUT_WB_06", "Chính xác! Mọi con số đã khớp hết rồi.")
		show_step(5)
	else:
		show_fail_feedback("STR_TUT_WB_FAIL_01", "Chưa khớp hết — hãy kiểm tra lại các ô!")
		shake_node(board_tutorial, 0.3, 10.0)
		flash_fail(lbl_hud_counter)
