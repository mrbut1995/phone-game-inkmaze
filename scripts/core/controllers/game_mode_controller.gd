class_name GameModeController
extends Node
## ============================================================================
## Controller: Quản lý và chuyển đổi chiến lược chế độ chơi (GameMode Strategy).
## Cung cấp khả năng chuyển đổi linh hoạt giữa 9 Game Modes của game.
## ============================================================================

signal mode_changed(new_mode: BaseGameMode)

@export var game_mode: BaseGameMode = null


func _init() -> void:
	if game_mode == null:
		game_mode = DungeonGameMode.new()


## Thiết lập GameMode trực tiếp
func set_game_mode(p_mode: BaseGameMode) -> void:
	game_mode = p_mode
	mode_changed.emit(game_mode)


## Chuyển đổi GameMode theo tên chế độ (name) và độ khó
func set_mode_by_name(mode_name: String, difficulty: String = "medium") -> BaseGameMode:
	var new_mode: BaseGameMode = null
	match mode_name.to_lower():
		"play", "classic", "standard":
			new_mode = StandardGameMode.new(difficulty)
		"dungeon":
			new_mode = DungeonGameMode.new()
		"time_attack":
			new_mode = TimeAttackGameMode.new(difficulty)
		"minesweeper":
			new_mode = MinesweeperPathGameMode.new()
		"sum_path":
			new_mode = SumPathGameMode.new(difficulty)
		"countdown_cost":
			new_mode = CountdownCostGameMode.new(difficulty)
		"blind_memory":
			new_mode = BlindMemoryGameMode.new(difficulty)
		"fog_of_war":
			new_mode = FogOfWarGameMode.new(difficulty)
		"area":
			new_mode = AreaGameMode.new()
		_:
			new_mode = DungeonGameMode.new()

	set_game_mode(new_mode)
	return new_mode
