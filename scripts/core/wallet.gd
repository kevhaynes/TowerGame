extends RefCounted
class_name Wallet

## The player's credits for one level. Each level creates a fresh wallet from
## its starting_credits, so credits never carry over between levels.

signal credits_changed(credits: int)

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
