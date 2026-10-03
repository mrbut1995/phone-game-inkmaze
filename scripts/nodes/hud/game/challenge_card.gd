class_name ChallengeCard
extends NinePatchRect
## ============================================================================
## Thẻ "THỬ THÁCH" trên HUD — nodes/hud/<hướng>/game/level_mode.tscn → `Content/ModeInformation/Challenge`
##
## TỰ LO TRÌNH BÀY: cột trái "x/3 ✓" + dòng "n ĐÃ HOÀN THÀNH", bên phải 3 dải thử thách
## (nền + ô tích + tên + trạng thái, đạt rồi thì hiện NHÃN "✓ ĐẠT").
##
## BÊN NGOÀI CHỈ GỌI `refresh()` — không tự lấy node con của thẻ:
##   · ChallengeController tính TRẠNG THÁI (đạt chưa · còn cơ hội không) rồi đưa vào đây;
##   · thẻ tự quyết ART + MÀU (đó là chuyện hiển thị, không phải chuyện luật chơi).
## Nhờ vậy đổi mockup/art/màu của thẻ chỉ cần sửa file này + scene, không đụng controller.
## ============================================================================

const ROW_DONE := preload("res://assets/images-png/game/chal_row_done.png")
const ROW_PENDING := preload("res://assets/images-png/game/chal_row_pending.png")
const CHECK_DONE := preload("res://assets/images-png/game/chal_check_done.png")
const CHECK_PENDING := preload("res://assets/images-png/game/chal_check_pending.png")

## Chưa đạt nhưng vẫn còn cơ hội (chữ cam) / đã lệch mục tiêu (chữ đỏ)
const COLOR_LIVE := Color(0.70980394, 0.38431373, 0.101960786, 1)
const COLOR_FAIL := Color(0.84705883, 0.26666668, 0.26666668, 1)
## Màu chữ mờ (tên thử thách hỏng) + màu tên bình thường
const COLOR_IDLE := Color(0.44313726, 0.54509807, 0.61960787, 1)
const COLOR_NAME := Color(0.13333334, 0.29803923, 0.42745098, 1)


## Vẽ lại toàn bộ thẻ.
## `rows` = [{ title:String, status:String, done:bool, on_track:bool }] (tối đa
## `ChallengeTypes.MAX_PER_LEVEL` dải — khai ít thử thách thì các dải thừa bị ẩn).
## `done_total`/`total` = số thử thách đã đạt / tổng số thử thách của màn · `note` = dòng chân thẻ.
func refresh(rows: Array, done_total: int, total: int, note: String) -> void:
	_set_text("CountRow/Count", str(done_total))
	_set_text("CountRow/CountMax", "/%d ✓" % total)
	_set_text("Note", note)

	for i in ChallengeTypes.MAX_PER_LEVEL:
		var row_node := get_node_or_null("Row%d" % (i + 1)) as Control
		if row_node == null:
			continue
		var has_row := i < rows.size()
		row_node.visible = has_row
		if has_row and rows[i] is Dictionary:
			_apply_row(row_node, rows[i])


## 1 dải thử thách: nền + ô tích + tên + (trạng thái HOẶC nhãn ĐẠT)
func _apply_row(row_node: Control, row: Dictionary) -> void:
	var done := bool(row.get("done", false))
	var on_track := bool(row.get("on_track", true))

	_set_texture(row_node, "Bg", ROW_DONE if done else ROW_PENDING)
	_set_texture(row_node, "Bg/Check", CHECK_DONE if done else CHECK_PENDING)

	var name_label := row_node.get_node_or_null("Bg/Name") as Label
	if name_label != null:
		var title := str(row.get("title", ""))
		if name_label.text != title:
			name_label.text = title
		name_label.modulate = COLOR_IDLE if (not done and not on_track) else COLOR_NAME

	# Đã đạt -> ẩn dòng trạng thái (đã có nhãn ĐẠT), chưa đạt -> hiện mô tả tiến độ
	var status_label := row_node.get_node_or_null("Bg/Status") as Label
	if status_label != null:
		status_label.visible = not done
		var status := str(row.get("status", ""))
		if status_label.text != status:
			status_label.text = status
		status_label.modulate = COLOR_LIVE if on_track else COLOR_FAIL

	var badge := row_node.get_node_or_null("Bg/Badge") as Control
	if badge != null:
		badge.visible = done


## Gán text cho Label con (bỏ qua nếu trùng -> không redraw mỗi frame)
func _set_text(path: String, text: String) -> void:
	var label := get_node_or_null(path) as Label
	if label != null and label.text != text:
		label.text = text


func _set_texture(root: Node, path: String, texture: Texture2D) -> void:
	var rect := root.get_node_or_null(path) as TextureRect
	if rect != null and rect.texture != texture:
		rect.texture = texture
