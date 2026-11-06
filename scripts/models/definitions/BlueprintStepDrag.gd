class_name BlueprintStepDrag
extends Resource

## ============================================================================
## BlueprintStepDrag: Mô tả animation kéo cursor từ ô này sang ô kia trong demo.
## Được embed trực tiếp vào BlueprintStep.pointer_drag trong editor.
## ============================================================================

@export var from_cell: Vector2i = Vector2i(0, 0)
@export var to_cell: Vector2i = Vector2i(1, 0)
@export var duration: float = 0.6


func to_dictionary() -> Dictionary:
	return {
		"from_cell": from_cell,
		"to_cell": to_cell,
		"duration": duration,
	}
