class_name DailyDayCell
extends Control
## ============================================================================
## Component: Ô ngày trong Lịch Daily Challenge
## ============================================================================

signal day_selected(day_number: int)

@export var day_number: int = 1
@export var is_completed: bool = false
@export var is_today: bool = false

@onready var btn: TextureButton = $Button


func _ready() -> void:
	if btn != null:
		btn.pressed.connect(_on_btn_pressed)


func setup(p_day: int, p_completed: bool = false, p_today: bool = false) -> void:
	day_number = p_day
	is_completed = p_completed
	is_today = p_today


func _on_btn_pressed() -> void:
	day_selected.emit(day_number)
