class_name EventData
extends Resource
## ============================================================================
## Resource: Dữ liệu cấu hình cho 1 Sự kiện (Event).
## Mỗi event = 1 file .tres trong resources/events/.
## Thêm event mới CHỈ cần tạo .tres — KHÔNG cần sửa script (data-driven, §B12 GDD).
## ============================================================================

enum Type {
	SPECIAL_SERIES,  ## Chuỗi màn dùng luật Special
	STANDARD_SERIES, ## Chuỗi màn chuẩn (luật Play)
	DUNGEON,         ## Sự kiện trên Dungeon (hệ số thưởng + mốc tầng)
	LOGIN_STREAK,    ## Đăng nhập/chơi mỗi ngày trong N ngày
	DAILY,           ## Daily Challenge — event ảo ghim đầu danh sách
}

## ID duy nhất, dùng làm khoá lưu & tra chuỗi dịch
@export var id: StringName = &""

@export var type: Type = Type.SPECIAL_SERIES

## Theme hình ảnh + màu sắc của thẻ
@export var theme: EventTheme = null

## Thứ tự sắp xếp trong carousel (nhỏ = đứng trước; Daily luôn đầu bất kể giá trị này)
@export var sort_order: int = 100

## false = ẩn khỏi danh sách (không xuất hiện dù còn hạn)
@export var enabled: bool = true

# ---------------------------------------------------------------------------
# Chuỗi chữ — CHỈ khoá dịch, KHÔNG chữ cứng
# ---------------------------------------------------------------------------
## Nhãn chip loại: "HALLOWEEN", "MÙA ĐÔNG"…
@export var chip_key: StringName = &""

## Dòng tiêu đề 1 (VD: "Đêm Mực")
@export var title_key_1: StringName = &""

## Dòng tiêu đề 2 (VD: "Ma Quái")
@export var title_key_2: StringName = &""

## Phụ đề dòng 1
@export var sub_key_1: StringName = &""

## Phụ đề dòng 2
@export var sub_key_2: StringName = &""

## Đơn vị tiến độ: "chế độ" / "màn" / "tầng" / "ngày" / "thử thách"
@export var unit_key: StringName = &"STR_EVENT_UNIT_LEVELS"

## Nhãn nút CTA: "CHƠI TIẾP", "VÀO HẦM", "NHẬN LÌ XÌ"…
@export var cta_key: StringName = &"STR_EVENT_CTA_PLAY"

# ---------------------------------------------------------------------------
# Thời hạn (UTC ISO-8601 hoặc chuỗi unix; DAILY bỏ qua)
# ---------------------------------------------------------------------------
## VD: "2026-10-31T00:00:00Z" — để trống = chưa bắt đầu hoặc không áp dụng
@export var start_utc: String = ""

## VD: "2026-11-07T00:00:00Z" — để trống = không hết hạn (chỉ dùng cho DAILY)
@export var end_utc: String = ""

# ---------------------------------------------------------------------------
# Nội dung theo loại
# ---------------------------------------------------------------------------
## SPECIAL_SERIES / STANDARD_SERIES: danh sách LevelData (thứ tự chơi)
@export var levels: Array[LevelData] = []

## DUNGEON: hệ số nhân xu mỗi tầng
@export var dungeon_coin_multiplier: float = 1.0

## DUNGEON: các mốc tầng cần đạt [5, 10, 15, 20, 25]
@export var dungeon_milestones: PackedInt32Array = PackedInt32Array()

## LOGIN_STREAK: số ngày liên tiếp cần đăng nhập
@export var login_days_required: int = 0

# ---------------------------------------------------------------------------
# Phần thưởng (tối đa 2 phần thưởng hiển thị trên thẻ)
# ---------------------------------------------------------------------------
@export var rewards: Array[EventReward] = []

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
## Tổng số mốc tiến độ cần đạt (dùng để tính % và hiển thị "x / total")
func total_progress() -> int:
	match type:
		Type.SPECIAL_SERIES, Type.STANDARD_SERIES:
			return levels.size()
		Type.DUNGEON:
			return dungeon_milestones.size()
		Type.LOGIN_STREAK:
			return login_days_required
		Type.DAILY:
			return 3 # 3 thử thách
		_:
			return 1


## Trả true nếu event đang trong thời hạn hoạt động (dùng giờ UTC hiện tại)
## DAILY luôn trả true
func is_active_now(now_unix: int) -> bool:
	if type == Type.DAILY:
		return true
	if not enabled:
		return false
	var start := _parse_utc(start_utc)
	var end := _parse_utc(end_utc)
	if start > 0 and now_unix < start:
		return false
	if end > 0 and now_unix > end:
		return false
	return true


## Số giây còn lại đến khi hết hạn (âm = đã hết hạn; MAX_INT cho DAILY)
func seconds_remaining(now_unix: int) -> int:
	if type == Type.DAILY:
		return 0x7FFFFFFF
	var end := _parse_utc(end_utc)
	if end <= 0:
		return 0x7FFFFFFF
	return end - now_unix


## Kiểm tra cơ bản: thiếu theme / series rỗng / hạn không hợp lệ → false
func is_valid() -> bool:
	if id.is_empty():
		return false
	if theme == null:
		return false
	if type in [Type.SPECIAL_SERIES, Type.STANDARD_SERIES] and levels.is_empty():
		return false
	if not start_utc.is_empty() and not end_utc.is_empty():
		var s := _parse_utc(start_utc)
		var e := _parse_utc(end_utc)
		if s > 0 and e > 0 and e < s:
			return false
	return true


## Parse chuỗi ISO-8601 "YYYY-MM-DDTHH:MM:SSZ" → unix timestamp (0 nếu lỗi)
static func _parse_utc(s: String) -> int:
	if s.is_empty():
		return 0
	# Godot 4: Time.get_unix_time_from_datetime_dict
	var d := Time.get_datetime_dict_from_datetime_string(s, true)
	if d.is_empty():
		# fallback: thử parse như unix int
		if s.is_valid_int():
			return int(s)
		return 0
	return int(Time.get_unix_time_from_datetime_dict(d))
