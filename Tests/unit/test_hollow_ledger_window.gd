extends GutTest

func test_describe_weight_zero_returns_none() -> void:
	assert_eq(HollowLedgerWindow.DescribeWeight(0, 10, 35), "None")

func test_describe_weight_all_equal_nonzero_returns_medium() -> void:
	assert_eq(HollowLedgerWindow.DescribeWeight(10, 10, 10), "Medium")

func test_describe_weight_at_min_returns_low() -> void:
	assert_eq(HollowLedgerWindow.DescribeWeight(10, 10, 30), "Low")

func test_describe_weight_at_max_returns_high() -> void:
	assert_eq(HollowLedgerWindow.DescribeWeight(30, 10, 30), "High")

func test_describe_weight_middle_value_returns_medium() -> void:
	assert_eq(HollowLedgerWindow.DescribeWeight(20, 10, 30), "Medium")

func test_describe_weight_fierce_attack_is_high() -> void:
	# Fierce weights: Health=15, Speed=10, Attack=35, Defence=10,
	# Accuracy=20, Resistance=0, Mysticism=5, Knowledge=5
	# nonzero: 10,15,35,10,20,5,5 => min=5 max=35 range=30
	# Attack(35) >= 35 - 0.25*30 = 27.5 → High
	assert_eq(HollowLedgerWindow.DescribeWeight(35, 5, 35), "High")

func test_describe_weight_fierce_resistance_is_none() -> void:
	assert_eq(HollowLedgerWindow.DescribeWeight(0, 5, 35), "None")

func test_describe_weight_boundary_low_edge() -> void:
	# weight <= min + 0.25 * range: range=20, threshold=10+5=15
	assert_eq(HollowLedgerWindow.DescribeWeight(15, 10, 30), "Low")

func test_describe_weight_boundary_high_edge() -> void:
	# weight >= max - 0.25 * range: range=20, threshold=30-5=25
	assert_eq(HollowLedgerWindow.DescribeWeight(25, 10, 30), "High")

func test_pity_row_text_below_threshold_shows_no_bonus() -> void:
	var text: String = HollowLedgerWindow.PityRowText("Bone", 3, 0.0, 7)
	assert_eq(text, "Bone - 3 duplicates in a row, +0% bonus, 7 unowned")

func test_pity_row_text_with_active_bonus() -> void:
	var text: String = HollowLedgerWindow.PityRowText("Brass", 6, 0.20, 3)
	assert_eq(text, "Brass - 6 duplicates in a row, +20% bonus, 3 unowned")

func test_pity_row_text_fully_owned_tier_omits_bonus() -> void:
	var text: String = HollowLedgerWindow.PityRowText("Parchment", 12, 1.0, 0)
	assert_eq(text, "Parchment - 12 duplicates in a row (all Champions owned)")
