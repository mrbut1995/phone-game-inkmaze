class_name EventHeader
extends Control
## ============================================================================
## Node: EventHeader — tiêu đề khối Sự kiện trên Main Screen.
## Badge cam hiện SỐ event đang mở (kể cả Daily); link "Xem tất cả" (giai đoạn 1
## có thể ẩn — xem §B5).
## ============================================================================

signal view_all_pressed

@onready var title_label: Label = $Title
@onready var count_label: Label = $Badge/CountLabel
@onready var view_all: Button = $ViewAll


func _ready() -> void:
	if view_all != null:
		view_all.pressed.connect(func() -> void: view_all_pressed.emit())


## Số event đang mở (hiện trên badge cam)
func set_count(count: int) -> void:
	if count_label != null:
		count_label.text = str(count)


## Ẩn/hiện link "Xem tất cả" (giai đoạn 1 ẩn)
func set_view_all_visible(shown: bool) -> void:
	if view_all != null:
		view_all.visible = shown
