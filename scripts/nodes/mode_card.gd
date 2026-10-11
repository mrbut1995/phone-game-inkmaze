@tool
class_name ModeCard
extends NinePatchButton
## ============================================================================
## Node: ModeCard — "thẻ giấy" cho 2 chế độ thường trực (Play · Dungeon).
##
## Bản thân thẻ LÀ nút (kế thừa `NinePatchButton`): art
## `assets/images-png/common/card_mode_{normal,pressed,focus,disabled}.png` kéo giãn
## bằng 9-slice (KHÔNG để art méo — §A2) + đủ 4 trạng thái.
##
## Dùng cho CẢ 2 hướng: bề rộng do layout cha quyết định, chiều cao lấy từ scene.
## Cấu hình bằng `setup(data)` — không tạo node lúc chạy (§13.15).
## ============================================================================

signal card_pressed(mode_id: StringName)

## Chế độ thẻ này đại diện ("play" hoặc "dungeon")
@export var mode_id: StringName = &"play"

@onready var tape: ColorRect = $Tape
@onready var icon_rect: TextureRect = $Content/IconBox/Panel/Icon
@onready var chip: PanelContainer = $Content/Texts/Chip
@onready var chip_label: Label = $Content/Texts/Chip/ChipLabel
@onready var title_label: Label = $Content/Texts/Title
@onready var subtitle_label: Label = $Content/Texts/Subtitle
@onready var info_icon: TextureRect = $Content/Texts/Info/InfoIcon
@onready var info_label: Label = $Content/Texts/Info/InfoLabel
@onready var stat_label: Label = $Content/Right/StatLabel
@onready var stat_value: Label = $Content/Right/StatValue
@onready var action_button: Button = $Content/Right/ActionButton
@onready var action_label: Label = $Content/Right/ActionButton/ActionLabel


func _ready() -> void:
	super()
	if action_button != null:
		action_button.pressed.connect(_on_pressed)
	pressed.connect(_on_pressed)


## Áp dữ liệu vào thẻ.
## data: { chip, title, subtitle, info, info_icon, stat_label, stat_value, button,
##         tape_color, accent_color, chip_color, chip_text, icon }
func setup(data: Dictionary) -> void:
	if icon_rect != null and data.has("icon"):
		icon_rect.texture = data["icon"] as Texture2D
	if chip_label != null:
		chip_label.text = str(data.get("chip", ""))
		chip_label.add_theme_color_override("font_color", data.get("chip_text", Color.WHITE))
	if chip != null:
		var cs := StyleBoxFlat.new()
		cs.bg_color = data.get("chip_color", Color("#9CCBE8"))
		cs.set_corner_radius_all(7)
		cs.content_margin_left = 7.0
		cs.content_margin_right = 7.0
		cs.content_margin_top = 1.0
		cs.content_margin_bottom = 1.0
		chip.add_theme_stylebox_override("panel", cs)
	if title_label != null:
		title_label.text = str(data.get("title", ""))
		if title_label.has_method("refresh"):
			title_label.call("refresh")
	if subtitle_label != null:
		subtitle_label.text = str(data.get("subtitle", ""))
		if subtitle_label.has_method("refresh"):
			subtitle_label.call("refresh")
	if info_icon != null:
		var itex: Texture2D = data.get("info_icon", null)
		info_icon.texture = itex
		info_icon.visible = itex != null
	if info_label != null:
		info_label.text = str(data.get("info", ""))
	if stat_label != null:
		stat_label.text = str(data.get("stat_label", ""))
	if stat_value != null:
		stat_value.text = str(data.get("stat_value", ""))
	if action_label != null:
		action_label.text = str(data.get("button", ""))
	if action_button != null:
		var fill: Color = data.get("accent_color", Color("#256C96"))
		action_button.add_theme_stylebox_override("normal", _cta_style(fill, 0))
		action_button.add_theme_stylebox_override("hover", _cta_style(fill, 0))
		action_button.add_theme_stylebox_override("pressed", _cta_style(fill.darkened(0.15), 2))
	if tape != null:
		tape.color = data.get("tape_color", Color("#9CCBE8"))


func _cta_style(fill: Color, sink: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = fill.darkened(0.35)
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_width_left = 2
	sb.set_corner_radius_all(10)
	sb.content_margin_top = 4 + sink
	sb.content_margin_bottom = 4 - sink
	return sb


func _on_pressed() -> void:
	card_pressed.emit(mode_id)
