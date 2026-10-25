extends RefCounted
class_name Wallet

## The player's credits for one level. Each level creates a fresh wallet from
## its starting_credits, so credits never carry over between levels.

signal credits_changed(credits: int)

## Share of a tower's price returned when it is sold.
const SELL_REFUND_PERCENT: int = 70
const PERCENT: int = 100

var credits: int = 0


func _init(starting_credits: int) -> void:
	credits = maxi(starting_credits, 0)


func can_afford(cost: int) -> bool:
	return cost >= 0 and cost <= credits


## Deducts [param cost] if affordable. Returns false (and changes nothing) otherwise.
func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	credits -= cost
	credits_changed.emit(credits)
	return true


func earn(amount: int) -> void:
	if amount <= 0:
		return
	credits += amount
	credits_changed.emit(credits)


## Credits returned for selling a tower bought for [param price]:
## SELL_REFUND_PERCENT of it, rounded to the nearest credit (halves round up).
## Integer maths, so a price like 15 refunds 11 rather than float-rounding to 10.
static func sell_refund(price: int) -> int:
	if price <= 0:
		return 0
	@warning_ignore("integer_division")
	return (price * SELL_REFUND_PERCENT + PERCENT / 2) / PERCENT
