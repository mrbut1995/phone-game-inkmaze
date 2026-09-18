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

## ART GHI ĐÈ theo chế độ (null = dùng art mặc định ở trên). GameScene gọi
## `set_mode_textures()` mỗi lần đổi chế độ (VD One Stroke: nút VẼ ĐƯỜNG ĐI bè ngang 680px;
## Wall Builder: nút thứ 2 thành nút GỬI BÀI màu xanh).
var path_active_override: Texture2D = null
var path_inactive_override: Texture2D = null
var path_pressed_override: Texture2D = null
var wall_active_override: Texture2D = null
var wall_inactive_override: Texture2D = null
var wall_pressed_override: Texture2D = null


func _on_tool_pressed(mode : String) :
	Sfx.play(Sfx.BTN_WOOD_TAP)
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
		var path_active := path_active_override if path_active_override != null else PATH_ACTIVE_TEX
		var path_inactive := path_inactive_override if path_inactive_override != null else PATH_INACTIVE_TEX
		tb.texture_normal = path_active if current_tool == ToolMode.PATH else path_inactive
		if path_pressed_override != null:
			tb.texture_pressed = path_pressed_override
	if tool_wall_btn is TextureButton:
		var wb := tool_wall_btn as TextureButton
		var wall_active := wall_active_override if wall_active_override != null else WALL_ACTIVE_TEX
		var wall_inactive := wall_inactive_override if wall_inactive_override != null else WALL_INACTIVE_TEX
		wb.texture_normal = wall_active if current_tool == ToolMode.WALL else wall_inactive
		if wall_pressed_override != null:
			wb.texture_pressed = wall_pressed_override


## GameScene gọi mỗi lần đổi chế độ: đặt lại art ghi đè của 2 nút rồi vẽ lại ngay.
## Truyền null cho chế độ không cần ghi đè.
func set_mode_textures(
	path_active: Texture2D, path_pressed: Texture2D, path_inactive: Texture2D,
	wall_active: Texture2D, wall_pressed: Texture2D, wall_inactive: Texture2D
) -> void:
	path_active_override = path_active
	path_pressed_override = path_pressed
	path_inactive_override = path_inactive
	wall_active_override = wall_active
	wall_pressed_override = wall_pressed
	wall_inactive_override = wall_inactive
	_refresh_ui()


func _on_wall_pressed(_mode: String = "wall") -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	select_tool(ToolMode.WALL)
