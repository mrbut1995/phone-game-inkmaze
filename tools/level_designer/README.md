# InkMaze Level Designer

Công cụ desktop (Python + Tkinter) để **thiết kế màn chơi** cho game InkMaze / Number Maze.
Tool ghi trực tiếp file `resources/levels/level_N.tres` của dự án Godot — cùng định dạng Godot
sinh ra, nên chỉ cần mở Godot là chạy được ngay.

```
┌─────────────────────────── InkMaze Level Designer ───────────────────────────┐
│ File  Sửa  Xem  Trợ giúp                                                     │
│ [Công cụ: Tường hiện|Tường ẩn|Xoá|S|F]  ☑Số tường ☑Đường đi ☑Tường ẩn  − + [Lưu]│
│ ┌──────────┬────────────────────────────────────────┬──────────────────────┐ │
│ │ Danh sách│            LƯỚI MÊ CUNG               │  Thông tin màn       │ │
│ │ level_1  │      (vẽ bằng chuột, zoom được)        │  Lưới & luật chơi    │ │
│ │ level_2  │   S = xuất phát · F = đích · số = tường│  Kiểm tra/tự động    │ │
│ └──────────┴────────────────────────────────────────┴──────────────────────┘ │
│ Trạng thái: Đã lưu level_3.tres        Level #3 · 3x3 · Tường hiện (1)         │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## 1. Chạy tool

**Không cần cài thêm gì** (chỉ dùng thư viện chuẩn Python + tkinter).

```powershell
# cách 1: chạy từ mã nguồn
cd tools\level_designer
python main.py

# cách 2: dùng file đã build sẵn
tools\level_designer\dist\LevelDesigner.exe
```

Mở nhanh một màn cụ thể:

```powershell
python main.py --level 3
python main.py --project "D:\godot-phone-game\phone-game-inkmaze"   # chỉ định gốc dự án
```

Tool tự dò thư mục gốc dự án (thư mục chứa `project.godot`): đi ngược từ file `main.py`
hoặc từ file `.exe`, nên đặt exe ở đâu trong dự án cũng chạy đúng.

Các cờ hữu ích khác (không mở cửa sổ):

| Cờ | Việc |
|---|---|
| `--selftest` | Đọc cả 9 màn thật → ghi lại → đọc lại so sánh, thử solver/validator/undo |
| `--export-example N --out <path>` | Xuất màn N ra file `.tres` khác (mặc định vào `tools/level_designer/out/`) |
| `--version` | In phiên bản |

---

## 2. Tính năng

**Vẽ màn chơi**
- Vẽ tường **hiện** (đường liền) / **ẩn** (đường nét đứt) bằng chuột trái, kéo để vẽ liên tục.
- Chuột phải (hoặc `Delete`) để xoá tường. Click lại đúng loại tường đang có = xoá nhanh.
- Đặt điểm xuất phát **S** và đích **F** bằng công cụ 4/5 hoặc sửa toạ độ ở bảng phải.
- **Sửa hình dạng board (công cụ 6)**: bấm/kéo để **bật-tắt ô** — board có thể là hình bất kỳ
  (chữ H, thập tự, vòng có lỗ, chữ U…). Ô tắt (ô trống) không có số, không bước vào được, và mọi cạnh
  bao quanh board tự động thành tường hiện (giống viền ngoài) nên không sửa được.
- Nút **“Toàn bộ ô = board (chữ nhật)”** để quay về lưới đặc.

**Hỗ trợ thiết kế**
- Hiện **số tường** từng ô đúng như trong game (0 thì ẩn, giống `MazeData`).
- Hiện **đường đi ngắn nhất** bằng BFS để biết màn có lời giải hay không — BFS chỉ đi trong **các ô thuộc board**.
- **Vẽ đường đi trước rồi sinh tường (công cụ 8)** — kéo chuột vẽ đường S→F, bấm `Ctrl+Enter` là có
  ngay một màn “đi được tới đích” với đường đã vẽ là **đường duy nhất** ⇒ chi tiết ở **mục 5b**.
- **NHIỆM VỤ — Mission (tối đa 3 / màn — 1 nhiệm vụ hoàn thành = 1 Sao)**: chọn loại ở 3 ô combobox bên phải,
  nhập tham số N (bước / giây / % số ô / tổng số), nút `×` để bỏ. Để trống = game dùng 3 nhiệm vụ mặc định
  (không đâm tường · đủ bước · đủ thời gian). Nút **“Ghi 3 mặc định”** để ghi rõ 3 nhiệm vụ chuẩn vào màn.
  17 loại: xem bảng trong `Number_Maze_Game_Design.md` (mục 3.1) hoặc `app/models/missions.py`
  (mới 2026-10: `no_wrong_submit` — riêng Wall Builder, gửi đúng ngay lần đầu).
- **CHALLENGE MODE — 1 LUẬT THỬ THÁCH / màn**: khối **“Thử thách (Challenge)”** ở bảng phải — chọn
  `mode_id = "challenge"` rồi chọn **1 luật** (9 luật: countdown · move_limit · step_timer · no_tool ·
  no_move_overlapped · walk_number_only · walk_empty_only · backtrack_limit · fog_of_war) + tham số (0 = game tự tính).
  Vi phạm luật (hoặc quá hạn) là **THUA NGAY**. Validator kiểm tra màn *có đường thắng được không* —
  vd `move_limit` nhỏ hơn đường ngắn nhất, hay luật “chỉ đi trên ô có số/không số” mà màn KHÔNG có
  đường hợp lệ ⇒ **LỖI** (chặn lưu). Xem **mục 5c**.
- Bảng **Kiểm tra** tự động: S/F trùng, S/F nằm ở **ô trống**, **không có đường đi từ S tới F**,
  `max_steps` nhỏ hơn đường ngắn nhất (không thể thắng), **ô thuộc board không tới được**,
  màn thiếu tường ẩn, **nhiệm vụ mâu thuẫn / không thể đạt** (ví dụ `steps_max` < đường ngắn nhất,
  `len_max_percent` quá nhỏ, `only_numbered` + `avoid_numbered` cùng lúc…) và **luật thử thách**
  (luật đặt sai chỗ, tham số ngoài khoảng, không có đường theo luật…)
  ⇒ **nút Lưu bị chặn nếu có lỗi** (cảnh báo thì vẫn lưu được).
- **Hoàn tác / Làm lại** (Ctrl+Z / Ctrl+Y) theo từng "nét vẽ".
- Panel bên trái: mở / tạo mới / nhân bản / xoá file level.
- Cảnh báo **chưa lưu** khi mở màn khác, tạo màn mới hoặc thoát.
- Lưu sẽ **bị chặn nếu dữ liệu sai** (ví dụ không có đường đi) — tránh ghi ra màn không chơi được.

**Phím tắt**

| Phím | Việc | Phím | Việc |
|---|---|---|---|
| `1` `2` `3` | Tường hiện · Tường ẩn · Xoá | `Ctrl+S` | Lưu |
| `4` `5` `6` | Đặt S · Đặt F · **Sửa ô board** | `Ctrl+Shift+S` | Lưu thành level khác |
| `7` | **Tô dữ liệu riêng của chế độ** (mục 5) | `Ctrl+N` | Màn mới |
| `8` | **Vẽ đường đi** rồi áp dụng cho đường (mục 5b) | `Ctrl+Enter` | **Sinh tường / TÔ GIÁ TRỊ** quanh đường vừa vẽ |
| `Delete` | Xoá tường đang trỏ | `Esc` | Xoá nét đường đang vẽ |
| `Ctrl+Z` / `Ctrl+Y` | Hoàn tác / Làm lại | `Ctrl+0` | Zoom mặc định |
| `+` `-` / `Ctrl+lăn` | Zoom | `G` `P` `H` | Số tường · đường đi · tường ẩn |

---

## 3. Cấu trúc mã nguồn (MVC, dạng module)

```
tools/level_designer/
├── main.py                     # điểm khởi chạy + các chế độ CLI (selftest, export)
├── build_exe.py / .bat         # đóng gói .exe bằng PyInstaller
├── requirements.txt            # KHÔNG có thư viện ngoài (tkinter là chuẩn)
├── requirements-dev.txt        # pyinstaller (chỉ để build)
├── app/
│   ├── config.py               # đường dẫn, giới hạn, màu, tên công cụ
│   ├── models/                 # MODEL - dữ liệu thuần, không phụ thuộc GUI
│   │   ├── level.py            #   LevelModel: tường, S/F, kích thước, mission + challenge, snapshot/undo
│   │   ├── missions.py         #   registry 17 NHIỆM VỤ (khớp MissionTypes bên game)
│   │   ├── challenge_rules.py  #   registry 9 LUẬT THỬ THÁCH (khớp ChallengeGameMode bên game)
│   │   ├── chapter.py          #   ChapterModel (chương — resources/chapters/*.tres)
│   │   ├── chapter_repository.py #  đọc/ghi/xoá các chương
│   │   └── repository.py       #   đọc/ghi/xoá resources/levels/*.tres
│   ├── services/               # dịch vụ dùng chung
│   │   ├── tres_io.py          #   parser/ghi file .tres đúng định dạng Godot
│   │   ├── solver.py           #   BFS đường ngắn nhất + phân tích màn
│   │   └── validator.py        #   luật kiểm tra dữ liệu màn chơi
│   ├── controllers/            # CONTROLLER - nghiệp vụ, không vẽ
│   │   ├── events.py           #   bộ phát sự kiện (view nghe controller)
│   │   ├── editor_controller.py#   công cụ, undo/redo, sửa model
│   │   └── app_controller.py   #   mở/lưu/tạo/xoá, kiểm tra, xuất JSON
│   └── views/                  # VIEW - chỉ hiển thị + bắt sự kiện
│       ├── theme.py            #   font/màu ttk theo tông sổ ô ly
│       ├── grid_view.py        #   canvas lưới mê cung (vẽ + chuột + zoom)
│       ├── inspector_view.py   #   bảng thuộc tính + kết quả kiểm tra
│       ├── level_list_view.py  #   danh sách level + nút file
│       ├── chapter_dialog.py   #   hộp thoại tạo/sửa chương
│       └── main_window.py      #   menu, toolbar, 3 panel, phím tắt, trạng thái
└── tests/                      # unittest (chạy: python -m unittest discover -s tests -t .)
    ├── test_level_model.py     #   quy ước chỉ số tường, resize, snapshot
    ├── test_tres_roundtrip.py  #   định dạng .tres + đọc lại màn thật
    ├── test_missions.py        #   NHIỆM VỤ: model → .tres → validator → undo
    ├── test_challenge.py       #   LUẬT THỬ THÁCH: registry → model → .tres → validator → undo
    ├── test_controllers.py     #   undo/redo, lưu/xoá, chặn lưu màn lỗi
    └── test_gui_smoke.py       #   dựng cửa sổ thật, vẽ thử, kiểm tra toạ độ
```

Luồng dữ liệu: **View → Controller → Model → (sự kiện) → View**.
View không bao giờ sửa `LevelModel` trực tiếp; mọi thay đổi đi qua `EditorController`
(để tự động có undo + cờ dirty + vẽ lại).

---

## 4. Định dạng file & quy ước (quan trọng khi sửa code)

File `level_N.tres` giữ đúng các trường của `scripts/resources/level_data.gd`:

```gdscript
[gd_resource type="Resource" script_class="LevelData" load_steps=2 format=3 uid="uid://..."]
[ext_resource type="Script" path="res://scripts/data/level_data.gd" id="1_level"]

[resource]
script = ExtResource("1_level")
level_id = 3
level_title = "Level 1-3 · Mê Cung 3x3"
chapter = 1
mode_id = "play"                 # hoặc id chế độ Special / "challenge" (mục 5)
difficulty = "easy"
challenge = ""                       # LUẬT THỬ THÁCH (chỉ dùng khi mode_id = "challenge"):
challenge_param = 0                   # countdown · move_limit · step_timer · no_tool ·
                                      # no_move_overlapped · walk_number_only · walk_empty_only ·
                                      # backtrack_limit — 0 tham số = game tự tính; "" = không gắn
width = 3
height = 3
start_pos = Vector2i(0, 2)     # Vector2i(x, y)
end_pos = Vector2i(2, 0)
max_steps = 14
par_time = 35.0
v_walls = PackedByteArray(...)          # tường DỌC  (w+1)*h phần tử, index = x*h + y
v_walls_visible = PackedByteArray(...)  # 1 = tường nhìn thấy, 0 = tường ẩn
h_walls = PackedByteArray(...)          # tường NGANG w*(h+1) phần tử, index = x*(h+1) + y
h_walls_visible = PackedByteArray(...)
cell_mask = PackedByteArray(...)        # HÌNH DẠNG BOARD: w*h phần tử, index = y*w + x
                                        # 1 = ô thuộc board, 0 = ô trống (ngoài board)
                                        # PackedByteArray() = chữ nhật đầy đủ (màn cũ)
mission_types = PackedStringArray("no_wall", "steps_max", "len_max_percent")
                                        # NHIỆM VỤ của màn — TỐI ĐA 3, hai mảng SONG SONG;
mission_params = PackedInt32Array(0, 15, 80)
                                        # rỗng = game dùng 3 nhiệm vụ mặc định (màn cũ)
custom_cell_values = {}                 # DỮ LIỆU RIÊNG CỦA CHẾ ĐỘ: {"x,y": giá trị} — xem mục 5
                                        # (mìn ghim · điểm ô · chi phí bước); {} = game tự sinh hết
```

Quy ước toạ độ (khớp `maze_data.gd` / `level_manager.gd`):
- `x` tăng sang **phải**, `y` tăng xuống **dưới** ⇒ `y = 0` là hàng **TRÊN cùng**.
- `v_walls[x][y]` = tường dọc bên **trái** ô `(x, y)`; `h_walls[x][y]` = tường ngang **trên** ô `(x, y)`.
- Số tường của ô = tổng các cạnh **giữa 2 Ô THUỘC BOARD** là tường:
  `h[x][y] + h[x][y+1] + v[x][y] + v[x+1][y]` nhưng **bỏ mọi cạnh bao quanh board**
  (viền ngoài hoặc giáp ô trống). Ô có số 0 thì game không hiện số.
- Cạnh bao quanh board luôn là tường và luôn nhìn thấy, **vẫn chặn đường đi** nhưng **không được đếm** vào ô.

---

## 5. MÀN CHẠY CHẾ ĐỘ SPECIAL (Blind Memory · Wall Builder · Challenge)

Từ 2026-09-26, **ngoài Daily Challenge, một MÀN trong campaign cũng chạy được chế độ Special**:
chọn `Chế độ` ở bảng phải (trường `mode_id` trong file `.tres`) khác `play` là xong.

> Đã **còn đúng 2 chế độ Special: `blind_memory` · `wall_builder`** (cộng `play` và `challenge`).
> 6 chế độ cũ — minesweeper · sum_path · countdown_cost · fading_ink · one_stroke · fog_of_war (mode riêng) —
> **đã bị xoá khỏi game**; file cũ khai các id đó sẽ bị validator báo LỖI và game chơi như `play`.
> **Fog of War nay là LUẬT THỬ THÁCH** (`challenge = "fog_of_war"`) — xem **mục 5c**.

**Game sẽ làm gì với màn đó**

| Việc | Chi tiết |
|---|---|
| Bàn chơi | Dùng **ĐÚNG bàn của màn**: tường + hình dạng board (`cell_mask`) do tool vẽ — KHÔNG tự sinh bàn |
| Số bước | `max(max_steps của màn, ngân sách mặc định của chế độ)` — màn to không bị hết bước oan |
| Tiêu đề HUD | Hiện `MÀN nn` + dòng phụ `TÊN CHẾ ĐỘ · CHƯƠNG n` (giống Play Mode) |
| Nút SKIP | Có ở **mọi màn** (chỉ ẩn khi chơi Dungeon/Daily): bấm là mở khoá màn kế tiếp trong cùng chương mà **KHÔNG ghi Sao**, rồi vào luôn màn đó |

**Tường hiện/ẩn ở game có ép riêng**

| Chế độ | Trạng thái tường |
|---|---|
| `blind_memory` · `wall_builder` | Game **ép ẨN** toàn bộ tường khi chơi (màn ghi gì không quan trọng) |
| `play` · `challenge` | Tôn trọng đúng thiết kế (tường ẩn là luật chơi gốc) |

**Riêng từng chế độ (validator cũng nhắc)**

- `wall_builder`: các con số suy ra từ chính tường của màn; màn quá ít tường thì "dễ" một hay (validator cảnh báo).
- `blind_memory`: màn càng nhiều tường ẩn càng khó ở thì chơi để còn lại `par_time`.
- `challenge`: chơi y như Play Mode nhưng kèm **1 luật thử thách** — xem **mục 5c**.

Danh sách màn bên trái hiện nhãn `ở tên_chế_độ` ở cuối dòng để nhìn là biết ngay màn nào đặc biệt.
**Màn mẫu có sẵn** (`make_samples.py` ghi lại được vào **`resources/levels_samples/`** — cố ý TÁCH khỏi
`resources/levels/` để không đè lên màn thật):
**13** = challenge `walk_number_only` · **14** = challenge `fog_of_war` · **15** = blind_memory ·
**16** = wall_builder (12 tường ẩn) · **17** = play có **Ô KHOÁ + CHÌA** (xem dưới).

**Ô KHOÁ + CHÌA KHOÁ — `lock_cells` / `key_cells`**

Màn có thể khoá vài ô; muốn đi qua phải nhặt **chìa cùng id**. Tool xuất 2 mảng phẳng bộ ba `(x, y, id)`
đúng định dạng `LevelData.lock_cells` / `key_cells` của game; id nằm trong **1..30** (game mã hoá tập chìa
đã nhặt bằng bit). Mỗi id khoá phải có **ít nhất 1 chìa**, khoá/chìa **không** đặt trên S/F, và validator
vẫn kiểm **có đường S→F** bằng BFS theo trạng thái `(ô, tập chìa)` — y như `MazeData.get_play_path`.
---

## 5b. VẼ ĐƯỜNG ĐI RỒI SINH TƯỜNG (công cụ 8 — mới 2026-09-27)

Cách nhanh nhất để có một màn “đi được tới đích” mà không phải đoán tường:

1. **Công cụ 6** — bật/tắt các ô muốn chơi (hoặc để nguyên hình chữ nhật đầy đủ).
2. **Công cụ 8** (phím `8`) — **kéo chuột** trên lưới để vẽ đường đi: bắt đầu ở ô nào cũng được
   (thường là ô S cũ) và kết thúc ở ô đích. Nét vẽ chỉ nối **ô kề**, không nhảy ô, không đi đè;
   kéo ngược về ô trước = lùi 1 ô. Nét vẽ hiện **màu tím** đè lên lưới.
3. **Ctrl + Enter** (hoặc nút **“Sinh tường (Ctrl+Enter)”** trên thanh công cụ — chỉ hiện khi đang có nét vẽ)
   → tool sinh màn chơi từ nét vẽ:

| Việc | Kết quả |
|---|---|
| S / F | `S` = ô **ĐẦU** nét vẽ · `F` = ô **CUỐI** nét vẽ |
| Tường | Mọi cạnh **BÊN HÔNG** của nét vẽ thành **tường hiện** ⇒ nét vẽ trở thành **ĐƯỜNG DUY NHẤT** từ S tới F |
| Lối đi | Cạnh nối 2 ô liền nhau trên nét vẽ được **MỞ** (kể cả trước đó đang có tường) |
| `max_steps` | Tự tính = số bước của nét vẽ + 2 nhịp thở |
| Hoàn tác | Cả lần sinh tường là **1 bước** `Ctrl+Z` |

> **Không chế độ nào còn dùng giá trị ô** (minesweeper/sum_path/countdown_cost/fading_ink đã bị xoá) nên
> nút này **luôn là “Sinh tường”**. Phần tô giá trị theo đường + ô “Tổng …” + công cụ 7 vẫn còn trong code
> nhưng **bị ẩn** vì cả 4 chế độ trong `app/config.py` (`MODE_EDITS`) đều khai `kind: "none"`; muốn dùng lại
> thì chỉ cần thêm `"kind": "cell_value"` và khối `"path"` cho chế độ mới.

- Muốn vài đoạn tường **ẩn** cho đúng chất “mực”? Sinh tường xong, chọn **công cụ 2** rồi bấm/kéo
  lên đúng đoạn đó để đổi sang tường ẩn.
- **Chuột phải** khi đang ở công cụ 8 = **xoá nét vẽ** (không đụng tới màn chơi) — hoặc bấm `Esc`.
- Nét vẽ là dữ liệu **TẠM** của phiên làm việc: **không ghi vào `.tres`**, đổi màn là tự bỏ.
- Bấm `P` để xem lại **đường ngắn nhất** (BFS): sau khi sinh tường, đường này trùng đúng nét bạn vừa vẽ
  ⇒ dùng để tự kiểm tra trước khi lưu.

---

## 5c. CHALLENGE MODE — MÀN GẮN 1 LUẬT THỬ THÁCH (mới 2026-10)

Chế độ chơi của game (`scripts/modes/challenge_game_mode.gd`): ván chơi **y như Play Mode**
(đâm tường = thua ngay, xếp hạng theo thời gian) nhưng màn gắn **1 LUẬT** — **vi phạm luật (hoặc quá hạn)
là THUA NGAY**; thắng màn mở popup “HOÀN THÀNH THỬ THÁCH”.

**Gắn luật trong tool**

1. Ô `mode_id` (bảng phải) → chọn **`challenge`**.
2. Khối **“Thử thách (Challenge)”** → chọn **Luật** + nhập **Tham số** (0 = game tự tính).

| Luật | Ý nghĩa | Tham số |
|---|---|---|
| `countdown` | Về đích trước khi hết đếm ngược | giây (0 = 60 + 4×số ô, tối thiểu 75) |
| `move_limit` | Đi tối đa N bước | bước (0 = đúng `max_steps` của màn) |
| `step_timer` | MỖI bước phải đi trong X giây (đồng hồ con, reset mỗi bước) | giây (0 = dễ 30 · thường 20 · khó 15) |
| `no_tool` | Bấm GỢI Ý hoặc DỊCH CHUYỂN = thua ngay | — |
| `no_move_overlapped` | Đi lại ô đã đi = thua ngay | — |
| `walk_number_only` | Chỉ đi trên ô CÓ SỐ (ô 0 tường quanh nó = ô không số) | — |
| `walk_empty_only` | Chỉ đi trên ô KHÔNG SỐ | — |
| `backtrack_limit` | Quay đầu (lùi về ô vừa rời) tối đa N lần | lượt (0 = 3) |

- **Ô S/F luôn đi được** với 2 luật “đi trên ô …”; bước vào ô sai loại = **không di chuyển** + thua ngay.
- Luật CHỈ áp dụng khi `mode_id = "challenge"` — đặt luật ở mode khác thì game BỎ QUA (validator cảnh báo).

**Validator kiểm tra thay bạn** (chặn Lưu nếu LỖI)

| Tình huống | Kết quả |
|---|---|
| `move_limit` nhỏ hơn đường đi ngắn nhất | **LỖI** — không thể thắng |
| `walk_number_only` mà màn KHÔNG có đường chỉ qua ô có số | **LỖI** (tool BFS theo đúng luật) |
| `walk_empty_only` mà màn KHÔNG có đường chỉ qua ô không số | **LỖI** (tool BFS theo đúng luật) |
| Tham số ngoài khoảng (giây 5..3600 · bước 1..9999 · lượt 1..99) | **LỖI** |
| `mode_id = "challenge"` nhưng chưa chọn luật | cảnh báo — game sẽ chơi như Play thường |
| `move_limit` ĐÚNG BẰNG đường ngắn nhất · `countdown` < 1 giây/bước · `step_timer` < 4 giây | cảnh báo (quá gắt) |

- Màn mẫu: **level_13** = `move_limit` · **level_14** = `fog_of_war` (đều ở chương 2).
- Nhiệm vụ hàng ngày (Daily) cũng dùng đúng 9 luật này để sinh 3 game/ngày cho mỗi ngày.

---

## 6. Test & build

```powershell
cd tools\level_designer

# chạy test (170 test)
python -m unittest discover -s tests -t .

# self-test đọc/ghi các màn thật (kể cả màn polyomino) + kiểm tra đường đi
python main.py --selftest

# tạo lại các MÀN MẪU (level_10..level_17: polyomino + chế độ Special + challenge + ô khoá/chìa)
# ⚠️ Ghi vào resources/levels_samples/ (KHÔNG phải resources/levels/) vì id 10..17 đã là MÀN THẬT —
#    ghi đè sẽ mất màn thật. Muốn ghi chỗ khác: --dir resources/levels
python make_samples.py             # thêm --dry-run để chỉ kiểm tra, không ghi file
python make_samples.py --only 17   # chỉ ghi lại 1 (hoặc vài) màn mẫu: --only 13,14

# build file .exe  ->  dist\LevelDesigner.exe
python build_exe.py            # hoặc double-click build_exe.bat
python build_exe.py --console  # bản có console để xem log khi gỡ lỗi
python build_exe.py --keep     # giữ thư mục build/ trung gian
```

Nếu muốn dùng môi trường ảo (đã có `.gitignore` bỏ qua `venv/`, `.venv/`):

```powershell
cd tools\level_designer
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt   # chỉ cần khi build exe
python main.py
```

Sau khi build, kiểm tra nhanh bản exe:

```powershell
.\dist\LevelDesigner.exe --selftest     # mã thoát 0 là đạt
```

---

## 7. Ghi chú

- **Board dạng polyomino**: màn chơi không nhất thiết là lưới chữ nhật — `cell_mask` đánh dấu ô nào
  thuộc board. Màn mẫu có sẵn: `level_10` chữ H · `level_11` thập tự · `level_12` vòng có lỗ ·
  `level_13` chữ U · `level_14` bàn cờ lớn 11×11 (đều ở chương 2).
- **Board nhiều ô vẫn vừa khung**: trong game, ô tự co lại cho vừa khung giấy (lưới ≤ 5×5 giữ nguyên cỡ gốc;
  11×11 ≈ 92px/ô, 20×20 ≈ 50px/ô và số vẫn đọc được). Tool cho tạo tới **20×20**; xem trước bằng zoom (`+`/`-`).
- Game **hỗ trợ nhiều hơn 9 màn**: màn *Chọn Màn* tự chia **9 thẻ/trang** và **vuốt ngang để sang trang**
  (chỉ số trang + bấm dot để nhảy trang). Tạo `level_10.tres`, `level_11.tres`… bằng tool này là chơi được ngay,
  không cần sửa code game.
- File `.tres` do tool ghi **giống hệt** định dạng Godot sinh ra (khác duy nhất id nội bộ
  `1_level` của `ext_resource` — Godot không quan tâm giá trị này).
- Lần đầu mở Godot sau khi thêm màn mới, editor sẽ tự import resource — không cần thao tác gì thêm.
- Tool **không** sửa `custom_cell_values` ngoài công cụ 7: nếu file có khoá mà tool không hiểu,
tool GIỮ NGUYÊN chuỗi gốc khi lưu (validator cảnh báo) — xem mục 5.
- Nếu muốn thêm loại tường/thuộc tính mới: sửa `app/models/level.py` (dữ liệu) +
  `app/services/tres_io.py` (đọc/ghi). View không cần sửa.
