Dưới đây là bản tóm tắt **Font & Layout Spec** chi tiết cho toàn bộ 10 tỉ lệ màn hình, chia thành 2 nhóm: **Màn hình Dọc** và **Màn hình Ngang**.

---

### PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT)
> **Bố cục chung:** 1 cột dọc duy nhất (Top to Bottom: Header $\to$ HUD $\to$ Board $\to$ Tips $\to$ Controls).

#### 1. Bảng Thông Số Layout (Kích Thước & Vị Trí Panel)

| Thành phần UI | 3:4 · 1080×1440 | 3:4 · 1200×1600 | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lề màn hình (Padding X)** | 40 px | 60 px | 50 px | 50 px | 50 px | 50 px |
| **Kích thước Bàn cờ (Board)** | **800 × 800 px** | **920 × 920 px** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** |
| **Top Safe Area (Y Offset)** | 40 px | 50 px | 70 px | 90 px | 110 px | 130 px |
| **Header Panel (W × H)** | 1000 × 70 px | 1080 × 85 px | 980 × 80 px | 980 × 85 px | 980 × 90 px | 980 × 95 px |
| **HUD: Thẻ Thời Gian (W × H)** | 280 × 120 px | 310 × 140 px | 250 × 145 px | 250 × 155 px | 260 × 160 px | 270 × 170 px |
| **HUD: Thẻ Thử Thách (W × H)**| 700 × 120 px | 750 × 140 px | 710 × 145 px | 710 × 155 px | 700 × 160 px | 690 × 170 px |
| **Banner Hướng Dẫn/Tip (W × H)**| 1000 × 65 px | 1080 × 80 px | 980 × 85 px | 980 × 90 px | 980 × 100 px | 980 × 110 px |
| **Nút Chính: Vẽ / Ghi Nhớ (W × H)**| 360 × 135 px | 395 × 160 px | 360 × 150 px | 360 × 160 px | 360 × 165 px | 360 × 175 px |
| **Nút Phụ: Undo / Hint (W × H)**| 110 × 135 px | 115 × 160 px | 105 × 150 px | 105 × 160 px | 105 × 165 px | 105 × 175 px |

#### 2. Bảng Thông Số Cỡ Chữ (Font Size Spec)

| Text Item | 3:4 · 1080×1440 | 3:4 · 1200×1600 | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Màn chơi (MÀN 04)** | 32 px | 38 px | 38 px | 40 px | 40 px | 42 px |
| **Tag Chương / Mode** | 18 px | 20 px | 18 px | 18 px | 20 px | 20 px |
| **Đồng hồ Thời gian (01:24)** | **44 px** | **50 px** | **46 px** | **48 px** | **52 px** | **54 px** |
| **Label "THỜI GIAN"** | 18 px | 22 px | 20 px | 20 px | 22 px | 22 px |
| **Tổng kết Challenge (1/3 ✓)** | 36 px | 42 px | 48 px | 48 px | 50 px | 52 px |
| **Dòng Thử thách (3 items)** | 18 px | 22 px | 20 px | 20 px | 20 px | 22 px |
| **Số manh mối trên Board** | **44 px** | **50 px** | **52 px** | **52 px** | **52 px** | **52 px** |
| **Banner Mẹo / Luật chơi** | 20 px | 24 px | 22 px | 24 px | 24 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | **26 px** | **30 px** | **28 px** | **28 px** | **30 px** | **30 px** |
| **Mô tả Nút Chính ("Kéo từ tâm")**| 18 px | 20 px | 18 px | 18 px | 18 px | 18 px |
| **Nhãn Nút Phụ (UNDO / HINT)**| 18 px | 20 px | 18 px | 18 px | 18 px | 18 px |

---

### PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE)
> **Bố cục chung:** Chia đôi 2 cột (Cột Trái: Bàn cờ vuông; Cột Phải: Sidebar chứa Header, HUD, Tips, Controls).

#### 1. Bảng Thông Số Layout (Kích Thước & Vị Trí Panel)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 60 px | 60 px | 80 px | 100 px *(Tránh Notch/Camera)* |
| **Kích thước Bàn cờ (Board)** | **1040 × 1040 px** | **960 × 960 px** | **960 × 960 px** | **960 × 960 px** |
| **Chiều rộng Sidebar Phải (Width)** | 420 px | 820 px | 1000 px | 1180 px |
| **Header Panel (W × H)** | 420 × 100 px | 810 × 80 px | 980 × 85 px | 1120 × 90 px |
| **HUD Thẻ Thời Gian (W × H)** | Gộp chung HUD *(cao 340)* | 270 × 230 px | 310 × 230 px | 340 × 235 px |
| **HUD Thẻ Thử Thách (W × H)** | Gộp chung HUD *(cao 340)* | 520 × 230 px | 650 × 230 px | 755 × 235 px |
| **Banner Mẹo / Tip (W × H)** | 420 × 110 px | 810 × 80 px | 980 × 85 px | 1120 × 90 px |
| **Nút Chính: Vẽ Đường (W × H)** | 420 × 180 px | 810 × 220 px | 475 × 230 px | 540 × 230 px |
| **Nút Chính: Ghi Nhớ (W × H)** | 420 × 130 px | 460 × 150 px | 475 × 230 px | 555 × 230 px |
| **Nút Phụ: Undo / Hint (W × H)**| 200 × 80 px *(Mỗi nút)* | 155 × 150 px *(Mỗi nút)*| 475 × 130 px *(Nằm ngang)*| 540 × 135 px *(Nằm ngang)*|

#### 2. Bảng Thông Số Cỡ Chữ (Font Size Spec)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Màn chơi (MÀN 04)** | 36 px | 38 px | 40 px | 42 px |
| **Tag Chương / Mode** | 18 px | 18 px | 20 px | 20 px |
| **Đồng hồ Thời gian (01:24)** | **48 px** | **52 px** | **56 px** | **58 px** |
| **Label "THỜI GIAN"** | 22 px | 22 px | 24 px | 24 px |
| **Tổng kết Challenge (1/3 ✓)** | 32 px | 44 px | 46 px | 48 px |
| **Dòng Thử thách (3 items)** | 20 px | 20 px | 22 px | 24 px |
| **Số manh mối trên Board** | **56 px** | **52 px** | **52 px** | **52 px** |
| **Banner Mẹo / Luật chơi** | 20 px | 22 px | 24 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | **32 px** | **34 px** | **34 px** | **36 px** |
| **Mô tả Nút Chính ("Kéo từ tâm")**| 20 px | 22 px | 22 px | 22 px |
| **Nhãn Nút Phụ (UNDO / HINT)**| 22 px | 20 px | 26 px | 28 px |