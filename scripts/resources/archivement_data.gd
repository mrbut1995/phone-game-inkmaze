class_name ArchivementData
extends Resource
## ============================================================================
## Dữ liệu 1 DANH HIỆU (Thành tựu) — nguồn cho "Sổ tay thành tựu" (scenes/archivement.tscn).
##
## Mỗi danh hiệu là 1 file .tres trong `res://resources/archivements/` (giống màn chơi
## là .tres trong resources/levels/) -> ArchivementManager quét thư mục để nạp danh sách,
## nên THÊM danh hiệu mới chỉ cần tạo file .tres, không phải sửa code.
##
## Tiến trình: ArchivementManager đo số liệu theo khoá `stat` rồi so với `target`:
##   - progress >= target  -> ĐÃ ĐẠT (mở khoá danh hiệu)
##   - đã đạt + chưa nhận  -> có thể bấm NHẬN (cộng `reward_coins` xu, cộng `points` AP)
## ============================================================================

@export var id: String = ""                              # duy nhất, vd "lv_clear_10"
@export_enum("levels", "dungeon", "daily", "special")
var category: String = "levels"                          # tab phân loại trong Sổ tay
@export var title: String = ""                           # tiêu đề (mặc định tiếng Việt)
@export_multiline var description: String = ""           # mô tả điều kiện
@export var title_key: String = ""                       # có khoá -> dùng tr(title_key)
@export var desc_key: String = ""                        # có khoá -> dùng tr(desc_key)
@export var icon: Texture2D = null                       # huy hiệu (assets/images/icons/...)
@export var stat: String = ""                            # khoá số liệu (xem ArchivementManager)
@export var target: int = 1                              # mốc cần đạt
@export var unit: String = ""                            # đơn vị ở dòng tiến độ: "Màn", "Tầng", "Ngày"...
@export var reward_coins: int = 50                       # thưởng xu khi bấm NHẬN
@export var points: int = 10                             # điểm danh hiệu (AP)
@export var secret: bool = false                         # danh hiệu ẩn: khoá nội dung tới khi đạt


## Tiêu đề đã dịch (dùng title_key nếu có, không thì lấy title)
func display_title() -> String:
	if not title_key.is_empty():
		return tr(title_key)
	return title


## Mô tả đã dịch
func display_description() -> String:
	if not desc_key.is_empty():
		return tr(desc_key)
	return description


## Id hợp lệ để dùng làm khoá lưu trữ / tra cứu
func is_valid() -> bool:
	return not id.is_empty() and not stat.is_empty() and target > 0
