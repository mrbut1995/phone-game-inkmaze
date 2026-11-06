class_name ToolIds
extends RefCounted
## Mã CÔNG CỤ hỗ trợ (dùng chung cho controller, HUD, debug).
## Giá trị khớp `GameManager.TOOL_*` — nguồn duy nhất để tránh lệch chuỗi giữa nơi dùng và nơi lưu.

const SKIP := "skip"
const TELEPORT := "teleport"
const HINT := "hint"

const ALL: Array[String] = [SKIP, TELEPORT, HINT]
