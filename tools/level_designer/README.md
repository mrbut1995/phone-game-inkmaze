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
- Viền ngoài luôn là tường cứng (khớp với `level_manager.gd`), không sửa được.

**Hỗ trợ thiết kế**
- Hiện **số tường** từng ô đúng như trong game (0 thì ẩn, giống `MazeData`).
- Hiện **đường đi ngắn nhất** bằng BFS để biết màn có lời giải hay không.
- Bảng **Kiểm tra** tự động: S/F trùng hoặc ngoài lưới, không có đường đi, `max_steps`
  nhỏ hơn đường ngắn nhất (không thể thắng), ô không tới được, màn thiếu tường ẩn…
- Nút **Tính max_steps theo đường đi**, **Xoá hết tường bên trong**, **Sinh tường ẩn ngẫu nhiên**.
- **Hoàn tác / Làm lại** (Ctrl+Z / Ctrl+Y) theo từng "nét vẽ".
- Panel bên trái: mở / tạo mới / nhân bản / xoá file level.
- Cảnh báo **chưa lưu** khi mở màn khác, tạo màn mới hoặc thoát.
- Lưu sẽ **bị chặn nếu dữ liệu sai** (ví dụ không có đường đi) — tránh ghi ra màn không chơi được.

**Phím tắt**

| Phím | Việc | Phím | Việc |
|---|---|---|---|
| `1` `2` `3` | Tường hiện · Tường ẩn · Xoá | `Ctrl+S` | Lưu |
| `4` `5` | Đặt S · Đặt F | `Ctrl+Shift+S` | Lưu thành level khác |
| `Delete` | Xoá tường đang trỏ | `Ctrl+N` | Màn mới |
| `Ctrl+Z` / `Ctrl+Y` | Hoàn tác / Làm lại | `Ctrl+0` | Zoom mặc định |
| `G` `P` `H` | Số tường · đường đi · tường ẩn | `+` `-` / `Ctrl+lăn` | Zoom |

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
│   │   ├── level.py            #   LevelModel: tường, S/F, kích thước, snapshot/undo
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
│       └── main_window.py      #   menu, toolbar, 3 panel, phím tắt, trạng thái
└── tests/                      # unittest (29 test)
    ├── test_level_model.py     #   quy ước chỉ số tường, resize, snapshot
    ├── test_tres_roundtrip.py  #   định dạng .tres + đọc lại 9 màn thật
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
[ext_resource type="Script" path="res://scripts/resources/level_data.gd" id="1_level"]

[resource]
script = ExtResource("1_level")
level_id = 3
level_title = "Level 1-3 · Mê Cung 3x3"
chapter = 1
mode_id = "play"
difficulty = "easy"
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
custom_cell_values = {}                 # giữ nguyên khi sửa (tool không đổi)
```

Quy ước toạ độ (khớp `maze_data.gd` / `level_manager.gd`):
- `x` tăng sang **phải**, `y` tăng xuống **dưới** ⇒ `y = 0` là hàng **TRÊN cùng**.
- `v_walls[x][y]` = tường dọc bên **trái** ô `(x, y)`; `h_walls[x][y]` = tường ngang **trên** ô `(x, y)`.
- Số tường của ô = tổng 4 cạnh **bên trong board** là tường: `h[x][y] + h[x][y+1] + v[x][y] + v[x+1][y]`,
  **nhưng BỎ QUA cạnh nào thuộc viền ngoài board** (tường bao quanh board không tính vào ô).
  Ô góc/sát biên không bị cộng thêm vì viền; ô có số 0 thì game không hiện số.
- Viền ngoài luôn là tường và luôn nhìn thấy, **vẫn chặn đường đi** nhưng **không được đếm** vào ô.

---

## 5. Test & build

```powershell
cd tools\level_designer

# chạy test (29 test)
python -m unittest discover -s tests -t .

# self-test đọc/ghi 9 màn thật
python main.py --selftest

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

## 6. Ghi chú

- File `.tres` do tool ghi **giống hệt** định dạng Godot sinh ra (khác duy nhất id nội bộ
  `1_level` của `ext_resource` — Godot không quan tâm giá trị này).
- Lần đầu mở Godot sau khi thêm màn mới, editor sẽ tự import resource — không cần thao tác gì thêm.
- Tool **không** sửa `custom_cell_values` (một số mode dùng để lưu giá trị ô đặc biệt).
- Nếu muốn thêm loại tường/thuộc tính mới: sửa `app/models/level.py` (dữ liệu) +
  `app/services/tres_io.py` (đọc/ghi). View không cần sửa.
