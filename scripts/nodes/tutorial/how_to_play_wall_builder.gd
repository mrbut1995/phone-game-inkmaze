class_name HowToPlayWallBuilderTutorial
extends BaseTutorial

## ============================================================================
## HowToPlayWallBuilderTutorial: Chế độ Xây Tường (Planning.md §3.8)
## Bàn mini 2×2 có 2 đoạn tường NGANG bật/tắt được (component `TutorialWallToggle`).
## Người chơi bật đủ đoạn tường rồi bấm GỬI. Nút GỬI + 2 nút tường đều khai trong `.tscn`,
## dây tín hiệu cũng nằm trong `.tscn` ([connection]).
## ============================================================================

## 2 nút tường (bind trong .tscn, kèm `wall_id` cho từng nút)
@export var wall_toggles: Array[TutorialWallToggle] = []
## Nhãn "Đã vẽ: … / 2 đoạn" — bind trong .tscn
@export var lbl_hud_counter: Label = null

## Các đoạn tường đúng đáp án (2 đoạn ngang)
const WALL_TARGETS: Array[String] = ["0,1-1,1", "1,1-2,1"]
const CELL_SIZE := 92.0
const CELL_GAP := 10.0
const BOARD_ORIGIN := Vector2(110, 120)


func _init_tutorial() -> void:
	tutorial_id = "how_to_play_wall_builder"
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
			"spotlight_rect": Rect2(BOARD_ORIGIN, Vector2(CELL_SIZE, CELL_SIZE))
		},
		{
			"message_key": "STR_TUT_WB_03",
			"fallback_text": "Chạm vào các cặp điểm neo liền kề để bật đoạn tường.",
			"advance_mode": "MANUAL",
			"pointer_tap": BOARD_ORIGIN + Vector2(CELL_SIZE * 0.5, CELL_SIZE + CELL_GAP * 0.5)
		},
		{
			"message_key": "STR_TUT_WB_04",
			"fallback_text": "Khung đếm phía trên cho biết bạn cần vẽ bao nhiêu đoạn tường.",
			"advance_mode": "MANUAL",
			"spotlight_rect": Rect2(Vector2(110, 75), Vector2(CELL_SIZE * 2 + CELL_GAP, 36))
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


## Dây: [connection signal="wall_toggled" from="BoardHost/…/WallToggle1" to="." method="_on_wall_toggled"]
func _on_wall_toggled(_wall_id: String, _active: bool) -> void:
	_update_wall_counter()


## Dây: [connection signal="pressed" from="BoardHost/BtnSubmit" to="." method="_on_submit_pressed"]
func _on_submit_pressed() -> void:
	if current_step_index < 4:
		return

	# Kiểm tra xem có đúng 2 tường mục tiêu không
	var active := _active_wall_ids()
	var correct := active.size() == WALL_TARGETS.size()
	if correct:
		for key in WALL_TARGETS:
			if not active.has(key):
				correct = false
				break

	if correct:
		Sfx.play(Sfx.STAMP_IMPACT)
		play_cells_win()
		show_success_feedback("STR_TUT_WB_06", "Chính xác! Mọi con số đã khớp hết rồi.")
		show_step(5)
	else:
		show_fail_feedback("STR_TUT_WB_FAIL_01", "Chưa khớp hết — hãy kiểm tra lại các ô!")
		shake_node(board_host, 0.3, 10.0)
		flash_fail(lbl_hud_counter)


func _active_wall_ids() -> Array[String]:
	var ids: Array[String] = []
	for toggle in wall_toggles:
		if toggle != null and toggle.is_active():
			ids.append(toggle.wall_id)
	return ids


func _update_wall_counter() -> void:
	if lbl_hud_counter == null:
		return
	lbl_hud_counter.text = str(tr("STR_TUT_WB_COUNTER_FORMAT")).format([
		_active_wall_ids().size(), WALL_TARGETS.size()])
	UIAnim.play_pop_in(lbl_hud_counter, 0.0, 0.9, 0.22)
