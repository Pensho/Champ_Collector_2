extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Bleed and Plague, the CasterAttributeSnapshotPercent self-tick debuffs:
# their tick damage is snapshotted from the applying source's attribute at the moment
# of application (the Phalanx Guard per-instance precedent), not re-read live on later
# ticks, and Plague additionally spreads to a random other living ally of the holder
# when it expires (Concept_Document.md 3.2.3.2).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _apply_debuff(p_type: Types.Debuff_Type, p_target_ID: int, p_source_ID: int, p_duration: int = 2) -> void:
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = p_type
	template.duration = p_duration
	template.source_ID = p_source_ID
	_resolver.ApplyDebuff(p_target_ID, template)

func _debuff_ticks(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(result): return result.kind == CombatResult.Kind.Debuff_Tick)

func test_bleed_tick_snapshots_the_appliers_attack_at_application() -> void:
	_roster[1]._attributes[Types.Attribute.Attack] = 100
	_apply_debuff(Types.Debuff_Type.Bleed, 0, 1)
	# Changing the source's Attack after application must not affect the already-snapshotted tick.
	_roster[1]._attributes[Types.Attribute.Attack] = 9999

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _debuff_ticks(results)[0]
	var expected: int = int(floor(100 * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Bleed).magnitude))
	assert_eq(tick.amount, expected, "Bleed's tick damage should use the Attack snapshotted at application")
	assert_eq(tick.amount_by_source[1], expected, "The applying source should be credited with the Bleed tick")

func test_plague_tick_scales_with_the_appliers_mysticism() -> void:
	_roster[1]._attributes[Types.Attribute.Mysticism] = 50
	_apply_debuff(Types.Debuff_Type.Plague, 0, 1)

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)
	var tick: CombatResult = _debuff_ticks(results)[0]
	var expected: int = int(floor(50 * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Plague).magnitude))
	assert_eq(tick.amount, expected, "Plague's tick damage should scale with the applier's snapshotted Mysticism")

func test_plague_spreads_to_a_random_other_living_ally_on_expiry() -> void:
	# Only 0 and 1 remain alive on the player side, so the spread must land on 1.
	_roster[2]._current_health = 0
	_apply_debuff(Types.Debuff_Type.Plague, 0, 3, 1)

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._active_debuffs.size(), 0, "Plague should expire off the original holder")
	assert_eq(_roster[1]._active_debuffs.size(), 1, "Plague should spread to the only other living ally")
	assert_eq(_roster[1]._active_debuffs[0].type, Types.Debuff_Type.Plague)

func test_plague_does_not_spread_when_no_other_ally_is_alive() -> void:
	for id in [1, 2]:
		_roster[id]._current_health = 0
	_apply_debuff(Types.Debuff_Type.Plague, 0, 3, 1)

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)

	var applied_to_others: Array[CombatResult] = results.filter(
		func(result): return result.kind == CombatResult.Kind.Status_Applied and result.target_ID != 0)
	assert_eq(applied_to_others.size(), 0, "With no living ally to spread to, Plague should just expire")

func test_zone_delivered_bleed_snapshots_the_zone_owners_attack() -> void:
	_roster[0]._attributes[Types.Attribute.Attack] = 40
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.characters_in_zones = true
	var zone_resolver: BattleResolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), positions)
	for id in [1, 2, 4, 5]:
		_roster[id]._current_health = 0
	var zone_skill: Skill = TestFactory.make_lava_zone_skill()
	zone_skill.debuffs = {Types.Skill_Target.ZoneAll: Types.Debuff_Type.Bleed}
	zone_resolver.PlaceZone(0, 0, zone_skill)

	zone_resolver.TriggerZones(0)

	var expected: float = 40 * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Bleed).magnitude
	assert_almost_eq(_roster[3]._active_debuffs[0].value, expected, 0.0001,
		"A zone-delivered Bleed should snapshot the zone owner's Attack, same as a skill-cast one")
	zone_resolver.GetZones()[0].free()
