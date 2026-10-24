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
## Chip LƯỢT CHƠI trên thanh trên (bấm `+` = mở tab DỤNG CỤ để mua thêm lượt)
@export var life_chip: LifeChip = null
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
## NavBar nền dưới (NinePatchRect — bối cảnh cho hàng tab)
@export var nav_bar: Control = null
## Khung nội dung chính (VBoxContainer 'Body') — cần điều chỉnh offset_bottom theo safe area
@export var content_body: Control = null

# --- Safe area: lưu offset GỐC (design) của các node neo ở đáy màn ---
var _sa_nodes: Array[Control] = []              # danh sách node cần shift
var _sa_base_offset_top: Array[float] = []      # offset_top thiết kế
var _sa_base_offset_bottom: Array[float] = []   # offset_bottom thiết kế
var _sa_body_base_bottom: float = -232.0        # offset_bottom thiết kế của Body
var _sa_inited: bool = false


func _ready() -> void:
	super._ready()
	_init_safe_area_bases.call_deferred()


## Thu thập offset GỐC của các node neo ở đáy TRƯỚC khi safe area được áp lần đầu.
## Dùng call_deferred để đảm bảo các node đã sẵn sàng.
func _init_safe_area_bases() -> void:
	_sa_nodes.clear()
	_sa_base_offset_top.clear()
	_sa_base_offset_bottom.clear()

	# Chỉ thu thập khi node tồn tại VÀ anchor top = 1 (nghĩa là neo ở đáy)
	for node in [nav_bar, tabs_box, gift_banner, pager]:
		var ctrl := node as Control
		if ctrl == null:
			continue
		if not is_equal_approx(ctrl.anchor_top, 1.0):
			continue
		_sa_nodes.append(ctrl)
		_sa_base_offset_top.append(ctrl.offset_top)
		_sa_base_offset_bottom.append(ctrl.offset_bottom)

	_sa_inited = true
	# Lưu offset thiết kế của Body (nếu có)
	if content_body != null and is_instance_valid(content_body):
		_sa_body_base_bottom = content_body.offset_bottom
	# Áp ngay sau khi lấy base (SafeArea có thể đã phát tín hiệu rồi)
	_apply_safe_area()


## Override hook từ BaseLayout: shift các node neo ở đáy lên theo safe area bottom inset.
## Đồng thời thu nhỏ vùng nội dung Body (offset_bottom) để không bị NavBar che.
func _on_safe_area_applied(inset_px: float) -> void:
	if not _sa_inited:
		return
	for i in _sa_nodes.size():
		var ctrl := _sa_nodes[i]
		if ctrl == null or not is_instance_valid(ctrl):
			continue
		ctrl.offset_top    = _sa_base_offset_top[i]    - inset_px
		ctrl.offset_bottom = _sa_base_offset_bottom[i] - inset_px
	# Body cũng phải thu lại để nội dung không bị NavBar che khuất
	if content_body != null and is_instance_valid(content_body):
		if content_body.anchor_bottom > 0.5:  # chỉ điều chỉnh khi Body neo ở đáy
			content_body.offset_bottom = _sa_body_base_bottom - inset_px