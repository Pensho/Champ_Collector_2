extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# --- GetExperienceRequirement ---

func test_xp_required_is_positive_at_level_1() -> void:
	var xp: float = LevelSystem.GetExperienceRequirement(1)
	assert_gt(xp, 0.0, "Level 1 should require positive XP")

func test_xp_grows_monotonically() -> void:
	var prev: float = LevelSystem.GetExperienceRequirement(1)
	for lvl in range(2, 11):
		var curr: float = LevelSystem.GetExperienceRequirement(lvl)
		assert_gt(curr, prev, "Level %d should require more XP than level %d" % [lvl, lvl - 1])
		prev = curr

func test_xp_grows_at_higher_levels() -> void:
	var xp_10: float = LevelSystem.GetExperienceRequirement(10)
	var xp_50: float = LevelSystem.GetExperienceRequirement(50)
	var xp_100: float = LevelSystem.GetExperienceRequirement(100)
	assert_gt(xp_50, xp_10, "Level 50 should cost more than level 10")
	assert_gt(xp_100, xp_50, "Level 100 should cost more than level 50")

# --- LevelUpCriteriaMet ---

func test_level_up_not_met_at_zero_xp() -> void:
	var c: Character = TestFactory.make_character()
	c._level = 1
	c._experience = 0
	assert_false(LevelSystem.LevelUpCriteriaMet(c), "Should not level up with 0 XP")


func test_level_up_met_at_threshold() -> void:
	var c: Character = TestFactory.make_character()
	c._level = 1
	c._experience = int(LevelSystem.GetExperienceRequirement(1))
	assert_true(LevelSystem.LevelUpCriteriaMet(c), "Should level up when XP meets the threshold")


func test_level_up_criteria_met_does_not_consume_xp() -> void:
	# LevelUpCriteriaMet is now a pure predicate: it must report readiness without
	# spending any experience. Consumption happens only inside AddExperience.
	var c: Character = TestFactory.make_character()
	c._level = 1
	var req: int = int(LevelSystem.GetExperienceRequirement(1))
	c._experience = req + 5
	assert_true(LevelSystem.LevelUpCriteriaMet(c), "Should report ready at the threshold")
	assert_eq(c._experience, req + 5, "Predicate must not consume experience")


func test_level_up_false_leaves_xp_unchanged() -> void:
	var c: Character = TestFactory.make_character()
	c._level = 1
	c._experience = 1
	LevelSystem.LevelUpCriteriaMet(c)
	assert_eq(c._experience, 1, "XP must not change when level-up threshold is not met")


# --- AddExperience ---

func _make_character_with_weights() -> Character:
	var c: Character = TestFactory.make_character()
	var weights: AttributeWeightPreset = AttributeWeightPreset.new()
	for attribute in weights._weights.keys():
		weights._weights[attribute] = 1
	c._attributes_weights = weights
	return c


func test_add_experience_below_threshold_does_not_level_or_consume() -> void:
	var c: Character = _make_character_with_weights()
	c._level = 1
	c._experience = 0
	var gained: int = int(LevelSystem.GetExperienceRequirement(1)) - 1
	LevelSystem.AddExperience(c, gained)
	assert_eq(c._level, 1, "Sub-threshold experience must not raise the level")
	assert_eq(c._experience, gained, "Sub-threshold experience must be retained, not consumed")


func test_add_experience_consumes_requirement_on_level_up() -> void:
	var c: Character = _make_character_with_weights()
	c._level = 1
	var req: int = int(LevelSystem.GetExperienceRequirement(1))
	c._experience = 0
	LevelSystem.AddExperience(c, req + 5)
	assert_eq(c._level, 2, "Reaching the threshold should raise the level by one")
	assert_eq(c._experience, 5, "Only the level's requirement should be consumed, leaving the surplus")


# --- SetOpponentLevel ---

func test_set_opponent_level_guard_below_1() -> void:
	var c: Character = TestFactory.make_character()
	c._level = 5
	LevelSystem.SetOpponentLevel(c, 0)
	assert_eq(c._level, 5, "Level below 1 should be rejected")


func test_set_opponent_level_guard_above_999() -> void:
	var c: Character = TestFactory.make_character()
	c._level = 5
	LevelSystem.SetOpponentLevel(c, 1000)
	assert_eq(c._level, 5, "Level above 999 should be rejected")


func test_set_opponent_level_guard_not_lower_than_current() -> void:
	var c: Character = TestFactory.make_character()
	c._level = 10
	var attack_before: int = c._attributes[Types.Attribute.Attack]
	LevelSystem.SetOpponentLevel(c, 10)
	assert_eq(c._level, 10, "Setting same level should be a no-op")
	assert_eq(c._attributes[Types.Attribute.Attack], attack_before, "Attributes unchanged for no-op")


func test_set_opponent_level_increases_attributes() -> void:
	var c: Character = TestFactory.make_character()
	c._level = 1
	var attack_before: int = c._attributes[Types.Attribute.Attack]
	LevelSystem.SetOpponentLevel(c, 10)
	assert_eq(c._level, 10, "Level should be updated to target")
	assert_gt(c._attributes[Types.Attribute.Attack], attack_before,
		"Attack should increase when levelling up")


func test_set_opponent_level_boss_scales_higher_than_non_boss() -> void:
	# The boss branch multiplies distributed points by 1.5, so at the same target
	# level a boss must end up with a higher attribute total than a non-boss.
	var non_boss: Character = TestFactory.make_character()
	var boss: Character = TestFactory.make_character()
	non_boss._level = 1
	boss._level = 1
	LevelSystem.SetOpponentLevel(non_boss, 10, false)
	LevelSystem.SetOpponentLevel(boss, 10, true)

	var non_boss_total: int = 0
	var boss_total: int = 0
	for attribute in non_boss._attributes.keys():
		non_boss_total += non_boss._attributes[attribute]
		boss_total += boss._attributes[attribute]
	assert_gt(boss_total, non_boss_total,
		"A boss opponent should have a higher attribute total than a non-boss at the same level")


func test_set_opponent_level_speed_scales_differently() -> void:
	# Speed uses a linear scale; all other attributes use a polynomial scale.
	# At high levels the polynomial factor dominates, so non-speed stats grow
	# faster than speed does (per-point weight).
	var c1: Character = TestFactory.make_character()
	var c2: Character = TestFactory.make_character()
	c1._level = 1
	c2._level = 1
	LevelSystem.SetOpponentLevel(c1, 50)
	LevelSystem.SetOpponentLevel(c2, 50)

	var speed_gain: int = c1._attributes[Types.Attribute.Speed] - 5
	var attack_gain: int = c1._attributes[Types.Attribute.Attack] - 8
	# Attack has a higher base weight per point so it should gain more than Speed
	# when the polynomial (level^1.1) term dominates.
	assert_gt(attack_gain, speed_gain, "Attack should gain more than Speed at high level")

