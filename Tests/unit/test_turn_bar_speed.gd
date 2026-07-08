extends GutTest

# Regression coverage for the turn-bar speed normalization defect: the fastest
# (geared) character must normalize to exactly 1.0 and no one may exceed it, even
# when a character's gear pushes their battle speed above every base speed.

func test_fastest_normalizes_to_one() -> void:
	var speeds: Dictionary[int, int] = {0: 5, 1: 8, 2: 3}
	var normalized: Dictionary[int, float] = TurnBar.NormalizeSpeeds(speeds)
	assert_almost_eq(normalized[1], 1.0, 0.0001, "The fastest character should normalize to 1.0")

func test_no_speed_exceeds_one() -> void:
	# Slot 2 has the highest geared speed; it must be the 1.0 anchor and nothing
	# may exceed it. This is the exact case the mixed-source bug produced.
	var speeds: Dictionary[int, int] = {0: 10, 1: 12, 2: 20}
	var normalized: Dictionary[int, float] = TurnBar.NormalizeSpeeds(speeds)
	for id in normalized.keys():
		assert_lte(normalized[id], 1.0, "No normalized speed may exceed 1.0")
	assert_almost_eq(normalized[2], 1.0, 0.0001, "The gear-boosted fastest character anchors at 1.0")

func test_proportional_scaling() -> void:
	var speeds: Dictionary[int, int] = {0: 5, 1: 10}
	var normalized: Dictionary[int, float] = TurnBar.NormalizeSpeeds(speeds)
	assert_almost_eq(normalized[0], 0.5, 0.0001, "Half-speed character normalizes to 0.5")

func test_all_zero_speed_does_not_divide_by_zero() -> void:
	var speeds: Dictionary[int, int] = {0: 0, 1: 0}
	var normalized: Dictionary[int, float] = TurnBar.NormalizeSpeeds(speeds)
	assert_eq(normalized[0], 0.0, "Zero highest speed normalizes to 0.0 instead of dividing by zero")
	assert_eq(normalized[1], 0.0, "Zero highest speed normalizes to 0.0 instead of dividing by zero")
