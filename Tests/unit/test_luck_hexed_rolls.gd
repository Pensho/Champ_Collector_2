extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Luck and Hexed: the crit-chance roll and the debuff-resist roll are each
# rolled twice, keeping the better (Luck) or worse (Hexed) result; a holder with both
# cancels out to a single normal roll (Concept_Document.md 3.2.3.2, user decision on the
# simultaneous case). The damage-variance roll is a sub-1% spread that neither status
# favors any more (a sub-1% variance term fails the collapse test in Concept_Document.md
# 1.1.6): BattleResolver rolls it with a plain randf_range instead of RollFavoring. Outcomes
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

func test_luck_does_not_change_the_damage_variance_rolls_distribution() -> void:
	var baseline: int = _damage()
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_strike_skill())
	_roster[0]._attributes[Types.Attribute.CritChance] = 0
	_roster[0]._attributes[Types.Attribute.Attack] = 500
	_add_buff(Types.Buff_Type.Luck)

	assert_eq(_damage(), baseline,
		"Luck must no longer favor the damage-variance roll; both draws use the same RNG stream")

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
	# Seed 2 (rather than the file's default 0) is the one whose crit-roll draws land on
	# opposite sides of CritChance 25 for the baseline vs. the better-of-two Luck roll,
	# now that the damage-variance roll no longer burns an extra draw for Luck holders.
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), null, 2)
	var results: Array[CombatResult] = resolver.ResolveSkill(0, [3], 0)
	for r in results:
		if(r.kind == CombatResult.Kind.Damage):
			return r.critical
	return false

func test_luck_improves_the_crit_chance_roll() -> void:
	assert_false(_critical_roll(false), "Baseline setup for this test must not roll a critical")
	assert_true(_critical_roll(true), "Luck's better-of-two crit roll should land a critical the baseline missed")
