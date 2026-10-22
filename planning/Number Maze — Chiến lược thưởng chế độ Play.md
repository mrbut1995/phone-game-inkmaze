# Number Maze — Chiến lược thưởng chế độ Play

Hoạch định phần thưởng cho người chơi ở chế độ Play (chọn màn theo chương) · 22/10/2026

## 1. Mục tiêu và nguyên tắc

**Giả định:** "một màn" trong yêu cầu được hiểu là một **chương**: khoảng 10 màn thường, có thể thêm 1 bonus level. Mỗi màn thường tối đa 3★ nên một chương có khoảng **30★**.

**Phần thưởng ở Play cần làm ba việc:**

- **Bù lại tài nguyên đã tiêu.** Thua màn mất 1 lượt chơi, dùng Gợi ý/Hoàn tác/Bỏ qua trừ vào số lượt toàn game (mặc định 3 mỗi loại). Hiện chỉ Daily và nhiệm vụ cấp thêm miễn phí, nên Play đang chỉ tiêu mà không nhận lại.
- **Ghi nhận tiến trình và sự tinh thông.** Thưởng gắn với Sao và hoàn thành chương, không gắn với việc chơi lại nhiều lần.
- **Giữ vai trò riêng so với Daily.** Daily là nguồn thưởng *tái tạo theo tháng* để tạo thói quen. Play là nguồn thưởng *một lần theo tiến trình*.

**Nguyên tắc thiết kế:**

1. Mỗi phần thưởng chỉ nhận **một lần** (idempotent), không farm bằng cách chơi lại.
2. Thưởng theo **Sao đạt được lần đầu**, không thưởng theo số lần chơi.
3. Thưởng lớn gắn với mốc xa, thưởng nhỏ gắn với hành động thường xuyên.
4. Không để thưởng Play làm mất ý nghĩa của Cửa hàng và Daily (xem mục 5).
5. Người chơi luôn thấy được mốc kế tiếp ("còn 1★ nữa").

## 2. Khung thưởng 4 tầng

| Tầng | Kích hoạt | Phần thưởng | Mục đích |
| --- | --- | --- | --- |
| **A. Sao đầu tiên** | Lần đầu đạt thêm mỗi ★ ở một màn | Xu nhỏ | Phản hồi tức thì sau mỗi ván |
| **B. Rương mốc chương** | Tổng Sao trong chương đạt 33% / 67% / 100% (≈10★ / 20★ / 30★) | Xu, lượt công cụ, 1 lượt chơi ở rương cuối | Mục tiêu trung hạn, kéo người chơi tối ưu Sao |
| **C. Hoàn thành chương** | Thắng đủ \~10 màn thường | Vật phẩm trang trí riêng của chương (ví dụ skin ngòi bút) | Dấu ấn sưu tầm, không ảnh hưởng kinh tế |
| **D. Bonus level** | Điều kiện mở khóa (xem mục 3) | Xu + lượt công cụ, nhận một lần | Phần thưởng cho người chơi giỏi |

### Tầng A. Thưởng Sao đầu tiên

- **+5 Xu cho mỗi ★ mới** đạt lần đầu ở một màn. Một màn tối đa 15 Xu, một chương khoảng 150 Xu.
- Chơi lại màn đã đạt đủ 3★ không nhận thêm gì.
- Có thể thêm nhãn "lần đầu 3★" ở màn đang chơi để người chơi biết thưởng đang chờ (như mockup).

### Tầng B. Rương mốc chương

Theo mockup, ba rương nằm trên thanh tiến độ chương. Giá trị khởi điểm cho chương 1:

| Rương | Mốc | Thưởng |
| --- | --- | --- |
| 1 | 33% (≈10★) | +50 Xu |
| 2 | 67% (≈20★) | Gợi ý ×2 + Hoàn tác ×1 |
| 3 | 100% (≈30★) | +150 Xu + 1 lượt chơi |

- Mốc tính theo **tỉ lệ Sao của chương**, nên mỗi chương tự co giãn theo số màn.
- Chỉ rương cuối cho lượt chơi, vì lượt chơi đang là tài nguyên chặn vào ván và có giá 300 Xu trong shop.
- Mốc 100% gắn với Sao của **mọi** màn thường nên chỉ người chơi giỏi mới đạt. Điều này hợp lý vì đây là phần thưởng lớn nhất.

### Tầng C. Hoàn thành chương

- Mỗi chương có một món trang trí riêng (skin ngòi bút hoặc khung avatar). Tài liệu thiết kế ghi `PEN_SKIN`/`AVATAR_FRAME` chưa có item, nên đây là hạng mục cần dựng thêm.
- Nếu chưa kịp dựng, tạm thay bằng huy hiệu chương trong Sổ tay thành tựu. Cách này vẫn tạo dấu ấn mà không đụng kinh tế.
- Món trang trí không thể mua bằng Xu, để có giá trị sưu tầm.

## 3. Bonus level

Bonus level nên là phần thưởng cho người chơi chủ động, không phải một cổng chặn tiến trình.

**Mở khóa (chọn một trong hai):**

- **Phương án 1, theo Sao:** mở khi đạt 67% Sao của chương. Phù hợp nếu muốn bonus level là mục tiêu giữa chặng.
- **Phương án 2, theo hoàn thành:** mở khi thắng đủ \~10 màn thường. Đơn giản hơn nhưng ít thúc đẩy tối ưu Sao.

Khuyến nghị bắt đầu với **phương án 1**.

**Hình thức:**

- Dùng luật Special (One Stroke, Wall Builder, Fog of War…) trên bàn do nhà thiết kế vẽ, để bonus level khác cảm giác với các màn thường. Hệ thống màn của bạn đã hỗ trợ khai `mode_id` trong màn.
- **Thua không mất lượt chơi** và được thử lại tự do, vì đây là nội dung thưởng. Tránh để người chơi bị phạt khi thử phần thưởng.
- Thưởng chỉ nhận **một lần**, lần đầu thắng: +100 Xu và 1 lượt công cụ ngẫu nhiên (Gợi ý, Hoàn tác hoặc Bỏ qua).
- Không tính Sao vào tổng chương, để không làm lệch mốc rương và chi phí mở chương.

## 4. Ngân sách thưởng mỗi chương

Tổng giá trị miễn phí mỗi chương (khởi điểm):

| Nguồn | Xu | Vật phẩm |
| --- | --- | --- |
| Sao đầu tiên (tầng A) | \~150 | – |
| Rương 1 | 50 | – |
| Rương 2 | – | Gợi ý ×2, Hoàn tác ×1 |
| Rương 3 | 150 | 1 lượt chơi |
| Bonus level | 100 | 1 lượt công cụ |
| **Tổng** | **\~450** | **\~3 lượt công cụ + 1 lượt chơi** |

**Cách đọc con số:**

- So với các điểm tiêu Xu hiện có: thử lại 100 Xu, gói lượt chơi 300 Xu. Ngân sách này đủ tương đương khoảng 4 lần thử lại, nhưng chưa đủ mua skin hay chủ đề lớn, nên Cửa hàng vẫn có vai trò.
- So với Daily: một tháng Daily cho tối đa 850 Xu và vài lượt công cụ. Một chương Play cho \~450 Xu, nhưng chỉ nhận **một lần**, nên tổng Play không vượt Daily về tốc độ.
- **Tăng theo chương:** nên tăng nhẹ (khoảng +15–25% mỗi chương) để thưởng theo kịp độ khó, hoặc giữ phẳng và tăng giá trị bằng trang trí để tránh lạm phát Xu.

Đây là **điểm khởi đầu**, cần chỉnh theo dữ liệu thực tế (xem mục 7).

## 5. Phân vai Play và Daily

|  | Play | Daily |
| --- | --- | --- |
| Nhịp thưởng | Một lần, theo tiến trình | Lặp lại hằng tháng |
| Mục đích chính | Tiến trình, tinh thông, sưu tầm | Thói quen quay lại mỗi ngày |
| Thưởng chính | Xu, lượt công cụ, trang trí chương | Xu, lượt công cụ, lượt chơi theo mốc tháng |
| Rủi ro nếu quá tay | Lạm phát Xu, mất doanh thu shop | Người chơi dồn hết vào Daily |

Quy tắc giữ cân bằng: **Daily vẫn là nguồn lượt chơi tái tạo chính.** Play chỉ cho lượt chơi ở rương cuối chương.

## 6. Lựa chọn kiếm tiền (tùy chọn)

- **Nhân đôi thưởng bằng quảng cáo** ở popup rương và popup Sao đầu tiên. Quảng cáo chỉ là tùy chọn, người chơi không bắt buộc xem. Hệ thống đã có `AdsManager.show_rewarded()` (hiện là placeholder).
- Không khóa phần thưởng chính sau quảng cáo, để người chơi không cảm thấy bị ép.
- Giữ nguyên các điểm xem quảng cáo hiện có (hồi sinh, mở khóa ngày Daily) để không chia nhỏ sự chú ý.

## 7. Chỉ số theo dõi và cách tinh chỉnh

| Chỉ số | Cho biết điều gì | Tín hiệu cần chỉnh |
| --- | --- | --- |
| Tỉ lệ nhận từng rương | Rương nào quá xa hoặc quá gần | Rương 3 dưới \~10%: mốc quá khó, hạ mốc hoặc thêm gợi ý |
| Tỉ lệ người chơi hết lượt chơi | Play có đang gây kẹt | Tăng, thì cân nhắc thêm thưởng lượt chơi |
| Số Xu trung vị trong ví | Lạm phát hay thiếu Xu | Tích lũy quá nhanh: giảm tầng A |
| Tỉ lệ xem quảng cáo nhân đôi | Giá trị của lựa chọn kiếm tiền | Quá thấp: thưởng quá nhỏ để đáng xem |
| Tỉ lệ hoàn thành chương và quay lại ngày 1 / 7 | Hiệu quả giữ chân | Chương bị bỏ giữa chừng: kiểm tra độ khó chứ không chỉ thưởng |
| Doanh thu shop (gói lượt, Xu) | Thưởng có ăn vào shop | Giảm mạnh: hạ ngân sách thưởng |

Nên thử nghiệm A/B ở hai mức ngân sách (ví dụ 450 Xu và 300 Xu mỗi chương) trước khi áp dụng toàn bộ.

## 8. Lộ trình triển khai

**Giai đoạn 1: cốt lõi**

- Thêm các nguồn cấp mới cho `grant_tool_uses`/`grant_lives` (ví dụ `level_chest`, `bonus_level`). Hiện hàm chỉ nhận `purchase`, `mission`, `daily_milestone`.
- Lưu trạng thái đã nhận theo chương, tương tự `claimed` của Daily.
- Dựng thanh rương chương trên màn chọn màn và tái dùng popup mốc Daily cùng animation rương.
- Thêm kiểm thử: nhận một lần, không nhận hai lần, lưu và nạp.

**Giai đoạn 2: nội dung**

- Tầng A (Sao đầu tiên) và nhãn gợi ý trên màn đang chơi.
- Bonus level đầu tiên cho một chương thử nghiệm.

**Giai đoạn 3: hoàn thiện**

- Trang trí theo chương (cần dựng item skin/khung).
- Nhân đôi bằng quảng cáo.
- Cập nhật tài liệu thiết kế (§12 Chọn chương) và Debug Console (thêm lệnh cộng Sao chương, mở rương).

## 9. Việc cần quyết định

1. Xác nhận "màn" = chương và một chương có \~10 màn thường. Mockup đang dùng 36★ nên cần đổi về \~30★ (mốc 10/20/30★).
2. Chọn điều kiện mở khóa bonus level (phương án 1 hay 2).
3. Có kịp dựng skin ngòi bút/khung avatar cho tầng C hay tạm dùng huy hiệu.
4. Chọn mức ngân sách khởi điểm (\~450 Xu hay thấp hơn) để thử nghiệm.
