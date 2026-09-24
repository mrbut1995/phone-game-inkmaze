Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **LEVEL SELECTION (Màn Hình Chọn Màn Chơi)** trên toàn bộ **10 tỉ lệ màn hình**, được phân chia theo 2 nhóm: **Màn hình Dọc (Portrait — 6 tỉ lệ)** và **Màn hình Ngang (Landscape — 4 tỉ lệ)**, kèm quy chuẩn trạng thái thẻ level.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc thống nhất từ trên xuống: Top Header (Nút Back + Tiêu đề + Thẻ Tổng Sao) $\to$ Khung Thông Tin Chương (Chapter Banner kèm Slider Bar) $\to$ Ma trận Lưới 3×3 Thẻ Level (9 màn/trang) $\to$ Phân trang Dots Pagination $\to$ Nút Lớn Hành Động Chân Trang $\to$ Gesture Bar.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Lề ngang (Padding X)** | 55 px | 55 px | 55 px | 55 px | 40 px | 60 px |
| **Top Safe Area (Y Offset)** | 90 px | 90 px | 110 px | 130 px | 30 px | 40 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px | 65 × 65 px | 70 × 70 px |
| **Thẻ Tổng Sao (Star Wallet)**| 200 × 70 px | 200 × 75 px | 200 × 80 px | 200 × 85 px | 210 × 65 px | 220 × 70 px |
| **Khung Chương (Chapter Banner)**| **970 × 140 px** | **970 × 150 px** | **970 × 155 px** | **970 × 165 px** | **1000 × 95 px** | **1080 × 115 px** |
| **Thanh Slider Bar Tiến Độ** | 760 × 14 px | 760 × 14 px | 760 × 16 px | 760 × 16 px | 780 × 12 px | 840 × 14 px |
| **Bố Cục Lưới Thẻ Level** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** |
| **Thẻ Màn Chơi Card (W × H)** | **290 × 350 px** | **290 × 365 px** | **290 × 375 px** | **290 × 385 px** | **310 × 270 px** | **335 × 310 px** |
| **Khoảng Cách Dọc Giữa Các Hàng**| 40 px | 45 px | 50 px | 55 px | 20 px | 30 px |
| **Chỉ Số Trang (Dots Pagination)**| 34 × 12 px *(Trang active)* | 34 × 12 px | 36 × 12 px | 36 × 12 px | 30 × 10 px | 30 × 10 px |
| **Nút Hành Động Chân Trang** | **800 × 120 px** | **800 × 130 px** | **800 × 135 px** | **800 × 140 px** | **800 × 95 px** | **800 × 110 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: CHỌN MÀN CHƠI** | **44 px** | **44 px** | **46 px** | **46 px** | **36 px** | **40 px** |
| **Tổng Sao Tích Lũy ("28/45")** | 28 px | 28 px | 30 px | 30 px | 22 px | 24 px |
| **Tên Chương ("CHƯƠNG 1...")** | **26 px** | **26 px** | **28 px** | **28 px** | **22 px** | **24 px** |
| **Nút "ĐỔI CHƯƠNG ›"** | 22 px | 22 px | 22 px | 24 px | 16 px | 18 px |
| **% Hoàn Thành Chương ("65%")**| 22 px | 22 px | 22 px | 24 px | 16 px | 18 px |
| **Nhãn Thẻ Màn ("MÀN", "MÀN TIẾP")**| 18 px | 18 px | 18 px | 20 px | 14 px | 16 px |
| **Số Màn Đã Xong ("01", "02"...)**| **88 px** | **88 px** | **88 px** | **90 px** | **64 px** | **70 px** |
| **Số Màn Focus Đang Chờ ("07")** | **94 px** | **94 px** | **96 px** | **96 px** | **68 px** | **74 px** |
| **Số Màn Khóa ("08", "09")** | 60 px | 60 px | 60 px | 62 px | 44 px | 50 px |
| **Nhãn Góc Thẻ Focus ("NEW")** | 13 px | 13 px | 14 px | 14 px | 11 px | 12 px |
| **Nút "TIẾP TỤC MÀN 07"** | **34 px** | **34 px** | **36 px** | **36 px** | **28 px** | **32 px** |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình thành 2 cột độc lập:
> - **Cột Trái (Sidebar — Thông Tin & Điều Khiển):** Top Header, Thẻ Tổng Sao, Khung Thông Tin Chương (Chapter Banner kèm tiến độ slider), Nút Lớn *"TIẾP TỤC MÀN 07"* gắn cố định ở đáy.
> - **Cột Phải (Level Matrix — Ma Trận 3×3 Màn Chơi):** Toàn bộ 9 màn chơi dàn trải theo lưới **3 Cột × 3 Hàng** không cần cuộn trang, thanh phân trang Dots ở dưới cùng.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 60 px | 70 px | 120 px *(Tránh Notch/Camera)* |
| **Chiều rộng Cột Trái (Sidebar)** | 460 px | 560 px | 610 px | 625 px |
| **Chiều rộng Cột Phải (Level Matrix)**| 980 px | 1200 px | 1340 px | 1400 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px |
| **Thẻ Tổng Sao (Star Wallet)**| 460 × 100 px | 560 × 95 px | 610 × 100 px | 625 × 105 px |
| **Khung Chương (Chapter Banner)**| **460 × 240 px** | **560 × 230 px** | **610 × 240 px** | **625 × 245 px** |
| **Thanh Slider Bar Tiến Độ** | 400 × 14 px | 500 × 14 px | 540 × 14 px | 545 × 16 px |
| **Bố Cục Lưới Thẻ Level** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** | **3 Cột × 3 Hàng** |
| **Thẻ Màn Chơi Card (W × H)** | **300 × 300 px** | **360 × 265 px** | **410 × 265 px** | **430 × 265 px** |
| **Nút Tiếp Tục Chơi Ở Cột Trái** | **460 × 160 px** | **560 × 150 px** | **610 × 160 px** | **625 × 165 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: CHỌN MÀN CHƠI** | **28 px** | **32 px** | **34 px** | **36 px** |
| **Tổng Sao Tích Lũy ("28/45")** | **28 px** | **30 px** | **32 px** | **34 px** |
| **Tên Chương ("CHƯƠNG 1...")** | **22 px** | **24 px** | **26 px** | **28 px** |
| **Nút "ĐỔI CHƯƠNG ›"** | 16 px | 18 px | 18 px | 18 px |
| **Số Màn Đã Xong ("01", "02"...)**| **72 px** | **76 px** | **78 px** | **80 px** |
| **Số Màn Focus Đang Chờ ("07")** | **76 px** | **82 px** | **84 px** | **86 px** |
| **Số Màn Khóa ("08", "09")** | 52 px | 56 px | 58 px | 60 px |
| **Nút "TIẾP TỤC CHƠI" (Dòng 1)** | **28 px** | **30 px** | **32 px** | **34 px** |
| **Màn Tiếp Tục (Dòng 2: Màn 07)** | 22 px | 20 px | 22 px | 22 px |

---

# PHẦN 3: QUY CHUẨN 3 TRẠNG THÁI THẺ LEVEL

| Trạng Thái Thẻ | Màu Viền & Nền | Hiển Thị Số Màn | Ngôi Sao / Biểu Tượng Đáy |
| :--- | :--- | :--- | :--- |
| **1. ĐÃ HOÀN THÀNH** | Viền mực xanh (`#6EA0C8`), Nền giấy vở kẻ ngang | Con số xanh đậm (`#224C6D`), kích thước $88\text{px}$ (Dọc) / $76\text{px}$ (Ngang) | 1, 2 hoặc 3 ngôi sao vàng (`#FBBF24`), sao chưa đạt để rỗng (`#FAF5EB`) |
| **2. ĐANG CHỜ CHƠI (FOCUS)** | Viền vàng cam (`#C4843A`) dày $4\text{px}$ kèm viền đứt hào quang, nhãn `NEW` đỏ | Con số cam nổi bật lớn nhất ($94\text{px} - 96\text{px}$), nhãn `MÀN TIẾP` | 3 ngôi sao rỗng viền nét cam, sẵn sàng chinh phục |
| **3. ĐANG KHÓA (LOCKED)** | Viền xám mờ (`#A7B9C3`), Nền xám ngả vàng (`#EFECE6`), lề đỏ đứt nét | Con số mờ xám ($60\text{px}$) đặt phía trên | Biểu tượng **Ổ khóa mực vẽ tay** ở trung tâm, 3 ngôi sao xám mờ |