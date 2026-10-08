class_name MazeCell
extends Control
## ============================================================================
## View: Một ô trên lưới (Control chứa TextureButton + Label số tường).
## Tự co giãn theo kích thước ô (không có khoảng cách): board.gd đặt `size` cho ô,
## art (mọi trạng thái) đều cùng khung 176x176 và TextureButton ở chế độ stretch
## nên co lại vẫn khớp nhau; số trên ô co theo qua set_font_size().
##
## MỌI tham số (node · texture · màu · tỉ lệ cỡ chữ) chỉnh TRONG `cell.tscn` —
## script chỉ `@export`, KHÔNG hard-code; binding node khai bằng `node_paths`.
## ============================================================================

@export var grid_pos: Vector2i = Vector2i.ZERO

@export var NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
@export var FOCUS_MODULATE := Color(0.85, 0.95, 1.0, 1.0)

## Số trên ô vẽ ĐÈ LÊN icon Bomb (nền mìn đậm) -> thêm viền màu giấy cho số để vẫn đọc được.
@export var BOMB_TEXT_OUTLINE_SIZE := 4
@export var BOMB_TEXT_OUTLINE_COLOR := Color(0.996078, 0.992157, 0.980392, 1.0)   # #FEFDFA

## Texture nền ô theo NỘI DUNG: thường / xuất phát S / đích F (gán trong `cell.tscn`)
@export var texture_normal: Texture2D = null
@export var texture_start: Texture2D = null
@export var texture_finish: Texture2D = null

## Mực phai (Fading Ink): tỉ lệ cỡ chữ phụ so với cỡ số trên ô (số gốc 56 -> 11 / 22)
@export var WARN_TEXT_RATIO := 11.0 / 56.0
@export var FADED_TEXT_RATIO := 22.0 / 56.0
## One Stroke: tỉ lệ cỡ chữ nhãn "ĐÃ ĐI" (số gốc 56 -> 12)
@export var VISITED_TEXT_RATIO := 12.0 / 56.0

## Node binding: khai `node_paths` + NodePath trong `cell.tscn`
@export var button: TextureButton = null
@export var label: Label = null
@export var bomb: TextureRect = null
@export var warn: TextureRect = null
@export var warn_label: Label = null
@export var faded: TextureRect = null
@export var faded_badge: TextureRect = null
@export var faded_label: Label = null
@export var visited: TextureRect = null
@export var visited_label: Label = null
@export var satisfied: TextureRect = null
## AnimationPlayer của chính `cell.tscn` — mọi hiệu ứng nảy/rung/nháy (entrance · pulse · step ·
## win · shudder · fail · pop_text) khai trong scene; code chỉ set pose ban đầu + gọi play.
@export var anim: AnimationPlayer = null
## Hẹn giờ SO LE khi ô bay vào / nảy mừng — Timer khai trong `cell.tscn` (dây `timeout` cũng ở đó);
## code chỉ đặt `wait_time` (dữ liệu so le do Board tính) rồi `start()`.
@export var entrance_timer: Timer = null
@export var win_timer: Timer = null


func _play_anim(anim_name: StringName) -> bool:
	if anim == null or not anim.has_animation(anim_name):
		return false
	anim.play(anim_name)
	return true


func set_text(text: String) -> void:
	if text == "S":
		if button != null:
			button.texture_normal = texture_start
		if label != null:
			label.text = ""
			label.visible = false
	elif text == "F":
		if button != null:
			button.texture_normal = texture_finish
		if label != null:
			label.text = ""
			label.visible = false
	else:
		if button != null:
			button.texture_normal = texture_normal
		if label != null:
			label.text = text
			label.visible = not text.is_empty()


## Cỡ chữ SỐ đang dùng trên ô (0 = scene chưa khai LabelSettings) — Board đọc giá trị này
## để suy cỡ chữ GỐC rồi co theo từng cỡ board, KHÔNG cần biết cấu trúc node con của ô.
func text_font_size() -> int:
	if label == null or label.label_settings == null:
		return 0
	return label.label_settings.font_size


## Đặt cỡ ô (Board tính theo số cột/hàng) — ô tự lo phần đi kèm cỡ: TÂM XOAY cho hiệu ứng
func set_cell_size(side: float) -> void:
	size = Vector2(side, side)
	pivot_offset = size * 0.5


## Hiệu ứng xuất hiện khi vào màn — Board gọi cho từng ô, `delay` theo (x + y)
func play_entrance(delay: float) -> void:
	pivot_offset = size * 0.5
	scale = Vector2(0.65, 0.65)
	modulate.a = 0.0
	if anim != null and anim.has_animation(&"entrance"):
		if delay > 0.0:
			if entrance_timer != null:
				entrance_timer.wait_time = delay
				entrance_timer.start()
			else:
				# Fallback khi scene thiếu EntranceTimer (dây thật khai trong cell.tscn)
				get_tree().create_timer(delay).timeout.connect(_play_entrance_now)
		else:
			_play_entrance_now()
		return
	# Fallback khi scene thiếu AnimationPlayer
	var tw := create_tween().set_parallel(true)
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_entrance_now() -> void:
	_play_anim(&"entrance")


func set_font_size(fs: int) -> void:
	_apply_label_font_size(label, fs)
	# Chữ phụ của lớp mực phai co theo cùng tỉ lệ với số trên ô
	_apply_label_font_size(warn_label, maxi(int(round(fs * WARN_TEXT_RATIO)), 8))
	_apply_label_font_size(faded_label, maxi(int(round(fs * FADED_TEXT_RATIO)), 10))
	# Nhãn "ĐÃ ĐI" của mode One Stroke co theo cùng tỉ lệ với số trên ô
	_apply_label_font_size(visited_label, maxi(int(round(fs * VISITED_TEXT_RATIO)), 9))


## Đổi cỡ chữ 1 Label — LƯU Ý: LabelSettings đè theme override nên phải sửa cả hai;
## các LabelSettings này dùng chung cho mọi ô -> phải duplicate trước khi đổi cỡ chữ.
func _apply_label_font_size(lbl: Label, fs: int) -> void:
	if lbl == null:
		return
	if lbl.label_settings != null and lbl.label_settings.font_size != fs:
		var settings := lbl.label_settings.duplicate() as LabelSettings
		settings.font_size = fs
		lbl.label_settings = settings
	lbl.add_theme_font_size_override("font_size", fs)


## Fading Ink: mực còn lại trên ô — 1 = SẮP PHAI (nền hổ phách + chữ cảnh báo, vẫn còn số),
## 0 = CẠN (lớp gạch ngang + huy hiệu CẠN), giá trị khác = ô bình thường.
## Gọi set_ink_left(-1) để tắt mọi lớp cảnh báo (dùng cho ô S/F).
func set_ink_left(ink: int) -> void:
	var warn_on := ink == 1
	var faded_on := ink == 0
	if warn != null:
		warn.visible = warn_on
	if warn_label != null:
		warn_label.visible = warn_on
	if faded != null:
		faded.visible = faded_on
	if faded_badge != null:
		faded_badge.visible = faded_on
	if faded_label != null:
		faded_label.visible = faded_on


func warn_visible() -> bool:
	return warn != null and warn.visible


## One Stroke: ô ĐÃ ĐI QUA (bị khoá vĩnh viễn, đi lại là thua) — tô mực xanh + gạch chéo
## + nhãn "ĐÃ ĐI" ở mép trên. Ô S/F không bao giờ bật lớp này (mockup giữ nguyên art S/F).
func set_visited_own(on: bool) -> void:
	if visited != null:
		visited.visible = on
	if visited_label != null:
		visited_label.visible = on
		if on:
			visited_label.text = tr("STR_OS_CELL_VISITED")


func visited_visible() -> bool:
	return visited != null and visited.visible


## Wall Builder: ô ĐÃ KHỚP SỐ (số tường quanh ô bằng đúng các đoạn đã nối) — nền xanh lá nhạt.
## Chỉ là gợi ý trực quan của chế độ, không ảnh hưởng luật.
func set_satisfied(on: bool) -> void:
	if satisfied != null:
		satisfied.visible = on


func satisfied_visible() -> bool:
	return satisfied != null and satisfied.visible


func visited_text() -> String:
	return visited_label.text if visited_label != null else ""


func faded_visible() -> bool:
	return faded != null and faded.visible


func warn_text() -> String:
	return warn_label.text if warn_label != null else ""


func faded_text() -> String:
	return faded_label.text if faded_label != null else ""


func get_text() -> String:
	return label.text if label != null else ""


func set_focused(active: bool) -> void:
	if button != null:
		button.modulate = FOCUS_MODULATE if active else NORMAL_MODULATE


## Hiện/ẩn biểu tượng Bomb đã nổ (Minesweeper) — icon to giữa ô, số trên ô vẽ ĐÈ LÊN icon.
func set_bomb(active: bool) -> void:
	if bomb != null:
		bomb.visible = active
	_apply_bomb_text_outline(active)


## Số nằm trên nền mìn đậm nên cần viền sáng; khi ẩn Bomb thì trả lại như cũ.
func _apply_bomb_text_outline(active: bool) -> void:
	if label == null or label.label_settings == null:
		return
	var settings := label.label_settings
	var has_outline := settings.outline_size > 0
	if active == has_outline:
		return
	# LabelSettings dùng chung cho mọi ô -> phải duplicate trước khi đổi
	settings = settings.duplicate() as LabelSettings
	settings.outline_size = BOMB_TEXT_OUTLINE_SIZE if active else 0
	settings.outline_color = BOMB_TEXT_OUTLINE_COLOR
	label.label_settings = settings


func has_bomb() -> bool:
	return bomb != null and bomb.visible


func pulse() -> void:
	pivot_offset = size * 0.5
	if _play_anim(&"pulse"):
		return
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Hiệu ứng rung lắc ô khi xảy ra va chạm nguy hiểm (nổ mìn, đâm gai)
func play_shudder() -> void:
	if _play_anim(&"shudder"):
		return
	if button == null:
		return
	# Fallback khi scene thiếu AnimationPlayer
	button.position = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(button, "position", Vector2(-6, 4), 0.035)
	tw.tween_property(button, "position", Vector2(6, -4), 0.035)
	tw.tween_property(button, "position", Vector2(-3, 2), 0.035)
	tw.tween_property(button, "position", Vector2.ZERO, 0.04)


## Hiệu ứng nảy số trên ô khi giá trị được cập nhật (Fading Ink / Sum Path)
func play_pop_text() -> void:
	if label == null or not label.visible:
		return
	label.pivot_offset = label.size * 0.5
	if _play_anim(&"pop_text"):
		return
	var tw := create_tween()
	tw.tween_property(label, "scale", Vector2(1.32, 1.32), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Hiệu ứng chúc mừng thắng màn / bài hướng dẫn: nảy nhẹ so le
func play_win(delay: float = 0.0) -> void:
	pivot_offset = size * 0.5
	if anim != null and anim.has_animation(&"win"):
		if delay > 0.0:
			if win_timer != null:
				win_timer.wait_time = delay
				win_timer.start()
			else:
				# Fallback khi scene thiếu WinTimer (dây thật khai trong cell.tscn)
				get_tree().create_timer(delay).timeout.connect(_play_win_now)
		else:
			_play_win_now()
		return
	var tw := create_tween()
	if delay > 0.0:
		tw.tween_interval(delay)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _play_win_now() -> void:
	_play_anim(&"win")


## Hiệu ứng khi được chọn / đi qua trong tutorial: nảy nhẹ + nháy sáng
func play_step() -> void:
	pivot_offset = size * 0.5
	if _play_anim(&"step"):
		return
	pulse()
	modulate = Color(1.18, 1.18, 1.12, 1.0)
	var flash := create_tween()
	flash.tween_property(self, "modulate", Color.WHITE, 0.3)


## Hiệu ứng khi thao tác sai: rung giật và nháy đỏ nhẹ
func play_fail() -> void:
	if _play_anim(&"fail"):
		return
	if button != null:
		# Fallback khi scene thiếu AnimationPlayer
		button.position = Vector2.ZERO
		var tw := create_tween()
		tw.tween_property(button, "position", Vector2(-6, 4), 0.035)
		tw.tween_property(button, "position", Vector2(6, -4), 0.035)
		tw.tween_property(button, "position", Vector2(-3, 2), 0.035)
		tw.tween_property(button, "position", Vector2.ZERO, 0.04)
	modulate = Color(1.0, 0.45, 0.42, 1.0)
	var fade := create_tween()
	fade.tween_property(self, "modulate", Color.WHITE, 0.35)
