Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **ACHIEVEMENT SCENE (Sổ Tay Thành Tựu)** trên toàn bộ **10 tỉ lệ màn hình**, được chia thành 2 nhóm: **Màn hình Dọc (Portrait — 6 tỉ lệ)** và **Màn hình Ngang (Landscape — 4 tỉ lệ)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc thống nhất nằm trọn trong trang giấy sổ còng (Sheet). Thứ tự từ trên xuống: Safe Area $\to$ Top Header (Nút Back + Tiêu đề) $\to$ Thẻ Overview (Tiến độ % + AP) $\to$ Hàng 4 Tab phân loại $\to$ Danh sách cuộn các Thẻ Thành Tựu $\to$ Footer (Quote + Con dấu Badges).

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Top Safe Area (Y Offset Sheet)** | 190 px | 210 px | 225 px | 245 px | 125 px | 135 px |
| **Kích thước Tờ Giấy Sổ (Sheet)** | **920 × 1550 px** | **920 × 1760 px** | **920 × 1920 px** | **920 × 2080 px** | **960 × 1260 px** | **1060 × 1420 px** |
| **Nút Back (W × H)** | 70 × 70 px | 85 × 85 px | 85 × 85 px | 90 × 90 px | 70 × 70 px | 75 × 75 px |
| **Thẻ Tổng Kết Overview (W × H)** | **710 × 120 px** | **710 × 135 px** | **710 × 140 px** | **710 × 150 px** | **740 × 105 px** | **840 × 120 px** |
| **Thanh Slider Bar Tiến Độ** | 440 × 14 px | 440 × 16 px | 440 × 16 px | 440 × 18 px | 420 × 12 px | 500 × 14 px |
| **Hàng Tab Phân Loại (Mỗi tab)** | 170 × 46 px | 170 × 50 px | 170 × 52 px | 170 × 54 px | 175 × 42 px | 200 × 46 px |
| **Thẻ Thành Tựu Item (W × H)** | **710 × 170 px** | **710 × 175 px** | **710 × 180 px** | **710 × 185 px** | **740 × 145 px** | **840 × 165 px** |
| **Nút "NHẬN THƯỞNG" (Claim Btn)** | 165 × 52 px | 165 × 54 px | 170 × 56 px | 170 × 58 px | 150 × 46 px | 175 × 50 px |
| **Mộc Đã Đạt / Con Dấu Stamp** | 125 × 74 px | 130 × 76 px | 130 × 76 px | 135 × 78 px | 115 × 65 px | 130 × 70 px |
| **Huy Hiệu Badge Stamp Footer** | 150 × 46 px | 150 × 48 px | 150 × 48 px | 150 × 50 px | 150 × 42 px | 160 × 46 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: SỔ TAY THÀNH TỰU** | **44 px** | **44 px** | **46 px** | **46 px** | **36 px** | **40 px** |
| **Tiêu đề Overview Card** | 20 px | 22 px | 22 px | 24 px | 18 px | 22 px |
| **% Tiến độ Slider (72%)** | 18 px | 18 px | 18 px | 20 px | 16 px | 18 px |
| **Chi tiết Overview (Đã mở 18/25)**| 15 px | 16 px | 16 px | 16 px | 14 px | 16 px |
| **Nhãn 4 Tab (TẤT CẢ, MÀN...)** | 16 px | 16 px | 17 px | 18 px | 15 px | 16 px |
| **Tên Thành Tựu (Item Title)** | **22 px** | **24 px** | **24 px** | **26 px** | **20 px** | **24 px** |
| **Mô tả Thành Tựu (Subtext)** | 16 px | 16 px | 18 px | 18 px | 15 px | 16 px |
| **Text Tiến độ Thẻ ("10/10 Màn")** | 14 px | 14 px | 15 px | 15 px | 13 px | 14 px |
| **Chữ Mộc "ĐÃ ĐẠT"** | 18 px | 18 px | 18 px | 18 px | 16 px | 18 px |
| **Nút "NHẬN +100 💵"** | **16 px** | **16 px** | **17 px** | **18 px** | **15 px** | **17 px** |
| **Huy hiệu Thưởng ("Thưởng +150")** | 15 px | 15 px | 16 px | 16 px | 14 px | 15 px |
| **Quote Chân Trang (Slogan)** | 18 px | 20 px | 20 px | 20 px | 16 px | 18 px |
| **Dấu Mộc Footer (18/25 BADGES)** | 16 px | 16 px | 16 px | 16 px | 15 px | 16 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi (Split-View / Master-Detail):
> - **Cột Trái (Sidebar / Overview):** Nút Back, Header, Thẻ Overview tiến độ, 4 Tab lọc danh mục, Quote và Con dấu chân trang.
> - **Cột Phải (Scroll Area):** Danh sách cuộn các Thẻ Thành Tựu to bản, thông thoáng.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 50 px | 60 px | 100 px *(Tránh Notch/Camera)* |
| **Kích thước Tờ Giấy Sổ (Sheet)** | **1500 × 1100 px** | **1820 × 980 px** | **2040 × 980 px** | **2140 × 980 px** |
| **Chiều rộng Cột Trái (Sidebar/Overview)**| 510 px | 630 px | 720 px | 760 px |
| **Chiều rộng Cột Phải (Scroll List)** | 850 px | 1050 px | 1160 px | 1220 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px |
| **Thẻ Tổng Kết Overview (W × H)** | **510 × 220 px** | **630 × 200 px** | **720 × 205 px** | **760 × 210 px** |
| **Thanh Slider Bar Tiến Độ** | 420 × 16 px | 500 × 16 px | 560 × 16 px | 600 × 18 px |
| **Hàng Tab Phân Loại (Mỗi tab)** | 510 × 60 px *(Xếp dọc)* | 305 × 58 px *(2×2)* | 350 × 60 px *(2×2)* | 370 × 62 px *(2×2)* |
| **Thẻ Thành Tựu Item (W × H)** | **850 × 195 px** | **1050 × 205 px** | **1160 × 205 px** | **1220 × 205 px** |
| **Nút "NHẬN THƯỞNG" (Claim Btn)** | 180 × 54 px | 195 × 56 px | 205 × 58 px | 215 × 60 px |
| **Mộc Đã Đạt / Con Dấu Stamp** | 130 × 74 px | 135 × 76 px | 140 × 78 px | 145 × 80 px |
| **Huy Hiệu Badge Stamp Footer** | 180 × 55 px | 180 × 55 px | 190 × 58 px | 200 × 60 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: SỔ TAY THÀNH TỰU** | **36 px** | **38 px** | **40 px** | **42 px** |
| **Tiêu đề Overview Card** | 22 px | 24 px | 24 px | 26 px |
| **% Tiến độ Slider (72%)** | 20 px | 20 px | 20 px | 22 px |
| **Chi tiết Overview (Đã mở 18/25)**| 16 px | 16 px | 16 px | 18 px |
| **Nhãn 4 Tab (TẤT CẢ, MÀN...)** | 18 px | 18 px | 18 px | 18 px |
| **Tên Thành Tựu (Item Title)** | **24 px** | **26 px** | **28 px** | **30 px** |
| **Mô tả Thành Tựu (Subtext)** | 16 px | 18 px | 18 px | 18 px |
| **Text Tiến độ Thẻ ("10/10 Màn")** | 14 px | 14 px | 15 px | 15 px |
| **Chữ Mộc "ĐÃ ĐẠT"** | 18 px | 18 px | 18 px | 20 px |
| **Nút "NHẬN +100 💵"** | **18 px** | **18 px** | **18 px** | **20 px** |
| **Huy hiệu Thưởng ("Thưởng +150")** | 16 px | 16 px | 16 px | 16 px |
| **Quote Chân Trang (Slogan)** | 16 px | 18 px | 18 px | 18 px |
| **Dấu Mộc Footer (18/25 BADGES)** | 18 px | 18 px | 18 px | 20 px |