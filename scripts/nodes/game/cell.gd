class_name MazeCell
extends Control
## ============================================================================
## View: Một ô trên lưới (Control chứa TextureButton + Label số tường).
## Tự co giãn theo kích thước ô (không có khoảng cách): board.gd đặt `size` cho ô,
## art (mọi trạng thái) đều cùng khung 176x176 và TextureButton ở chế độ stretch
## nên co lại vẫn khớp nhau; số trên ô co theo qua set_font_size().
## ============================================================================

@export var grid_pos: Vector2i = Vector2i.ZERO

@export var NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
@export var FOCUS_MODULATE := Color(0.85, 0.95, 1.0, 1.0)

## Số trên ô vẽ ĐÈ LÊN icon Bomb (nền mìn đậm) -> thêm viền màu giấy cho số để vẫn đọc được.
@export var BOMB_TEXT_OUTLINE_SIZE := 4
@export var BOMB_TEXT_OUTLINE_COLOR := Color(0.996078, 0.992157, 0.980392, 1.0)   # #FEFDFA

const TEX_NORMAL := preload("res://assets/images-png/game/cell_normal.png")
const TEX_START := preload("res://assets/images-png/game/cell_start.png")
const TEX_FINISH := preload("res://assets/images-png/game/cell_finish.png")

## Mực phai (Fading Ink): tỉ lệ cỡ chữ phụ so với cỡ số trên ô (số gốc 56 -> 11 / 22)
@export var WARN_TEXT_RATIO := 11.0 / 56.0
@export var FADED_TEXT_RATIO := 22.0 / 56.0
## One Stroke: tỉ lệ cỡ chữ nhãn "ĐÃ ĐI" (số gốc 56 -> 12)
@export var VISITED_TEXT_RATIO := 12.0 / 56.0

@onready var _button: TextureButton = $Sprite
@onready var _label: Label = $Sprite/Label
@onready var _bomb: TextureRect = $Sprite/Bomb
@onready var _warn: TextureRect = get_node_or_null("Sprite/Warn")
@onready var _warn_label: Label = get_node_or_null("Sprite/WarnLabel")
@onready var _faded: TextureRect = get_node_or_null("Sprite/Faded")
@onready var _faded_badge: TextureRect = get_node_or_null("Sprite/FadedBadge")
@onready var _faded_label: Label = get_node_or_null("Sprite/FadedLabel")
@onready var _visited: TextureRect = get_node_or_null("Sprite/Visited")
@onready var _visited_label: Label = get_node_or_null("Sprite/VisitedLabel")
@onready var _satisfied: TextureRect = get_node_or_null("Sprite/Satisfied")
## AnimationPlayer của chính `cell.tscn` — mọi hiệu ứng nảy/rung/nháy (entrance · pulse · step ·
## win · shudder · fail · pop_text) khai trong scene; code chỉ set pose ban đầu + gọi play.
@onready var _anim: AnimationPlayer = get_node_or_null("AnimationPlayer")
## Hẹn giờ SO LE khi ô bay vào / nảy mừng — Timer khai trong `cell.tscn` (dây `timeout` cũng ở đó);
## code chỉ đặt `wait_time` (dữ liệu so le do Board tính) rồi `start()`.
@onready var _entrance_timer: Timer = get_node_or_null("EntranceTimer")
@onready var _win_timer: Timer = get_node_or_null("WinTimer")


func _play_anim(anim_name: StringName) -> bool:
	if _anim == null or not _anim.has_animation(anim_name):
		return false
	_anim.play(anim_name)
	return true


func _ready() -> void:
	if _button != null:
		_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_text(text: String) -> void:
	if _label == null:
		_label = $Sprite/Label
	if _button == null:
		_button = $Sprite

	if text == "S":
		if _button != null:
			_button.texture_normal = TEX_START
		if _label != null:
			_label.text = ""
			_label.visible = false
	elif text == "F":
		if _button != null:
			_button.texture_normal = TEX_FINISH
		if _label != null:
			_label.text = ""
			_label.visible = false
	else:
		if _button != null:
			_button.texture_normal = TEX_NORMAL
		if _label != null:
			_label.text = text
			_label.visible = not text.is_empty()


## Cỡ chữ SỐ đang dùng trên ô (0 = scene chưa khai LabelSettings) — Board đọc giá trị này
## để suy cỡ chữ GỐC rồi co theo từng cỡ board, KHÔNG cần biết cấu trúc node con của ô.
func text_font_size() -> int:
	if _label == null:
		_label = $Sprite/Label
	if _label == null or _label.label_settings == null:
		return 0
	return _label.label_settings.font_size


## Đặt cỡ ô (Board tính theo số cột/hàng) — ô tự lo phần đi kèm cỡ: TÂM XOAY cho hiệu ứng
func set_cell_size(side: float) -> void:
	size = Vector2(side, side)
	pivot_offset = size * 0.5


## Hiệu ứng xuất hiện khi vào màn — Board gọi cho từng ô, `delay` theo (x + y)
func play_entrance(delay: float) -> void:
	pivot_offset = size * 0.5
	scale = Vector2(0.65, 0.65)
	modulate.a = 0.0
	if _anim != null and _anim.has_animation(&"entrance"):
		if delay > 0.0:
			if _entrance_timer != null:
				_entrance_timer.wait_time = delay
				_entrance_timer.start()
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
	if _label == null:
		_label = $Sprite/Label
	_apply_label_font_size(_label, fs)
	# Chữ phụ của lớp mực phai co theo cùng tỉ lệ với số trên ô
	if _warn_label == null:
		_warn_label = get_node_or_null("Sprite/WarnLabel")
	_apply_label_font_size(_warn_label, maxi(int(round(fs * WARN_TEXT_RATIO)), 8))
	if _faded_label == null:
		_faded_label = get_node_or_null("Sprite/FadedLabel")
	_apply_label_font_size(_faded_label, maxi(int(round(fs * FADED_TEXT_RATIO)), 10))
	# Nhãn "ĐÃ ĐI" của mode One Stroke co theo cùng tỉ lệ với số trên ô
	if _visited_label == null:
		_visited_label = get_node_or_null("Sprite/VisitedLabel")
	_apply_label_font_size(_visited_label, maxi(int(round(fs * VISITED_TEXT_RATIO)), 9))


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
	var warn := ink == 1
	var faded := ink == 0
	if _warn == null:
		_warn = get_node_or_null("Sprite/Warn")
	if _warn_label == null:
		_warn_label = get_node_or_null("Sprite/WarnLabel")
	if _faded == null:
		_faded = get_node_or_null("Sprite/Faded")
	if _faded_badge == null:
		_faded_badge = get_node_or_null("Sprite/FadedBadge")
	if _faded_label == null:
		_faded_label = get_node_or_null("Sprite/FadedLabel")
	if _warn != null:
		_warn.visible = warn
	if _warn_label != null:
		_warn_label.visible = warn
	if _faded != null:
		_faded.visible = faded
	if _faded_badge != null:
		_faded_badge.visible = faded
	if _faded_label != null:
		_faded_label.visible = faded


func warn_visible() -> bool:
	return _warn != null and _warn.visible


## One Stroke: ô ĐÃ ĐI QUA (bị khoá vĩnh viễn, đi lại là thua) — tô mực xanh + gạch chéo
## + nhãn "ĐÃ ĐI" ở mép trên. Ô S/F không bao giờ bật lớp này (mockup giữ nguyên art S/F).
func set_visited_own(on: bool) -> void:
	if _visited == null:
		_visited = get_node_or_null("Sprite/Visited")
	if _visited_label == null:
		_visited_label = get_node_or_null("Sprite/VisitedLabel")
	if _visited != null:
		_visited.visible = on
	if _visited_label != null:
		_visited_label.visible = on
		if on:
			_visited_label.text = tr("STR_OS_CELL_VISITED")


func visited_visible() -> bool:
	return _visited != null and _visited.visible


## Wall Builder: ô ĐÃ KHỚP SỐ (số tường quanh ô bằng đúng các đoạn đã nối) — nền xanh lá nhạt.
## Chỉ là gợi ý trực quan của chế độ, không ảnh hưởng luật.
func set_satisfied(on: bool) -> void:
	if _satisfied == null:
		_satisfied = get_node_or_null("Sprite/Satisfied")
	if _satisfied != null:
		_satisfied.visible = on


func satisfied_visible() -> bool:
	return _satisfied != null and _satisfied.visible


func visited_text() -> String:
	return _visited_label.text if _visited_label != null else ""


func faded_visible() -> bool:
	return _faded != null and _faded.visible


func warn_text() -> String:
	return _warn_label.text if _warn_label != null else ""


func faded_text() -> String:
	return _faded_label.text if _faded_label != null else ""


func get_text() -> String:
	if _label == null:
		_label = $Sprite/Label
	return _label.text if _label != null else ""


func set_focused(active: bool) -> void:
	if _button == null:
		_button = $Sprite
	if _button != null:
		_button.modulate = FOCUS_MODULATE if active else NORMAL_MODULATE


## Hiện/ẩn biểu tượng Bomb đã nổ (Minesweeper) — icon to giữa ô, số trên ô vẽ ĐÈ LÊN icon.
func set_bomb(active: bool) -> void:
	if _bomb == null:
		_bomb = get_node_or_null("Sprite/Bomb")
	if _bomb != null:
		_bomb.visible = active
	_apply_bomb_text_outline(active)


## Số nằm trên nền mìn đậm nên cần viền sáng; khi ẩn Bomb thì trả lại như cũ.
func _apply_bomb_text_outline(active: bool) -> void:
	if _label == null:
		_label = get_node_or_null("Sprite/Label")
	if _label == null or _label.label_settings == null:
		return
	var settings := _label.label_settings
	var has_outline := settings.outline_size > 0
	if active == has_outline:
		return
	# LabelSettings dùng chung cho mọi ô -> phải duplicate trước khi đổi
	settings = settings.duplicate() as LabelSettings
	settings.outline_size = BOMB_TEXT_OUTLINE_SIZE if active else 0
	settings.outline_color = BOMB_TEXT_OUTLINE_COLOR
	_label.label_settings = settings


func has_bomb() -> bool:
	if _bomb == null:
		_bomb = get_node_or_null("Sprite/Bomb")
	return _bomb != null and _bomb.visible


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
	var sprite := get_node_or_null("Sprite") as Control
	if sprite == null:
		return
	sprite.position = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(sprite, "position", Vector2(-6, 4), 0.035)
	tw.tween_property(sprite, "position", Vector2(6, -4), 0.035)
	tw.tween_property(sprite, "position", Vector2(-3, 2), 0.035)
	tw.tween_property(sprite, "position", Vector2.ZERO, 0.04)


## Hiệu ứng nảy số trên ô khi giá trị được cập nhật (Fading Ink / Sum Path)
func play_pop_text() -> void:
	if _label == null:
		_label = get_node_or_null("Sprite/Label")
	if _label == null or not _label.visible:
		return
	_label.pivot_offset = _label.size * 0.5
	if _play_anim(&"pop_text"):
		return
	var tw := create_tween()
	tw.tween_property(_label, "scale", Vector2(1.32, 1.32), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Hiệu ứng chúc mừng thắng màn / bài hướng dẫn: nảy nhẹ so le
func play_win(delay: float = 0.0) -> void:
	pivot_offset = size * 0.5
	if _anim != null and _anim.has_animation(&"win"):
		if delay > 0.0:
			if _win_timer != null:
				_win_timer.wait_time = delay
				_win_timer.start()
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
	var sprite := get_node_or_null("Sprite") as Control
	if sprite != null:
		sprite.position = Vector2.ZERO
		var tw := create_tween()
		tw.tween_property(sprite, "position", Vector2(-6, 4), 0.035)
		tw.tween_property(sprite, "position", Vector2(6, -4), 0.035)
		tw.tween_property(sprite, "position", Vector2(-3, 2), 0.035)
		tw.tween_property(sprite, "position", Vector2.ZERO, 0.04)
	modulate = Color(1.0, 0.45, 0.42, 1.0)
	var fade := create_tween()
	fade.tween_property(self, "modulate", Color.WHITE, 0.35)
