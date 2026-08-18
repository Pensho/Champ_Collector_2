extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

## Coverage for the zone-placement and zone-scaling skills (Catalyst Cloud, Unstable
## Rift, Temporal Sinkhole, Miasma, Weight of Law, Inscribe, Cataclysm,
## Inscription Surge), cast through the real ResolveSkill pipeline so the shipped .tres
## data (charges, target filtering, on_trigger effects) is exercised end to end rather
## than hand-built SkillEffects.

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_positions = TestFactory.FakeTurnPositions.new()
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)

func after_each() -> void:
	for zone in _resolver.GetZoneResolver().GetZones().values():
		zone.free()

func _cast(p_caster_ID: int, p_skill_path: String, p_target_IDs: Array[int] = [],
		p_pending_zone_section: int = -1) -> void:
	var skill: Skill = load(p_skill_path).duplicate(true)
	_roster[p_caster_ID]._skills = [skill]
	if(-1 != p_pending_zone_section):
		_resolver.SetPendingZoneSection(p_pending_zone_section)
	_resolver.ResolveSkill(p_caster_ID, p_target_IDs, 0)

func _has_debuff(p_character_ID: int, p_type: Types.Debuff_Type) -> bool:
	for debuff in _roster[p_character_ID]._active_debuffs:
		if(p_type == debuff.type):
			return true
	return false

func _has_buff(p_character_ID: int, p_type: Types.Buff_Type) -> bool:
	for buff in _roster[p_character_ID]._active_buffs:
		if(p_type == buff.type):
			return true
	return false

func test_catalyst_cloud_places_a_four_charge_zone_and_buffs_the_ally_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [1]

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Catalyst_Cloud.tres", [], 0)

	assert_true(_has_buff(1, Types.Buff_Type.Catalyst), "The ally standing in the zone should gain Catalyst")
	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 3,
		"4 charges minus the one immediate trigger")

func test_unstable_rift_splits_damage_and_warps_both_sides_while_dealing_more_to_the_enemy() -> void:
	_positions.occupants_by_zone[0] = [1, 3]
	_roster[0]._attributes[Types.Attribute.Mysticism] = 200
	_roster[1]._attributes[Types.Attribute.Health] = 100000
	_roster[1]._current_health = 100000
	_roster[3]._attributes[Types.Attribute.Health] = 100000
	_roster[3]._current_health = 100000
	var ally_health_before: int = _roster[1]._current_health
	var enemy_health_before: int = _roster[3]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Unstable_Rift.tres", [], 0)

	assert_true(_has_debuff(1, Types.Debuff_Type.Warped), "The affected ally should be Warped")
	assert_true(_has_debuff(3, Types.Debuff_Type.Warped), "The affected enemy should be Warped")
	var ally_damage: int = ally_health_before - _roster[1]._current_health
	var enemy_damage: int = enemy_health_before - _roster[3]._current_health
	assert_gt(ally_damage, 0)
	assert_gt(enemy_damage, ally_damage, "The enemy's 30% share should deal more damage than the ally's 15% share")

func test_temporal_sinkhole_only_drains_the_enemy_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [1, 3]
	var results: Array[CombatResult] = []
	_resolver.result_produced.connect(func(r: CombatResult) -> void: results.append(r))

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Temporal_Sinkhole.tres", [], 0)

	var bumps: Array[CombatResult] = results.filter(func(r): return r.kind == CombatResult.Kind.Turn_Bar_Bump)
	var affected_IDs: Array[int] = []
	for bump in bumps:
		affected_IDs.append(bump.target_ID)
	assert_true(affected_IDs.has(3), "The enemy standing in the zone should have its turn bar drained")
	assert_false(affected_IDs.has(1), "The ally standing in the same zone must not be affected")

func test_miasma_applies_blight_to_the_enemy_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [3]

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Miasma.tres", [], 0)

	assert_true(_has_debuff(3, Types.Debuff_Type.Blight))

func test_miasma_forces_an_extra_tick_on_the_enemys_existing_debuffs() -> void:
	_positions.occupants_by_zone[0] = [3]
	_roster[3]._attributes[Types.Attribute.Health] = 100000
	_roster[3]._current_health = 100000
	_roster[1]._attributes[Types.Attribute.Mysticism] = 50
	var plague: StatusEffects.Debuff = StatusEffects.Debuff.new()
	plague.type = Types.Debuff_Type.Plague
	plague.duration = 3
	plague.source_ID = 1
	_resolver.GetStatusResolver().ApplyDebuff(3, plague)
	var health_before: int = _roster[3]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Miasma.tres", [], 0)

	var expected_tick: int = int(floor(50 * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Plague).magnitude))
	assert_eq(health_before - _roster[3]._current_health, expected_tick,
		"Miasma's trigger should force Plague to tick again immediately")
	assert_eq(_roster[3]._active_debuffs[0].duration, 3,
		"The forced extra tick must not cost the debuff a turn of duration")

func test_miasmas_forced_tick_also_cascades_a_comorbidity_flagged_debuff() -> void:
	_positions.occupants_by_zone[0] = [3]
	_roster[3]._attributes[Types.Attribute.Health] = 100000
	_roster[3]._current_health = 100000
	_roster[1]._attributes[Types.Attribute.Mysticism] = 50
	# Appended directly (rather than through ApplyDebuff, whose zone-trigger path does not
	# thread the Comorbidity flag - a separate, pre-existing gap) so the flag is actually set.
	var plague: StatusEffects.Debuff = StatusEffects.Debuff.new()
	plague.type = Types.Debuff_Type.Plague
	plague.duration = 3
	plague.source_ID = 1
	plague.trait_riders[&"repeats_per_distinct_debuff"] = true
	plague.value = floor(50 * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Plague).magnitude)
	_roster[3]._active_debuffs.append(plague)
	var enfeeble: StatusEffects.Debuff = StatusEffects.Debuff.new()
	enfeeble.type = Types.Debuff_Type.Enfeeble
	enfeeble.duration = 3
	enfeeble.source_ID = 1
	_roster[3]._active_debuffs.append(enfeeble)
	var health_before: int = _roster[3]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Miasma.tres", [], 0)

	# Blight also lands and applies_on_self_tick=false by default is irrelevant here; only
	# Plague and the forced retick's Comorbidity cascade should reduce health.
	var plague_tick: int = int(floor(50 * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Plague).magnitude))
	# 2 distinct types (Plague, Enfeeble) on Miasma's forced tick => 1 base + 1 cascade repeat.
	assert_eq(health_before - _roster[3]._current_health, plague_tick * 2,
		"Miasma's forced tick should drain and resolve a Comorbidity cascade instance")

func test_weight_of_law_stuns_the_enemy_standing_in_it() -> void:
	_positions.occupants_by_zone[0] = [3]

	_cast(0, "res://Data/Character_Skill_Variants/Zone_Skills/Weight_of_Law.tres", [], 0)

	assert_true(_has_debuff(3, Types.Debuff_Type.Stun))

func test_inscribe_damages_its_cast_target_and_places_a_left_most_glyph_that_damages_and_warps_visitors() -> void:
	_positions.occupants_by_zone[0] = [4]
	var target_health_before: int = _roster[3]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Inscribe.tres", [3])

	assert_lt(_roster[3]._current_health, target_health_before, "The direct cast target should take damage")
	assert_true(_resolver.GetZoneResolver().HasZone(0), "The glyph should land in the left-most empty section")
	assert_eq(_resolver.GetZoneResolver().GetZones()[0]._charges, 2,
		"3 charges minus the one immediate trigger on the visitor")
	assert_true(_has_debuff(4, Types.Debuff_Type.Warped), "A visitor to the glyph should be Warped")

func test_cataclysm_deals_more_damage_to_a_warped_target() -> void:
	var warped: StatusEffects.Debuff = StatusEffects.Debuff.new()
	warped.type = Types.Debuff_Type.Warped
	warped.duration = 2
	_roster[3]._active_debuffs.append(warped)
	var warped_health_before: int = _roster[3]._current_health
	var plain_health_before: int = _roster[4]._current_health

	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Cataclysm.tres", [3, 4, 5])

	var warped_damage: int = warped_health_before - _roster[3]._current_health
	var plain_damage: int = plain_health_before - _roster[4]._current_health
	assert_gt(warped_damage, plain_damage, "The Warped target should take 30% more damage than an unaffected one")

func _boost_caster_and_targets() -> void:
	_roster[0]._attributes[Types.Attribute.Mysticism] = 200
	for id in [3, 4, 5]:
		_roster[id]._attributes[Types.Attribute.Health] = 100000
		_roster[id]._current_health = 100000

func _damage_zone_effect(p_bonus_per: Dictionary[Types.Trait_Count_Source, float] = {}) -> ZoneEffect:
	var damage: DamageEffect = DamageEffect.new()
	damage.damage_scaling = {Types.Attribute.Attack: 0.5}
	damage.bonus_per = p_bonus_per
	return TestFactory.make_zone_effect(10, [damage])

func _place_and_trigger(p_zone_ID: int, p_source_name: String,
		p_bonus_per: Dictionary[Types.Trait_Count_Source, float] = {}) -> Array[CombatResult]:
	TestFactory.place_zone(_resolver, p_zone_ID, 0, _damage_zone_effect(p_bonus_per),
			Types.Skill_Target.ZoneAll, p_source_name)
	_positions.occupants_by_zone[p_zone_ID] = [3]
	return _resolver.GetZoneResolver().TriggerZones(0)

func _first_damage_modifier(p_results: Array[CombatResult]) -> CombinedDamageModifier:
	for result in p_results:
		if(CombatResult.Kind.Damage == result.kind):
			return result.combined_damage_modifier
	return null

func test_zone_damage_bucket_is_keyed_by_source_name_not_section() -> void:
	var results: Array[CombatResult] = _place_and_trigger(0, "Unstable Rift")

	var modifier: CombinedDamageModifier = _first_damage_modifier(results)
	assert_true(modifier.Buckets().has(&"Zone: Unstable Rift"),
		"The zone's damage bucket should be named for its source, not its section")
	assert_false(modifier.Buckets().has(&"Zone 0"), "The bucket must not be keyed by the turn-bar section")

func test_two_zone_kinds_in_the_same_section_get_distinct_keys() -> void:
	var first_results: Array[CombatResult] = _place_and_trigger(0, "Unstable Rift")
	var first_key: StringName = _first_damage_modifier(first_results).Buckets().keys()[0]
	_resolver.GetZoneResolver().ClearZone(0)

	var second_results: Array[CombatResult] = _place_and_trigger(0, "Spore Bloom")
	var second_key: StringName = _first_damage_modifier(second_results).Buckets().keys()[0]

	assert_ne(first_key, second_key,
		"Two different zone kinds placed in the same section must not share a bucket")

func test_same_zone_kind_in_two_sections_gets_one_key() -> void:
	var first_results: Array[CombatResult] = _place_and_trigger(0, "Unstable Rift")
	var first_key: StringName = _first_damage_modifier(first_results).Buckets().keys()[0]

	# Move the visitor off section 0 so only section 1 can produce the second result —
	# otherwise a still-occupied section 0 would independently satisfy the assertion
	# via _affected_since_entry rather than section 1 doing so.
	_positions.occupants_by_zone[0] = []
	_positions.occupants_by_zone[1] = [3]
	TestFactory.place_zone(_resolver, 1, 0, _damage_zone_effect(),
			Types.Skill_Target.ZoneAll, "Unstable Rift")
	var second_results: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)
	var second_key: StringName = _first_damage_modifier(second_results).Buckets().keys()[0]

	assert_eq(first_key, second_key,
		"The same zone kind placed in a different section should reuse the same bucket key")

func test_amplify_zone_damage_contributes_its_own_bucket_on_the_next_trigger() -> void:
	TestFactory.place_zone(_resolver, 0, 0, _damage_zone_effect(), Types.Skill_Target.ZoneAll, "Unstable Rift")
	_resolver.GetZoneResolver().AmplifyZoneDamage(0, 1.15)
	_positions.occupants_by_zone[0] = [3]
	var results: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)

	var modifier: CombinedDamageModifier = _first_damage_modifier(results)
	assert_almost_eq(modifier.Buckets().get(&"Zone: Unstable Rift (amplified)", 0.0), 0.15, 0.0001,
		"AmplifyZoneDamage should contribute its own bucket, additive with the zone's own key")

func test_amplify_zone_damage_compounds_across_repeated_calls() -> void:
	TestFactory.place_zone(_resolver, 0, 0, _damage_zone_effect(), Types.Skill_Target.ZoneAll, "Unstable Rift")
	_resolver.GetZoneResolver().AmplifyZoneDamage(0, 1.15)
	_resolver.GetZoneResolver().AmplifyZoneDamage(0, 1.15)
	_positions.occupants_by_zone[0] = [3]
	var results: Array[CombatResult] = _resolver.GetZoneResolver().TriggerZones(0)

	var modifier: CombinedDamageModifier = _first_damage_modifier(results)
	assert_almost_eq(modifier.Buckets().get(&"Zone: Unstable Rift (amplified)", 0.0), 0.3225, 0.0001,
		"Repeated AmplifyZoneDamage calls should compound (1.15^2 - 1.0)")

func test_inscription_surge_deals_more_damage_with_zones_standing_on_the_bar() -> void:
	_boost_caster_and_targets()
	var baseline_before: int = _roster[3]._current_health
	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Inscription_Surge.tres", [3, 4, 5])
	var baseline_damage: int = baseline_before - _roster[3]._current_health

	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	_boost_caster_and_targets()
	TestFactory.place_zone(_resolver, 0, 0, TestFactory.make_zone_effect(1), Types.Skill_Target.ZoneAll)
	var zoned_before: int = _roster[3]._current_health
	_cast(0, "res://Data/Character_Skill_Variants/Attack_Skills/Inscription_Surge.tres", [3, 4, 5])
	var zoned_damage: int = zoned_before - _roster[3]._current_health

	assert_gt(zoned_damage, baseline_damage, "A zone standing on the bar should add 30% damage")
