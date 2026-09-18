Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp toàn diện** cho chế độ **COUNTDOWN COST (TỐI ƯU CHI PHÍ / SỔ THEO DÕI NGÂN SÁCH)** trên toàn bộ **10 tỉ lệ màn hình**, được chia làm 2 nhóm: **Màn hình Dọc (Portrait - 6 tỉ lệ)** và **Màn hình Ngang (Landscape - 4 tỉ lệ)**.

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
| **HUD Trái: Timer (W × H)** | 250 × 156 px | 250 × 165 px | 250 × 170 px | 250 × 175 px | 250 × 125 px | 280 × 145 px |
| **HUD Phải: Sổ Ngân Sách (W × H)**| **710 × 156 px** | **710 × 165 px** | **710 × 170 px** | **710 × 175 px** | **730 × 125 px** | **780 × 145 px** |
| **Banner Mẹo / Tip (W × H)** | 980 × 90 px | 980 × 90 px | 980 × 100 px | 980 × 110 px | 1000 × 65 px | 1080 × 80 px |
| **Nút Chính (Vẽ / Ghi Nhớ) (W × H)**| 360 × 140 px | 360 × 150 px | 360 × 165 px | 360 × 175 px | 360 × 135 px | 395 × 160 px |
| **Nút Phụ (Undo / Hint) (W × H)** | 105 × 140 px | 105 × 150 px | 105 × 165 px | 105 × 175 px | 110 × 135 px | 115 × 160 px |

---

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Tiêu đề: COUNTDOWN COST** | 38 px | 40 px | 40 px | 42 px | 32 px | 38 px |
| **Tag Daily Challenge** | 18 px | 18 px | 18 px | 18 px | 16 px | 18 px |
| **Label "THỜI GIAN"** | 17 px | 18 px | 20 px | 20 px | 15 px | 18 px |
| **Giá trị Đồng hồ (00:36)** | **46 px** | **48 px** | **52 px** | **54 px** | **40 px** | **46 px** |
| **Sub "Phụ trợ xếp hạng"** | 14 px | 14 px | 16 px | 16 px | 12 px | 14 px |
| **Tiêu đề Thẻ Sổ Ngân Sách** | 13 px | 14 px | 15 px | 16 px | 12 px | 14 px |
| **Label "NGÂN SÁCH CÒN"** | 13 px | 14 px | 14 px | 14 px | 12 px | 13 px |
| **Giá trị Còn (08)** | **46 px** | **48 px** | **50 px** | **52 px** | **36 px** | **44 px** |
| **Mẫu số Ngân sách (/ 16)** | 20 px | 20 px | 22 px | 22 px | 16 px | 20 px |
| **Label "ĐÃ TIÊU TỐN"** | 13 px | 14 px | 14 px | 14 px | 12 px | 13 px |
| **Giá trị Đã tiêu (-08)** | **44 px** | **46 px** | **48 px** | **50 px** | **34 px** | **42 px** |
| **Sub "BƯỚC / Đã đi"** | 12 px | 12 px | 13 px | 14 px | 11 px | 12 px |
| **Label "GIÁ CƯỚC MỖI Ô"** | 12 px | 13 px | 13 px | 13 px | 12 px | 12 px |
| **Tag "1-2: RẺ / 3-4: ĐẮT"** | 12 px | 12 px | 13 px | 14 px | 11 px | 12 px |
| **Sub "Dự phòng: +3 bước"** | 11 px | 12 px | 13 px | 14 px | 10 px | 12 px |
| **Con số cước phí trên ô** | **52 px** | **52 px** | **52 px** | **52 px** | **44 px** | **50 px** |
| **Banner Mẹo / Luật chơi** | 22 px | 24 px | 24 px | 24 px | 20 px | 24 px |
| **Nhãn Nút Chính (VẼ / NHỚ)** | 28 px | 28 px | 30 px | 30 px | 26 px | 30 px |
| **Mô tả Nút Chính** | 18 px | 18 px | 18 px | 18 px | 16 px | 18 px |
| **Nút Undo: Nhãn "UNDO"** | 14 px | 16 px | 16 px | 16 px | 14 px | 16 px |
| **Nút Undo: Tag "+HOÀN"** | 12 px | 14 px | 14 px | 14 px | 12 px | 14 px |
| **Nút Gợi ý: Nhãn "GỢI Ý"** | 15 px | 16 px | 16 px | 16 px | 14 px | 16 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi 2 cột (Cột Trái: Bàn cờ vuông; Cột Phải: Sidebar chứa Header, HUD Sổ Ngân Sách, Tip và cụm Action Controls).

### 1. Layout Spec (Kích thước & Tọa độ Panel)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 60 px | 60 px | 80 px | 100 px *(Tránh Notch/Camera)* |
| **Bàn cờ vuông (Board)** | **1040 × 1040 px** | **960 × 960 px** | **960 × 960 px** | **960 × 960 px** |
| **Chiều rộng Cột Phải (Sidebar W)** | 420 px | 810 px | 980 px | 1120 px |
| **Header Panel (W × H)** | 420 × 90 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **HUD: Timer (W × H)** | 180 × 115 px | 220 × 195 px | 250 × 200 px | 280 × 210 px |
| **HUD: Sổ Ngân Sách Bước (W × H)** | **420 × 175 px** *(Dưới Timer)* | **570 × 195 px** *(Song song Timer)* | **710 × 200 px** *(Song song Timer)* | **815 × 210 px** *(Song song Timer)* |
| **Banner Mẹo / Tip (W × H)** | 420 × 90 px | 810 × 75 px | 980 × 80 px | 1120 × 85 px |
| **Nút Chính: Vẽ Đường (W × H)** | 420 × 185 px | 810 × 235 px | 475 × 250 px | 540 × 255 px |
| **Nút Chính: Ghi Nhớ (W × H)** | 420 × 135 px | 460 × 165 px | 475 × 250 px | 555 × 255 px |
| **Nút Phụ: Undo (W × H)** | 200 × 90 px | 155 × 165 px | 475 × 145 px *(Nằm ngang)* | 540 × 150 px *(Nằm ngang)* |
| **Nút Phụ: Hint (W × H)** | 200 × 90 px | 155 × 165 px | 475 × 145 px *(Nằm ngang)* | 555 × 150 px *(Nằm ngang)* |

---

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Tiêu đề: COUNTDOWN COST** | 28 px | 34 px | 38 px | 40 px |
| **Tag Daily Challenge** | 16 px | 16 px | 18 px | 18 px |
| **Label "THỜI GIAN"** | 16 px | 18 px | 20 px | 22 px |
| **Giá trị Đồng hồ (00:36)** | **40 px** | **48 px** | **52 px** | **56 px** |
| **Sub "Phụ trợ xếp hạng"** | 12 px | 14 px | 15 px | 16 px |
| **Tiêu đề Thẻ Sổ Ngân Sách** | 14 px | 14 px | 15 px | 16 px |
| **Label "NGÂN SÁCH CÒN"** | 14 px | 14 px | 15 px | 16 px |
| **Giá trị Còn (08)** | **36 px** | **44 px** | **48 px** | **50 px** |
| **Mẫu số Ngân sách (/ 16)** | 18 px | 20 px | 22 px | 24 px |
| **Label "ĐÃ TIÊU TỐN"** | 14 px | 14 px | 15 px | 16 px |
| **Giá trị Đã tiêu (-08)** | **34 px** | **42 px** | **46 px** | **48 px** |
| **Tag "1-2 RẺ / 3-4 ĐẮT"** | 12 px | 13 px | 14 px | 14 px |
| **Con số cước phí trên ô** | **56 px** | **52 px** | **52 px** | **52 px** |
| **Banner Mẹo / Luật chơi** | 18 px | 22 px | 24 px | 24 px |
| **Nhãn Nút Chính (VẼ ĐƯỜNG)** | **32 px** | **34 px** | **36 px** | **38 px** |
| **Nhãn Nút Chính (GHI NHỚ)** | **26 px** | **28 px** | **36 px** | **38 px** |
| **Mô tả Nút Chính** | 18 px | 20 px | 22 px | 24 px |
| **Nút Undo: Nhãn "UNDO"** | 16 px | 18 px | 24 px | 26 px |
| **Nút Undo: Tag "+HOÀN"** | 13 px | 14 px | 16 px | 18 px |
| **Nút Gợi ý: Nhãn "HINT / GỢI Ý"**| 18 px | 18 px | 26 px | 28 px |