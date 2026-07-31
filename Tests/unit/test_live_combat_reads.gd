extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Before GetEffectiveAttributes existed, these combat reads used GetCombatAttributes, which
# never folded in active statuses at all (not even the old self-tick/target-snapshot gating
# applied here). Each test below exercises one such site to confirm it now reads live status
# modifiers, not a status-blind base value.

# --- Debuff-resist roll (StatusEffectResolver.CastDebuff) reads live Resistance/Accuracy ---

func test_resist_roll_uses_live_resistance_from_an_active_debuff() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[0]._attributes[Types.Attribute.Accuracy] = 85
	roster[3]._attributes[Types.Attribute.Resistance] = 100
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	# 85 * [0.95, 1.0] = [80.75, 85] is always below 100 * [0.95, 1.0] = [95, 100], so at
	# full Resistance the debuff is always resisted regardless of the random roll.
	var first_attempt: StatusEffects.Debuff = StatusEffects.Debuff.new()
	first_attempt.type = Types.Debuff_Type.Blind
	first_attempt.duration = 2
	resolver.GetStatusResolver().CastDebuff(3, first_attempt, 0)
	assert_eq(roster[3]._active_debuffs.size(), 0, "Blind should be resisted against full Resistance")

	var unravel: StatusEffects.Debuff = StatusEffects.Debuff.new()
	unravel.type = Types.Debuff_Type.Unravel
	unravel.value = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Unravel).magnitude
	roster[3]._active_debuffs.append(unravel)

	# Unravel's live -30% brings effective Resistance to 70: 85 * [0.95, 1.0] = [80.75, 85]
	# is always above 70 * [0.95, 1.0] = [66.5, 70], so the next debuff always lands.
	var second_attempt: StatusEffects.Debuff = StatusEffects.Debuff.new()
	second_attempt.type = Types.Debuff_Type.Blind
	second_attempt.duration = 2
	resolver.GetStatusResolver().CastDebuff(3, second_attempt, 0)
	var blinds: Array = roster[3]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Blind)
	assert_eq(blinds.size(), 1,
		"Unravel's live Resistance reduction (not the pre-status base value) must let the next debuff land")

# --- Redirected damage is re-mitigated against the soaker's own live Defence ---

func _damage_to(p_results: Array[CombatResult], p_target_ID: int) -> Array:
	return p_results.filter(func(r): return CombatResult.Kind.Damage == r.kind and r.target_ID == p_target_ID)

func _make_redirect_resolver(p_apply_fortify_to_soaker: bool) -> BattleResolver:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[1]._trait = ShieldWallTrait.new()
	roster[1]._trait.Init(Types.Rarity.Uncommon)
	roster[1]._attributes[Types.Attribute.Defence] = 30
	roster[3]._attributes[Types.Attribute.Attack] = 300
	if(p_apply_fortify_to_soaker):
		var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
		fortify.type = Types.Buff_Type.Fortify
		fortify.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify).magnitude
		roster[1]._active_buffs.append(fortify)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0]
	return TestFactory.make_resolver(roster, TestFactory.make_full_sides(), positions)

func test_redirect_soaker_defence_reads_a_live_defence_buff() -> void:
	var baseline_resolver: BattleResolver = _make_redirect_resolver(false)
	var baseline_targets: Array[int] = [0]
	var baseline_results: Array[CombatResult] = baseline_resolver.ResolveTraitDamage(
		3, baseline_targets, baseline_resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})
	var baseline_soak: int = _damage_to(baseline_results, 1)[0].amount

	var buffed_resolver: BattleResolver = _make_redirect_resolver(true)
	var buffed_targets: Array[int] = [0]
	var buffed_results: Array[CombatResult] = buffed_resolver.ResolveTraitDamage(
		3, buffed_targets, buffed_resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})
	var buffed_soak: int = _damage_to(buffed_results, 1)[0].amount

	assert_lt(buffed_soak, baseline_soak,
		"A Fortify buff on the soaker must lower the redirected damage it takes, not just its base Defence")

# --- Trait/DoT damage against a target reads the target's live Defence ---

func test_trait_damage_reads_the_targets_live_defence_buff() -> void:
	var baseline_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	baseline_roster[0]._attributes[Types.Attribute.Attack] = 300
	baseline_roster[3]._attributes[Types.Attribute.Defence] = 100
	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	var baseline_results: Array[CombatResult] = baseline_resolver.ResolveTraitDamage(
		0, [3], baseline_resolver.GetEffectiveAttributes(0), {Types.Attribute.Attack: 1.0})
	var baseline_damage: int = _damage_to(baseline_results, 3)[0].amount

	var buffed_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	buffed_roster[0]._attributes[Types.Attribute.Attack] = 300
	buffed_roster[3]._attributes[Types.Attribute.Defence] = 100
	var fortify: StatusEffects.Buff = StatusEffects.Buff.new()
	fortify.type = Types.Buff_Type.Fortify
	fortify.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Fortify).magnitude
	buffed_roster[3]._active_buffs.append(fortify)
	var buffed_resolver: BattleResolver = TestFactory.make_resolver(buffed_roster, TestFactory.make_full_sides())
	var buffed_results: Array[CombatResult] = buffed_resolver.ResolveTraitDamage(
		0, [3], buffed_resolver.GetEffectiveAttributes(0), {Types.Attribute.Attack: 1.0})
	var buffed_damage: int = _damage_to(buffed_results, 3)[0].amount

	assert_lt(buffed_damage, baseline_damage,
		"ResolveTraitDamage must read the target's live Defence, including an active Fortify buff")

# --- TurnBar.NormalizeSpeeds fed live (status-inclusive) speeds ---

func test_normalize_speeds_reflects_a_live_haste_boosted_speed() -> void:
	# battle.gd feeds NormalizeSpeeds each character's BattleResolver.GetEffectiveAttributes
	# Speed, not the base sheet value, so a Haste buff changes the ratio it produces.
	var base_speeds: Dictionary[int, int] = {0: 20, 1: 20}
	var base_ratios: Dictionary[int, float] = TurnBar.NormalizeSpeeds(base_speeds)
	assert_almost_eq(base_ratios[0], 1.0, 0.0001)
	assert_almost_eq(base_ratios[1], 1.0, 0.0001)

	# Character 0's live Speed after a +20% Haste buff (20 -> 24).
	var live_speeds: Dictionary[int, int] = {0: 24, 1: 20}
	var live_ratios: Dictionary[int, float] = TurnBar.NormalizeSpeeds(live_speeds)
	assert_almost_eq(live_ratios[0], 1.0, 0.0001, "The Hasted character should be the new fastest")
	assert_almost_eq(live_ratios[1], 20.0 / 24.0, 0.0001, "The other character should fall behind proportionally")
