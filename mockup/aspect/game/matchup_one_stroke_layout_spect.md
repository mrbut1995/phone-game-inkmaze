Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho chế độ **MỘT NÉT (ONE STROKE)** trên toàn bộ **10 tỉ lệ màn hình**, được phân tách thành 2 nhóm: **Màn hình Dọc (Portrait)** và **Màn hình Ngang (Landscape)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (6 TỈ LỆ)
> **Bố cục:** 1 cột dọc duy nhất (từ trên xuống: Safe Area $\to$ Header $\to$ HUD 2 thẻ (Timer + Phủ kín) $\to$ Board không số $\to$ Tip $\to$ Controls (Nút Vẽ to + Undo/Hint) $\to$ Gesture Bar).

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lề ngang (Padding X)** | 50 px | 50 px | 50 px | 50 px | 40 px | 60 px |
| **Top Safe Area (Y Offset)** | 70 px | 90 px | 110 px | 130 px | 35 px | 45 px |
| **Bàn cờ vuông (Board)** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** | **980 × 980 px** | **800 × 800 px** | **920 × 920 px** |
| **Header Panel (W × H)** | 980 × 80 px | 980 × 85 px | 980 × 90 px | 980 × 95 px | 1000 × 65 px | 1080 × 85 px |
| **HUD Trái: Timer (W × H)** | 270 × 155 px | 270 × 160 px | 270 × 165 px | 270 × 170 px | 270 × 120 px | 300 × 140 px |
| **HUD Phải: Phủ Kín (W × H)**| 690 × 155 px | 690 × 160 px | 690 × 165 px | 690 × 170 px | 710 × 120 px | 760 × 140 px |
| **Banner Mẹo / Tip (W × H)** | 980 × 90 px | 980 × 90 px | 980 × 100 px | 980 × 110 px | 1000 × 65 px | 1080 × 80 px |
| **Nút Vẽ Đường (To bản W × H)**| **680 × 150 px** | **680 × 160 px** | **680 × 165 px** | **680 × 175 px** | **690 × 135 px** | **760 × 160 px** |
| **Nút Undo / Hint (W × H)** | 135 × 150 px | 135 × 160 px | 135 × 165 px | 135 × 175 px | 135 × 135 px | 140 × 160 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: MÀN CHƠI / MODE** | 38 px | 40 px | 40 px | 42 px | 32 px | 38 px |
| **Tag Header (DAILY CHALLENGE)**| 18 px | 18 px | 18 px | 20 px | 16 px | 20 px |
| **Label "THỜI GIAN"** | 18 px | 20 px | 22 px | 22 px | 16 px | 20 px |
| **Giá trị Đồng hồ (00:38)** | **48 px** | **50 px** | **52 px** | **54 px** | **42 px** | **48 px** |
| **Label "ĐÃ PHỦ KÍN"** | 18 px | 20 px | 20 px | 22 px | 16 px | 20 px |
| **Số đếm ô (13/25 Ô)** | **52 px** | **54 px** | **54 px** | **56 px** | **44 px** | **50 px** |
| **Tiến độ / Slider / Tag %** | 16 – 18 px | 18 – 20 px | 20 px | 22 px | 16 px | 18 – 20 px |
| **Số manh mối trên Board** | **0 px (Không có)**| **0 px (Không có)**| **0 px (Không có)**| **0 px (Không có)**| **0 px (Không có)**| **0 px (Không có)**|
| **Banner Mẹo / Luật chơi** | 22 px | 24 px | 24 px | 24 px | 20 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | **30 px** | **30 px** | **32 px** | **32 px** | **26 px** | **32 px** |
| **Mô tả Nút Chính ("Kín trang")**| 20 px | 20 px | 20 px | 20 px | 16 px | 20 px |
| **Nhãn Nút Phụ (UNDO / HINT)** | 18 px | 18 px | 18 px | 18 px | 16 px | 20 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình (Bên Trái: Bàn cờ vuông không số; Bên Phải: Sidebar chứa Header, HUD Timer + Phủ Kín, Tip và Cụm phím Vẽ Đường mở rộng).

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 60 px | 60 px | 80 px | 100 px *(Tránh Notch)* |
| **Bàn cờ vuông (Board)** | **1040 × 1040 px** | **960 × 960 px** | **960 × 960 px** | **960 × 960 px** |
| **Chiều rộng Cột Phải (Sidebar W)** | 420 px | 810 px | 980 px | 1120 px |
| **Header Panel (W × H)** | 420 × 90 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **HUD: Timer (W × H)** | 420 × 120 px | 270 × 180 px | 310 × 190 px | 340 × 200 px |
| **HUD: Phủ Kín (W × H)** | 420 × 180 px | 520 × 180 px | 650 × 190 px | 755 × 200 px |
| **Banner Mẹo / Tip (W × H)** | 420 × 100 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **Nút Vẽ Đường (To bản W × H)**| **420 × 280 px** *(To ở trên)* | **560 × 235 px** *(Ngang)* | **680 × 245 px** *(Ngang)* | **780 × 260 px** *(Ngang)* |
| **Nút Undo / Hint (W × H)** | 200 × 185 px *(Mỗi nút dưới)* | 110 × 235 px *(Cột dọc)* | 135 × 245 px *(Cột dọc)* | 150 × 260 px *(Cột dọc)* |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: MÀN CHƠI / MODE** | 36 px | 38 px | 40 px | 42 px |
| **Tag Header (DAILY CHALLENGE)**| 18 px | 18 px | 20 px | 20 px |
| **Label "THỜI GIAN"** | 18 px | 18 px | 20 px | 22 px |
| **Giá trị Đồng hồ (00:38)** | **44 px** | **50 px** | **54 px** | **56 px** |
| **Label "ĐÃ PHỦ KÍN"** | 20 px | 20 px | 22 px | 24 px |
| **Số đếm ô (13/25 Ô)** | **48 px** | **48 px** | **52 px** | **56 px** |
| **Nội dung Tip / Slider tiến độ**| 18 px | 18 px | 20 px | 22 px |
| **Số manh mối trên Board** | **0 px (Không có)**| **0 px (Không có)**| **0 px (Không có)**| **0 px (Không có)**|
| **Banner Mẹo / Luật chơi** | 20 px | 22 px | 24 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | **34 px** | **36 px** | **38 px** | **40 px** |
| **Mô tả Nút Chính ("Kín trang")**| 20 px | 22 px | 22 px | 24 px |
| **Nhãn Nút Phụ (UNDO / HINT)** | 22 px | 20 px | 22 px | 24 px |