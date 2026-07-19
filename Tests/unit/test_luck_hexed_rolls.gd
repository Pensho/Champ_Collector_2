extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Luck and Hexed: every roll site the resolver makes (damage variance,
# crit chance, resist) is rolled twice and the holder keeps the better (Luck) or
# worse (Hexed) result; a holder with both cancels out to a single normal roll
# (Concept_Document.md 3.2.3.2, user decision on the simultaneous case). Outcomes
# below are deterministic for the default seed (0) — see BattleResolver._RollFavoring.

var _roster: Dictionary[int, Character] = {}

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	_roster[0]._attributes[Types.Attribute.CritChance] = 0
	_roster[0]._attributes[Types.Attribute.Attack] = 500

func _add_buff(p_type: Types.Buff_Type) -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = 2
	_roster[0]._active_buffs.append(buff)

func _add_debuff(p_type: Types.Debuff_Type) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = 2
	_roster[0]._active_debuffs.append(debuff)

func _damage() -> int:
	var resolver: BattleResolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], 0)
	for r in results:
		if(r.kind == CombatResult.Kind.Damage):
			return r.amount
	return -1

func test_hexed_worsens_the_damage_variance_roll() -> void:
	var baseline: int = _damage()
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	_roster[0]._attributes[Types.Attribute.CritChance] = 0
	_roster[0]._attributes[Types.Attribute.Attack] = 500
	_add_debuff(Types.Debuff_Type.Hexed)

	assert_lt(_damage(), baseline, "Hexed should roll the damage-variance site worse than an unbuffed baseline")

func test_luck_and_hexed_together_cancel_out_on_the_damage_variance_roll() -> void:
	var baseline: int = _damage()
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	_roster[0]._attributes[Types.Attribute.CritChance] = 0
	_roster[0]._attributes[Types.Attribute.Attack] = 500
	_add_buff(Types.Buff_Type.Luck)
	_add_debuff(Types.Debuff_Type.Hexed)

	assert_eq(_damage(), baseline, "Luck and Hexed together must cancel out to a single normal roll")

func _critical_roll(p_with_luck: bool) -> bool:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	roster[0]._attributes[Types.Attribute.CritChance] = 25
	roster[0]._attributes[Types.Attribute.Attack] = 500
	if(p_with_luck):
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = Types.Buff_Type.Luck
		buff.duration = 2
		roster[0]._active_buffs.append(buff)
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	if(not p_with_luck):
		resolver.GetRandom().randf_range(0.95, 1.05)  # realign with Luck's extra variance-roll draw
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], 0)
	for r in results:
		if(r.kind == CombatResult.Kind.Damage):
			return r.critical
	return false

func test_luck_improves_the_crit_chance_roll() -> void:
	assert_false(_critical_roll(false), "Baseline setup for this test must not roll a critical")
	assert_true(_critical_roll(true), "Luck's better-of-two crit roll should land a critical the baseline missed")
