class_name ToolController
extends Node
## ============================================================================
## Controller: Quản lý chế độ công cụ của BÀN CỜ: "VẼ ĐƯỜNG" (path) ⇄ "GHI NHỚ" (wall mark).
##
## 2 nút công cụ trên HUD (Tool · Wall) đã BỎ (2026-09-26): bàn cờ tự nhận cả 2 thao tác
## (kéo nhân vật đi đường · kéo nối 2 Anchor để đánh dấu tường) nên controller chỉ còn giữ
## TRẠNG THÁI công cụ + phát signal khi đổi (Board lắng nghe qua `tool_changed` → `set_tool_mode`).
## ============================================================================

signal tool_changed(tool_name: String)

enum ToolMode { PATH, WALL }

var current_tool: ToolMode = ToolMode.PATH


func _on_tool_pressed(mode : String) :
	Sfx.play(Sfx.BTN_WOOD_TAP)
	if mode == "path":
		select_tool(ToolMode.PATH)
	elif mode == "wall":
		select_tool(ToolMode.WALL)

func select_tool(mode: ToolMode) -> void:
	current_tool = mode
	var mode_name := "path" if current_tool == ToolMode.PATH else "wall"
	tool_changed.emit(mode_name)


func _on_wall_pressed(_mode: String = "wall") -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	select_tool(ToolMode.WALL)
