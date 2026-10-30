class_name DailyLayout
extends BaseLayout
## ============================================================================
## Binding node cho màn Thử thách hằng ngày (scenes/layout/<hướng>/daily.tscn).
##
## Hai hướng (Portrait / Landscape) dùng CÙNG bộ export — màn hình chỉ việc khai
## `node_paths` trong scene. Mọi số đo/bố cục nằm trong scene, không ở script.
##
## HIỆU ỨNG SAO BAY (vừa thắng ván Daily): sao đã đạt trên thẻ bay lên Sao lớn, mỗi sao tới
## nơi thì Sao lớn nảy + nổ, thanh Sao chạy thêm 1 bậc. Toàn bộ chuyển động khai trong scene:
##   · `VfxAnim` / `fly`      — 3 ngôi sao bay (`VfStarFly.t`), mỗi sao tới đích gọi `on_fly_arrived`
##   · `ArriveAnim` / `arrive` — hiệu ứng MỖI LẦN một sao chạm đích (nảy, nổ, quét sáng, chạy thanh)
## Script chỉ lo SỐ LIỆU: điểm xuất phát/đích, số sao hiển thị `từ → tới`.
## ============================================================================

## Sao bay xong + thanh Sao đã chạy đủ (màn Daily nghe để bật hiệu ứng chip mốc thưởng)
signal star_gain_finished

@export var btn_back: BaseButton = null
@export var calendar: DailyCalendar = null

@export_group("Thanh Sao tháng")
## Số Sao tích luỹ của tháng (chữ to nằm trong ngôi sao lớn)
@export var lbl_star_total: Label = null
## Thanh tiến độ (nền navy + phần đã đạt màu hổ phách)
@export var bar_stars: TextureProgressBar = null
## HBox chứa các huy hiệu mốc thưởng
## Node chứa các huy hiệu mốc thưởng (bản ngang: HBox · bản đường mốc: Control, chip đặt theo `Slot`)
@export var milestones_host: Control = null

@export_group("Bản đường mốc (dải tuần + đường phần thưởng)")
## Đường phần thưởng (thay thanh Sao). Null ở bản ngang.
@export var road: DailyRoad = null
## Dải 7 ngày + nút mở lịch tháng. Null ở bản ngang (lịch tháng luôn hiện).
@export var week_strip: DailyWeekStrip = null
## Dòng "Còn N★ tới rương M★" dưới sao tổng
@export var lbl_road_hint: Label = null
## Scene chip mốc riêng của bố cục (null = dùng `MILESTONE_CHIP` của màn)
@export var chip_scene: PackedScene = null
## Bản NGANG: đường đi ngang (zigzag lên/xuống) ⇒ bảng phần thưởng nằm TRÊN/DƯỚI chip thay vì bên cạnh
@export var tag_vertical := false
## Bảng lịch tháng (overlay) + AnimationPlayer có `open` / `close` / `RESET`
@export var month_sheet: Control = null
@export var sheet_anim: AnimationPlayer = null

@export_group("Thẻ hành động")
@export var play_card: DailyActionCard = null
@export var challenge_card: DailyActionCard = null

@export_group("Khác")
@export var lbl_reset: Label = null
## Ví Xu ở thanh trên (bấm `+` mở Cửa hàng) — cùng `coin_chip.tscn` như Main Screen
@export var coin_chip: CoinChip = null

@export_group("Hiệu ứng Sao bay")
## Ngôi sao lớn trên thanh Sao (đích của sao bay)
@export var star_big: Control = null
## AnimationPlayer chứa `fly` (3 sao bay lần lượt)
@export var vfx_anim: AnimationPlayer = null
## AnimationPlayer chứa `arrive` (hiệu ứng mỗi lần 1 sao chạm đích)
@export var arrive_anim: AnimationPlayer = null
## Node chứa các `VfStarFly` (Fly0..2) — thứ tự con = thứ tự bay
@export var fly_host: Control = null
## 0..1 — nội suy số Sao hiển thị giữa `_star_from` → `_star_to` (AnimationPlayer `arrive` animate
## thuộc tính này để thanh Sao chạy mượt, số trên Sao lớn đổi theo)
@export_range(0.0, 1.0, 0.001) var star_progress := 1.0: set = _set_star_progress

## Hiệu ứng thanh Sao (đầu thanh sáng + dải sáng quét) — màn Daily instance rồi gắn vào đây
var _bar_fx: StarBarFx = null
## Ngưỡng Sao của các mốc (theo thứ tự chip trong `milestones_host`)
var _thresholds: Array[int] = []
## Số Sao đang hiển thị (có thể lẻ trong lúc sao bay)
var _stars_shown := 0.0
var _gain_active := false
var _gain_count := 0
var _ticks := 0
var _total_from := 0
var _total_to := 0
var _star_from := 0.0
var _star_to := 0.0
var _shown := 0.0


## Bắt đầu hiệu ứng: `gained` ngôi sao MỚI ĐẠT của thẻ `card` bay lên Sao lớn.
## `total_from → total_to` = tổng Sao tháng trước/sau ván. Trả false nếu không chạy được
## (thiếu node hiệu ứng / không có sao mới) — khi đó màn Daily hiện số liệu thật ngay.
func play_star_gain(card: DailyActionCard, gained: int, total_from: int, total_to: int) -> bool:
	if vfx_anim == null or fly_host == null or star_big == null or card == null:
		return false
	if gained <= 0 or not vfx_anim.has_animation(&"fly"):
		return false
	var flies := _flies()
	if flies.is_empty():
		return false
	_gain_count = mini(gained, flies.size())
	# Các sao MỚI nằm ở cuối hàng sao của thẻ (vd thẻ 3 sao, mới được 2 ⇒ sao thứ 2 và 3)
	var first := maxi(card.lit_stars() - _gain_count, 0)
	var target := star_big.get_global_transform() * (star_big.size * 0.5)
	for k in flies.size():
		flies[k].visible = k < _gain_count
		if k < _gain_count:
			flies[k].setup(card.star_center(first + k), target)
	_total_from = total_from
	_total_to = total_to
	_ticks = 0
	_gain_active = true
	_star_from = float(total_from)
	_star_to = float(total_from)
	star_progress = 1.0
	vfx_anim.stop()
	vfx_anim.play(&"fly")
	return true


## Đang chạy hiệu ứng (màn Daily KHÔNG ghi đè số Sao/thanh Sao trong lúc này)
func is_star_gain_playing() -> bool:
	return _gain_active


## Dừng ngay (đổi hướng màn hình / rời màn) và đưa mọi node hiệu ứng về trạng thái nghỉ
func stop_star_gain() -> void:
	_gain_active = false
	for player in [vfx_anim, arrive_anim]:
		var anim := player as AnimationPlayer
		if anim == null:
			continue
		anim.stop()
		if anim.has_animation(&"RESET"):
			anim.play(&"RESET")
			anim.seek(0.0, true)


## Method track của `VfxAnim/fly` gọi khi sao thứ `index` (0..2) chạm Sao lớn
func on_fly_arrived(index: int) -> void:
	if not _gain_active or index >= _gain_count:
		return
	_ticks += 1
	_star_from = _shown
	_star_to = float(mini(_total_from + _ticks, _total_to))
	star_progress = 0.0
	if arrive_anim != null and arrive_anim.has_animation(&"arrive"):
		arrive_anim.stop()
		arrive_anim.play(&"arrive")


## Dây `animation_finished` của `VfxAnim` khai trong scene
func _on_vfx_anim_finished(anim_name: StringName) -> void:
	if anim_name != &"fly" or not _gain_active:
		return
	_star_from = float(_total_to)
	_star_to = _star_from
	star_progress = 1.0
	_gain_active = false
	star_gain_finished.emit()


func _set_star_progress(value: float) -> void:
	star_progress = clampf(value, 0.0, 1.0)
	_shown = lerpf(_star_from, _star_to, star_progress)
	if not _gain_active:
		return
	show_stars(_shown)


# --- Thanh Sao: tỉ lệ đầy khớp với vị trí các chip mốc --------------------------

## Đặt ngưỡng Sao các mốc (theo thứ tự chip) — màn Daily gọi sau khi dựng chip
func set_milestone_thresholds(values: Array) -> void:
	_thresholds.clear()
	for v in values:
		_thresholds.append(int(v))
	_chip_fractions.clear()
	if milestones_host is Container and not (milestones_host as Container).sort_children.is_connected(_on_host_sorted):
		(milestones_host as Container).sort_children.connect(_on_host_sorted)
	refresh_bar.call_deferred()


## Hiện `stars` Sao: chữ trên Sao lớn + độ đầy của thanh (tính theo vị trí chip, không tuyến tính)
func show_stars(stars: float) -> void:
	_stars_shown = stars
	if lbl_star_total != null:
		lbl_star_total.text = str(roundi(stars))
	var fraction := bar_fraction(stars)
	if bar_stars != null:
		bar_stars.min_value = 0.0  # keep-code: khởi tạo thanh Sao (runtime)
		bar_stars.max_value = 1.0  # keep-code: khởi tạo thanh Sao (runtime)
		bar_stars.step = 0.0005  # keep-code: khởi tạo thanh Sao (runtime)
		bar_stars.value = fraction
	if _bar_fx != null:
		_bar_fx.set_fraction(fraction)
	if road != null:
		road.progress = road_progress(stars)


## Bản đường mốc: đặt chip thứ i vào đúng `Slot` thứ i của `road` (tâm chip = tâm slot) và
## chọn bên hiển thị bảng phần thưởng (mốc nằm nửa phải → bảng bên phải, ngược lại bên trái)
func place_chips() -> void:
	if road == null or road.slots_host == null or milestones_host == null:
		return
	var slots := road.slots_host.get_children()
	var chips: Array[Control] = []
	for child in milestones_host.get_children():
		var chip := child as Control
		if chip != null and not chip.is_queued_for_deletion():
			chips.append(chip)
	var half := road.size.x * 0.5
	for i in mini(chips.size(), slots.size()):
		var slot := slots[i] as Control
		var chip := chips[i]
		var sz := chip.size.max(chip.get_combined_minimum_size())
		chip.size = sz
		chip.position = slot.position - sz * 0.5
		if chip is DailyMilestoneChip:
			if tag_vertical:
				# Chip ở nửa TRÊN ⇒ bảng nằm dưới; chip ở nửa DƯỚI ⇒ bảng nằm trên (không đè lên nhau)
				(chip as DailyMilestoneChip).set_tag_vertical(slot.position.y < road.size.y * 0.5)
			else:
				(chip as DailyMilestoneChip).set_tag_side(slot.position.x > half)


## Bản đường mốc: mở / đóng bảng lịch tháng (animation `open` / `close` khai trong scene)
func open_month_sheet() -> void:
	if month_sheet == null:
		return
	month_sheet.visible = true  # keep-code: trạng thái theo dữ liệu (runtime)
	if sheet_anim != null and sheet_anim.has_animation(&"open"):
		sheet_anim.stop()
		sheet_anim.play(&"open")


func close_month_sheet() -> void:
	if month_sheet == null or not month_sheet.visible:
		return
	if sheet_anim != null and sheet_anim.has_animation(&"close"):
		sheet_anim.stop()
		sheet_anim.play(&"close")
	else:
		month_sheet.visible = false  # keep-code: trạng thái theo dữ liệu (runtime)


## Dây `pressed` của nền mờ (`MonthSheet/Dim`) khai trong scene: bấm ra ngoài = đóng bảng
func _on_sheet_close_pressed() -> void:
	close_month_sheet()


func is_month_sheet_open() -> bool:
	return month_sheet != null and month_sheet.visible and (sheet_anim == null
		or sheet_anim.current_animation != "close" or not sheet_anim.is_playing())


## Chữ gợi ý dưới sao tổng ("Còn 9★ tới rương 45★")
func set_road_hint(text: String) -> void:
	if lbl_road_hint != null:
		lbl_road_hint.text = text


## Tiến độ theo ĐOẠN của đường (0 = ở sao · i = tới mốc i), nội suy theo ngưỡng Sao của các mốc
func road_progress(stars: float) -> float:
	if _thresholds.is_empty():
		return 0.0
	var prev_t := 0.0
	for i in _thresholds.size():
		var t := float(_thresholds[i])
		if stars <= t:
			if t <= prev_t:
				return float(i + 1)
			return float(i) + clampf((stars - prev_t) / (t - prev_t), 0.0, 1.0)
		prev_t = t
	return float(_thresholds.size())


## Tính lại vị trí các chip (sau khi bố cục/Stage đổi cỡ) rồi áp lại độ đầy của thanh
func refresh_bar() -> void:
	_chip_fractions = _measure_chip_fractions()
	if road != null:
		place_chips()
		road.rebuild()
	show_stars(_stars_shown)


## 0..1 — độ đầy của thanh ứng với `stars` Sao. Nội suy từng đoạn qua TÂM các chip:
## 0 Sao → mép trái · mỗi mốc → đúng tâm chip của nó · mốc cuối → mép phải (thanh đầy khi đủ mốc cuối).
func bar_fraction(stars: float) -> float:
	if _thresholds.is_empty():
		var goal := maxf(bar_stars.max_value if bar_stars != null else 1.0, 1.0)
		return clampf(stars / goal, 0.0, 1.0)
	var fr := _chip_fractions
	var n := _thresholds.size()
	var prev_t := 0.0
	var prev_f := 0.0
	for i in n:
		var t := float(_thresholds[i])
		var f := 1.0 if i == n - 1 else (fr[i] if i < fr.size() else float(i + 1) / float(n))
		if stars <= t:
			if t <= prev_t:
				return f
			return lerpf(prev_f, f, clampf((stars - prev_t) / (t - prev_t), 0.0, 1.0))
		prev_t = t
		prev_f = f
	return 1.0


## Gắn node hiệu ứng thanh (do màn Daily instance) làm con của thanh Sao
func attach_bar_fx(fx: StarBarFx) -> void:
	if bar_stars == null or fx == null:
		return
	_bar_fx = fx
	if fx.get_parent() != bar_stars:
		bar_stars.add_child(fx)
	fx.set_fraction(bar_fraction(_stars_shown))


func has_bar_fx() -> bool:
	return _bar_fx != null and is_instance_valid(_bar_fx) and _bar_fx.get_parent() == bar_stars


## Dọn hiệu ứng thanh (đổi hướng: layout cũ không còn dùng)
func clear_bar_fx() -> void:
	_bar_fx = null


var _chip_fractions: Array[float] = []


func _on_host_sorted() -> void:
	refresh_bar.call_deferred()


func _measure_chip_fractions() -> Array[float]:
	var out: Array[float] = []
	if bar_stars == null or milestones_host == null or bar_stars.size.x <= 0.0:
		return out
	var inv := bar_stars.get_global_transform().affine_inverse()
	for child in milestones_host.get_children():
		var chip := child as Control
		if chip == null or chip.is_queued_for_deletion():
			continue
		var c := inv * (chip.get_global_transform() * (chip.size * 0.5))
		out.append(clampf(c.x / bar_stars.size.x, 0.0, 1.0))
	# Bảo đảm tăng dần (tránh nội suy ngược nếu bố cục chưa ổn định)
	for i in range(1, out.size()):
		out[i] = maxf(out[i], out[i - 1])
	return out


func _flies() -> Array[VfStarFly]:
	var out: Array[VfStarFly] = []
	if fly_host == null:
		return out
	for child in fly_host.get_children():
		var fly := child as VfStarFly
		if fly != null:
			out.append(fly)
	return out
