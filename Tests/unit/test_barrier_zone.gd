extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Architect's Raise the Frame zone through the resolver: triggering
# it applies the Barrier buff to the character standing in it and, when the zone
# owner holds the Calibration trait, grants a charge (Zone_Used hook).

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_positions.characters_in_zones = true
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	# Only the zone owner (0) and one ally (1) participate; everyone else is dead so
	# the single trigger-per-round lands on the ally deterministically.
	for id in [2, 3, 4, 5]:
		_roster[id]._current_health = 0

func after_each() -> void:
	for zone in _resolver.GetZones().values():
		zone.free()

func _place_barrier_zone() -> void:
	var zone_skill: Skill = Skill.new()
	zone_skill.target = Types.Skill_Target.ZoneAlly
	zone_skill.skill_type = Types.Skill_Type.Barrier_Zone
	zone_skill.duration = 5
	var results: Array[CombatResult] = _resolver.PlaceZone(0, 0, zone_skill)
	assert_eq(results.size(), 1, "Placing a Barrier zone should report Zone_Placed")

func test_barrier_zone_applies_barrier_buff_to_the_ally_standing_in_it() -> void:
	_place_barrier_zone()
	_resolver.TriggerZones(0)
	assert_eq(_roster[1]._active_buffs.size(), 1)
	assert_eq(_roster[1]._active_buffs[0].type, Types.Buff_Type.Barrier)
	assert_eq(_roster[1]._active_buffs[0].duration, 2)
	assert_gt(_roster[1]._active_buffs[0].value, 0.0)

func test_barrier_zone_grants_the_owners_calibration_trait_a_charge() -> void:
	var calibration_trait: CalibrationTrait = CalibrationTrait.new()
	calibration_trait.Init(Types.Rarity.Epic)
	_roster[0]._trait = calibration_trait
	_place_barrier_zone()

	_resolver.TriggerZones(0)

	assert_eq(calibration_trait._charges, 1,
		"Zone use should generate one Calibration charge for the owner")

func test_zone_expires_after_duration_charges() -> void:
	_place_barrier_zone()

	for _i in range(5):
		_resolver.TriggerZones(0)

	assert_false(_resolver.HasZone(0), "A zone should be erased once its charges are spent")

func test_barrier_scales_with_the_owners_invested_charges() -> void:
	var calibration_trait: CalibrationTrait = CalibrationTrait.new()
	calibration_trait.Init(Types.Rarity.Legendary)
	_roster[0]._trait = calibration_trait
	for i in CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP:
		calibration_trait.OnSkillCast(0, [], "Cornerstone", {}, _resolver)

	_place_barrier_zone()
	_resolver.TriggerZones(0)

	var expected: int = Skills.Barrier(
			Game_Balance.BARRIER_ZONE_BASE, Game_Balance.BARRIER_ZONE_KNOWLEDGE_COEFF,
			_roster[0].GetTotalAttribute(Types.Attribute.Knowledge),
			CalibrationTrait.RAISE_THE_FRAME_CONSUME_CAP * calibration_trait._per_charge_potency)
	assert_eq(_roster[1]._active_buffs[0].value, expected,
		"Barrier should scale with both Knowledge and invested charges")

func test_barrier_with_zero_invested_charges_is_base_value_only() -> void:
	var calibration_trait: CalibrationTrait = CalibrationTrait.new()
	calibration_trait.Init(Types.Rarity.Legendary)
	_roster[0]._trait = calibration_trait

	_place_barrier_zone()
	_resolver.TriggerZones(0)

	var expected: int = Skills.Barrier(
			Game_Balance.BARRIER_ZONE_BASE, Game_Balance.BARRIER_ZONE_KNOWLEDGE_COEFF,
			_roster[0].GetTotalAttribute(Types.Attribute.Knowledge))
	assert_eq(_roster[1]._active_buffs[0].value, expected,
		"With no invested charges the Barrier should fall back to base plus Knowledge only")
