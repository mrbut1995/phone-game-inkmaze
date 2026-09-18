Dưới đây là **Bản đặc tả Layout & Font Spec tổng hợp hoàn chỉnh** cho màn hình **SHOP SCREEN (Cửa Hàng / Tiệm Văn Phòng Phẩm)** trên toàn bộ **10 tỉ lệ màn hình**, được phân chia thành 2 nhóm: **Màn hình Dọc (Portrait — 6 tỉ lệ)** và **Màn hình Ngang (Landscape — 4 tỉ lệ)**, kèm quy chuẩn hiển thị các tabs sản phẩm.

---

# PHẦN 1: NHÓM MÀN HÌNH DỌC (PORTRAIT — 6 TỈ LỆ)
> **Bố cục:** 1 Cột dọc thống nhất từ trên xuống: Top Header (Nút Back + Tiêu đề + Ví Xu Mực) $\to$ Hàng 4 Tab Bookmark Phân Loại $\to$ Bàn Nháp Thử Bút Trực Tiếp (Doodle Test Pad) $\to$ Lưới Sản Phẩm 2 Cột $\to$ Banner Tiếp Sức Nhận Xu $\to$ Footer $\to$ Gesture Bar.

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Top Safe Area (Y Offset)** | 85 px | 90 px | 110 px | 130 px | 30 px | 40 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px | 65 × 65 px | 70 × 70 px |
| **Ví Tiền Xu Mực (W × H)** | 255 × 70 px | 255 × 75 px | 255 × 80 px | 255 × 85 px | 255 × 65 px | 260 × 70 px |
| **Hàng 4 Tab Bookmark (Mỗi tab)**| 236 × 55 px | 236 × 60 px | 236 × 60 px | 236 × 65 px | 240 × 45 px | 260 × 55 px |
| **Bàn Nháp Thử Bút (W × H)** | **980 × 215 px** | **980 × 230 px** | **980 × 240 px** | **980 × 250 px** | **1000 × 170 px** | **1080 × 200 px** |
| **Bố Cục Lưới Sản Phẩm** | 2 Cột × 3 Hàng | 2 Cột × 3 Hàng | 2 Cột × 3 Hàng | 2 Cột × 3 Hàng | 2 Cột × 3 Hàng *(Scroll)* | 2 Cột × 3 Hàng |
| **Thẻ Sản Phẩm Card (W × H)** | **475 × 315 px** | **475 × 325 px** | **475 × 330 px** | **475 × 340 px** | **485 × 240 px** | **525 × 260 px** |
| **Khung Thumbnail Sản Phẩm** | 150 × 100 px | 150 × 105 px | 155 × 110 px | 160 × 115 px | 130 × 75 px | 140 × 85 px |
| **Nút Mua / Dùng (W × H)** | 200 × 46 px | 200 × 48 px | 200 × 50 px | 200 × 52 px | 200 × 42 px | 200 × 44 px |
| **Banner Nhận Xu (W × H)** | **980 × 115 px** | **980 × 125 px** | **980 × 130 px** | **980 × 135 px** | **1000 × 95 px** | **1080 × 110 px** |

### 2. Font Spec (Cỡ chữ)

| Text Item | 9:16 · 1080×1920 *(Base)* | 9:18 · 1080×2160 | 9:19.5 · 1080×2340 | 9:21 · 1080×2520 | 3:4 · 1080×1440 | 3:4 · 1200×1600 |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Header: CỬA HÀNG** | **38 px** | **40 px** | **40 px** | **42 px** | **32 px** | **38 px** |
| **Tag phụ ("TIỆM VĂN PHÒNG...")**| 16 px | 16 px | 16 px | 18 px | 14 px | 16 px |
| **Số Xu Trong Ví ("1,250")** | **32 px** | **32 px** | **34 px** | **34 px** | **28 px** | **30 px** |
| **Nhãn 4 Tabs ("✒️ BÚT & MỰC")** | 19 px / 18 px | 19 px / 18 px | 19 px / 18 px | 20 px / 18 px | 16 px / 15 px | 18 px / 17 px |
| **Tiêu đề Bàn Nháp Thử Bút** | 18 px | 20 px | 22 px | 22 px | 18 px | 20 px |
| **Tên Skin Trong Bàn Nháp** | 19 px | 19 px | 20 px | 20 px | 16 px | 18 px |
| **Nút Dùng Thử ("DÙNG THỬ ✓")** | 14 px | 15 px | 15 px | 16 px | 13 px | 14 px |
| **Tên Sản Phẩm Card (Item Name)**| **24 px** | **24 px** | **24 px** | **26 px** | **20 px** | **22 px** |
| **Mô tả Sản Phẩm (Subtext)** | 14 px | 14 px | 14 px | 16 px | 13 px | 14 px |
| **Tag Thẻ ("CƠ BẢN", "VIP"...)** | 12 px | 12 px | 12 px | 13 px | 11 px | 12 px |
| **Chữ Nút ("✓ ĐANG DÙNG")** | 16 px | 16 px | 16 px | 17 px | 15 px | 16 px |
| **Chữ Nút Mua ("350 XU"...)** | **18 px** | **18 px** | **18 px** | **18 px** | **16 px** | **18 px** |
| **Tiêu đề Banner Tiếp Sức** | 24 px | 24 px | 24 px | 24 px | 20 px | 22 px |
| **Mô tả Banner Nhận Xu** | 16 px | 16 px | 16 px | 16 px | 14 px | 15 px |
| **Nút Nhận Xu ("+50 XU ▶")** | **18 px** | **20 px** | **20 px** | **20 px** | **16 px** | **18 px** |
| **Quote Chân Trang (Footer)** | 18 px | 18 px | 18 px | 18 px | 15 px | 16 px |

---

# PHẦN 2: NHÓM MÀN HÌNH NGANG (LANDSCAPE — 4 TỈ LỆ)
> **Bố cục:** Chia đôi màn hình thành 2 cột độc lập:
> - **Cột Trái (Interactive Studio):** Top Header, Ví Xu, Bàn Nháp Thử Bút lớn để chạm thử ngay lập tức, Banner tiếp sức nhận xu miễn phí ở chân cột.
> - **Cột Phải (Catalog Grid):** Hàng 4 Tab Bookmark ở trên cùng, bên dưới là Lưới Sản Phẩm bày bán (2 Cột trên tỉ lệ 4:3; **3 Cột × 2 Hàng** trên các tỉ lệ 16:9, 18:9, 19.5:9).

### 1. Layout Spec (Kích thước & Vị trí)

| Thành phần UI | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Lề an toàn (Safe Area Left/Right)** | 50 px | 60 px | 70 px | 120 px *(Tránh Notch/Camera)* |
| **Chiều rộng Cột Trái (Studio Nháp)**| 600 px | 680 px | 750 px | 780 px |
| **Chiều rộng Cột Phải (Catalog Lưới)**| 880 px | 1100 px | 1260 px | 1320 px |
| **Nút Back (W × H)** | 70 × 70 px | 75 × 75 px | 80 × 80 px | 85 × 85 px |
| **Ví Tiền Xu Mực (W × H)** | 270 × 70 px | 295 × 75 px | 320 × 80 px | 335 × 85 px |
| **Bàn Nháp Thử Bút (W × H)** | **600 × 580 px** | **680 × 540 px** | **750 × 540 px** | **780 × 540 px** |
| **Banner Nhận Xu Tiếp Sức (W × H)**| **600 × 180 px** | **680 × 180 px** | **750 × 180 px** | **780 × 180 px** |
| **Hàng 4 Tab Bookmark (Mỗi tab)**| 210 × 50 px | 250 × 55 px | 290 × 55 px | 310 × 55 px |
| **Bố Cục Lưới Sản Phẩm** | 2 Cột × 3 Hàng | **3 Cột × 2 Hàng** | **3 Cột × 2 Hàng** | **3 Cột × 2 Hàng** |
| **Thẻ Sản Phẩm Card (W × H)** | 425 × 280 px | **340 × 360 px** | **380 × 360 px** | **400 × 360 px** |
| **Nút Mua / Dùng (W × H)** | 200 × 46 px | 200 × 46 px | 200 × 46 px | 200 × 46 px |

### 2. Font Spec (Cỡ chữ)

| Text Item | 4:3 · 1600×1200 | 16:9 · 1920×1080 *(Base)* | 18:9 · 2160×1080 | 19.5:9 · 2340×1080 |
| :--- | :--- | :--- | :--- | :--- |
| **Header: CỬA HÀNG** | **26 px** | **28 px** | **30 px** | **32 px** |
| **Số Xu Trong Ví ("1,250 XU")** | **24 px** | **26 px** | **26 px** | **28 px** |
| **Tiêu đề Bàn Nháp Thử Bút** | 20 px | 22 px | 22 px | 24 px |
| **Tên Skin Trong Bàn Nháp** | 20 px | 22 px | 22 px | 24 px |
| **Nút "DÙNG THỬ ✓"** | 16 px | 16 px | 16 px | 16 px |
| **Tiêu đề Banner Tiếp Sức** | 22 px | 24 px | 24 px | 26 px |
| **Nút Nhận Xu ("+50 XU ▶")** | **18 px** | **18 px** | **18 px** | **18 px** |
| **Nhãn 4 Tabs ("✒️ BÚT & MỰC")** | 16 px | 18 px | 18 px | 19 px |
| **Tên Sản Phẩm Card (Item Name)**| **20 px** | **20 px** | **22 px** | **22 px** |
| **Chữ Nút ("✓ ĐANG DÙNG")** | 15 px | 15 px | 16 px | 16 px |
| **Chữ Nút Mua ("350 XU"...)** | **18 px** | **18 px** | **18 px** | **18 px** |

---

# PHẦN 3: QUY CHUẨN HIỂN THỊ KHI CHUYỂN 4 TABS

Khi người chơi chuyển tab danh mục, cấu trúc layout khung giữ nguyên 100%, nội dung hiển thị sẽ thích ứng như sau:

| Tab Danh Mục | Nội Dung Lưới Sản Phẩm | Hành Động Bàn Nháp (Test Pad) |
| :--- | :--- | :--- |
| **✒️ BÚT & MỰC (Mặc định)** | Các skin màu mực & đầu bút (*Mực xanh, tím, chì 2B, bút đỏ, dạ quang, nhũ hoàng gia*) | **Vẽ thử trực tiếp**: Hiện vệt mực phát sáng theo màu đang chọn |
| **📜 GIẤY VỞ** | Các loại phông nền ô ly (*Giấy vở 4 ô ly, Giấy kẻ ngang Kẻ Caro, Giấy Vintage ngả vàng, Bảng đen phấn trắng*) | **Xem trước nền**: Nền Bàn Nháp đổi thành chất liệu giấy tương ứng |
| **🎒 DỤNG CỤ** | Các vật phẩm hỗ trợ gameplay (*Tẩy thần kỳ xóa 1 nét lỗi, Kính lúp gợi ý tường, Thước kẻ đo bước*) | **Xem demo hoạt ảnh**: Bàn Nháp chiếu video/vector mô phỏng cách dụng cụ hoạt động |
| **🪙 NẠP XU** | Các gói mua xu IAP (*Túi Xu Học Sinh 500 Xu, Hộp Bút Tiết Kiệm 2,000 Xu, Cặp Sách Tri Thức 10,000 Xu*) | **Hiển thị ưu đãi**: Bàn Nháp chuyển thành banner gói VIP hoặc khuyến mãi nạp lần đầu |