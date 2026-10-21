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
## Kỷ lục tầng cao nhất trong TUẦN / THÁNG (dòng riêng dưới 3 chỉ số)
@export var value_best_week: Label = null
@export var value_best_month: Label = null


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

	# KỶ LỤC TẦNG: cao nhất đạt được trong tuần / tháng (Dungeon = tầng vô tận)
	_set_record(value_best_week, "STR_GAMEOVER_BEST_WEEK", "week")
	_set_record(value_best_month, "STR_GAMEOVER_BEST_MONTH", "month")

	# Dây 3 nút (Hồi sinh / Menu / Thử lại) khai trong `gameover.tscn` (cùng scene)


## Vẽ 1 dòng kỷ lục: ưu tiên số trong `data` (GameController truyền sang), thiếu thì hỏi GameManager.
func _set_record(label: Label, key: String, kind: String) -> void:
	if label == null:
		return
	var best := int(data.get("best_floor_%s" % kind, -1))
	if best < 0:
		best = _best_floor(kind)
	label.text = tr(key).format([str(best) if best > 0 else tr("STR_GAMEOVER_BEST_NONE")])


## Tầng cao nhất của kỳ `kind` (đọc qua /root như các manager khác — an toàn khi chạy test)
func _best_floor(kind: String) -> int:
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("best_floor"):
		return int(gm.call("best_floor", kind))
	return 0


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
