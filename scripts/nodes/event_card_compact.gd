class_name EventCardCompact
extends EventCard
## ============================================================================
## Node: EventCardCompact — thẻ SỰ KIỆN GỌN cho Main gộp (nodes/main/event_card_compact.tscn).
## Dùng lại 100% logic `EventCard` (theme, chip, đếm ngược, tiến độ, CTA) — chỉ khác BỐ CỤC:
## thẻ ngang (tỉ lệ ~1.26) thay vì thẻ dọc 0.8, cao ~150 px thay vì 270 px.
##
## Cách làm: art gốc của mọi event có cùng khuôn 340×504 (cảnh phía trên, mảng "đồi/sàn" nền
## chữ từ y≈242 trở xuống). Thẻ gọn chỉ hiện CỬA SỔ CẮT [crop_top, crop_top + crop_height]
## của art đó (mặc định 60→330 = cảnh + dải đầu của mảng nền chữ), KHÔNG co méo.
## Chữ (tiêu đề 2 dòng) + nút CTA nằm trong dải nền chữ; khung tiến độ/phần thưởng bị ẩn
## (xem chi tiết ở màn Event).
## ============================================================================

const ART_SIZE := Vector2(340.0, 504.0)

## Cửa sổ cắt theo toạ độ art gốc (px). Khớp ratio của thẻ: ART_SIZE.x / crop_height.
@export var crop_top := 60.0
@export var crop_height := 270.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_art.call_deferred()


## Theme áp art + vị trí gốc ⇒ đặt lại theo cửa sổ cắt
func _paint_background(t: EventTheme, bg_gradient: ColorRect, back: TextureRect,
		front: NinePatchRect) -> void:
	super(t, bg_gradient, back, front)
	_layout_art()


func _layout_art() -> void:
	if back_art == null:
		return
	var host := back_art.get_parent() as Control
	if host == null or host.size.x <= 0.0:
		return
	var k := host.size.x / ART_SIZE.x
	for art in [back_art, front_art]:
		if art != null:
			art.position = Vector2(0.0, -crop_top * k)
			art.size = ART_SIZE * k
