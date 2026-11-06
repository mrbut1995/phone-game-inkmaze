class_name SaveBackend
extends RefCounted
## ============================================================================
## Interface: Backend lưu trữ dữ liệu người chơi.
##
## SaveManager chỉ làm việc với lớp trừu tượng này, nhờ vậy có thể đổi nơi lưu
## mà không phải sửa bất kỳ manager nào khác:
##   - LocalSaveBackend      : lưu máy (đang dùng)
##   - PlayGamesSaveBackend  : Google Play Games Saved Games (Snapshots) - TODO
##
## Backend cloud cần hỗ trợ thao tác bất đồng bộ; khi đó `load_data`/`save_data`
## có thể trả về dữ liệu rỗng/false trong lúc chờ và phát tín hiệu qua SaveManager.
## ============================================================================


## Khoá định danh backend ("local", "play_games", ...)
func id() -> String:
	return "base"


## Tên hiển thị cho UI cài đặt
func display_name() -> String:
	return "Base"


## Backend có dùng được ngay bây giờ không (đã đăng nhập / đã cài plugin)
func is_available() -> bool:
	return false


## Có phải lưu trên đám mây (đồng bộ nhiều thiết bị) không
func supports_cloud() -> bool:
	return false


## Đọc toàn bộ blob dữ liệu người chơi (rỗng nếu chưa có gì)
func load_data() -> Dictionary:
	return {}


## Ghi toàn bộ blob dữ liệu người chơi
func save_data(_data: Dictionary) -> bool:
	return false


## Xoá dữ liệu đã lưu trên backend này
func clear_data() -> bool:
	return false
