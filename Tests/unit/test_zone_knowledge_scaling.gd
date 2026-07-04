extends GutTest

# --- Skills.AllyZoneMagnitude ---

func test_ally_zone_magnitude_zero_knowledge_returns_base() -> void:
	var magnitude: float = Skills.AllyZoneMagnitude(0.15, 0)
	assert_eq(magnitude, 0.15, "Zero Knowledge should not change the base magnitude")

func test_ally_zone_magnitude_scales_linearly_with_knowledge() -> void:
	var base: float = 0.15
	var magnitude_at_100: float = Skills.AllyZoneMagnitude(base, 100)
	var expected: float = base * (1.0 + 100 * Game_Balance.ZONE_KNOWLEDGE_SCALING)
	assert_almost_eq(magnitude_at_100, expected, 0.0001,
		"Magnitude should scale by 1.0 + knowledge * ZONE_KNOWLEDGE_SCALING")

func test_ally_zone_magnitude_higher_knowledge_yields_higher_magnitude() -> void:
	var base: float = 0.15
	var low: float = Skills.AllyZoneMagnitude(base, 10)
	var high: float = Skills.AllyZoneMagnitude(base, 200)
	assert_true(high > low, "Higher Knowledge should produce a larger effect magnitude")

# --- Zone.CreateNew ---

func test_create_new_stores_owner_knowledge() -> void:
	var zone: Zone = Zone.new()
	zone.CreateNew(Types.Skill_Type.Flicker_Zone, 3, 0, Types.Skill_Target.ZoneAlly, 42)
	assert_eq(zone._owner_knowledge, 42, "Zone should snapshot the owner's Knowledge at placement")
	zone.free()

func test_create_new_defaults_owner_knowledge_to_zero() -> void:
	var zone: Zone = Zone.new()
	zone.CreateNew(Types.Skill_Type.Lava_Zone, 3, 3, Types.Skill_Target.ZoneEnemy)
	assert_eq(zone._owner_knowledge, 0, "Owner knowledge should default to 0 when not provided")
	zone.free()
