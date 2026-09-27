class_name ShopLayout
extends BaseLayout

@export var btn_back: BaseButton = null
@export var tabs_box: HBoxContainer = null
@export var list_box: VBoxContainer = null
@export var scroll: ScrollContainer = null
@export var wallet_count: Label = null
@export var wallet_plus: BaseButton = null
@export var pager: Control = null
@export var page_label: Label = null
@export var btn_prev: BaseButton = null
@export var btn_next: BaseButton = null
@export var dots_box: HBoxContainer = null
@export var btn_gift: BaseButton = null
@export var top_bar: Control = null
@export var wallet_bar: Control = null
@export var gift_banner: Control = null
@export var tab_line: ColorRect = null
## Khung riêng cho BÀN NHÁP THỬ BÚT (bố cục NGANG đặt nó ở cột trái như mockup;
## để trống ⇒ bàn nháp nằm trong danh sách như bố cục DỌC)
@export var pad_slot: Control = null
## Lưới ô KHAI SẴN trong scene (`Content/List/Grid` — nodes/shop/item_grid.tscn);
## màn dùng lại node này cho mọi lần dựng danh sách nên không cần instantiate lúc chạy.
@export var item_grid: ShopItemGrid = null
## Bàn nháp thử bút KHAI SẴN trong scene (bản DỌC: `Content/List/Pad` · bản NGANG: `Body/LeftCol/PadSlot/Pad`);
## màn chỉ BẬT/TẮT theo tab (tab BÚT & MỰC mới hiện).
@export var doodle_pad: Control = null
## Hàng VIP "Xoá quảng cáo" KHAI SẴN trong scene (`Content/List/NoAds` — nodes/shop/noads_row.tscn);
## màn chỉ hiện ở tab NẠP XU rồi nạp dữ liệu vào.
@export var noads_row: Control = null