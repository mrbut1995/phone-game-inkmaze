class_name GameOverPopup
extends BasePopup
## ============================================================================
## Popup: Thua cuộc (nodes/popups/gameover.tscn) - mockup popup_game_over.svg
## Dữ liệu: open({ floor, progress, wall_hits, score })
## ============================================================================

signal retry_requested
signal menu_requested
signal revive_requested


func _on_open() -> void:
	var progress := float(data.get("progress", 0.0))
	var hits := int(data.get("wall_hits", 0))

	var value_progress := piece("StatValue1") as Label
	var value_walls := piece("StatValue2") as Label
	var value_score := piece("StatValue3") as Label
	if value_progress != null:
		value_progress.text = tr("STR_GAMEOVER_DISTANCE_FORMAT").format([int(round(progress))])
	if value_walls != null:
		value_walls.text = tr("STR_GAMEOVER_WALLS_FORMAT").format([hits, hits])
	if value_score != null:
		value_score.text = tr("STR_SCORE_FORMAT").format([int(data.get("score", 0))])

	bind_button("Panel/Content/Banner/ReviveBtn", _on_revive_pressed)
	bind_button("Panel/Content/MenuBtn", _on_menu_pressed)
	bind_button("Panel/Content/RetryBtn", _on_retry_pressed)


func _on_revive_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	revive_requested.emit()
	close()


func _on_retry_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	retry_requested.emit()
	close()


func _on_menu_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	menu_requested.emit()
	close()
