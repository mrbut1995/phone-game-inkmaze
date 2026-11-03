"""Service: kiểm tra tính hợp lệ của màn chơi trước khi lưu."""

from __future__ import annotations

from dataclasses import dataclass

from ..config import (
    MAX_ID,
    MAX_SIZE,
    MIN_ID,
    MIN_SIZE,
    MODE_IDS,
    MODE_LABELS,
    MODE_WALL_VISIBILITY_OVERRIDE,
    MODES_NEEDING_VISIBLE_WALLS,
    PLAY_MODE_ID,
    REMOVED_MODE_IDS,
    RETIRED_MODE_IDS,
    TOOL_VALUE_KEY,
    mode_edit_spec,
)
from ..models import challenge_rules as chrules
from ..models import missions as chal
from ..models.level import Cell, LevelModel
from . import solver

LEVEL_ERROR = "error"
LEVEL_WARNING = "warning"
LEVEL_INFO = "info"


@dataclass(frozen=True)
class Issue:
    severity: str
    message: str

    @property
    def is_error(self) -> bool:
        return self.severity == LEVEL_ERROR

    def format(self) -> str:
        icon = {"error": "✕", "warning": "!", "info": "·"}.get(self.severity, "·")
        return "%s %s" % (icon, self.message)


# ---------------------------------------------------------------------------
# CHẾ ĐỘ SPECIAL TRÊN MÀN (mode_id khác "play")
# Bên game (scripts/modes/*.gd): màn khai `mode_id` sẽ được chạy bằng chế độ đó TRÊN ĐÚNG bàn này
# (tường + hình dạng board), còn phần dữ liệu riêng của chế độ (mìn · điểm ô · chi phí · mực...)
# do chế độ tự rắc và CỐ ĐỊNH theo level_id (chơi lại y hệt).
# ---------------------------------------------------------------------------
def _validate_mode(level: LevelModel, info: dict) -> list[Issue]:
    """Vấn đề/lưu ý riêng khi màn được gắn 1 chế độ Special."""
    issues: list[Issue] = []
    mode = str(level.mode_id or PLAY_MODE_ID).strip().lower()

    if mode not in MODE_IDS:
        if mode in REMOVED_MODE_IDS:
            issues.append(Issue(
                LEVEL_ERROR,
                "'%s' là chế độ ĐÃ BỊ XOÁ khỏi game — màn này sẽ chạy như Play. Đổi sang 'play', "
                "'challenge' (nếu chỉ cần luật sương mù: chọn luật 'fog_of_war'), 'blind_memory' "
                "hoặc 'wall_builder'." % mode,
            ))
        elif mode in RETIRED_MODE_IDS:
            issues.append(Issue(
                LEVEL_ERROR,
                "'%s' là chế độ BẤT TẬN — KHÔNG dùng được cho màn (game sẽ chơi như Play). "
                "Chọn 'play' hoặc một chế độ Special trong danh sách." % mode,
            ))
        else:
            issues.append(Issue(LEVEL_ERROR, "mode_id không tồn tại: '%s' — game sẽ chơi như Play" % mode))
        return issues

    stats = level.stats()
    hidden = int(stats["hidden_walls"])
    visible = int(stats["visible_walls"])
    issues.append(Issue(LEVEL_INFO, "Màn chạy chế độ SPECIAL: %s" % MODE_LABELS.get(mode, mode)))

    override = MODE_WALL_VISIBILITY_OVERRIDE.get(mode)
    if override == "visible":
        issues.append(Issue(LEVEL_INFO, "Chế độ này ÉP HIỆN toàn bộ tường khi chơi (bỏ qua cờ tường ẩn của màn)"))
    elif override == "hidden":
        issues.append(Issue(LEVEL_INFO, "Chế độ này ÉP ẨN toàn bộ tường khi chơi — số trên ô mới là dữ kiện để suy luận"))

    if mode in MODES_NEEDING_VISIBLE_WALLS:
        if hidden > 0:
            issues.append(Issue(
                LEVEL_WARNING,
                "%d đoạn tường đang ẨN — chế độ %s cần THẤY tường để tính đường (chuyển sang 'Tường hiện')"
                % (hidden, mode),
            ))
        if visible == 0:
            issues.append(Issue(LEVEL_WARNING, "Màn chưa có tường nào — chế độ %s sẽ thành đi thẳng tới F" % mode))


    issues.append(Issue(
        LEVEL_INFO,
        "Ngân sách bước khi chơi chế độ này = max(max_steps của màn, mặc định của chế độ) — hiện %d bước"
        % max(1, int(level.max_steps)),
    ))
    return issues


# ---------------------------------------------------------------------------
# DỮ LIỆU RIÊNG CỦA CHẾ ĐỘ (custom_cell_values) — KIỂU EDIT theo mode_id
# Mỗi chế độ có 1 kiểu edit (xem app/config.py MODE_EDITS): "none" = game tự sinh hết,
# "cell_value" = nhà thiết kế tô từng ô (Ghim mìn · Điểm ô · Chi phí ô).
# ---------------------------------------------------------------------------
def _validate_custom_values(level: LevelModel, info: dict) -> list[Issue]:
    issues: list[Issue] = []
    spec = mode_edit_spec(level.mode_id)
    cells = level.custom_cell_values
    if not cells:
        if spec["is_cell_value"]:
            issues.append(Issue(
                LEVEL_INFO,
                "Chưa tô %s nào — game tự sinh cho MỌI ô (muốn tự đặt thì dùng công cụ %s)" % (
                    spec["tool"].lower(), TOOL_VALUE_KEY),
            ))
        return issues

    if level.custom_raw_unknown:
        issues.append(Issue(
            LEVEL_WARNING,
            "custom_cell_values có phần tool KHÔNG hiểu — tool giữ nguyên chuỗi gốc khi lưu "
            "(giá trị tô thêm trong tool sẽ KHÔNG được ghi)",
        ))

    if not spec["is_cell_value"]:
        issues.append(Issue(
            LEVEL_INFO,
            "%d ô có giá trị riêng nhưng chế độ '%s' không dùng — xoá cho gọn (menu Sửa → Xoá hết giá trị riêng)"
            % (len(cells), spec["mode_id"]),
        ))
        return issues

    low, high = int(spec["min"]), int(spec["max"])
    out_of_range = [(cell, int(value)) for cell, value in cells.items()
                    if not low <= int(value) <= high]
    if out_of_range:
        cell, value = sorted(out_of_range)[0]
        issues.append(Issue(
            LEVEL_WARNING,
            "%d ô có giá trị NGOÀI khoảng %d..%d của chế độ %s (vd ô %d,%d = %d) — game sẽ kẹp về khoảng"
            % (len(out_of_range), low, high, spec["mode_id"], cell[0], cell[1], value),
        ))

    issues.append(Issue(
        LEVEL_INFO,
        "Đã tô %s cho %d ô — các ô còn lại game tự sinh." % (spec["tool"].lower(), len(cells)),
    ))

    # TỔNG THEO ĐƯỜNG ĐI ngắn nhất (chỉ tính các ô ĐÃ TÔ — ô chưa tô sẽ random khi vào game)
    path = info.get("path") or []
    if path and spec["has_sum_field"]:
        step_index = {cell: index for index, cell in enumerate(path)}
        painted_on_path = [cell for cell in path[1:-1] if level.custom_value(cell) > 0]
        if painted_on_path:
            total = sum(level.custom_value(cell) for cell in painted_on_path)
            if spec["path_fill"] == "step":
                # Đi theo bước: giá trị ô phải đủ lớn để đi tới được ô đó
                too_low = [cell for cell in painted_on_path
                           if level.custom_value(cell) < step_index[cell]]
                if too_low:
                    issues.append(Issue(
                        LEVEL_WARNING,
                        "%d ô trên đường ngắn nhất có giá trị quá thấp (nhỏ hơn số bước phải đi để tới ô đó, "
                        "vd ô %d,%d)" % (len(too_low), too_low[0][0], too_low[0][1]),
                    ))
                issues.append(Issue(
                    LEVEL_INFO,
                    "Đã tô giá trị cho %d ô trên đường ngắn nhất — giá trị mỗi ô tối thiểu BẰNG bước đi tới ô đó "
                    "(nên cho dư %d)." % (len(painted_on_path), spec["sum_default"]),
                ))
            else:
                issues.append(Issue(
                    LEVEL_INFO,
                    "Tổng giá trị đường ngắn nhất (chỉ tính %d ô đã tô) = %d." % (len(painted_on_path), total),
                ))
    return issues


# ---------------------------------------------------------------------------
# LUẬT THỬ THÁCH (CHALLENGE) — xem app/models/challenge_rules.py
# Luật chỉ áp dụng khi mode_id = "challenge" (game: scripts/modes/challenge_game_mode.gd).
# Vi phạm luật (hoặc quá hạn) là THUA NGAY; 2 luật "đi trên ô ..." cần màn có ĐƯỜNG hợp lệ.
# ---------------------------------------------------------------------------
def _walk_rule_path(level: LevelModel, walk_number: bool) -> list[Cell] | None:
    """Đường S→F chỉ đi qua ô có số (hoặc chỉ ô KHÔNG số) — S/F luôn được phép.

    Ô "có số" = số tường quanh ô > 0 (đúng như số hiển thị trong game).
    Giống điều kiện sinh màn của chế độ challenge daily bên game.
    """
    def allowed(cell: Cell) -> bool:
        if cell == level.start or cell == level.end:
            return True                      # S/F luôn được phép (chặn 2 đầu thì không bao giờ tới F)
        has_number = level.wall_count(cell) > 0
        return has_number if walk_number else not has_number

    return solver.path_filtered(level, allowed)


def _validate_challenge(level: LevelModel, path_length: int) -> list[Issue]:
    """Kiểm tra LUẬT THỬ THÁCH của màn (LevelData.challenge + challenge_param)."""
    issues: list[Issue] = []
    mode = str(level.mode_id or PLAY_MODE_ID).strip().lower()
    rule = str(level.challenge or "").strip()
    param = int(level.challenge_param)

    if not rule:
        if mode == "challenge":
            issues.append(Issue(
                LEVEL_WARNING,
                "mode_id = 'challenge' nhưng CHƯA chọn luật → game chơi như Play Mode thường "
                "(không có thử thách). Chọn 1 luật ở khối \"Thử thách (Challenge)\".",
            ))
        return issues

    if not chrules.is_valid(rule):
        issues.append(Issue(
            LEVEL_ERROR,
            "Luật thử thách không tồn tại: '%s' — xem danh sách luật trong khối \"Thử thách (Challenge)\"" % rule,
        ))
        return issues

    if mode != "challenge":
        issues.append(Issue(
            LEVEL_WARNING,
            "Luật thử thách '%s' CHỈ áp dụng khi mode_id = 'challenge' — hiện mode_id = '%s' "
            "nên game BỎ QUA luật này" % (rule, mode),
        ))
        return issues

    label = chrules.label(rule)
    unit = chrules.unit(rule)
    if chrules.has_param(rule):
        low, high = chrules.param_bounds(rule)
        if param != 0 and not low <= param <= high:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách \"%s\": tham số %d ngoài khoảng %d..%d" % (label, param, low, high),
            ))
        elif param == 0:
            suggestion = chrules.suggested_param(rule, level.width, level.height,
                                                 level.max_steps, level.difficulty)
            issues.append(Issue(
                LEVEL_INFO,
                "Thử thách \"%s\": tham số 0 = game tự tính (theo màn này ~%d %s)"
                % (label, suggestion, unit),
            ))
        else:
            issues.append(Issue(LEVEL_INFO, "Thử thách \"%s\": %d %s" % (label, param, unit)))
    else:
        issues.append(Issue(LEVEL_INFO, "Thử thách \"%s\"" % label))

    if rule == chrules.MOVE_LIMIT:
        limit = param if param > 0 else max(1, int(level.max_steps))
        if path_length and limit < path_length:
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách \"%s\": %d bước < đường đi ngắn nhất (%d) → không thể thắng"
                % (label, limit, path_length),
            ))
        elif path_length and limit == path_length:
            issues.append(Issue(
                LEVEL_WARNING,
                "Thử thách \"%s\": %d bước ĐÚNG BẰNG đường ngắn nhất (không có dự phòng)"
                % (label, limit),
            ))
    elif rule == chrules.COUNTDOWN and param > 0 and path_length and param < path_length:
        issues.append(Issue(
            LEVEL_WARNING,
            "Thử thách \"%s\": %d giây cho đường %d bước (< 1 giây/bước) — gần như không thể"
            % (label, param, path_length),
        ))
    elif rule == chrules.STEP_TIMER and 0 < param < 4:
        issues.append(Issue(
            LEVEL_WARNING,
            "Thử thách \"%s\": mỗi bước chỉ %d giây — quá gấp với người chơi" % (label, param),
        ))
    elif rule in (chrules.WALK_NUMBER_ONLY, chrules.WALK_EMPTY_ONLY):
        want_number = rule == chrules.WALK_NUMBER_ONLY
        route = _walk_rule_path(level, walk_number=want_number)
        cell_kind = "CÓ số" if want_number else "KHÔNG số"
        if route is None:
            hint = ("vẽ thêm tường quanh các ô trên đường (ô 0 tường quanh nó = ô không số)"
                    if want_number else
                    "cần hành lang các ô trống quanh nó (0 tường) nối S tới F")
            issues.append(Issue(
                LEVEL_ERROR,
                "Thử thách \"%s\": KHÔNG có đường S→F nào chỉ đi qua ô %s → không thể thắng (S/F luôn đi được). "
                "Gợi ý: %s" % (label, cell_kind, hint),
            ))
        else:
            issues.append(Issue(
                LEVEL_INFO,
                "Thử thách \"%s\": có đường hợp lệ %d bước (chỉ qua ô %s)"
                % (label, len(route) - 1, cell_kind),
            ))
    return issues


def validate(level: LevelModel) -> list[Issue]:
    """Trả về danh sách vấn đề (rỗng = hợp lệ hoàn toàn)."""
    issues: list[Issue] = []

    if not MIN_ID <= level.level_id <= MAX_ID:
        issues.append(Issue(LEVEL_ERROR, "level_id phải trong khoảng %d..%d" % (MIN_ID, MAX_ID)))
    if not level.level_title.strip():
        issues.append(Issue(LEVEL_WARNING, "Chưa đặt tên màn (level_title đang trống)"))
    if not (MIN_SIZE <= level.width <= MAX_SIZE and MIN_SIZE <= level.height <= MAX_SIZE):
        issues.append(Issue(LEVEL_ERROR, "Kích thước lưới phải trong khoảng %d..%d" % (MIN_SIZE, MAX_SIZE)))
    if level.active_count() < 2:
        issues.append(Issue(LEVEL_ERROR, "Board phải có ít nhất 2 ô (hiện có %d ô)" % level.active_count()))
    if not level.start_end_ok():
        if not level.is_cell_active(level.start) and level.in_bounds(level.start):
            issues.append(Issue(LEVEL_ERROR, "Điểm S đang nằm ở Ô TRỐNG (ngoài board) - bấm vào ô đó để thêm vào board"))
        if not level.is_cell_active(level.end) and level.in_bounds(level.end):
            issues.append(Issue(LEVEL_ERROR, "Đích F đang nằm ở Ô TRỐNG (ngoài board) - bấm vào ô đó để thêm vào board"))
    if level.max_steps <= 0:
        issues.append(Issue(LEVEL_ERROR, "max_steps phải lớn hơn 0"))
    if level.par_time <= 0:
        issues.append(Issue(LEVEL_ERROR, "par_time phải lớn hơn 0"))

    if not level.in_bounds(level.start):
        issues.append(Issue(LEVEL_ERROR, "Điểm S nằm ngoài lưới"))
    if not level.in_bounds(level.end):
        issues.append(Issue(LEVEL_ERROR, "Điểm F nằm ngoài lưới"))
    if level.start == level.end:
        issues.append(Issue(LEVEL_ERROR, "Điểm S và F đang trùng nhau"))
    if issues and any(issue.is_error for issue in issues):
        return issues

    info = solver.analyze(level)
    if not info["solved"]:
        issues.append(Issue(LEVEL_ERROR, "Không có đường đi từ S tới F (bị tường chặn kín)"))
        return issues

    path_length = int(info["path_length"])
    if level.max_steps < path_length:
        issues.append(Issue(
            LEVEL_ERROR,
            "max_steps (%d) nhỏ hơn đường đi ngắn nhất (%d) -> không thể thắng"
            % (level.max_steps, path_length),
        ))
    elif level.max_steps == path_length:
        issues.append(Issue(LEVEL_WARNING, "max_steps bằng đúng đường đi ngắn nhất (không có dự phòng)"))

    blocked = int(info["blocked_cells"])
    if blocked:
        issues.append(Issue(
            LEVEL_WARNING,
            "%d ô thuộc board KHÔNG tới được từ S (bị tường chặn kín)" % blocked,
        ))

    stats = level.stats()
    if stats["hidden_walls"] == 0:
        issues.append(Issue(LEVEL_INFO, "Màn chưa có tường ẩn nào (toàn bộ tường đều nhìn thấy)"))
    if str(level.mode_id or PLAY_MODE_ID).strip().lower() != PLAY_MODE_ID:
        issues.extend(_validate_mode(level, info))
    issues.extend(_validate_custom_values(level, info))
    issues.extend(_validate_challenge(level, path_length=int(path_length)))
    if int(info["empty_cells"]) > 0:
        issues.append(Issue(
            LEVEL_INFO,
            "Board dạng polyomino: %d/%d ô thuộc board (còn %d ô trống)"
            % (int(info["board_cells"]), level.width * level.height, int(info["empty_cells"])),
        ))

    issues.append(Issue(
        LEVEL_INFO,
        "Đường ngắn nhất %d bước · dư %d bước · %d tường hiện / %d tường ẩn"
        % (path_length, max(0, level.max_steps - path_length), stats["visible_walls"], stats["hidden_walls"]),
    ))
    issues.extend(_validate_locks(level, info))
    issues.extend(validate_missions(level, path_length=int(path_length), info=info))
    return issues


# ---------------------------------------------------------------------------
# Ô KHOÁ + CHÌA KHOÁ — xem LevelModel.lock_cells / key_cells
# Bên game: `MazeData.add_lock` / `add_key` / `get_play_path` (BFS theo cặp ô + tập chìa).
# ---------------------------------------------------------------------------
MAX_LOCK_ID = 30   # game mã hoá tập chìa đã nhặt bằng bit (1 << id), id kẹp 0..30


def _validate_locks(level: LevelModel, info: dict) -> list[Issue]:
    """Kiểm tra ô khoá/chìa: mỗi id khoá phải có chìa, không đè S/F, và vẫn có đường S→F."""
    issues: list[Issue] = []
    locks, keys = level.lock_cells, level.key_cells
    if not locks and not keys:
        return issues

    lock_ids: set[int] = set()
    for x, y, lock_id in locks:
        cell = (int(x), int(y))
        if lock_id not in range(1, MAX_LOCK_ID + 1):
            issues.append(Issue(LEVEL_ERROR, "Ô khoá %d,%d có id %d — id phải trong 1..%d"
                                % (x, y, lock_id, MAX_LOCK_ID)))
        if not level.in_bounds(cell) or not level.is_cell_active(cell):
            issues.append(Issue(LEVEL_ERROR, "Ô khoá %d,%d không thuộc board — game sẽ bỏ qua ô này" % (x, y)))
        elif cell == level.start or cell == level.end:
            issues.append(Issue(LEVEL_ERROR, "Ô khoá không được đặt trên S/F (%d,%d)" % (x, y)))
        lock_ids.add(int(lock_id))

    key_ids: set[int] = set()
    for x, y, key_id in keys:
        cell = (int(x), int(y))
        if not level.in_bounds(cell) or not level.is_cell_active(cell):
            issues.append(Issue(LEVEL_ERROR, "Ô chìa %d,%d không thuộc board — game sẽ bỏ qua ô này" % (x, y)))
        elif cell == level.start:
            issues.append(Issue(LEVEL_ERROR, "Ô chìa không được đặt trên S (%d,%d)" % (x, y)))
        elif level.lock_id_at(cell):
            issues.append(Issue(LEVEL_ERROR, "Ô %d,%d vừa là khoá vừa là chìa — game chỉ nhận ô khoá" % (x, y)))
        key_ids.add(int(key_id))

    for lock_id in sorted(lock_ids - key_ids):
        issues.append(Issue(
            LEVEL_ERROR,
            "Khoá id %d KHÔNG có chìa nào — màn sẽ không thắng được" % lock_id,
        ))
    for key_id in sorted(key_ids - lock_ids):
        issues.append(Issue(
            LEVEL_WARNING,
            "Chìa id %d không mở ô khoá nào — vô dụng (có thể bạn quên đặt ô khoá)" % key_id,
        ))

    # Đường S→F theo trạng thái (ô, tập chìa) — giống `MazeData.get_play_path`
    reachable = min_steps_with_keys(level)
    if not reachable:
        issues.append(Issue(
            LEVEL_ERROR,
            "KHÔNG có đường S→F khi tính ô khoá/chìa — thêm chìa hoặc bỏ bớt ô khoá",
        ))
    elif reachable > 0:
        issues.append(Issue(LEVEL_INFO, "Có đường S→F khi tính ô khoá/chìa (%d bước ít nhất)" % reachable))
    return issues


## BFS theo (ô, tập chìa đã nhặt) — trả về số bước ngắn nhất tới F (0 = không tới được)
def min_steps_with_keys(level: LevelModel) -> int:
    start, end = (int(level.start[0]), int(level.start[1])), (int(level.end[0]), int(level.end[1]))
    locks = {(int(k[0]), int(k[1])): int(k[2]) for k in level.lock_cells}
    keys = {(int(k[0]), int(k[1])): int(k[2]) for k in level.key_cells}
    start_state = (start, 0)
    queue = [start_state]
    dist = {start_state: 0}
    while queue:
        cell, mask = queue.pop(0)
        if cell == end:
            return dist[(cell, mask)]
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nxt = (cell[0] + dx, cell[1] + dy)
            if not level.in_bounds(nxt) or not level.is_cell_active(nxt):
                continue
            if _wall_between(level, cell, nxt):
                continue
            lock_id = locks.get(nxt, 0)
            if lock_id and not (mask & (1 << lock_id)):
                continue
            new_mask = mask
            key_id = keys.get(nxt, 0)
            if key_id:
                new_mask |= 1 << key_id
            state = (nxt, new_mask)
            if state in dist:
                continue
            dist[state] = dist[(cell, mask)] + 1
            queue.append(state)
    return 0


## Có tường giữa 2 ô cạnh nhau không (dùng đúng quy ước chỉ số của `LevelModel.v_index` / `h_index`)
def _wall_between(level: LevelModel, a: Cell, b: Cell) -> bool:
    if a[1] == b[1]:                      # cùng hàng -> tường DỌC
        return level.has_wall(("v", max(a[0], b[0]), a[1]))
    return level.has_wall(("h", a[0], max(a[1], b[1])))


# ---------------------------------------------------------------------------
# NHIỆM VỤ (tối đa 3 / màn) — xem app/models/missions.py
# ---------------------------------------------------------------------------
def validate_missions(
    level: LevelModel,
    path_length: int = 0,
    info: dict | None = None,
) -> list[Issue]:
    """Kiểm tra danh sách nhiệm vụ của màn (rỗng = dùng mặc định của game)."""
    issues: list[Issue] = []
    items = list(level.missions)

    if len(items) > chal.MAX_PER_LEVEL:
        issues.append(Issue(
            LEVEL_ERROR,
            "Mỗi màn chỉ được TỐI ĐA %d nhiệm vụ (đang có %d)" % (chal.MAX_PER_LEVEL, len(items)),
        ))
    if not items:
        issues.append(Issue(
            LEVEL_INFO,
            "Chưa chọn nhiệm vụ -> game dùng 3 nhiệm vụ mặc định (không đâm tường · %d bước · %d giây)"
            % (max(1, int(level.max_steps)), max(5, int(round(level.par_time)))),
        ))
        return issues

    types = [str(item[0]) for item in items]
    for type_id in types:
        if not chal.is_valid(type_id):
            issues.append(Issue(LEVEL_ERROR, "Loại nhiệm vụ không tồn tại: '%s'" % type_id))
    for type_id in sorted(set(types)):
        if list(types).count(type_id) > 1:
            issues.append(Issue(LEVEL_WARNING, "Nhiệm vụ '%s' bị lặp lại" % chal.label(type_id)))

    if chal.ONLY_NUMBERED in types and chal.AVOID_NUMBERED in types:
        issues.append(Issue(
            LEVEL_ERROR,
            "Hai nhiệm vụ 'chỉ đi vào ô CÓ số' và 'không đi vào ô CÓ số' mâu thuẫn nhau",
        ))

    numbers = _numbered_cells(level)
    total_number = sum(numbers.values())
    board_cells = max(1, level.active_count())
    max_percent = 100
    min_percent = int((100.0 * max(path_length, 1) + board_cells - 1) // board_cells)

    if (chal.ONLY_NUMBERED in types or chal.AVOID_NUMBERED in types or _uses_sum(types)) and not numbers:
        issues.append(Issue(
            LEVEL_WARNING,
            "Màn không có ô nào hiện số -> nhiệm vụ liên quan tới số rất khó đạt",
        ))

    if (chal.VISIT_ALL in types or chal.VISIT_ALL_NUMBERED in types) and info is not None:
        blocked = int(info.get("blocked_cells", 0))
        if chal.VISIT_ALL in types and blocked:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ 'đi qua hết mọi ô' không thể đạt: %d ô thuộc board không tới được" % blocked,
            ))
    if chal.VISIT_ALL in types and chal.NO_REVISIT in types:
        issues.append(Issue(
            LEVEL_WARNING,
            "'đi hết mọi ô' + 'không đi đè' cần đường đi Hamilton — hãy chơi thử để chắc chắn có lời giải",
        ))

    for index, (type_id, param) in enumerate(items):
        if not chal.is_valid(type_id):
            continue
        label = chal.label(type_id)
        if not chal.has_param(type_id):
            continue
        low, high = chal.param_bounds(type_id)
        if param < low or param > high:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ %d (%s): tham số %d ngoài khoảng %d..%d" % (index + 1, label, param, low, high),
            ))
            continue

        kind = chal.param_kind(type_id)
        if type_id == chal.STEPS_MAX and path_length and param < path_length:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ %d (%s): %d bước < đường đi ngắn nhất (%d) -> không thể đạt"
                % (index + 1, label, param, path_length),
            ))
        elif type_id == chal.LEN_MAX_PERCENT and param < min_percent:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ %d (%s): tối đa %d%% nhưng đường ngắn nhất đã cần %d%% số ô"
                % (index + 1, label, param, min_percent),
            ))
        elif type_id == chal.LEN_MIN_PERCENT and param > max_percent:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ %d (%s): tối thiểu %d%% > 100%%" % (index + 1, label, param),
            ))
        elif type_id == chal.SUM_LT and param <= 0:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ %d (%s): tổng luôn >= 0 nên N phải > 0" % (index + 1, label),
            ))
        elif type_id == chal.SUM_GT and param > 0 and param >= total_number:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ %d (%s): N = %d >= tổng số lớn nhất có thể (%d) -> không thể đạt"
                % (index + 1, label, param, total_number),
            ))
        elif type_id == chal.SUM_GE and param > 0 and param > total_number:
            issues.append(Issue(
                LEVEL_ERROR,
                "Nhiệm vụ %d (%s): N = %d > tổng số lớn nhất có thể (%d) -> không thể đạt"
                % (index + 1, label, param, total_number),
            ))
        elif kind == chal.PARAM_PERCENT:
            issues.append(Issue(
                LEVEL_INFO,
                "Nhiệm vụ %d (%s): đường ngắn nhất chiếm %d%% số ô" % (index + 1, label, min_percent),
            ))

    if len(items) < chal.MAX_PER_LEVEL:
        issues.append(Issue(
            LEVEL_INFO,
            "Màn có %d nhiệm vụ -> tối đa %d Sao cho màn này" % (len(items), len(items)),
        ))
    else:
        issues.append(Issue(
            LEVEL_INFO,
            "3 nhiệm vụ: %s" % " · ".join(chal.label(str(item[0])) for item in items),
        ))
    return issues


# ---------------------------------------------------------------------------
def _uses_sum(types: list[str]) -> bool:
    return any(t in (chal.SUM_LT, chal.SUM_LE, chal.SUM_GT, chal.SUM_GE) for t in types)


## Ô có số trên board -> {cell: số} (số = số tường quanh ô, giống số hiển thị trong game)
## S/F không tính (trong game 2 ô này hiện chữ S/F).
def _numbered_cells(level: LevelModel) -> dict:
    out: dict = {}
    for y in range(level.height):
        for x in range(level.width):
            cell = (x, y)
            if not level.is_cell_active(cell) or cell == level.start or cell == level.end:
                continue
            count = level.wall_count(cell)
            if count > 0:
                out[cell] = count
    return out


def has_errors(issues: list[Issue]) -> bool:
    return any(issue.is_error for issue in issues)


def summary_line(issues: list[Issue]) -> str:
    errors = sum(1 for i in issues if i.severity == LEVEL_ERROR)
    warnings = sum(1 for i in issues if i.severity == LEVEL_WARNING)
    if errors:
        return "%d lỗi · %d cảnh báo" % (errors, warnings)
    if warnings:
        return "Hợp lệ · %d cảnh báo" % warnings
    return "Hợp lệ"
