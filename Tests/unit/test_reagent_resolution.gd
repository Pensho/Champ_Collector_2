extends GutTest

## Smoke coverage for BattleResolver.ResolveReagent / ReagentResolver, driven the same
## headless way as test_battle_resolver.gd and test_skills.gd. Full free-action,
## once-per-battle, and UI-facing coverage is Plan_Reagent_Combat_Application.md step 5;
## this only exercises the resolution core landed in step 3.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func _make_resolver() -> BattleResolver:
	var roster: Dictionary[int, Character] = {}
	roster.assign(TestFactory.make_full_roster())
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	return TestFactory.make_resolver(roster, TestFactory.make_full_sides())

func test_heal_restores_health_without_ending_the_turn() -> void:
	var resolver: BattleResolver = _make_resolver()
	var target: Character = resolver.GetCharacters()[0]
	target._current_health = 5
	target._skills[0].cooldown_left = 2

	resolver.ResolveReagent(0, "Restorative_Draught_Rare", 0)

	assert_gt(target._current_health, 5, "Restorative Draught must heal the target")
	assert_eq(target._skills[0].cooldown_left, 2, "A reagent is a free action: cooldown must be untouched")

func test_heal_never_exceeds_max_health() -> void:
	var resolver: BattleResolver = _make_resolver()
	var target: Character = resolver.GetCharacters()[0]
	target._current_health = 39

	resolver.ResolveReagent(0, "Restorative_Draught_Legendary", 0)

	var max_health: int = target.GetTotalAttribute(Types.Attribute.Health) * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	assert_eq(target._current_health, max_health)

func test_clear_zone_removes_a_placed_zone() -> void:
	var resolver: BattleResolver = _make_resolver()
	resolver.PlaceZone(0, 0, TestFactory.make_lava_zone_skill())
	assert_true(resolver.HasZone(0))

	resolver.ResolveReagent(0, "Zone_Dissolving_Salts_Rare", 0)

	assert_false(resolver.HasZone(0), "Zone-Dissolving Salts must remove the targeted zone")

func test_reduce_cooldown_lowers_every_skill_on_the_target_floored_at_zero() -> void:
	var resolver: BattleResolver = _make_resolver()
	var target: Character = resolver.GetCharacters()[1]
	target._skills[0].cooldown_left = 1

	resolver.ResolveReagent(0, "Rewinding_Grit_Rare", 1)

	assert_eq(target._skills[0].cooldown_left, 0)

func test_remove_debuffs_removes_up_to_the_reagent_count() -> void:
	var resolver: BattleResolver = _make_resolver()
	var target: Character = resolver.GetCharacters()[1]
	for i in 2:
		var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
		debuff.type = Types.Debuff_Type.Enfeeble
		debuff.duration = 2
		debuff.ID = i
		target._active_debuffs.append(debuff)

	resolver.ResolveReagent(0, "Purging_Tonic_Rare", 1)

	assert_eq(target._active_debuffs.size(), 1, "Rare Purging Tonic removes up to 1 debuff")

func test_attribute_increase_is_visible_through_combat_attributes() -> void:
	var resolver: BattleResolver = _make_resolver()
	var before: int = resolver.GetCombatAttributes(0)[Types.Attribute.Speed]

	resolver.ResolveReagent(0, "Tincture_Speed_Rare", 0)

	var after: int = resolver.GetCombatAttributes(0)[Types.Attribute.Speed]
	assert_gt(after, before, "The Tincture bonus must be visible on the consumer's combat attributes")

func test_fractured_idol_never_reduces_consumer_below_one_health() -> void:
	var resolver: BattleResolver = _make_resolver()
	var consumer: Character = resolver.GetCharacters()[0]
	consumer._current_health = 1

	resolver.ResolveReagent(0, "Fractured_Idol_Rare", 0)

	assert_eq(consumer._current_health, 1, "Fractured Idol cannot drop the consumer below 1 Health")

func _strike_damage(p_resolver: BattleResolver) -> int:
	var results: Array[CombatResult] = p_resolver.ResolveSkill(0, [3], 0)
	for result in results:
		if(CombatResult.Kind.Damage == result.kind and 3 == result.target_ID):
			return result.amount
	return -1

func test_fractured_idol_grants_a_persistent_damage_dealt_bonus() -> void:
	var baseline_resolver: BattleResolver = _make_resolver()
	var baseline_damage: int = _strike_damage(baseline_resolver)

	var boosted_resolver: BattleResolver = _make_resolver()
	boosted_resolver.ResolveReagent(0, "Fractured_Idol_Rare", 0)
	var boosted_damage: int = _strike_damage(boosted_resolver)

	assert_gt(boosted_damage, baseline_damage,
			"Fractured Idol's battle-long damage-dealt bonus must raise subsequent damage")

func test_destroy_enemy_buffs_removes_up_to_the_reagent_count() -> void:
	var resolver: BattleResolver = _make_resolver()
	var target: Character = resolver.GetCharacters()[3]
	for i in 2:
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = Types.Buff_Type.Empower
		buff.duration = 2
		buff.ID = i
		target._active_buffs.append(buff)

	resolver.ResolveReagent(0, "Thiefs_Regret_Rare", 3)

	assert_eq(target._active_buffs.size(), 1, "Rare Thief's Regret destroys up to 1 buff")

func test_turn_bar_reset_emits_a_pending_result_with_the_reagent_percent() -> void:
	var resolver: BattleResolver = _make_resolver()

	var results: Array[CombatResult] = resolver.ResolveReagent(0, "Second_Wind_Phial_Rare", 0)

	var pending_resets: Array = results.filter(
			func(r): return r.kind == CombatResult.Kind.Turn_Bar_Reset_Pending and r.target_ID == 0)
	assert_eq(pending_resets.size(), 1, "Second Wind Phial must report exactly one pending reset")
	assert_almost_eq(pending_resets[0].fraction, 0.20, 0.001, "Rare Second Wind Phial resets to 20%")

func test_potency_scales_a_scalar_effect_but_not_a_binary_one() -> void:
	var scaled_resolver: BattleResolver = _make_resolver()
	var scaled_target: Character = scaled_resolver.GetCharacters()[0]
	scaled_target._trait = TestFactory.FakeAmplifyingTrait.new(1.0)  # +100% potency
	scaled_target._current_health = 5

	var baseline_resolver: BattleResolver = _make_resolver()
	var baseline_target: Character = baseline_resolver.GetCharacters()[0]
	baseline_target._current_health = 5

	scaled_resolver.ResolveReagent(0, "Restorative_Draught_Rare", 0)
	baseline_resolver.ResolveReagent(0, "Restorative_Draught_Rare", 0)

	assert_gt(scaled_target._current_health, baseline_target._current_health,
			"A scalar heal must scale with the consumer's potency modifier")

	# Clear_Zone is binary: potency must not change whether it succeeds.
	var zone_resolver: BattleResolver = _make_resolver()
	var zone_consumer: Character = zone_resolver.GetCharacters()[0]
	zone_consumer._trait = TestFactory.FakeAmplifyingTrait.new(5.0)
	zone_resolver.PlaceZone(0, 0, TestFactory.make_lava_zone_skill())

	zone_resolver.ResolveReagent(0, "Zone_Dissolving_Salts_Rare", 0)

	assert_false(zone_resolver.HasZone(0), "A binary effect resolves the same regardless of potency")

func test_potency_raises_fractured_idols_cost_and_damage_bonus() -> void:
	var baseline_resolver: BattleResolver = _make_resolver()
	var baseline_consumer: Character = baseline_resolver.GetCharacters()[0]
	baseline_consumer._current_health = baseline_consumer.GetTotalAttribute(
			Types.Attribute.Health) * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var baseline_start_health: int = baseline_consumer._current_health
	baseline_resolver.ResolveReagent(0, "Fractured_Idol_Rare", 0)
	var baseline_cost: int = baseline_start_health - baseline_consumer._current_health
	var baseline_damage: int = _strike_damage(baseline_resolver)

	var boosted_resolver: BattleResolver = _make_resolver()
	var boosted_consumer: Character = boosted_resolver.GetCharacters()[0]
	# A large contribution so the damage-bonus gap survives ceil() rounding
	# regardless of the test roster's small base damage numbers.
	boosted_consumer._trait = TestFactory.FakeAmplifyingTrait.new(10.0)
	boosted_consumer._current_health = boosted_consumer.GetTotalAttribute(
			Types.Attribute.Health) * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var boosted_start_health: int = boosted_consumer._current_health
	boosted_resolver.ResolveReagent(0, "Fractured_Idol_Rare", 0)
	var boosted_cost: int = boosted_start_health - boosted_consumer._current_health
	var boosted_damage: int = _strike_damage(boosted_resolver)

	assert_gt(boosted_cost, baseline_cost, "Higher potency must raise Fractured Idol's Health cost")
	assert_gt(boosted_damage, baseline_damage, "Higher potency must raise Fractured Idol's damage-dealt bonus")
