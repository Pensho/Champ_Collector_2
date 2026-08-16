extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Luck and Hexed: every chance roll in combat except the damage-variance roll is
# rolled twice, keeping the better (Luck) or worse (Hexed) result; a holder with both
# cancels out to a single normal roll (Concept_Document.md 3.2.3.2, user decision on the
# simultaneous case). The damage-variance roll is a sub-1% spread that neither status
# favors any more (a sub-1% variance term fails the collapse test in Concept_Document.md
# 1.1.6): BattleResolver rolls it with a plain randf_range instead of RollFavoring. Outcomes
# below are deterministic for the default seed (0) — see BattleResolver.RollFavoring.

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

# --- SkillEffect.chance gate (Types.Skill_Condition-independent) ---

func _chance_pass_count(p_samples: int, p_status: Variant) -> int:
	var passes: int = 0
	for i in p_samples:
		var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
		if(p_status == Types.Buff_Type.Luck):
			var buff: StatusEffects.Buff = StatusEffects.Buff.new()
			buff.type = p_status
			buff.duration = 2
			roster[0]._active_buffs.append(buff)
		elif(p_status == Types.Debuff_Type.Hexed):
			var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			debuff.type = p_status
			debuff.duration = 2
			roster[0]._active_debuffs.append(debuff)
		var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), null, i)
		var effect: SkillEffect = SkillEffect.new()
		effect.chance = 0.5
		var context: SkillCastContext = TestFactory.make_context(resolver, 0, [3], TestFactory.make_empty_skill())
		if(context.ConditionMet(effect)):
			passes += 1
	return passes

func test_hexed_lowers_the_skill_effect_chance_gates_pass_rate() -> void:
	var baseline: int = _chance_pass_count(200, null)
	var with_hexed: int = _chance_pass_count(200, Types.Debuff_Type.Hexed)
	assert_lt(with_hexed, baseline, "Hexed should take the worse (lower) of two chance-gate rolls")

func test_luck_raises_the_skill_effect_chance_gates_pass_rate() -> void:
	var baseline: int = _chance_pass_count(200, null)
	var with_luck: int = _chance_pass_count(200, Types.Buff_Type.Luck)
	assert_gt(with_luck, baseline, "Luck should take the better (higher) of two chance-gate rolls")

# --- Debuff-resist contest band (0.85-1.0) ---

func _resist_count(p_samples: int, p_defender_has_hexed: bool) -> int:
	var resisted: int = 0
	for i in p_samples:
		var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
		roster[0]._attributes[Types.Attribute.Accuracy] = 100
		roster[3]._attributes[Types.Attribute.Resistance] = 100
		if(p_defender_has_hexed):
			var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			debuff.type = Types.Debuff_Type.Hexed
			debuff.duration = 2
			roster[3]._active_debuffs.append(debuff)
		var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides(), null, i)
		var status_resolver: StatusEffectResolver = resolver.GetStatusResolver()
		var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
		template.type = Types.Debuff_Type.Enfeeble
		template.duration = 2
		var results: Array[CombatResult] = status_resolver.CastDebuff(3, template, 0)
		if(results.any(func(r): return r.kind == CombatResult.Kind.Debuff_Resisted)):
			resisted += 1
	return resisted

func test_widened_resist_band_makes_hexed_materially_more_resistible() -> void:
	# At an even Accuracy/Resistance matchup, the widened 0.85-1.0 band makes a defender's
	# own Hexed (worse-of-two on their own resist roll) resisted far less often than an
	# unhexed defender at the same stats — the old 0.95-1.0 band left this near-inert.
	var baseline: int = _resist_count(200, false)
	var with_hexed: int = _resist_count(200, true)
	assert_lt(with_hexed, baseline,
		"A Hexed defender should resist noticeably less often under the widened band")
