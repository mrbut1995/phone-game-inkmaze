class_name AvatarData
extends Resource
## ============================================================================
## Dữ liệu 1 AVATAR của hồ sơ người chơi (Profiler) — nguồn cho popup
## "DIỆN MẠO HỒ SƠ" (tab AVATAR).
##
## Mỗi avatar là 1 file .tres trong `res://resources/profiler/avatars/` (giống
## danh hiệu là .tres trong resources/archivements/) -> PlayerProfileManager
## quét thư mục để nạp danh sách, nên THÊM avatar mới chỉ cần tạo file .tres,
## KHÔNG phải sửa code.
##
## · id   = khoá lưu save — KHÔNG đổi sau khi phát hành
## · icon = texture trong assets/images-png/avatars/
## · price = giá mua bằng Xu mực; 0 = tặng sẵn lúc mở hồ sơ
## · lock_stat / lock_value = khoá theo mốc thành tích (points / daily_streak /
##   dungeon_best_floor); rỗng = không khoá mốc
## ============================================================================

@export var id: String = ""                              # duy nhất, vd "avatar_boy_kid"
@export var name_key: String = ""                        # khoá dịch, vd "STR_AVATAR_BOY_KID"
@export var icon: Texture2D = null                       # ảnh đại diện (240×240)
@export var price: int = 0                               # giá Xu mực (0 = tặng sẵn)
@export var lock_stat: String = ""                       # khoá mốc: "points" / "daily_streak" / "dungeon_best_floor"
@export var lock_value: int = 0                          # mốc cần đạt


## Hợp lệ để nạp vào catalog (đủ id + khoá dịch + icon)
func is_valid() -> bool:
	return not id.is_empty() and not name_key.is_empty() and icon != null
