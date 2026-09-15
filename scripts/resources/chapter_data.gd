class_name ChapterData
extends Resource
## ============================================================================
## Resource: Dữ liệu 1 CHƯƠNG (màn "CHỌN CHƯƠNG" — mockup/chapter_selection.svg)
##
## Chương gom các màn theo `LevelData.chapter`; file này chỉ chứa phần HIỂN THỊ
## + điều kiện mở khóa (số Sao cần có, tính trên TỔNG Sao toàn game).
## Các file: resources/chapters/chapter_<id>.tres (LevelManager quét thư mục này).
## ============================================================================

@export var chapter_id: int = 1
## Tên chương (KHÔNG gồm chữ "CHƯƠNG n:" — UI tự ghép theo ngôn ngữ)
@export var title: String = ""
## Mô tả ngắn 1 dòng dưới tên chương
@export var subtitle: String = ""
## Nhãn kích thước bàn cờ hiện trên chip, ví dụ "3×3 – 5×5" (rỗng = ẩn chip)
@export var size_label: String = ""
## Số SAO cần có để mở khóa chương (0 = mở sẵn, không cần điều kiện)
@export var star_cost: int = 0
## Tên icon riêng của chương (intro/logic/trap/master — rỗng = tự suy theo số chương)
## Icon thật nằm ở assets/images/chapters/icon_<tên>.svg (xem ChapterCard.ICON_KEYS)
@export var icon: String = ""


func is_valid() -> bool:
	return chapter_id > 0 and not title.is_empty()


## Nhãn hiển thị của chip kích thước (rỗng = không hiện)
func display_size() -> String:
	return size_label.strip_edges()


## Tên icon (rỗng = UI tự chọn theo số chương)
func display_icon() -> String:
	return icon.strip_edges()
