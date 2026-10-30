#!/usr/bin/env python3
"""CÀI BỘ NÚT EVENT MỚI (buttons_v2) + BỎ art thẻ (back_art / front_art) khỏi EventTheme.

    python3 tools/install_event_buttons_v2.py <project> <thư_mục_giải_nén_buttons_v2>            # xem trước (dry-run)
    python3 tools/install_event_buttons_v2.py <project> <thư_mục_giải_nén_buttons_v2> --apply    # làm thật
Tuỳ chọn:  --map <theme_id>=<tên_thư_mục>   (lặp được)  ·  --width 128 (bề rộng PNG đích, mặc định 128)

Cần: Pillow (`pip install pillow`). Commit git TRƯỚC khi --apply.

Script làm:
 1. Với mỗi `resources/events/themes/*.tres`: lấy `id`, đổi sang tên thư mục của bộ mới (ALIASES / --map / trùng tên).
 2. RESIZE cẩn thận: 209×216 → <width>×<width*216/209> (LANCZOS, giữ NGUYÊN tỉ lệ + giữ nguyên khung canvas nên
    độ "lún" của ảnh pressed không đổi). Lý do: nút hiển thị ~58×60 px; ảnh gốc to ~3,6 lần ⇒ Godot thu nhỏ
    không mipmap sẽ bị RĂNG CƯA. Ảnh 128 px ≈ 2,1 lần là vừa cho màn 2x.
 3. Ghi PNG vào `assets/images-png/event_btn/event_btn_<id>_{normal,pressed,disabled}.png` (ĐÚNG tên cũ ⇒ code cột
    nút event tự dùng, không phải sửa đường dẫn).
 4. Sửa theme `.tres`: gắn button_normal / button_pressed / button_disabled; XOÁ back_art, front_art, art_offset_y và
    các ext_resource thẻ không còn dùng.
 5. Báo: theme không có thư mục art · thư mục không theme nào dùng · nơi còn dùng back_art/front_art/art_offset_y
    trong .gd/.tscn (phải sửa/xoá trước khi bỏ khỏi `event_theme.gd`).
 6. `--apply`: nếu KHÔNG còn nơi nào dùng back_art/front_art ⇒ tự xoá 3 export đó khỏi `event_theme.gd`
    và thêm `button_disabled`. Art cũ (svg/png thẻ + icon cũ không còn dùng) chuyển vào `_removed_unused/`.
"""
import os, re, sys, glob, shutil
try:   # console Windows mac dinh la cp1252 -> print tieng Viet se crash
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

args = [a for a in sys.argv[1:]]
APPLY = "--apply" in args
W = 128
maps = {}
pos = []
i = 0
while i < len(args):
    a = args[i]
    if a == "--width": W = int(args[i + 1]); i += 2; continue
    if a == "--map": k, v = args[i + 1].split("="); maps[k] = v; i += 2; continue
    if a.startswith("--"): i += 1; continue
    pos.append(a); i += 1
if len(pos) < 2:
    sys.exit(__doc__)
ROOT, SRC = os.path.abspath(pos[0]), os.path.abspath(pos[1])
try:
    from PIL import Image
except ImportError:
    sys.exit("Thiếu Pillow: pip install pillow")

# id theme trong project -> tên thư mục trong buttons_v2 (chỉnh nếu id thật của bạn khác)
ALIASES = {
    "mansion": "haunted_house", "tomb": "explore_pyramid", "newyear": "chinese_new_year",
    "april": "april_fool", "autumn": "autumn_event", "easter": "easter_egg",
}
ALIASES.update(maps)
STATES = ("normal", "pressed", "disabled")
OUT_REL = "assets/images-png/event_btn"
TRASH = "_removed_unused"
H = round(216 * W / 209)

def rel(p): return os.path.relpath(p, ROOT).replace("\\", "/")
def move_to_trash(r):
    src = os.path.join(ROOT, r)
    if not os.path.exists(src): return
    dst = os.path.join(ROOT, TRASH, r); os.makedirs(os.path.dirname(dst), exist_ok=True)
    shutil.move(src, dst)
    for ext in (".import", ".uid"):
        if os.path.exists(src + ext): shutil.move(src + ext, dst + ext)

themes = sorted(glob.glob(os.path.join(ROOT, "resources/events/themes/*.tres")))
if not themes: sys.exit("Không thấy resources/events/themes/*.tres — trỏ vào GỐC project Godot.")
folders = {d for d in os.listdir(SRC) if os.path.isdir(os.path.join(SRC, d))}
used_folders, plan, no_art = set(), [], []
for f in themes:
    s = open(f, encoding="utf-8").read()
    m = re.search(r'^id = &"([^"]+)"', s, re.M)
    if not m: print("!! không thấy id:", rel(f)); continue
    tid = m.group(1); folder = ALIASES.get(tid, tid)
    if folder not in folders or not all(os.path.exists(os.path.join(SRC, folder, f"{folder}_{st}.png")) for st in STATES):
        no_art.append((tid, folder)); continue
    used_folders.add(folder); plan.append((f, tid, folder))

print(f"== {ROOT}  ·  {'LÀM THẬT' if APPLY else 'XEM TRƯỚC'}  ·  PNG đích {W}×{H} ==")
for f, tid, folder in plan: print(f"  theme {tid:<14} ← {folder}")
for tid, folder in no_art:
    print(f"!! theme '{tid}' KHÔNG có art (tìm thư mục '{folder}') — thêm `--map {tid}=<thư_mục>` hoặc bổ sung art; theme này GIỮ NGUYÊN")
for d in sorted(folders - used_folders): print(f"?  thư mục '{d}' chưa có theme nào dùng (sẽ dùng khi bạn tạo event/theme mới id = '{d}')")

# nơi còn dùng art thẻ
usage = []
for d, ds, fs in os.walk(ROOT):
    ds[:] = [x for x in ds if x not in (".git", ".godot", TRASH, "addons")]
    for fn in fs:
        if fn.endswith((".gd", ".tscn")) and fn != "event_theme.gd":
            p = os.path.join(d, fn)
            for n, line in enumerate(open(p, encoding="utf-8", errors="ignore"), 1):
                if re.search(r'\b(back_art|front_art|art_offset_y)\b', line): usage.append(f"{rel(p)}:{n}: {line.strip()[:90]}")
if usage:
    print("\n!! CÒN code dùng back_art/front_art/art_offset_y ⇒ KHÔNG xoá khỏi event_theme.gd (sửa các chỗ này trước, rồi chạy lại):")
    for u in usage: print("   ", u)
else:
    print("\nOK: không còn code nào dùng back_art/front_art/art_offset_y.")

def patch_tres(s, tid, folder):
    body_start = s.index("[resource]")
    head, body = s[:body_start], s[body_start:]
    body = re.sub(r'^(back_art|front_art|art_offset_y|button_normal|button_pressed|button_disabled) = .*\n', '', body, flags=re.M)
    head = re.sub(r'^\[ext_resource [^\]]*id="(btn_normal|btn_pressed|btn_disabled)"\]\n', '', head, flags=re.M)
    for m in list(re.finditer(r'^\[ext_resource [^\]]*id="([^"]+)"\]\n', head, re.M)):   # texture không còn ai dùng
        if 'type="Texture2D"' in m.group(0) and f'ExtResource("{m.group(1)}")' not in body:
            head = head.replace(m.group(0), "", 1)
    add = "".join(f'[ext_resource type="Texture2D" path="res://{OUT_REL}/event_btn_{tid}_{st}.png" id="btn_{st}"]\n' for st in STATES)
    head = head.rstrip("\n") + "\n" + add + "\n"
    body = body.rstrip("\n") + "\n" + "".join(f'button_{st} = ExtResource("btn_{st}")\n' for st in STATES)
    return head + body

if APPLY:
    os.makedirs(os.path.join(ROOT, OUT_REL), exist_ok=True)
    for f, tid, folder in plan:
        for st in STATES:
            im = Image.open(os.path.join(SRC, folder, f"{folder}_{st}.png")).convert("RGBA")
            im.resize((W, H), Image.LANCZOS).save(os.path.join(ROOT, OUT_REL, f"event_btn_{tid}_{st}.png"), optimize=True)
        s = open(f, encoding="utf-8").read()
        open(f, "w", encoding="utf-8", newline="\n").write(patch_tres(s, tid, folder))
    # art thẻ cũ + icon svg cũ
    keep = {f"event_btn_{t}_{st}.png" for _, t, _ in plan for st in STATES}
    for p in glob.glob(os.path.join(ROOT, OUT_REL, "event_btn_*.png")):
        if os.path.basename(p) not in keep and not any(os.path.basename(p).startswith(f"event_btn_{t}_") for t, _ in no_art):
            move_to_trash(rel(p))
    for p in glob.glob(os.path.join(ROOT, "assets/images/event_btn/*.svg")): move_to_trash(rel(p))
    for p in glob.glob(os.path.join(ROOT, "assets/images*/events/*card_*")):
        if not p.endswith((".import", ".uid")): move_to_trash(rel(p))
    # event_theme.gd
    tp = os.path.join(ROOT, "scripts/resources/event_theme.gd")
    if os.path.exists(tp):
        s = open(tp, encoding="utf-8").read()
        if "button_disabled" not in s:
            s = s.replace("@export var button_pressed: Texture2D = null", "@export var button_pressed: Texture2D = null\n## Trạng thái KHOÁ / chưa mở của nút\n@export var button_disabled: Texture2D = null", 1)
        if not usage:
            for name in ("back_art", "front_art", "art_offset_y"):
                s = re.sub(r'(?:^##[^\n]*\n)*@export var %s\b[^\n]*\n\n?' % name, '', s, flags=re.M)
        open(tp, "w", encoding="utf-8", newline="\n").write(s)
    print(f"\nĐÃ ÁP DỤNG: {len(plan)} theme. Mở Godot để import PNG mới. Bản cũ nằm trong {TRASH}/.")
else:
    print("\n(dry-run — chưa ghi gì. Thêm --apply để làm thật.)")
