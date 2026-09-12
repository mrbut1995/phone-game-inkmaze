class_name GameModeController
extends Node

@export var game_mode : BaseGameMode = null

func _init() -> void:
	if game_mode == null:
		game_mode = StandardGameMode.new()
