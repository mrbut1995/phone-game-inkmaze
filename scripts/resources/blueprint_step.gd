class_name BlueprintStep
extends Resource

## ============================================================================
## BlueprintStep: Resource mô tả 1 bước trong flow hướng dẫn.
##
## Tất cả trường đều có thể chỉnh trong Godot Inspector, kể cả pointer_drag
## (dùng BlueprintStepDrag thay Dictionary).
##
## Cách dùng trong editor:
##   1. Trong Inspector của tutorial scene, chọn @export var blueprint_steps
##   2. Thêm phần tử mới → chọn "New BlueprintStep"
##   3. Điền message_key, fallback_text, advance_mode…
##   4. Nếu cần cursor demo: gán pointer_drag = New BlueprintStepDrag
## ============================================================================

## --- Nội dung thẻ thoại ---
@export var message_key: String = ""
@export_multiline var fallback_text: String = ""
@export var title_key: String = "STR_TUT_COMMON_TITLE"

## --- Chế độ tiến bước ---
## "MANUAL"  → hiện nút Tiếp tục
## "AUTO"    → tự tiến khi required_action hoàn thành (hoặc dùng auto_delay)
@export_enum("MANUAL", "AUTO") var advance_mode: String = "MANUAL"
@export var required_action: String = ""
@export var auto_delay: float = 0.0

## --- Spotlight (chỉ 1 trong 3 nên được set) ---
@export var spotlight_cell: Vector2i = Vector2i(-1, -1)
@export var spotlight_node: NodePath = NodePath()
@export var spotlight_rect: Rect2 = Rect2()

## --- Cursor animation ---
## Nếu set pointer_drag → cursor chạy kéo từ from_cell → to_cell (loop)
@export var pointer_drag: BlueprintStepDrag = null
## Nếu set pointer_tap → cursor gõ nhẹ tại ô đó (loop)
@export var pointer_tap: Vector2i = Vector2i(-1, -1)


## Chuyển thành Dictionary tương thích với BaseTutorial.setup_steps()
func to_dictionary() -> Dictionary:
	var out: Dictionary = {
		"message_key": message_key,
		"fallback_text": fallback_text,
		"title_key": title_key,
		"advance_mode": advance_mode,
		"required_action": required_action,
	}

	if auto_delay > 0.0:
		out["auto_delay"] = auto_delay

	if spotlight_cell != Vector2i(-1, -1):
		out["spotlight_cell"] = spotlight_cell
	if not spotlight_node.is_empty():
		out["spotlight_node"] = spotlight_node
	if spotlight_rect != Rect2():
		out["spotlight_rect"] = spotlight_rect

	if pointer_drag != null:
		out["pointer_drag"] = pointer_drag.to_dictionary()
	if pointer_tap != Vector2i(-1, -1):
		out["pointer_tap"] = pointer_tap

	return out
