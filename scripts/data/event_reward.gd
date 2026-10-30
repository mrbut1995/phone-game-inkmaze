class_name EventReward
extends Resource
## ============================================================================
## Resource: Phần thưởng của một Event (tối đa 2 phần thưởng hiển thị trên thẻ).
## ============================================================================

enum Kind {
	COIN,            ## Xu Mực
	PEN_SKIN,        ## Bút vẽ (skin)
	AVATAR_FRAME,    ## Khung hồ sơ
	COIN_MULTIPLIER, ## Hệ số nhân xu (2 = x2)
}

@export var kind: Kind = Kind.COIN

## COIN: số xu · COIN_MULTIPLIER: hệ số (2 = ×2)
@export var amount: int = 0

## PEN_SKIN / AVATAR_FRAME: id vật phẩm trong shop/profile
@export var item_id: StringName = &""

## Nhãn ngắn hiển thị trên thẻ (khoá dịch): "500 Xu", "Bút Ma Trơi", "Khung Hoa Mai"…
@export var label_key: StringName = &""
