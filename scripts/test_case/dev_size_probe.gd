extends SceneTree
## Dev: in ra KÍCH THƯỚC CANVAS thật (đơn vị logic của Godot) ở 10 tỉ lệ màn hình.
## Chạy: godot --path . --rendering-driver opengl3 --script res://scripts/test_case/dev_size_probe.gd
## (KHÔNG chạy headless — headless dùng display giả nên không đổi được cửa sổ)

const SIZES: Array[Vector2i] = [
	Vector2i(1080, 1920),  # 9:16  dọc cơ bản
	Vector2i(1080, 2160),  # 9:18
	Vector2i(1080, 2340),  # 9:19.5
	Vector2i(1080, 2520),  # 9:21
	Vector2i(1080, 1440),  # 3:4  (tablet thấp)
	Vector2i(1200, 1600),  # 3:4  (tablet cao)
	Vector2i(1600, 1200),  # 4:3  NGANG
	Vector2i(1920, 1080),  # 16:9 NGANG
	Vector2i(2160, 1080),  # 18:9 NGANG
	Vector2i(2340, 1080),  # 19.5:9 NGANG
]


func _init() -> void:
	await process_frame
	print("\n%-14s %-14s %-14s %-8s %-10s" % ["WINDOW", "CANVAS", "TỈ LỆ CANVAS", "SCALE", "HƯỚNG"])
	for s in SIZES:
		DisplayServer.window_set_size(s)
		for i in 4:
			await process_frame
		var canvas := root.get_visible_rect().size
		var scale := float(s.y) / maxf(canvas.y, 1.0)
		var orient := "NGANG" if canvas.x > canvas.y else "dọc"
		print("%-14s %-14s %-14s %-8.3f %-10s" % [
			"%dx%d" % [s.x, s.y],
			"%.0fx%.0f" % [canvas.x, canvas.y],
			"%.3f" % (canvas.x / maxf(canvas.y, 1.0)),
			scale, orient])
	quit(0)
