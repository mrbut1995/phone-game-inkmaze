class_name GameOverPopup
extends BasePopup
## ============================================================================
## Popup: Thua cuộc (nodes/popups/gameover.tscn) - mockup popup_game_over_dungeon.svg
## (bản Play Mode là mockup popup_game_over_level.svg: thay vi va cham tuong + diem tich luy bang
##  danh sach 3 thu thach + trang thai, con dau in so thu thach da hoan thanh.)
## Dữ liệu: open({ floor, progress, wall_hits, score })
## ============================================================================

signal retry_requested
signal menu_requested
signal revive_requested

## Node binding: khai `node_paths` + `NodePath` trong `gameover.tscn`
@export var value_progress: Label = null
@export var value_walls: Label = null
@export var value_score: Label = null
@export var stamp_count: Label = null
@export var revive_desc: Label = null


func _on_open() -> void:
	var progress := float(data.get("progress", 0.0))
	var hits := int(data.get("wall_hits", 0))

	value_progress.text = tr("STR_GAMEOVER_DISTANCE_FORMAT").format([int(round(progress))])
	value_walls.text = tr("STR_GAMEOVER_WALLS_FORMAT").format([hits, hits])
	value_score.text = tr("STR_SCORE_FORMAT").format([int(data.get("score", 0))])

	# Con dấu: số bước còn lại khi hết bước (Dungeon Mode là chế độ duy nhất có bộ đếm bước)
	stamp_count.text = tr("STR_GAMEOVER_STAMP_STEPS").format([
		int(data.get("steps_left", 0)),
		int(data.get("steps_max", 0)),
	])

	# Dòng mô tả nút HỒI SINH: số bước thưởng do GameController truyền sang (mặc định 3)
	revive_desc.text = tr("STR_REVIVE_DESC_STEPS").format([int(data.get("revive_steps", 3))])

	# Dây 3 nút (Hồi sinh / Menu / Thử lại) khai trong `gameover.tscn` (cùng scene)


func _on_revive_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	# KHÔNG tự đóng popup: GameController chỉ đóng khi quảng cáo thưởng được chấp nhận
	# (nếu không, người chơi sẽ bị bỏ lại ở màn hình đứng yên vì ván đang ở trạng thái thua).
	revive_requested.emit()


func _on_retry_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	retry_requested.emit()
	close()


func _on_menu_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	menu_requested.emit()
	close()
