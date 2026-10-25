extends GutTest


func test_starts_with_starting_credits() -> void:
	assert_eq(Wallet.new(300).credits, 300)
	assert_eq(Wallet.new(-5).credits, 0, "never negative")


func test_spend_deducts_only_when_affordable() -> void:
	var wallet := Wallet.new(300)
	watch_signals(wallet)
	assert_true(wallet.spend(100))
	assert_eq(wallet.credits, 200)
	assert_false(wallet.spend(250))
	assert_eq(wallet.credits, 200, "unaffordable purchase changes nothing")
	assert_true(wallet.spend(200))
	assert_eq(wallet.credits, 0)
	assert_signal_emit_count(wallet, "credits_changed", 2)


func test_earn_adds_credits() -> void:
	var wallet := Wallet.new(0)
	watch_signals(wallet)
	wallet.earn(18)
	wallet.earn(0)
	wallet.earn(-4)
	assert_eq(wallet.credits, 18)
	assert_signal_emit_count(wallet, "credits_changed", 1)
	assert_signal_emitted_with_parameters(wallet, "credits_changed", [18])


func test_can_afford() -> void:
	var wallet := Wallet.new(150)
	assert_true(wallet.can_afford(150))
	assert_false(wallet.can_afford(151))
	assert_false(wallet.can_afford(-1))


func test_sell_refund_is_seventy_percent_rounded_to_nearest() -> void:
	assert_eq(Wallet.sell_refund(100), 70)
	assert_eq(Wallet.sell_refund(15), 11, "10.5 rounds up")
	assert_eq(Wallet.sell_refund(12), 8, "8.4 rounds down")
	assert_eq(Wallet.sell_refund(13), 9, "9.1 rounds down")
	assert_eq(Wallet.sell_refund(1), 1, "0.7 rounds up")
	assert_eq(Wallet.sell_refund(0), 0)
	assert_eq(Wallet.sell_refund(-10), 0, "never negative")
