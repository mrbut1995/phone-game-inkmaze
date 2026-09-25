class_name ArchivementCard
extends Control
## ============================================================================
## Thẻ 1 danh hiệu trong "Sổ tay thành tựu" (nodes/archivements/card.tscn).
## 4 trạng thái theo mockup/archivement_scene.svg:
##   - ĐÃ ĐẠT     : nền xanh + dải xanh lá, thanh 100%, dấu mộc "ĐÃ ĐẠT +N"
##   - NHẬN THƯỞNG: nền viền vàng, có nút "NHẬN +N"
##   - ĐANG LÀM   : nền xanh nhạt, chip "Thưởng: +N"
##   - ẨN / KHOÁ  : nền xám nét đứt, ổ khoá, tiến độ "??? / ???"
## Nhận dữ liệu đã tính sẵn từ ArchivementManager qua `setup(entry)`.
## ============================================================================

signal claim_requested(id: String)

const BG_CLAIMED := preload("res://assets/images/archivements/card_claimed.svg")
const BG_CLAIMABLE := preload("res://assets/images/archivements/card_claimable.svg")
const BG_PROGRESS := preload("res://assets/images/archivements/card_progress.svg")
const BG_LOCKED := preload("res://assets/images/archivements/card_locked.svg")
## Ổ khoá của thẻ: dùng icon CHUNG ở `assets/images/icons/` (bản riêng trong archivements/ đã gỡ)
const ICON_LOCK := preload("res://assets/images/icons/icon_lock.svg")

const COLOR_CLAIMED := Color(0.18039216, 0.49019608, 0.19607843, 1)   # #2E7D32
const COLOR_CLAIMABLE := Color(0.8509804, 0.46666667, 0.023529412, 1)  # #D97706
const COLOR_PROGRESS := Color(0.23921569, 0.5137255, 0.68235296, 1)    # #3D83AE
const COLOR_LOCKED := Color(0.47843137, 0.56078434, 0.60784316, 1)     # #7A8F9B
const COLOR_DESC := Color(0.44313726, 0.54509807, 0.61960787, 1)
const COLOR_DESC_LOCKED := Color(0.6313726, 0.69411767, 0.7372549, 1)

## Node UI nằm trong CẤU TRÚC: `Panel` (nền thẻ) → `Body` (HBox) → IconRing · Info (VBox) · Side (Stamp/ClaimButton/Chip)
## Mọi thành phần nằm TRONG `Panel` để nền và nội dung luôn khớp nhau khi co giãn.
@onready var bg: NinePatchRect = $Panel
@onready var icon_ring: TextureRect = $Panel/Body/IconRing
@onready var icon: TextureRect = $Panel/Body/IconRing/Icon
@onready var title_label: Label = $Panel/Body/Info/Title
@onready var desc_label: Label = $Panel/Body/Info/Desc
@onready var bar: Control = $Panel/Body/Info/Bar
@onready var bar_track: TextureRect = $Panel/Body/Info/Bar/Track
@onready var bar_fill: TextureRect = $Panel/Body/Info/Bar/Fill
@onready var progress_label: Label = $Panel/Body/Info/Progress
@onready var stamp: Control = $Panel/Body/Side/Stamp
@onready var stamp_state: Label = $Panel/Body/Side/Stamp/State
@onready var stamp_reward: Label = $Panel/Body/Side/Stamp/Reward
@onready var claim_btn: TextureButton = $Panel/Body/Side/ClaimButton
@onready var claim_label: Label = $Panel/Body/Side/ClaimButton/Label
@onready var chip: TextureRect = $Panel/Body/Side/Chip
@onready var chip_label: Label = $Panel/Body/Side/Chip/Label

var _entry: Dictionary = {}
var _pct := 0


func _ready() -> void:
	if claim_btn != null:
		claim_btn.pressed.connect(_on_claim_pressed)
	if stamp_state != null:
		stamp_state.text = tr("STR_ACH_STATE_CLAIMED")
	if chip_label != null:
		chip_label.text = tr("STR_ACH_STATE_LOCKED")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_bar_fill()


## Vạch tiến độ: đo lại mỗi khi thẻ đổi cỡ — thẻ nằm trong CONTAINER nên lúc `setup()`
## bề rộng thanh có thể còn 0 (bố cục chưa dàn xong).
func _apply_bar_fill() -> void:
	if bar == null or bar_fill == null:
		return
	bar_fill.size.x = maxf((bar.size.x - 2.0) * float(_pct) / 100.0, 0.0)


## Vẽ thẻ theo dữ liệu đã tính sẵn của ArchivementManager
func setup(entry: Dictionary) -> void:
	_entry = entry
	var hidden := bool(entry.get("secret_hidden", false))
	var unlocked := bool(entry.get("unlocked", false))
	var claimed := bool(entry.get("claimed", false))
	var claimable := bool(entry.get("claimable", false))
	var coins := int(entry.get("coins", 0))
	var pct := clampi(int(entry.get("pct", 0)), 0, 100)

	# Nền + màu trạng thái
	var state_color := COLOR_PROGRESS
	if hidden:
		bg.texture = BG_LOCKED
		state_color = COLOR_LOCKED
	elif claimed:
		bg.texture = BG_CLAIMED
		state_color = COLOR_CLAIMED
	elif claimable:
		bg.texture = BG_CLAIMABLE
		state_color = COLOR_CLAIMABLE
	else:
		bg.texture = BG_PROGRESS

	icon_ring.modulate = state_color

	# Huy hiệu + tiêu đề + mô tả
	if hidden:
		icon.texture = ICON_LOCK
		title_label.text = tr("STR_ACH_SECRET_TITLE")
		desc_label.text = tr("STR_ACH_SECRET_DESC")
		title_label.modulate = COLOR_LOCKED
		desc_label.modulate = COLOR_DESC_LOCKED
	else:
		icon.texture = entry.get("icon", null)
		title_label.text = str(entry.get("title", ""))
		desc_label.text = str(entry.get("desc", ""))
		title_label.modulate = Color(1, 1, 1, 1)
		desc_label.modulate = COLOR_DESC

	# Thanh tiến độ (bề rộng đo lại trong `_apply_bar_fill()` — xem `_notification`)
	_pct = pct
	_apply_bar_fill()
	if bar_fill != null:
		bar_fill.modulate = state_color
	if bar_track != null:
		bar_track.modulate = Color(1, 1, 1, 0.55) if hidden else Color(1, 1, 1, 1)

	# Dòng tiến độ
	if hidden:
		progress_label.text = tr("STR_ACH_SECRET_PROGRESS")
		progress_label.modulate = COLOR_DESC_LOCKED
	else:
		var progress := int(entry.get("progress", 0))
		var target := int(entry.get("target", 1))
		var unit := str(entry.get("unit", ""))
		if claimed:
			progress_label.text = tr("STR_ACH_PROGRESS_DONE").format([progress, target, unit])
		else:
			progress_label.text = tr("STR_ACH_PROGRESS_FORMAT").format([progress, target, unit])
		progress_label.modulate = state_color

	# Phần thưởng: dấu mộc (đã nhận) · nút nhận (đủ điều kiện) · chip (đang làm / khoá)
	stamp.visible = claimed
	claim_btn.visible = claimable
	chip.visible = not claimed and not claimable
	if claimed:
		stamp_reward.text = "+%d" % coins
	elif claimable:
		claim_label.text = tr("STR_ACH_STATE_CLAIM").format([coins])
	elif chip.visible:
		chip_label.text = tr("STR_ACH_STATE_LOCKED") if hidden \
			else tr("STR_ACH_STATE_REWARD").format([coins])


func _on_claim_pressed() -> void:
	if _entry.is_empty():
		return
	claim_requested.emit(str(_entry.get("id", "")))
