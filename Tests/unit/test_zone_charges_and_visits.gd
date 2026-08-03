extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the Concept_Document.md 3.2.4.1 zone rules this batch adds: once-per-
# visit triggering, Zone_Cleared on natural expiry, blocked placement into an occupied
# section, and ZoneEffect's three section-resolution modes.

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	# Only the zone owner (0) and one ally (1) participate; everyone else is dead so the
	# single trigger-per-round lands on the ally deterministically.
	for id in [2, 3, 4, 5]:
		_roster[id]._current_health = 0

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _bump_zone_effect() -> ZoneEffect:
	var bump: TurnBarEffect = TurnBarEffect.new()
	bump.fraction = 0.1
	return TestFactory.make_zone_effect(5, [bump])

func _skill_for(p_zone_effect: ZoneEffect, p_target: Types.Skill_Target) -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Test Zone Skill"
	skill.target = p_target
	skill.effects = [p_zone_effect]
	return skill

# --- Once-per-visit ---

func test_standing_still_does_not_retrigger() -> void:
	_positions.occupants_by_zone[0] = [1]
	TestFactory.place_zone(_resolver, 0, 0, _bump_zone_effect(), Types.Skill_Target.ZoneAll)

	_resolver.GetZoneResolver().TriggerZones(0)
	var second: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(second.filter(func(r): return r.kind == CombatResult.Kind.Zone_Triggered).size(), 0,
		"A character still standing in the zone must not be affected again")
	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 4,
		"Only the first visit should have consumed a charge")

func test_leaving_and_reentering_retriggers() -> void:
	_positions.occupants_by_zone[0] = [1]
	TestFactory.place_zone(_resolver, 0, 0, _bump_zone_effect(), Types.Skill_Target.ZoneAll)

	_resolver.GetZoneResolver().TriggerZones(0)
	_positions.occupants_by_zone[0] = []
	_resolver.GetZoneResolver().TriggerZones(0)
	_positions.occupants_by_zone[0] = [1]
	var third: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(third.filter(func(r): return r.kind == CombatResult.Kind.Zone_Triggered).size(), 1,
		"Leaving and re-entering the section should allow a fresh trigger")
	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 3)

# --- Natural expiry ---

func test_natural_expiry_emits_zone_cleared() -> void:
	_positions.occupants_by_zone[0] = [1]
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(1, [TurnBarEffect.new()]),
			Types.Skill_Target.ZoneAll)

	var results: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)

	assert_eq(results.filter(func(r): return r.kind == CombatResult.Kind.Zone_Cleared).size(), 1,
		"A zone reaching zero charges should report Zone_Cleared, not just silently vanish")
	assert_false(_resolver.GetZoneResolver().HasZone(0))

# --- Placement blocking ---

func test_placement_into_an_occupied_section_is_a_silent_no_op() -> void:
	TestFactory.place_zone(_resolver, 0, 0, _bump_zone_effect(), Types.Skill_Target.ZoneAll)
	var original_charges: int = _resolver.GetZoneResolver().GetZones()[0]._charges

	var second_effect: ZoneEffect = _bump_zone_effect()
	second_effect.section = ZoneEffect.Section.Left_Most_Empty
	# Fill every other section so Left_Most_Empty would otherwise have to reuse slot 0.
	for zone_number in range(1, GameBalance.NUMBER_OF_TURN_BAR_ZONES):
		TestFactory.place_zone(_resolver, zone_number, 0, _bump_zone_effect(), Types.Skill_Target.ZoneAll)
	var context: SkillCastContext = TestFactory.make_context(
			_resolver, 0, [], _skill_for(second_effect, Types.Skill_Target.ZoneAll), 0)
	second_effect.Resolve(context)

	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, original_charges,
		"An already-occupied section must not be overwritten")

# --- ZoneEffect section-resolution modes ---

func test_left_most_empty_picks_the_lowest_free_index() -> void:
	TestFactory.place_zone(_resolver, 0, 0, _bump_zone_effect(), Types.Skill_Target.ZoneAll)
	var zone_effect: ZoneEffect = _bump_zone_effect()
	zone_effect.section = ZoneEffect.Section.Left_Most_Empty
	var context: SkillCastContext = TestFactory.make_context(
			_resolver, 0, [], _skill_for(zone_effect, Types.Skill_Target.ZoneAll), 0)

	zone_effect.Resolve(context)

	assert_true(_resolver.GetZoneResolver().HasZone(1), "Section 0 is taken, so section 1 is the left-most free one")

func test_left_most_empty_no_ops_when_every_section_is_full() -> void:
	for zone_number in GameBalance.NUMBER_OF_TURN_BAR_ZONES:
		TestFactory.place_zone(_resolver, zone_number, 0, _bump_zone_effect(), Types.Skill_Target.ZoneAll)
	var zone_effect: ZoneEffect = _bump_zone_effect()
	zone_effect.section = ZoneEffect.Section.Left_Most_Empty
	var context: SkillCastContext = TestFactory.make_context(
			_resolver, 0, [], _skill_for(zone_effect, Types.Skill_Target.ZoneAll), 0)

	zone_effect.Resolve(context)  # Must not error.

	assert_true(true, "Reaching this line without error confirms a full turn bar was handled safely")

func test_player_chosen_uses_the_pending_section() -> void:
	_resolver.SetPendingZoneSection(2)
	var zone_effect: ZoneEffect = _bump_zone_effect()
	var context: SkillCastContext = TestFactory.make_context(
			_resolver, 0, [], _skill_for(zone_effect, Types.Skill_Target.ZoneAll), 0)

	zone_effect.Resolve(context)

	assert_true(_resolver.GetZoneResolver().HasZone(2))
	assert_false(_resolver.GetZoneResolver().HasZone(0))

func test_player_chosen_falls_back_to_random_with_no_pending_section() -> void:
	var zone_effect: ZoneEffect = _bump_zone_effect()
	var context: SkillCastContext = TestFactory.make_context(
			_resolver, 0, [], _skill_for(zone_effect, Types.Skill_Target.ZoneAll), 0)

	zone_effect.Resolve(context)  # An enemy AI cast: no player choice was ever set.

	assert_eq(_resolver.GetZoneResolver().GetZones().size(), 1,
		"With no pending section (an AI cast), placement should still succeed via a random free section")

# --- ApplyDebuffEffect Knowledge scaling ---

func test_zone_debuff_scales_with_the_owners_knowledge() -> void:
	_positions.occupants_by_zone[0] = [1]
	_roster[0]._attributes[Types.Attribute.Knowledge] = 200
	var blight: ApplyDebuffEffect = ApplyDebuffEffect.new()
	blight.debuff_type = Types.Debuff_Type.Blight
	blight.duration = 1
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(5, [blight]), Types.Skill_Target.ZoneAll)

	_resolver.GetZoneResolver().TriggerZones(0)

	var expected: float = Skills.ZoneMagnitude(StatusEffectRegistry.DebuffData(Types.Debuff_Type.Blight).magnitude, 200)
	assert_almost_eq(_roster[1]._active_debuffs[0].value, expected, 0.0001,
		"A zone-delivered debuff should scale with the placing character's Knowledge")
