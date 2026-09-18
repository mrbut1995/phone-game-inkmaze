class_name ChallengeTypes
extends RefCounted
## ============================================================================
## Registry: toàn bộ LOẠI THỬ THÁCH (challenge) mà game hỗ trợ.
##
## Mỗi màn (LevelData) gắn TỐI ĐA 3 thử thách: `challenge_types[i]` + `challenge_params[i]`
## (mảng song song). Màn cũ không có dữ liệu -> dùng 3 thử thách mặc định (DEFAULTS).
##
## Nhóm thử thách:
##   A. Mặc định (màn nào cũng có sẵn nếu không chỉnh):
##        no_wall · steps_max · time_max
##   B. Ô / đường đi:
##        only_numbered · avoid_numbered · no_revisit · visit_all · visit_all_numbered
##   C. Độ dài đường đi (% số ô của board):
##        len_min_percent · len_max_percent
##   D. Tổng số trên các ô đã đi:
##        sum_lt · sum_le · sum_gt · sum_ge
##   E. Cách chơi (công cụ):
##        no_hint · no_undo
##   F. Riêng Wall Builder:
##        no_wrong_submit (gửi đúng ngay lần GỬI đầu tiên)
##
## Xem Number_Maze_Game_Design.md (mục 3.1) và docs của tool Level Designer.
## ============================================================================

const MAX_PER_LEVEL := 3

const NO_WALL := "no_wall"
const STEPS_MAX := "steps_max"
const TIME_MAX := "time_max"
const ONLY_NUMBERED := "only_numbered"
const AVOID_NUMBERED := "avoid_numbered"
const NO_REVISIT := "no_revisit"
const VISIT_ALL := "visit_all"
const VISIT_ALL_NUMBERED := "visit_all_numbered"
const LEN_MIN_PERCENT := "len_min_percent"
const LEN_MAX_PERCENT := "len_max_percent"
const SUM_LT := "sum_lt"
const SUM_LE := "sum_le"
const SUM_GT := "sum_gt"
const SUM_GE := "sum_ge"
const NO_HINT := "no_hint"
const NO_UNDO := "no_undo"
const NO_WRONG_SUBMIT := "no_wrong_submit"

## 3 thử thách mặc định (màn cũ / màn chưa chọn gì)
const DEFAULTS := [NO_WALL, STEPS_MAX, TIME_MAX]

## Đơn vị của tham số (để tool hiển thị nhãn cho đúng)
const PARAM_NONE := ""
const PARAM_STEPS := "steps"
const PARAM_SECONDS := "seconds"
const PARAM_PERCENT := "percent"
const PARAM_SUM := "sum"

## Thứ tự hiển thị trong tool
const ORDER := [
	NO_WALL,
	STEPS_MAX,
	TIME_MAX,
	ONLY_NUMBERED,
	AVOID_NUMBERED,
	NO_REVISIT,
	VISIT_ALL,
	VISIT_ALL_NUMBERED,
	LEN_MIN_PERCENT,
	LEN_MAX_PERCENT,
	SUM_LT,
	SUM_LE,
	SUM_GT,
	SUM_GE,
	NO_HINT,
	NO_UNDO,
	NO_WRONG_SUBMIT,
]

## id -> { key: khoá chuỗi hiển thị · param: đơn vị tham số · unit: nhãn đơn vị }
const INFO := {
	NO_WALL: {"key": "STR_CHALLENGE_NO_WALL", "param": PARAM_NONE, "unit": ""},
	STEPS_MAX: {"key": "STR_CHALLENGE_STEPS", "param": PARAM_STEPS, "unit": "bước"},
	TIME_MAX: {"key": "STR_CHALLENGE_TIME", "param": PARAM_SECONDS, "unit": "giây"},
	ONLY_NUMBERED: {"key": "STR_CHALLENGE_ONLY_NUMBERED", "param": PARAM_NONE, "unit": ""},
	AVOID_NUMBERED: {"key": "STR_CHALLENGE_AVOID_NUMBERED", "param": PARAM_NONE, "unit": ""},
	NO_REVISIT: {"key": "STR_CHALLENGE_NO_REVISIT", "param": PARAM_NONE, "unit": ""},
	VISIT_ALL: {"key": "STR_CHALLENGE_VISIT_ALL", "param": PARAM_NONE, "unit": ""},
	VISIT_ALL_NUMBERED: {"key": "STR_CHALLENGE_VISIT_ALL_NUMBERED", "param": PARAM_NONE, "unit": ""},
	LEN_MIN_PERCENT: {"key": "STR_CHALLENGE_LEN_MIN", "param": PARAM_PERCENT, "unit": "%"},
	LEN_MAX_PERCENT: {"key": "STR_CHALLENGE_LEN_MAX", "param": PARAM_PERCENT, "unit": "%"},
	SUM_LT: {"key": "STR_CHALLENGE_SUM_LT", "param": PARAM_SUM, "unit": ""},
	SUM_LE: {"key": "STR_CHALLENGE_SUM_LE", "param": PARAM_SUM, "unit": ""},
	SUM_GT: {"key": "STR_CHALLENGE_SUM_GT", "param": PARAM_SUM, "unit": ""},
	SUM_GE: {"key": "STR_CHALLENGE_SUM_GE", "param": PARAM_SUM, "unit": ""},
	NO_HINT: {"key": "STR_CHALLENGE_NO_HINT", "param": PARAM_NONE, "unit": ""},
	NO_UNDO: {"key": "STR_CHALLENGE_NO_UNDO", "param": PARAM_NONE, "unit": ""},
	NO_WRONG_SUBMIT: {"key": "STR_CHALLENGE_NO_WRONG_SUBMIT", "param": PARAM_NONE, "unit": ""},
}

## Thử thách chưa cần tham số
const NO_PARAM_TYPES := [
	NO_WALL,
	ONLY_NUMBERED,
	AVOID_NUMBERED,
	NO_REVISIT,
	VISIT_ALL,
	VISIT_ALL_NUMBERED,
	NO_HINT,
	NO_UNDO,
	NO_WRONG_SUBMIT,
]

## Giá trị tham số mặc định khi tool/game tự sinh
const PARAM_DEFAULT := {
	PARAM_STEPS: 15,
	PARAM_SECONDS: 45,
	PARAM_PERCENT: 50,
	PARAM_SUM: 20,
}


static func is_valid(type_id: String) -> bool:
	return INFO.has(type_id)


static func has_param(type_id: String) -> bool:
	return str(INFO.get(type_id, {}).get("param", PARAM_NONE)) != PARAM_NONE


static func param_kind(type_id: String) -> String:
	return str(INFO.get(type_id, {}).get("param", PARAM_NONE))


static func unit(type_id: String) -> String:
	return str(INFO.get(type_id, {}).get("unit", ""))


static func label_key(type_id: String) -> String:
	return str(INFO.get(type_id, {}).get("key", ""))


## Tiêu đề tiếng Việt cho tool (không cần dịch)
static func tool_label(type_id: String) -> String:
	match type_id:
		NO_WALL:
			return "Không đâm vào tường vô hình"
		STEPS_MAX:
			return "Đi không quá N bước"
		TIME_MAX:
			return "Về đích dưới N giây"
		ONLY_NUMBERED:
			return "Chỉ đi vào ô CÓ số"
		AVOID_NUMBERED:
			return "Không đi vào ô CÓ số"
		NO_REVISIT:
			return "Không đi đè lên đường đã đi"
		VISIT_ALL:
			return "Đi qua hết mọi ô của board"
		VISIT_ALL_NUMBERED:
			return "Đi qua hết mọi ô CÓ số"
		LEN_MIN_PERCENT:
			return "Đi tối thiểu N% số ô"
		LEN_MAX_PERCENT:
			return "Đi tối đa N% số ô"
		SUM_LT:
			return "Tổng số trên đường đi < N"
		SUM_LE:
			return "Tổng số trên đường đi ≤ N"
		SUM_GT:
			return "Tổng số trên đường đi > N"
		SUM_GE:
			return "Tổng số trên đường đi ≥ N"
		NO_HINT:
			return "Không dùng gợi ý"
		NO_UNDO:
			return "Không dùng hoàn tác"
		_:
			return type_id


## Danh sách 3 thử thách mặc định suy ra từ dữ liệu màn (giữ hành vi cũ)
static func defaults_for(design_steps: int, time_limit: float) -> Array:
	return [
		{"type": NO_WALL, "param": 0},
		{"type": STEPS_MAX, "param": maxi(design_steps, 1)},
		{"type": TIME_MAX, "param": int(round(time_limit))},
	]
