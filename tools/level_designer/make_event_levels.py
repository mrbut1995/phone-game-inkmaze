"""Sinh MÀN CHƠI RIÊNG cho từng SỰ KIỆN (chuỗi màn tạo sẵn) — có Ô KHOÁ + CHÌA.

Chạy:  cd tools/level_designer && python make_event_levels.py [--dry-run] [--only autumn,tomb]
Ghi:   data/levels/events/<event>/level_<base+i>.tres  (+ cập nhật danh sách levels trong data/events/<event>.tres)

Mỗi màn: mê cung HOÀN HẢO (1 đường duy nhất, sinh bằng DFS ngẫu nhiên, seed cố định theo event/số thứ tự
⇒ chạy lại ra đúng màn cũ) · tỉ lệ tường ẨN tăng dần · từ nửa sau chuỗi có 1–2 cặp khoá/chìa.
Chìa luôn nằm trên NHÁNH CỤT tới được mà không phải đi qua chính ô khoá → bắt buộc đi vòng lấy chìa.
Mỗi màn qua validator (không lỗi) và max_steps = số bước ít nhất (tính cả khoá) + dự phòng.
"""
from __future__ import annotations
import random, re, sys
from pathlib import Path
from collections import deque

APP = Path(__file__).resolve().parent
sys.path.insert(0, str(APP))
from app.models.level import LevelModel          # noqa: E402
from app.services import tres_io, validator       # noqa: E402

ROOT = APP.parents[1]   # gốc project (chứa project.godot)

# event: (id đầu, tên hiển thị, [(w, h, độ khó, tỉ lệ tường ẩn, dự phòng bước, số cặp khoá)])
def ramp(n, sizes, locks_from):
    out = []
    for i in range(n):
        w, h = sizes[min(i * len(sizes) // n, len(sizes) - 1)]
        t = i / max(n - 1, 1)
        diff = "easy" if t < 0.34 else ("medium" if t < 0.75 else "hard")
        hidden = round(0.25 + 0.5 * t, 2)
        extra = 4 if diff == "easy" else (3 if diff == "medium" else 2)
        locks = 0 if i < locks_from else (1 if t < 0.85 else 2)
        out.append((w, h, diff, hidden, extra, locks))
    return out

S3 = [(3, 3), (4, 3), (4, 4)]
EVENTS = {
    "halloween":   (1000, "Halloween",   ramp(5, [(3, 3), (4, 4), (5, 4)], 3)),
    "mansion":     (1100, "Mansion",     ramp(6, [(3, 3), (4, 4), (5, 5)], 2)),
    "tomb":        (1200, "Tomb",        ramp(4, [(3, 3), (4, 4), (5, 4)], 2)),
    "april":       (1300, "April",       ramp(6, [(3, 3), (4, 4), (5, 5)], 3)),
    "winter":      (1400, "Winter",      ramp(10, [(3, 3), (4, 4), (5, 5), (6, 5)], 4)),
    "anniversary": (1500, "Anniversary", ramp(3, S3, 1)),
    "autumn":      (1600, "Autumn",      ramp(3, S3, 1)),
    "easter":      (1700, "Easter",      ramp(3, S3, 1)),
    "new_year":    (1800, "New Year",    ramp(3, S3, 1)),
    "spring":      (1900, "Spring",      ramp(3, S3, 1)),
    "summer":      (2000, "Summer",      ramp(3, S3, 1)),
    "thanksgiving": (2100, "Thanksgiving", ramp(3, S3, 1)),
    "valentine":   (2200, "Valentine",   ramp(3, S3, 1)),
}
DIRS = ((1, 0), (-1, 0), (0, 1), (0, -1))


def edge(a, b):
    (x, y), (nx, ny) = a, b
    if ny == y:
        return ("v", max(x, nx), y)
    return ("h", x, max(y, ny))


def carve(w, h, rng):
    """Cây khung ngẫu nhiên (DFS) -> tập cạnh mở."""
    seen = {(rng.randrange(w), rng.randrange(h))}
    stack = list(seen)
    opened = set()
    while stack:
        c = stack[-1]
        nxt = [(c[0] + dx, c[1] + dy) for dx, dy in DIRS
               if 0 <= c[0] + dx < w and 0 <= c[1] + dy < h and (c[0] + dx, c[1] + dy) not in seen]
        if not nxt:
            stack.pop()
            continue
        n = rng.choice(nxt)
        seen.add(n)
        opened.add(edge(c, n))
        stack.append(n)
    return opened


def bfs(level, src, blocked=frozenset()):
    dist, prev, q = {src: 0}, {src: None}, deque([src])
    while q:
        c = q.popleft()
        for dx, dy in DIRS:
            n = (c[0] + dx, c[1] + dy)
            if n in dist or n in blocked or not level.in_bounds(n) or not level.is_cell_active(n):
                continue
            if level.has_wall(edge(c, n)):
                continue
            dist[n], prev[n] = dist[c] + 1, c
            q.append(n)
    return dist, prev


def build(event, idx, base, name, spec, seed_salt=0):
    w, h, diff, hidden, extra, nlocks = spec
    for attempt in range(400):
        rng = random.Random(f"{event}:{idx}:{seed_salt}:{attempt}")
        lv = LevelModel(level_id=base + idx, level_title=f"{name} · {idx + 1}", chapter=0,
                        difficulty=diff, width=w, height=h)
        lv.reset_walls()
        opened = carve(w, h, rng)
        for ref in lv.iter_walls():
            if lv.is_outline(ref):
                continue
            if ref not in opened:
                lv.set_wall(ref, True, rng.random() >= hidden)   # True = hiện
        # S ở 1 góc, F = ô xa nhất
        lv.start = rng.choice([(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)])
        dist, prev = bfs(lv, lv.start)
        far = max(dist.values())
        lv.end = rng.choice([c for c, d in dist.items() if d == far])
        path, c = [], lv.end
        while c is not None:
            path.append(c)
            c = prev[c]
        path.reverse()
        if len(path) < w + h - 1:
            continue
        lv.lock_cells, lv.key_cells = [], []
        ok = True
        mid = path[1:-1]
        used = {lv.start, lv.end}
        for k in range(1, nlocks + 1):
            # khoá k nằm ở khoảng k/(nlocks+1) của đường
            lo = int(len(mid) * (k - 1) / nlocks)
            hi = max(lo + 1, int(len(mid) * k / nlocks))
            cand = [c for c in mid[lo:hi] if c not in used]
            if not cand:
                ok = False
                break
            lock = rng.choice(cand)
            # vùng tới được từ S khi các khoá CHƯA mở (kể cả khoá trước đã có chìa → coi khoá trước là mở)
            blocked = {(x, y) for x, y, i in lv.lock_cells if i >= k} | {lock}
            blocked -= {(x, y) for x, y, i in lv.lock_cells if i < k}
            reach, _ = bfs(lv, lv.start, frozenset(blocked))
            pool = [c for c in reach if c not in used and c not in path and c != lock]
            if not pool:
                ok = False
                break
            best = max(reach[c] for c in pool)
            key = rng.choice([c for c in pool if reach[c] >= best - 1])
            lv.add_lock(lock, k)
            lv.add_key(key, k)
            used |= {lock, key}
        if not ok:
            continue
        steps = validator.min_steps_with_keys(lv) if lv.lock_cells else len(path) - 1
        if steps <= 0:
            continue
        lv.max_steps = steps + extra
        lv.par_time = float(steps * 3 + 12)
        if any(i.is_error and "level_id" not in i.message for i in validator.validate(lv)):
            continue
        return lv, steps
    raise RuntimeError(f"không sinh được {event} #{idx}")


def main():
    dry = "--dry-run" in sys.argv
    only = None
    if "--only" in sys.argv:
        only = set(sys.argv[sys.argv.index("--only") + 1].split(","))
    for event, (base, name, specs) in EVENTS.items():
        if only and event not in only:
            continue
        folder = ROOT / "data/levels/events" / event
        paths = []
        for i, spec in enumerate(specs):
            lv, steps = build(event, i, base, name, spec)
            p = folder / f"level_{base + i}.tres"
            paths.append(p)
            print(f"{event:12s} #{i + 1:2d} {spec[0]}x{spec[1]} {spec[2]:6s} locks={len(lv.lock_cells)} "
                  f"min_steps={steps} max_steps={lv.max_steps}")
            if not dry:
                folder.mkdir(parents=True, exist_ok=True)
                tres_io.save_file(lv, p)
        if dry:
            continue
        # xoá màn thừa của lần trước (nếu số màn giảm)
        for old in folder.glob("level_*.tres"):
            if old not in paths:
                old.unlink()
        # cập nhật danh sách levels trong data/events/<event>.tres
        ev = ROOT / "data/events" / f"{event}.tres"
        txt = ev.read_text(encoding="utf-8")
        ids = re.findall(r'\[ext_resource type="Resource" path="res://data/levels/events/[^"]+" id="([^"]+)"\]', txt)
        assert len(ids) == len(paths), (event, len(ids), len(paths))
        for rid, p in zip(ids, paths):
            txt = re.sub(r'(\[ext_resource type="Resource" path=")res://data/levels/events/[^"]+(" id="%s"\])' % re.escape(rid),
                         r'\g<1>res://data/levels/events/%s/%s\g<2>' % (event, p.name), txt)
        ev.write_text(txt, encoding="utf-8")


if __name__ == "__main__":
    main()
