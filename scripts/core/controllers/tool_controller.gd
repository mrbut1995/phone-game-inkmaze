class_name ToolController
extends Node
## ============================================================================
## Controller: Quản lý chuyển đổi chế độ công cụ: "Vẽ Đường" và "Ghi Nhớ".
## ============================================================================

signal tool_changed(tool_name: String)

enum ToolMode { PATH, WALL }

var current_tool: ToolMode = ToolMode.PATH

@export var tool_path_btn: BaseButton = null
@export var tool_wall_btn: BaseButton = null

const PATH_ACTIVE_TEX := preload("res://assets/images/game/btn_tool_path_active.svg")
const PATH_INACTIVE_TEX := preload("res://assets/images/game/btn_tool_path_inactive.svg")
const WALL_ACTIVE_TEX := preload("res://assets/images/game/btn_tool_wall_active.svg")
const WALL_INACTIVE_TEX := preload("res://assets/images/game/btn_tool_wall_inactive.svg")


func _on_tool_pressed(mode : String) :
	if mode == "path":
		select_tool(ToolMode.PATH)
	elif mode == "wall":
		select_tool(ToolMode.WALL)

func select_tool(mode: ToolMode) -> void:
	current_tool = mode
	_refresh_ui()
	var mode_name := "path" if current_tool == ToolMode.PATH else "wall"
	tool_changed.emit(mode_name)


func _refresh_ui() -> void:
	if tool_path_btn is TextureButton:
		var tb := tool_path_btn as TextureButton
		tb.texture_normal = PATH_ACTIVE_TEX if current_tool == ToolMode.PATH else PATH_INACTIVE_TEX
	if tool_wall_btn is TextureButton:
		var tb := tool_wall_btn as TextureButton
		tb.texture_normal = WALL_ACTIVE_TEX if current_tool == ToolMode.WALL else WALL_INACTIVE_TEX


func _on_wall_pressed(extra_arg_0: String) -> void:
	pass # Replace with function body.
