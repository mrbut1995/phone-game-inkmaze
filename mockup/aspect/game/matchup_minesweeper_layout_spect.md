Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp toàn diện** cho chế độ **MINESWEEPER MAZE (DÒ MÌN)** trên toàn bộ **10 tỉ lệ màn hình**, được chia làm 2 nhóm: **Màn hình Dọc (Portrait - 6 tỉ lệ)** và **Màn hình Ngang (Landscape - 4 tỉ lệ)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 cột dọc duy nhất (từ trên xuống: Safe Area Offset $\to$ Header $\to$ HUD Row $\to$ Bàn cờ $\to$ Tip Banner $\to$ Controls $\to$ Gesture Bar).

### 1. Layout Spec (Kích thước & Tọa độ Panel)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lề ngang (Padding X)** | 50 px | 50 px | 50 px | 50 px | 40 px | 60 px |
| **Top Safe Area (Y Offset)** | 70 px | 90 px | 110 px | 130 px | 35 px | 45 px |
| **Bàn cờ vuông (Board)** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** | **800 × 800 px** | **920 × 920 px** |
| **Header Panel (W × H)** | 980 × 85 px | 980 × 85 px | 980 × 90 px | 980 × 95 px | 1000 × 65 px | 1080 × 85 px |
| **HUD Trái: Timer (W × H)** | 250 × 158 px | 250 × 165 px | 250 × 175 px | 250 × 185 px | 260 × 125 px | 280 × 145 px |
| **HUD Phải: Thẻ Bom (W × H)** | **700 × 158 px** | **700 × 165 px** | **700 × 175 px** | **700 × 185 px** | **725 × 125 px** | **780 × 145 px** |
| **Banner Mẹo / Tip (W × H)** | 980 × 90 px | 980 × 90 px | 980 × 100 px | 980 × 110 px | 1000 × 65 px | 1080 × 80 px |
| **Nút Chính (Vẽ/Ghi Nhớ) (W × H)**| 360 × 140 px | 360 × 150 px | 360 × 165 px | 360 × 175 px | 360 × 135 px | 395 × 160 px |
| **Nút Phụ (Undo/Hint) (W × H)** | 105 × 140 px | 105 × 150 px | 105 × 165 px | 105 × 175 px | 110 × 135 px | 115 × 160 px |

---

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Tiêu đề: MINESWEEPER MAZE**| 42 px | 42 px | 44 px | 44 px | 34 px | 40 px |
| **Tag Daily Challenge** | 26 px | 26 px | 26 px | 26 px | 20 px | 26 px |
| **Label "THỜI GIAN"** | 18 px | 18 px | 20 px | 22 px | 16 px | 18 px |
| **Giá trị Đồng hồ (00:37)** | **46 px** | **48 px** | **52 px** | **54 px** | **40 px** | **46 px** |
| **Label "BOM CÒN LẠI"** | 30 px | 30 px | 32 px | 32 px | 24 px | 28 px |
| **Giá trị Bom (2/3)** | **72 px** | **76 px** | **80 px** | **84 px** | **58 px** | **68 px** |
| **Số mìn 8 ô lân cận trên Board**| **60 px** | **60 px** | **60 px** | **60 px** | **50 px** | **56 px** |
| **Ký hiệu Start/Finish (S/F)**| **52 px** | **52 px** | **52 px** | **52 px** | **42 px** | **48 px** |
| **Banner Mẹo / Luật chơi** | 22 px | 24 px | 24 px | 24 px | 20 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | 34 px | 34 px | 36 px | 36 px | 28 px | 32 px |
| **Nhãn Nút Chính (GHI NHỚ)** | 34 px | 34 px | 36 px | 36 px | 28 px | 32 px |
| **Nhãn Nút Phụ (UNDO / HINT)**| 16 px | 16 px | 18 px | 18 px | 14 px | 16 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi 2 cột (Cột Trái: Bàn cờ vuông; Cột Phải: Sidebar chứa Header, HUD Thẻ Bom & Timer, Tip và cụm Action Controls).

### 1. Layout Spec (Kích thước & Tọa độ Panel)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 60 px | 60 px | 80 px | 100 px *(Tránh Notch/Camera)* |
| **Bàn cờ vuông (Board)** | **1040 × 1040 px** | **960 × 960 px** | **960 × 960 px** | **960 × 960 px** |
| **Chiều rộng Cột Phải (Sidebar W)** | 420 px | 810 px | 980 px | 1120 px |
| **Header Panel (W × H)** | 420 × 90 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **HUD: Timer (W × H)** | 420 × 95 px *(Dưới thẻ Bom)* | 240 × 195 px *(Cạnh thẻ Bom)* | 280 × 200 px *(Cạnh thẻ Bom)* | 310 × 210 px *(Cạnh thẻ Bom)* |
| **HUD: Thẻ Bom (W × H)** | **420 × 165 px** *(To ở trên)* | **550 × 195 px** *(To bên phải)* | **680 × 200 px** *(To bên phải)* | **785 × 210 px** *(To bên phải)* |
| **Banner Mẹo / Tip (W × H)** | 420 × 90 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **Nút Chính: Vẽ Đường (W × H)** | 420 × 185 px | 810 × 235 px | 475 × 250 px | 540 × 255 px |
| **Nút Chính: Ghi Nhớ (W × H)** | 420 × 140 px | 460 × 165 px | 475 × 250 px | 555 × 255 px |
| **Nút Phụ: Undo (W × H)** | 200 × 90 px | 155 × 165 px | 475 × 145 px *(Nằm ngang)* | 540 × 150 px *(Nằm ngang)* |
| **Nút Phụ: Hint (W × H)** | 200 × 90 px | 155 × 165 px | 475 × 145 px *(Nằm ngang)* | 555 × 150 px *(Nằm ngang)* |

---

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Tiêu đề: MINESWEEPER MAZE**| 32 px | 36 px | 40 px | 42 px |
| **Tag Daily Challenge** | 20 px | 22 px | 24 px | 26 px |
| **Label "THỜI GIAN"** | 18 px | 18 px | 20 px | 22 px |
| **Giá trị Đồng hồ (00:37)** | **44 px** | **48 px** | **52 px** | **56 px** |
| **Label "BOM CÒN LẠI"** | 28 px | 28 px | 30 px | 32 px |
| **Giá trị Bom (2/3)** | **74 px** | **80 px** | **88 px** | **94 px** |
| **Số mìn 8 ô lân cận trên Board**| **64 px** | **60 px** | **60 px** | **60 px** |
| **Ký hiệu Start/Finish (S/F)**| **56 px** | **52 px** | **52 px** | **52 px** |
| **Banner Mẹo / Luật chơi** | 18 px | 22 px | 24 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | **36 px** | **40 px** | **40 px** | **42 px** |
| **Nhãn Nút Chính (GHI NHỚ)** | **32 px** | **36 px** | **40 px** | **42 px** |
| **Nhãn Nút Phụ (UNDO / HINT)**| 20 px | 20 px | 26 px | 28 px |