class_name EventTheme
extends Resource
## ============================================================================
## Resource: Cấu hình theme hình ảnh + màu sắc cho một loại sự kiện (Event).
## Mỗi theme = 1 file .tres trong resources/events/themes/.
## ============================================================================

@export var id: StringName = &""

## Gradient nền dọc (2–3 màu từ trên xuống dưới)
@export var bg_stops: PackedColorArray = PackedColorArray()

## Lưới ô ly phủ lên nền: "white" (dùng với nền tối) | "dark" (dùng với nền sáng)
@export var grid_overlay: StringName = &"dark"

## SVG lớp SAU chữ (trăng, kim tự tháp, pháo hoa…)
@export var back_art: Texture2D = null

## SVG lớp TRƯỚC (đồi, tuyết, hàng rào…) — nằm TRƯỚC nền nhưng SAU chữ
@export var front_art: Texture2D = null

## Dịch dọc cả 2 lớp art so với toạ độ vẽ gốc (âm = lên, dương = xuống)
@export var art_offset_y: float = -25.0

## Art NÚT event trên Main (thay cho thẻ) — PNG 192×192, hiển thị scale ~0.3
@export var button_normal: Texture2D = null
@export var button_pressed: Texture2D = null

## Màu nhấn chính (dùng cho tiến độ, chấm chip, điểm nhấn)
@export var accent: Color = Color(0.847, 0.267, 0.267, 1.0)

## Màu nhấn phụ (dùng cho giá trị số trong panel tiến độ)
@export var accent2: Color = Color(0.988, 0.620, 0.043, 1.0)

## Màu chữ tiêu đề
@export var title_color: Color = Color(0.086, 0.227, 0.345, 1.0)

## Màu viền chữ tiêu đề (stroke dày 10px)
@export var title_outline: Color = Color(1.0, 1.0, 1.0, 1.0)

## Màu phụ đề
@export var sub_color: Color = Color(0.443, 0.545, 0.620, 1.0)

## Màu nhãn
@export var label_color: Color = Color(0.086, 0.227, 0.345, 1.0)

## Màu nền panel tiến độ (kèm alpha)
@export var panel_color: Color = Color(1.0, 0.886, 0.886, 0.6)

## Màu viền panel tiến độ
@export var panel_stroke: Color = Color(0.847, 0.267, 0.267, 0.25)

## Màu nền nút CTA
@export var cta_fill: Color = Color(0.847, 0.267, 0.267, 1.0)

## Màu viền nút CTA
@export var cta_stroke: Color = Color(0.631, 0.169, 0.169, 1.0)

## Màu chữ nút CTA
@export var cta_text: Color = Color(1.0, 1.0, 1.0, 1.0)

## Màu nền chip loại sự kiện (độ trong suốt 0.85)
@export var chip_fill: Color = Color(0.847, 0.267, 0.267, 0.85)

## Màu chữ chip
@export var chip_text: Color = Color(1.0, 1.0, 1.0, 1.0)
