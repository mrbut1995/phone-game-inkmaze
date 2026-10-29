"""Gắn art NÚT (button) vào các EventTheme (.tres) — thay cho art THẺ (card).
Với mỗi file resources/events/themes/*.tres: đọc `id = &"<theme_id>"`, rồi thêm
    button_normal  = assets/images-png/event_btn/event_btn_<id>_normal.png
    button_pressed = assets/images-png/event_btn/event_btn_<id>_pressed.png
(chạy lại nhiều lần vẫn an toàn — file đã có `button_normal` thì bỏ qua).
Dùng:  python3 tools/patch_event_theme_buttons.py <thư_mục_project_godot> [--drop-card-art]
  --drop-card-art : (tuỳ chọn) xoá luôn back_art / front_art / art_offset_y khỏi theme. CHỈ dùng khi màn chi tiết
                    Event không còn dùng thẻ (xem 06_HUONG_DAN…md, mục B5)."""
import os, re, sys, glob
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")   # console Windows hay la cp1252
except Exception:
    pass
root = sys.argv[1] if len(sys.argv) > 1 else "."
drop = "--drop-card-art" in sys.argv
THEME_DIR = os.path.join(root, "resources", "events", "themes")
ICON_DIR = "assets/images-png/event_btn"
patched = skipped = missing = 0
for f in sorted(glob.glob(os.path.join(THEME_DIR, "*.tres"))):
    s = open(f, encoding="utf-8").read()
    has_btn = "button_normal" in s
    if has_btn and not drop:
        skipped += 1; print("bỏ qua (đã có):", os.path.basename(f)); continue
    m = re.search(r'^id = &"([^"]+)"', s, re.M)
    if not m:
        print("!! không thấy id:", f); continue
    tid = m.group(1)
    n_png = f"{ICON_DIR}/event_btn_{tid}_normal.png"; p_png = f"{ICON_DIR}/event_btn_{tid}_pressed.png"
    if not has_btn and not (os.path.exists(os.path.join(root, n_png)) and os.path.exists(os.path.join(root, p_png))):
        missing += 1; print(f"!! THIẾU icon cho theme '{tid}' ({n_png}) — thêm vào gen_event_icons.py rồi chạy lại"); continue
    if not has_btn:
        ext = [m2 for m2 in re.finditer(r'^\[ext_resource .*\]$', s, re.M)]
        ins = ext[-1].end() if ext else s.index("\n")
        add = (f'\n[ext_resource type="Texture2D" path="res://{n_png}" id="btn_normal"]'
               f'\n[ext_resource type="Texture2D" path="res://{p_png}" id="btn_pressed"]')
        s = s[:ins] + add + s[ins:]
        s = s.rstrip("\n") + '\nbutton_normal = ExtResource("btn_normal")\nbutton_pressed = ExtResource("btn_pressed")\n'
    if drop:
        s = re.sub(r'^(back_art|front_art) = ExtResource\("[^"]+"\)\n', '', s, flags=re.M)
        s = re.sub(r'^art_offset_y = .*\n', '', s, flags=re.M)
        # bỏ ext_resource texture thẻ không còn dùng
        for rid in re.findall(r'\[ext_resource [^\]]*type="Texture2D"[^\]]*card_(?:back|front)ground[^\]]*id="([^"]+)"\]', s):
            if f'ExtResource("{rid}")' not in s.split("[resource]")[1]:
                s = re.sub(r'^\[ext_resource [^\]]*id="%s"\]\n' % re.escape(rid), '', s, flags=re.M)
    open(f, "w", encoding="utf-8", newline="\n").write(s)
    patched += 1; print("đã gắn:", os.path.basename(f), "→", tid)
print(f"XONG: {patched} theme đã gắn · {skipped} bỏ qua · {missing} thiếu icon")
