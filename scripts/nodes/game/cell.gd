class_name MazeCell
extends Control
## ============================================================================
## View: Một ô trên lưới (Control chứa TextureButton + Label số tường).
## Tự co giãn theo kích thước ô (không có khoảng cách): board.gd đặt `size` cho ô,
## art (mọi trạng thái) đều cùng khung 176x176 và TextureButton ở chế độ stretch
## nên co lại vẫn khớp nhau; số trên ô co theo qua set_font_size().
## ============================================================================

signal cell_pressed(grid_pos: Vector2i)

@export var grid_pos: Vector2i = Vector2i.ZERO

const NORMAL_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const FOCUS_MODULATE := Color(0.85, 0.95, 1.0, 1.0)

## Số trên ô vẽ ĐÈ LÊN icon Bomb (nền mìn đậm) -> thêm viền màu giấy cho số để vẫn đọc được.
const BOMB_TEXT_OUTLINE_SIZE := 4
const BOMB_TEXT_OUTLINE_COLOR := Color(0.996078, 0.992157, 0.980392, 1.0)   # #FEFDFA

const TEX_NORMAL := preload("res://assets/images/game/cell_normal.svg")
const TEX_START := preload("res://assets/images/game/cell_start.svg")
const TEX_FINISH := preload("res://assets/images/game/cell_finish.svg")

## Mực phai (Fading Ink): tỉ lệ cỡ chữ phụ so với cỡ số trên ô (số gốc 56 -> 11 / 22)
const WARN_TEXT_RATIO := 11.0 / 56.0
const FADED_TEXT_RATIO := 22.0 / 56.0
## One Stroke: tỉ lệ cỡ chữ nhãn "ĐÃ ĐI" (số gốc 56 -> 12)
const VISITED_TEXT_RATIO := 12.0 / 56.0

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
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Hiệu ứng rung lắc ô khi xảy ra va chạm nguy hiểm (nổ mìn, đâm gai)
func play_shudder() -> void:
	var base_pos := position
	var tw := create_tween()
	tw.tween_property(self, "position", base_pos + Vector2(-5, 3), 0.035)
	tw.tween_property(self, "position", base_pos + Vector2(5, -3), 0.035)
	tw.tween_property(self, "position", base_pos + Vector2(-3, 2), 0.035)
	tw.tween_property(self, "position", base_pos, 0.04)


## Hiệu ứng nảy số trên ô khi giá trị được cập nhật (Fading Ink / Sum Path)
func play_pop_text() -> void:
	if _label == null:
		_label = get_node_or_null("Sprite/Label")
	if _label == null or not _label.visible:
		return
	_label.pivot_offset = _label.size * 0.5
	var tw := create_tween()
	tw.tween_property(_label, "scale", Vector2(1.32, 1.32), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

