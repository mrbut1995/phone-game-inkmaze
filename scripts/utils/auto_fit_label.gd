class_name AutoFitLabel
extends Label
## ============================================================================
## Helper: Label tự co cỡ chữ để VỪA khung (không tràn dòng, không cắt chữ).
##
## Dùng khi chữ có thể dài hơn khung ở một số ngôn ngữ: thay vì giảm cỡ cứng trong
## `.tscn` (dễ quá nhỏ), label tự bò cỡ chữ từ `font_size` khai trong scene xuống tới
## `min_font_size` cho tới khi chữ vừa bề ngang khả dụng.
##
## KHÔNG hard-code cỡ trong script: `font_size` gốc lấy từ theme/scene override của
## chính node; script chỉ thu nhỏ theo bước 1px trong khoảng [min_font_size, font_size].
## ============================================================================

## Cỡ chữ nhỏ nhất cho phép (không bao giờ nhỏ hơn — §đặc tả: tối thiểu 8px)
@export_range(1, 64, 1) var min_font_size: int = 8

## Bề ngang đệm trừ ra khi đo (viền/nhịp thở hai bên)
@export var padding: float = 0.0

var _base_size: int = -1


func _ready() -> void:
	clip_text = true
	_apply()
	resized.connect(_apply)


## Áp lại cỡ chữ (gọi sau khi đổi text/ngôn ngữ)
func refresh() -> void:
	_apply()


func _apply() -> void:
	if _base_size < 0:
		_base_size = get_theme_font_size("font_size")
		if _base_size <= 0:
			_base_size = 16
	var avail := size.x - padding
	if avail <= 1.0:
		return
	var font := get_theme_font("font")
	if font == null:
		return
	var chosen := _base_size
	var floor_size := mini(mini(min_font_size, _base_size), _base_size)
	while chosen > floor_size:
		if font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, chosen).x <= avail:
			break
		chosen -= 1
	add_theme_font_size_override("font_size", chosen)
