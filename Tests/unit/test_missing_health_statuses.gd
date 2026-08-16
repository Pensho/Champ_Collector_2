extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Sanguine Pact and Hemorrhage: one continuous missing-Health computation read three ways
# (Role_Kit_Design.md 9.4) — the pact holder's own missing Health for Sanguine Pact, the
# target's own missing Health for Hemorrhage — landing in distinct CombinedDamageModifier
# buckets so the two multiply rather than share one.

func _roster_with_strike(p_caster_ID: int) -> Dictionary:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[p_caster_ID]._skills.append(TestFactory.make_strike_skill())
	return roster

func _damage_modifier(p_results: Array[CombatResult]) -> CombinedDamageModifier:
	for r in p_results:
		if(r.kind == CombatResult.Kind.Damage):
			return r.combined_damage_modifier
	return null

func _wound(p_character: Character, p_fraction_missing: float) -> void:
	var max_health: int = p_character._attributes[Types.Attribute.Health] * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	p_character._current_health = int(round(max_health * (1.0 - p_fraction_missing)))

func test_sanguine_pact_scales_holders_own_damage_with_holders_own_missing_health() -> void:
	var roster: Dictionary = _roster_with_strike(0)
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Sanguine_Pact).magnitude
	pact.duration = 3
	pact.source_ID = 1
	roster[0]._active_buffs.append(pact)
	_wound(roster[0], 0.5)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var modifier: CombinedDamageModifier = _damage_modifier(resolver.ResolveSkill(0, [3], 0))

	assert_almost_eq(modifier.Buckets()[&"Sanguine_Pact"], 0.6, 0.0001,
		"12% per 10% missing at 50% missing should be 0.6")

func test_sanguine_pact_has_no_effect_when_holder_is_at_full_health() -> void:
	var roster: Dictionary = _roster_with_strike(0)
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Sanguine_Pact).magnitude
	pact.duration = 3
	pact.source_ID = 1
	roster[0]._active_buffs.append(pact)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	roster[0]._current_health = resolver.GetMaxHealth(0)

	var modifier: CombinedDamageModifier = _damage_modifier(resolver.ResolveSkill(0, [3], 0))

	assert_false(modifier.Buckets().has(&"Sanguine_Pact"),
		"No missing Health means no Sanguine Pact contribution")

func test_hemorrhage_scales_every_attackers_damage_with_targets_own_missing_health() -> void:
	var roster: Dictionary = _roster_with_strike(0)
	var hemorrhage: StatusEffects.Debuff = StatusEffects.Debuff.new()
	hemorrhage.type = Types.Debuff_Type.Hemorrhage
	hemorrhage.value = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Hemorrhage).magnitude
	hemorrhage.duration = 3
	hemorrhage.source_ID = 1 # applied by a different ally than the attacker
	roster[3]._active_debuffs.append(hemorrhage)
	_wound(roster[3], 0.5)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var modifier: CombinedDamageModifier = _damage_modifier(resolver.ResolveSkill(0, [3], 0))

	assert_almost_eq(modifier.Buckets()[&"Hemorrhage"], 0.3, 0.0001,
		"6% per 10% missing at 50% missing should be 0.3, readable by any attacker")

func test_sanguine_pact_and_hemorrhage_multiply_in_distinct_buckets() -> void:
	var roster: Dictionary = _roster_with_strike(0)
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.value = StatusEffectRegistry.BuffData(Types.Buff_Type.Sanguine_Pact).magnitude
	pact.duration = 3
	pact.source_ID = 1
	roster[0]._active_buffs.append(pact)
	_wound(roster[0], 0.5)
	var hemorrhage: StatusEffects.Debuff = StatusEffects.Debuff.new()
	hemorrhage.type = Types.Debuff_Type.Hemorrhage
	hemorrhage.value = StatusEffectRegistry.DebuffData(Types.Debuff_Type.Hemorrhage).magnitude
	hemorrhage.duration = 3
	hemorrhage.source_ID = 1
	roster[3]._active_debuffs.append(hemorrhage)
	_wound(roster[3], 0.5)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var buckets: Dictionary[StringName, float] = _damage_modifier(resolver.ResolveSkill(0, [3], 0)).Buckets()

	assert_almost_eq(buckets[&"Sanguine_Pact"], 0.6, 0.0001)
	assert_almost_eq(buckets[&"Hemorrhage"], 0.3, 0.0001)

# --- Damage redirect precedence: Sanguine Pact over a nearby Shield Wall ---

func test_sanguine_pact_redirects_damage_to_its_applier() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.duration = 3
	pact.source_ID = 1
	roster[0]._active_buffs.append(pact)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [0], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var damage_to_applier: Array = results.filter(
			func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 1)
	assert_eq(damage_to_applier.size(), 1, "30% of the incoming damage should redirect to the pact's applier")

func test_sanguine_pact_takes_precedence_over_shield_wall() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	roster[2]._trait = ShieldWallTrait.new()
	roster[2]._trait.Init(Types.Rarity.Legendary)
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.duration = 3
	pact.source_ID = 1
	roster[0]._active_buffs.append(pact)
	var positions: TestFactory.FakeTurnPositions = TestFactory.FakeTurnPositions.new()
	positions.proximity_IDs = [0]
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), positions)

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [0], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var damage_to_pact_applier: Array = results.filter(
			func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 1)
	var damage_to_shield_wall: Array = results.filter(
			func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 2)
	assert_eq(damage_to_pact_applier.size(), 1, "Sanguine Pact should redirect")
	assert_eq(damage_to_shield_wall.size(), 0, "Shield Wall should not also redirect the same hit")

func test_sanguine_pact_does_not_redirect_when_its_applier_is_dead() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.duration = 3
	pact.source_ID = 1
	roster[0]._active_buffs.append(pact)
	roster[1]._current_health = 0
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())

	var results: Array[CombatResult] = resolver.ResolveTraitDamage(
			3, [0], resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

	var damage_to_applier: Array = results.filter(
			func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 1)
	assert_eq(damage_to_applier.size(), 0, "A dead applier cannot soak redirected damage")
