class_name NextFloorPopup
extends BasePopup
## ============================================================================
## Popup: QUA TẦNG của DUNGEON (nodes/popups/next_floor.tscn)
## Bố cục (cùng ngôn ngữ với Game Over Dungeon):
##   1. Đầu: "TẦNG n" (xanh)
##   2. Thước tầng (NextFloorRuler): tầng vừa qua · SẮP VÀO tầng kế · kỷ lục TUẦN/THÁNG
##   3. Thẻ điểm CỘNG DỒN: Cơ bản +a · Đi nhanh +b · Hoàn hảo +c ──── Tổng (dòng bằng 0 tự ẩn)
##   4. Thẻ thưởng bước đi "+N" (có hiệu ứng "bonus_pop"; N = 0 thì ẩn)
##   5. Nút: Về Menu · Vào tầng kế
##
## Dữ liệu (GameController._complete_floor): floor, next_floor, bonus_steps|steps_bonus,
##   base_score, move_bonus, perfect_bonus, total_score|score, best_floor_week?, best_floor_month?
## Signal giữ nguyên tên cũ để UIController nối như trước:
##   rest_requested  -> _emit_home      enter_requested -> _emit_continue
## ============================================================================

signal rest_requested
signal enter_requested

## Node binding: khai `node_paths` + `NodePath` trong `next_floor.tscn`
@export var label_floor: Label = null
@export var ruler: NextFloorRuler = null
@export var row_move: Control = null
@export var row_perfect: Control = null
@export var value_base: Label = null
@export var value_move: Label = null
@export var value_perfect: Label = null
@export var value_total: Label = null
@export var bonus_card: Control = null
@export var value_bonus: Label = null
@export var go_label: Label = null
@export var fx_anim: AnimationPlayer = null


func _on_open() -> void:
	var floor_no := maxi(int(data.get("floor", data.get("level", 1))), 1)
	var next_no := maxi(int(data.get("next_floor", floor_no + 1)), floor_no + 1)
	label_floor.text = tr("STR_GO_FLOOR").format([floor_no])
	go_label.text = tr("STR_NF_ENTER").format([next_no])

	var week := _record("week")
	var month := _record("month")
	ruler.set_data(floor_no, next_no, week, month,
		tr("STR_GO_YOU"), tr("STR_NF_NEXT"), tr("STR_GO_WEEK"), tr("STR_GO_MONTH"))

	var base_pts := int(data.get("base_score", 0))
	var move_pts := int(data.get("move_bonus", 0))
	var perfect_pts := int(data.get("perfect_bonus", 0))
	value_base.text = _fmt_signed(base_pts)
	value_move.text = _fmt_signed(move_pts)
	value_perfect.text = _fmt_signed(perfect_pts)
	# Khoản bằng 0 thì ẩn cho gọn
	row_move.visible = move_pts != 0
	row_perfect.visible = perfect_pts != 0
	value_total.text = _fmt_int(int(data.get("total_score", data.get("score", 0))))

	var bonus := int(data.get("bonus_steps", data.get("steps_bonus", 0)))
	value_bonus.text = "+%d" % bonus
	bonus_card.visible = bonus > 0
	_play_bonus_pop.call_deferred(bonus)


func _play_bonus_pop(bonus: int) -> void:
	if bonus <= 0 or fx_anim == null or not is_inside_tree():
		return
	value_bonus.pivot_offset = value_bonus.size * 0.5
	if fx_anim.has_animation(&"bonus_pop"):
		fx_anim.play(&"bonus_pop")


# ---------------------------------------------------------------------------
# Kỷ lục (cho thước tầng)
# ---------------------------------------------------------------------------
func _record(kind: String) -> int:
	var best := int(data.get("best_floor_%s" % kind, -1))
	if best >= 0:
		return best
	var gm := get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("best_floor"):
		return int(gm.call("best_floor", kind))
	return 0


## 1240 -> "1.240"
static func _fmt_int(value: int) -> String:
	var s := str(absi(value))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return ("-" if value < 0 else "") + out


## 200 -> "+200"
static func _fmt_signed(value: int) -> String:
	return ("+" if value >= 0 else "-") + _fmt_int(absi(value))


# ---------------------------------------------------------------------------
# Nút (nối trong next_floor.tscn)
# ---------------------------------------------------------------------------
func _on_rest_pressed() -> void:
	Sfx.play(Sfx.BTN_WOOD_TAP)
	rest_requested.emit()
	close()


func _on_enter_pressed() -> void:
	Sfx.play(Sfx.BTN_CLICK)
	enter_requested.emit()
	close()
