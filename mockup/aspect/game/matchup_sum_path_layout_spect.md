Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho chế độ **SUM PATH (CÂN BẰNG TỔNG ĐIỂM)** trên toàn bộ **10 tỉ lệ màn hình**, được chia thành 2 nhóm: **Màn hình Dọc (Portrait)** và **Màn hình Ngang (Landscape)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (6 TỈ LỆ)
> **Bố cục:** 1 cột dọc duy nhất (từ trên xuống: Safe Area $\to$ Header $\to$ HUD 2 khối: Timer + Bảng tính toán hợp nhất $\to$ Board có số $\to$ Tip $\to$ Controls 4 nút $\to$ Gesture Bar).

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lề ngang (Padding X)** | 50 px | 50 px | 50 px | 50 px | 40 px | 60 px |
| **Top Safe Area (Y Offset)** | 70 px | 90 px | 110 px | 130 px | 35 px | 45 px |
| **Bàn cờ vuông (Board)** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** | **800 × 800 px** | **920 × 920 px** |
| **Header Panel (W × H)** | 980 × 80 px | 980 × 85 px | 980 × 90 px | 980 × 95 px | 1000 × 65 px | 1080 × 85 px |
| **HUD Trái: Timer (W × H)** | 250 × 155 px | 250 × 160 px | 250 × 165 px | 250 × 170 px | 250 × 120 px | 280 × 140 px |
| **HUD Phải: Bảng Tính (W × H)**| **715 × 155 px** | **715 × 160 px** | **715 × 165 px** | **715 × 170 px** | **735 × 120 px** | **780 × 140 px** |
| **Thanh Progress Bar (W × H)** | 655 × 12 px | 655 × 14 px | 655 × 16 px | 655 × 16 px | 685 × 12 px | 720 × 14 px |
| **Banner Mẹo / Tip (W × H)** | 980 × 90 px | 980 × 90 px | 980 × 100 px | 980 × 110 px | 1000 × 65 px | 1080 × 80 px |
| **Nút Vẽ / Ghi Nhớ (W × H)** | 360 × 150 px | 360 × 160 px | 360 × 165 px | 360 × 175 px | 360 × 135 px | 395 × 160 px |
| **Nút Undo / Hint (W × H)** | 105 × 150 px | 105 × 160 px | 105 × 165 px | 105 × 175 px | 110 × 135 px | 115 × 160 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: SUM PATH** | 38 px | 40 px | 40 px | 42 px | 32 px | 38 px |
| **Tag Header (CÂU ĐỐ SỐ HỌC)**| 18 px | 18 px | 18 px | 20 px | 16 px | 20 px |
| **Label "THỜI GIAN"** | 18 px | 20 px | 22 px | 22 px | 16 px | 20 px |
| **Giá trị Đồng hồ (00:42)** | **46 px** | **48 px** | **50 px** | **52 px** | **40 px** | **46 px** |
| **Tiêu đề Thẻ: CÂN BẰNG ĐIỂM**| 14 px | 14 px | 14 px | 14 px | 13 px | 14 px |
| **Label "TỔNG HIỆN TẠI"** | 14 px | 14 px | 16 px | 16 px | 13 px | 14 px |
| **Số Tổng Hiện Tại (16)** | **44 px** | **46 px** | **48 px** | **50 px** | **38 px** | **44 px** |
| **Dấu Đẳng Thức (=)** | **34 px** | **36 px** | **38 px** | **40 px** | **30 px** | **34 px** |
| **Label "MỤC TIÊU PHẢI ĐẠT"**| 14 px | 14 px | 16 px | 16 px | 13 px | 14 px |
| **Số Mục Tiêu Cần Đạt (50)** | **44 px** | **46 px** | **48 px** | **50 px** | **38 px** | **44 px** |
| **Chip Trạng Thái ("+34")** | 13 px | 14 px | 14 px | 14 px | 12 px | 13 px |
| **Số manh mối trên Board** | **52 px** | **52 px** | **52 px** | **52 px** | **44 px** | **50 px** |
| **Banner Mẹo / Luật chơi** | 22 px | 24 px | 24 px | 24 px | 20 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | 28 px | 28 px | 30 px | 30 px | 26 px | 30 px |
| **Mô tả Nút Chính ("Kéo từ tâm")**| 18 px | 18 px | 18 px | 18 px | 16 px | 20 px |
| **Nhãn Nút Phụ (UNDO / HINT)** | 18 px | 18 px | 18 px | 18 px | 16 px | 20 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình (Bên Trái: Bàn cờ vuông có số; Bên Phải: Cột Sidebar chứa Header, HUD Timer + Bảng tính, Tip và Controls).

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 60 px | 60 px | 80 px | 100 px *(Tránh Notch)* |
| **Bàn cờ vuông (Board)** | **1040 × 1040 px** | **960 × 960 px** | **960 × 960 px** | **960 × 960 px** |
| **Chiều rộng Sidebar Phải** | 420 px | 810 px | 980 px | 1120 px |
| **Header Panel (W × H)** | 420 × 85 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **HUD: Timer (W × H)** | 420 × 110 px | 240 × 185 px | 270 × 195 px | 310 × 205 px |
| **HUD: Bảng Tính (W × H)** | 420 × 210 px | 550 × 185 px | 690 × 195 px | 790 × 205 px |
| **Thanh Progress Bar (W × H)** | 370 × 14 px | 500 × 12 px | 630 × 14 px | 720 × 16 px |
| **Banner Mẹo / Tip (W × H)** | 420 × 95 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **Nút Chính: Vẽ Đường (W × H)** | 420 × 180 px | 810 × 235 px | 475 × 240 px | 540 × 255 px |
| **Nút Chính: Ghi Nhớ (W × H)** | 420 × 135 px | 460 × 165 px | 475 × 240 px | 555 × 255 px |
| **Nút Phụ: Undo / Hint (W × H)** | 200 × 135 px *(Mỗi nút)* | 155 × 165 px *(Mỗi nút)* | 475 × 145 px *(Ngang)* | 540 × 145 px *(Ngang)* |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: SUM PATH** | 36 px | 38 px | 40 px | 42 px |
| **Tag Header (CÂU ĐỐ SỐ HỌC)**| 18 px | 18 px | 20 px | 20 px |
| **Label "THỜI GIAN"** | 18 px | 18 px | 20 px | 22 px |
| **Giá trị Đồng hồ (00:42)** | **42 px** | **48 px** | **52 px** | **56 px** |
| **Tiêu đề Thẻ: CÂN BẰNG ĐIỂM**| 14 px | 14 px | 16 px | 16 px |
| **Label "TỔNG HIỆN TẠI"** | 14 px | 14 px | 16 px | 16 px |
| **Số Tổng Hiện Tại (16)** | **40 px** | **44 px** | **48 px** | **50 px** |
| **Dấu Đẳng Thức (=)** | **28 px** | **32 px** | **34 px** | **38 px** |
| **Label "MỤC TIÊU PHẢI ĐẠT"**| 14 px | 14 px | 16 px | 16 px |
| **Số Mục Tiêu Cần Đạt (50)** | **40 px** | **44 px** | **48 px** | **50 px** |
| **Chip Trạng Thái ("+34")** | 14 px | 14 px | 16 px | 16 px |
| **Số manh mối trên Board** | **56 px** | **52 px** | **52 px** | **52 px** |
| **Banner Mẹo / Luật chơi** | 20 px | 22 px | 24 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | **32 px** | **36 px** | **36 px** | **38 px** |
| **Mô tả Nút Chính ("Kéo từ tâm")**| 20 px | 22 px | 22 px | 24 px |
| **Nhãn Nút Phụ (UNDO / HINT)** | 22 px | 20 px | 26 px | 28 px |