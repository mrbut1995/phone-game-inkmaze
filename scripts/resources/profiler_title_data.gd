class_name ProfilerTitleData
extends Resource
## ============================================================================
## Dữ liệu 1 BẬC DANH HIỆU HỒ SƠ (chip cạnh tên trong Profiler) — nguồn cho
## `PlayerProfileManager.title_key()`.
##
## Mỗi bậc là 1 file .tres trong `res://resources/profiler/titles/`
## (giống danh hiệu là .tres trong resources/archivements/) -> PlayerProfileManager
## quét thư mục + sắp theo `min_level`, nên THÊM bậc mới chỉ cần tạo file .tres,
## KHÔNG phải sửa code.
##
## Cấp hồ sơ = 1 + EXP/200 (EXP = AP danh hiệu + Sao×25) — xem EXP_PER_LEVEL.
## ============================================================================

@export var min_level: int = 1                           # cấp tối thiểu để đạt bậc này
@export var name_key: String = ""                        # khoá dịch, vd "STR_PROFILE_TIER_1"


## Hợp lệ để nạp vào catalog (đủ khoá dịch)
func is_valid() -> bool:
	return not name_key.is_empty()
