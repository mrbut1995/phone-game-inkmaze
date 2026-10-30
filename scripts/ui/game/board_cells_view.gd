class_name BoardCellsView
extends RefCounted
## ============================================================================
## HIỂN THỊ TỪNG Ô của bàn cờ theo CHẾ ĐỘ CHƠI — tách khỏi `BoardView`.
##
## Chỉ đụng tới `MazeCell` (node con) + `BaseGameMode` (dữ liệu ô), không đụng input
## hay nét mực. `BoardView` truyền 2 Callable: tra node theo toạ độ (`cell_at`) và
## đồng bộ huy hiệu mìn (`sync_marker`) — nhờ vậy board giữ nguyên cách ánh xạ polyomino.
##
## Ai gọi: `BoardView.refresh_cell_texts()` · `BoardView.apply_fog_of_war()`.
## ============================================================================


## Cập nhật lại SỐ trên mọi ô theo chế độ (mode có giá trị đổi theo thời gian — Fading Ink).
## `dim_unwalkable` = ô không còn đi vào được thì mờ đi (hết mực thì coi như trống).
## Mode có `ink_left()`: thay vì mờ cả ô, ô hiện LỚP cảnh báo riêng (1 mực = nền hổ phách
## "SẮP PHAI" · 0 mực = lớp gạch + huy hiệu "CẠN") để phần huy hiệu không bị mờ theo ô.
static func refresh_texts(width: int, height: int, cell_at: Callable, maze: MazeData,
		mode: BaseGameMode, dim_unwalkable: bool, sync_marker: Callable) -> void:
	if maze == null or mode == null:
		return
	var has_ink := mode.shows_ink_left()
	# One Stroke: ô đã đi qua bị KHOÁ -> tô mực xanh + gạch chéo + nhãn "ĐÃ ĐI"
	var has_visited := mode.tracks_visited_cells()
	# Wall Builder: ô đã KHỚP SỐ (đủ tường quanh ô) -> nền xanh lá nhạt
	var has_satisfied := mode.tracks_satisfied_cells()
	for y in height:
		for x in width:
			var pos := Vector2i(x, y)
			var cell_node := cell_at.call(pos) as MazeCell
			if cell_node == null:
				continue
			cell_node.set_text(mode.get_cell_text(pos, maze))
			sync_marker.call(cell_node, pos)
			if has_ink:
				# Ô S/F không bao giờ cạn mực -> tắt lớp cảnh báo
				var ink := -1
				if pos != maze.get_start() and pos != maze.get_end():
					ink = mode.ink_left(pos)
				cell_node.set_ink_left(ink)
				cell_node.modulate = Color(1, 1, 1, 1)  # keep-code: màu theo dữ liệu (runtime)
			elif has_visited:
				# Ô S/F giữ nguyên art xuất phát/đích (mockup không gạch chéo 2 ô này)
				var seen := false
				if pos != maze.get_start() and pos != maze.get_end():
					seen = mode.is_cell_visited(pos)
				cell_node.set_visited_own(seen)
				cell_node.modulate = Color(1, 1, 1, 1)  # keep-code: màu theo dữ liệu (runtime)
			elif has_satisfied:
				cell_node.set_satisfied(mode.is_cell_satisfied(pos))
				cell_node.modulate = Color(1, 1, 1, 1)  # keep-code: màu theo dữ liệu (runtime)
			elif dim_unwalkable:
				var walkable := mode.is_walkable(pos)
				cell_node.modulate = Color(1, 1, 1, 1) if walkable else Color(1, 1, 1, 0.4)


## Fog of War: ô CHƯA khám phá thì mờ + xám; ô đã khám phá hiện số bình thường.
static func apply_fog(width: int, height: int, cell_at: Callable, maze: MazeData,
		mode: BaseGameMode, explored: Dictionary, sync_marker: Callable) -> void:
	if maze == null or mode == null:
		return
	for y in height:
		for x in width:
			var p := Vector2i(x, y)
			var cell_node := cell_at.call(p) as MazeCell
			if cell_node == null:
				continue      # ô ngoài board: không có số để làm mờ
			var text: String = mode.get_cell_text(p, maze)
			cell_node.set_text(text)
			sync_marker.call(cell_node, p)
			if explored.has(p):
				cell_node.modulate = Color(1, 1, 1, 1.0)  # keep-code: màu theo dữ liệu (runtime)
			else:
				cell_node.modulate = Color(0.6, 0.6, 0.6, 0.4)  # keep-code: màu theo dữ liệu (runtime)
