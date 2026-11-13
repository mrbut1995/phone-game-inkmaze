class_name EventRulerCell
extends VBoxContainer
## ============================================================================
## Một vạch trên "thước kẻ" của popup QUA TẦNG sự kiện (event_ruler_cell.tscn).
## Đã qua = dấu ✔ xanh · sắp vào = bút chì · chưa tới = chỉ có vạch + số.
## ============================================================================

## Scene contract
## Exports:  mark_check, mark_pencil, label_num
## Emits:    (none)
## Handlers wired in scene: (none)
## Subscribes in code (EventBus/Model): (none)

@export var mark_check: TextureRect = null
@export var mark_pencil: TextureRect = null
@export var label_num: Label = null


func setup(number: int, done: bool, now: bool) -> void:
	label_num.text = str(number)
	mark_check.visible = done
	mark_pencil.visible = now
