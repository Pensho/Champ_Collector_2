extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Exposed Facet / Cracked Facet: attacker-side crit bonuses read from the *target's*
# active debuffs in BattleResolver._ResolveDamage, not from the attacker's own statuses.

func _add_debuff(p_character: Character, p_type: Types.Debuff_Type) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.value = StatusEffectRegistry.DebuffData(p_type).magnitude
	debuff.duration = 5
	p_character._active_debuffs.append(debuff)

func test_exposed_facet_grants_the_attacker_crit_chance_points() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	assert_eq(resolver._AttackerCritChanceBonus(roster[3]), 0, "No debuff, no crit-chance bonus")

	_add_debuff(roster[3], Types.Debuff_Type.Exposed_Facet)
	assert_eq(resolver._AttackerCritChanceBonus(roster[3]), 15,
		"Exposed Facet should grant a flat +15 crit-chance bonus to the attacker")

func test_cracked_facet_grants_the_attacker_crit_damage_points() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	assert_eq(resolver._AttackerCritDamageBonus(roster[3]), 0, "No debuff, no crit-damage bonus")

	_add_debuff(roster[3], Types.Debuff_Type.Cracked_Facet)
	assert_eq(resolver._AttackerCritDamageBonus(roster[3]), 25,
		"Cracked Facet should grant a flat +25 crit-damage bonus to the attacker")

func test_cracked_facet_increases_actual_crit_damage_dealt() -> void:
	var baseline_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var facet_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for roster in [baseline_roster, facet_roster]:
		roster[0]._skills.append(TestFactory.make_strike_skill())
		roster[0]._attributes[Types.Attribute.CritChance] = 100
	_add_debuff(facet_roster[3], Types.Debuff_Type.Cracked_Facet)

	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	var facet_resolver: BattleResolver = TestFactory.make_resolver(facet_roster, TestFactory.make_full_sides())

	var baseline_results: Array[CombatResult] = baseline_resolver.ResolveSkill(0, [3], 0)
	var facet_results: Array[CombatResult] = facet_resolver.ResolveSkill(0, [3], 0)

	var baseline_damage: Array = baseline_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	var facet_damage: Array = facet_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)
	assert_true(baseline_damage[0].critical and facet_damage[0].critical, "Both hits should be guaranteed crits")
	assert_gt(facet_damage[0].amount, baseline_damage[0].amount,
		"Cracked Facet should increase the crit damage dealt to the debuffed target")
