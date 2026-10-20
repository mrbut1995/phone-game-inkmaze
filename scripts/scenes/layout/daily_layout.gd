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
@export var milestones_host: HBoxContainer = null

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
	if bar_stars != null:
		bar_stars.step = 0.01
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
	if bar_stars != null:
		bar_stars.value = _shown
	if lbl_star_total != null:
		lbl_star_total.text = str(roundi(_shown))


func _flies() -> Array[VfStarFly]:
	var out: Array[VfStarFly] = []
	if fly_host == null:
		return out
	for child in fly_host.get_children():
		var fly := child as VfStarFly
		if fly != null:
			out.append(fly)
	return out
