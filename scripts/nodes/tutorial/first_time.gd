class_name FirstTimeTutorial
extends BaseTutorial

## ============================================================================
## FirstTimeTutorial: Chào mừng người chơi mới (Planning.md §3.1)
## Không có bàn cờ mini thật — chỉ hoạt cảnh 3 ô S · ? · F + nét vẽ mẫu.
## Node (3 ô preview + Line2D) khai trong `nodes/tutorials/first_time.tscn`.
## ============================================================================

## 3 ô preview S — giữa — F (theo thứ tự trái → phải), bind trong .tscn
@export var preview_cells: Array[TutorialCell] = []
## Nét vẽ mẫu nối 3 ô (child của AnimContainer để toạ độ trùng tâm ô)
@export var preview_line: Line2D = null


func _init_tutorial() -> void:
	tutorial_id = "first_time"
	btn_skip_all.visible = true

	var steps: Array = [
		{
			"message_key": "STR_TUT_FIRST_TIME_01",
			"fallback_text": "Chào mừng bạn đến với Number Maze!",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FIRST_TIME_02",
			"fallback_text": "Vẽ một đường đi từ điểm BẮT ĐẦU (S) tới điểm KẾT THÚC (F).",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FIRST_TIME_03",
			"fallback_text": "Những con số trên mỗi ô sẽ giúp bạn đoán ra đâu là tường vô hình.",
			"advance_mode": "MANUAL",
		},
		{
			"message_key": "STR_TUT_FIRST_TIME_04",
			"fallback_text": "Trước khi chơi thật, hãy cùng luyện 3 kỹ năng cơ bản nhé!",
			"advance_mode": "MANUAL",
		}
	]
	setup_steps(steps)


func _on_step_entered(index: int, _data: Dictionary) -> void:
	match index:
		0:
			# Chỉ chào hỏi — xoá nét vẽ + con số ở ô giữa
			if preview_line != null:
				preview_line.clear_points()
			if preview_cells.size() >= 2:
				preview_cells[1].set_text("")
		1:
			# Hoạt cảnh vẽ nét S -> F
			if preview_line == null:
				return
			Sfx.play(Sfx.PATH_DRAW)
			preview_line.clear_points()
			var p0 := Vector2(85, 95)
			var p1 := Vector2(185, 95)
			var p2 := Vector2(285, 95)
			preview_line.add_point(p0)
			var tw := create_tween()
			tw.tween_method(func(p: Vector2) -> void:
				if preview_line.get_point_count() == 1:
					preview_line.add_point(p)
				elif preview_line.get_point_count() >= 2:
					preview_line.set_point_position(1, p)
			, p0, p1, 0.4)
			tw.tween_method(func(p: Vector2) -> void:
				if preview_line.get_point_count() == 2:
					preview_line.add_point(p)
				elif preview_line.get_point_count() >= 3:
					preview_line.set_point_position(2, p)
			, p1, p2, 0.4)
		2:
			# Con số hiện ra ở ô giữa (kèm nhún nhẹ)
			if preview_cells.size() >= 2:
				var mid := preview_cells[1]
				mid.set_text("2")
				mid.set_text_color(Color("#2C3E50"))
				mid.set_text_size(24)
				mid.play_step()
				Sfx.play(Sfx.CELL_STEP)
		3:
			# Sẵn sàng! Đổi chữ nút Tiếp tục thành "Bắt Đầu"
			Sfx.play(Sfx.CHECKBOX)
			btn_next.text = tr("STR_TUT_FIRST_TIME_START") if tr("STR_TUT_FIRST_TIME_START") != "STR_TUT_FIRST_TIME_START" else "Bắt Đầu"
