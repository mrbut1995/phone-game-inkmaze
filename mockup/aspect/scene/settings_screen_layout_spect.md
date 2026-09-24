Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **SETTINGS SCREEN (Cài Đặt Hệ Thống)** trên toàn bộ **10 tỉ lệ màn hình**, được phân chia theo 2 nhóm: **Màn hình Dọc (Portrait — 6 tỉ lệ)** và **Màn hình Ngang (Landscape — 4 tỉ lệ)**.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc thống nhất nằm trọn trong trang giấy sổ còng (Sheet). Thứ tự từ trên xuống: Safe Area $\to$ Top Header (Nút Back + Tiêu đề) $\to$ Tiêu đề phụ $\to$ Mục 1: Âm thanh (Sliders) $\to$ Mục 2: Bàn cờ & Điều khiển (Checkboxes) $\to$ Mục 3: Ngôn ngữ & Lưu trữ (Dropdown + Cloud + Player ID) $\to$ Mục 4: Hỗ trợ & Thao tác (Luật chơi & Reset) $\to$ Footer (Slogan + Con dấu Version) $\to$ Gesture Bar.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Top Safe Area (Y Offset Sheet)** | 190 px | 210 px | 225 px | 245 px | 115 px | 130 px |
| **Kích thước Tờ Giấy Sổ (Sheet)** | **920 × 1550 px** | **920 × 1760 px** | **920 × 1920 px** | **920 × 2080 px** | **960 × 1260 px** | **1060 × 1420 px** |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px | 65 × 65 px | 70 × 70 px |
| **Thanh Trượt Slider BGM/SFX** | 360 × 12 px | 360 × 14 px | 360 × 16 px | 360 × 16 px | 320 × 12 px | 380 × 14 px |
| **Nút Vuông Checkbox (W × H)** | 38 × 38 px | 40 × 40 px | 42 × 42 px | 42 × 42 px | 34 × 34 px | 38 × 38 px |
| **Khung Dropdown Ngôn Ngữ** | 310 × 54 px | 310 × 56 px | 310 × 58 px | 310 × 58 px | 280 × 48 px | 320 × 52 px |
| **Nút Đồng Bộ Đám Mây (Cloud)**| 160 × 42 px | 160 × 44 px | 165 × 44 px | 170 × 44 px | 140 × 38 px | 160 × 40 px |
| **Thẻ Nút Hướng Dẫn Luật Chơi** | **710 × 80 px** | **710 × 85 px** | **710 × 90 px** | **710 × 95 px** | **740 × 70 px** | **840 × 75 px** |
| **Thẻ Nút Reset Mặc Định** | **710 × 80 px** | **710 × 85 px** | **710 × 90 px** | **710 × 95 px** | **740 × 70 px** | **840 × 75 px** |
| **Con Dấu Version Stamp (W × H)** | 150 × 50 px | 150 × 50 px | 150 × 50 px | 150 × 50 px | 150 × 45 px | 160 × 48 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: CÀI ĐẶT HỆ THỐNG** | **44 px** | **44 px** | **46 px** | **46 px** | **36 px** | **40 px** |
| **Tiêu đề phụ ("THIẾT LẬP...")**| 34 px | 36 px | 36 px | 36 px | 28 px | 32 px |
| **Tag Danh mục ("ÂM THANH"...)**| 14 px | 14 px | 14 px | 14 px | 12 px | 13 px |
| **Tên Tùy chọn (BGM, Haptic...)**| **22 px** | **22 px** | **22 px** | **22 px** | **18 px** | **20 px** |
| **Mô tả Tùy chọn (Subtext)** | 16 px | 16 px | 16 px | 18 px | 14 px | 15 px |
| **Chỉ số Slider ("70%", "85%")** | 22 px | 22 px | 22 px | 22 px | 18 px | 20 px |
| **Text Dropdown ("Tiếng Việt")** | 18 px | 18 px | 18 px | 18 px | 16 px | 17 px |
| **Trạng thái Cloud ("ĐÃ KẾT NỐI")**| 15 px | 15 px | 15 px | 16 px | 13 px | 14 px |
| **Chữ Mã Player ID** | 20 px | 20 px | 20 px | 22 px | 16 px | 18 px |
| **Chữ Nút Luật Chơi / Reset** | **22 px** | **22 px** | **22 px** | **22 px** | **18 px** | **20 px** |
| **Quote Chân Trang (Footer)** | 18 px | 18 px | 18 px | 18 px | 14 px | 16 px |
| **Con dấu VER 1.0.0** | 17 px | 17 px | 17 px | 17 px | 15 px | 16 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình thành 2 cột:
> - **Cột Trái (Audio & Controls):** Mục 1 (Thanh trượt BGM & SFX) và Mục 2 (3 Checkbox xúc giác, gạch cạnh an toàn, dạ quang).
> - **Cột Phải (System & Actions):** Mục 3 (Dropdown Ngôn ngữ, Đám mây Cloud, Player ID) và Mục 4 (Nút xem 9 luật chơi & Nút Reset mặc định), Footer con dấu version.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 50 px | 60 px | 100 px *(Tránh Notch/Camera)* |
| **Kích thước Tờ Giấy Sổ (Sheet)** | **1500 × 1100 px** | **1820 × 980 px** | **2040 × 980 px** | **2140 × 980 px** |
| **Chiều rộng Cột Trái (Audio & Controls)**| 680 px | 840 px | 940 px | 980 px |
| **Chiều rộng Cột Phải (System & Actions)**| 680 px | 840 px | 940 px | 980 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px |
| **Thanh Trượt Slider (W × H)** | 360 × 14 px | 450 × 14 px | 500 × 14 px | 530 × 14 px |
| **Nút Vuông Checkbox (W × H)** | 38 × 38 px | 40 × 40 px | 42 × 42 px | 42 × 42 px |
| **Khung Dropdown Ngôn Ngữ** | 310 × 52 px | 350 × 52 px | 380 × 54 px | 400 × 56 px |
| **Nút Đồng Bộ Đám Mây (Cloud Btn)**| 160 × 42 px | 170 × 42 px | 180 × 44 px | 180 × 44 px |
| **Thẻ Nút Hướng Dẫn Luật Chơi** | **680 × 85 px** | **800 × 85 px** | **890 × 90 px** | **940 × 90 px** |
| **Thẻ Nút Reset Mặc Định** | **680 × 85 px** | **800 × 85 px** | **890 × 90 px** | **940 × 90 px** |
| **Con Dấu Version Stamp (W × H)** | 160 × 50 px | 160 × 50 px | 170 × 52 px | 180 × 54 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: CÀI ĐẶT HỆ THỐNG** | **40 px** | **42 px** | **44 px** | **46 px** |
| **Tag Danh mục ("ÂM THANH"...)**| 14 px | 14 px | 14 px | 14 px |
| **Tên Tùy chọn (BGM, Haptic...)**| **20 px** | **22 px** | **22 px** | **22 px** |
| **Mô tả Tùy chọn (Subtext)** | 15 px | 16 px | 16 px | 16 px |
| **Chỉ số Slider ("70%", "85%")** | 20 px | 20 px | 20 px | 22 px |
| **Text Dropdown ("Tiếng Việt")** | 18 px | 18 px | 18 px | 18 px |
| **Trạng thái Cloud ("ĐÃ KẾT NỐI")**| 15 px | 15 px | 15 px | 15 px |
| **Chữ Mã Player ID** | 18 px | 20 px | 20 px | 22 px |
| **Chữ Nút Luật Chơi / Reset** | **22 px** | **22 px** | **22 px** | **24 px** |
| **Quote Chân Trang (Footer)** | 18 px | 18 px | 18 px | 18 px |
| **Con dấu VER 1.0.0** | 16 px | 16 px | 17 px | 17 px |