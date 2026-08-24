extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the buff-manipulation primitives on StatusEffectResolver:
# ReduceBuffDurations (shear and expire), ConsumeBuffs (capped removal), and StealBuff
# (theft with a fresh or preserved duration, respecting Severance on the recipient). Also
# covers Skill.steal_buff_count/steal_buff_to's wiring through ResolveSkill (Writ of
# Seizure's shape: steal from the primary enemy target, land on the caster's ward).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	buff.ID = _resolver._NextStatusID()
	return buff

func _debuff(p_type: Types.Debuff_Type, p_duration: int = 2) -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = p_type
	debuff.duration = p_duration
	return debuff

# --- ReduceBuffDurations ---

func test_reduce_buff_durations_shears_every_buff_on_the_target() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 3))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Fortify, 2))

	_resolver.GetStatusResolver().ReduceBuffDurations(0, 1)

	assert_eq(_roster[0]._active_buffs[0].duration, 2)
	assert_eq(_roster[0]._active_buffs[1].duration, 1)

func test_reduce_buff_durations_expires_a_buff_that_reaches_zero() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 1))

	_resolver.GetStatusResolver().ReduceBuffDurations(0, 1)

	assert_eq(_roster[0]._active_buffs.size(), 0, "A buff shorn to zero duration should expire")

func test_reduce_buff_durations_emits_statuses_removed_for_the_expired_buff() -> void:
	var buff: StatusEffects.Buff = _buff(Types.Buff_Type.Empower, 1)
	_roster[0]._active_buffs.append(buff)
	var caught: Array[CombatResult] = []
	_resolver.result_produced.connect(func(r: CombatResult) -> void: caught.append(r))

	_resolver.GetStatusResolver().ReduceBuffDurations(0, 1)

	var removed: Array = caught.filter(func(r): return r.kind == CombatResult.Kind.Statuses_Removed)
	assert_eq(removed.size(), 1)
	assert_eq(removed[0].status_IDs, [buff.ID] as Array[int])

func test_reduce_buff_durations_does_nothing_for_a_non_positive_amount() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 2))

	_resolver.GetStatusResolver().ReduceBuffDurations(0, 0)

	assert_eq(_roster[0]._active_buffs[0].duration, 2)

# --- ConsumeBuffs ---

func test_consume_buffs_removes_up_to_the_requested_count() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Fortify))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Haste))

	var consumed: int = _resolver.GetStatusResolver().ConsumeBuffs(0, 2)

	assert_eq(consumed, 2)
	assert_eq(_roster[0]._active_buffs.size(), 1)

func test_consume_buffs_negative_one_removes_all() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower))
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Fortify))

	var consumed: int = _resolver.GetStatusResolver().ConsumeBuffs(0, -1)

	assert_eq(consumed, 2)
	assert_eq(_roster[0]._active_buffs.size(), 0)

func test_consume_buffs_returns_zero_when_the_target_holds_none() -> void:
	var consumed: int = _resolver.GetStatusResolver().ConsumeBuffs(0, -1)

	assert_eq(consumed, 0)

# --- StealBuff ---

func test_steal_buff_moves_a_buff_from_source_to_recipient() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 2))

	var stole: bool = _resolver.GetStatusResolver().StealBuff(0, 1)

	assert_true(stole)
	assert_eq(_roster[0]._active_buffs.size(), 0, "The source should lose the stolen buff")
	assert_eq(_roster[1]._active_buffs.size(), 1, "The recipient should gain it")
	assert_eq(_roster[1]._active_buffs[0].type, Types.Buff_Type.Empower)

func test_steal_buff_defaults_to_the_stolen_buffs_own_duration() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 3))

	_resolver.GetStatusResolver().StealBuff(0, 1)

	assert_eq(_roster[1]._active_buffs[0].duration, 3)

func test_steal_buff_can_grant_a_fresh_duration() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 1))

	_resolver.GetStatusResolver().StealBuff(0, 1, 2)

	assert_eq(_roster[1]._active_buffs[0].duration, 2)

func test_steal_buff_returns_false_when_the_source_holds_nothing() -> void:
	var stole: bool = _resolver.GetStatusResolver().StealBuff(0, 1)

	assert_false(stole)

func test_steal_buff_is_blocked_by_severance_on_the_recipient() -> void:
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 2))
	_roster[1]._active_debuffs.append(_debuff(Types.Debuff_Type.Severance))

	var stole: bool = _resolver.GetStatusResolver().StealBuff(0, 1)

	assert_true(stole, "The source should still lose the buff")
	assert_eq(_roster[0]._active_buffs.size(), 0)
	assert_eq(_roster[1]._active_buffs.size(), 0, "Severance should block the re-application")

# --- Skill.steal_buff_count / steal_buff_to wiring (Writ of Seizure's shape) ---

func test_steal_buff_count_skill_steals_from_the_target_to_the_casters_ward() -> void:
	# Notary (3) / Collector (4) vs. a lone target (0): Ally_Not_Self resolves to exactly
	# one candidate, matching the cataloged Collector-of-Debts encounter's shape.
	var roster: Dictionary[int, Character] = {}
	roster[0] = TestFactory.make_character()
	roster[0]._current_health = roster[0]._attributes[Types.Attribute.Health]
	roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 3))
	roster[3] = TestFactory.make_character()
	roster[3]._current_health = roster[3]._attributes[Types.Attribute.Health]
	roster[4] = TestFactory.make_character()
	roster[4]._current_health = roster[4]._attributes[Types.Attribute.Health]
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [3, 4]))
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Writ of Seizure"
	var effect: StealBuffEffect = StealBuffEffect.new()
	effect.count = 1
	effect.to = Types.Skill_Target.Ally_Not_Self
	effect.duration_override = 2
	skill.effects = [effect]
	roster[3]._skills.append(skill)

	resolver.ResolveSkill(3, [0], 0)

	assert_eq(roster[0]._active_buffs.size(), 0, "The buff should be stolen from the target")
	assert_eq(roster[4]._active_buffs.size(), 1, "The only living ally should receive the stolen buff")
	assert_eq(roster[4]._active_buffs[0].duration, 2, "The stolen buff should get the skill's fresh duration")

func test_steal_buff_count_skips_a_dead_ward_in_favor_of_a_living_one() -> void:
	var roster: Dictionary[int, Character] = {}
	roster[0] = TestFactory.make_character()
	roster[0]._current_health = roster[0]._attributes[Types.Attribute.Health]
	roster[0]._active_buffs.append(_buff(Types.Buff_Type.Empower, 3))
	roster[3] = TestFactory.make_character()
	roster[3]._current_health = roster[3]._attributes[Types.Attribute.Health]
	roster[4] = TestFactory.make_character()
	roster[4]._current_health = 0
	roster[5] = TestFactory.make_character()
	roster[5]._current_health = roster[5]._attributes[Types.Attribute.Health]
	var resolver: BattleResolver = TestFactory.make_resolver(roster, CombatSides.new([0], [3, 4, 5]))
	var skill: Skill = TestFactory.make_empty_skill()
	skill.name = "Writ of Seizure"
	var effect: StealBuffEffect = StealBuffEffect.new()
	effect.count = 1
	effect.to = Types.Skill_Target.Ally_Not_Self
	effect.duration_override = 2
	skill.effects = [effect]
	roster[3]._skills.append(skill)

	resolver.ResolveSkill(3, [0], 0)

	assert_eq(roster[4]._active_buffs.size(), 0, "A dead ward must never receive the stolen buff")
	assert_eq(roster[5]._active_buffs.size(), 1, "The buff should go to the only living ally")

# --- RemoveBuff ---

func test_remove_buff_erases_from_active_buffs() -> void:
	var buff: StatusEffects.Buff = _buff(Types.Buff_Type.Empower)
	_roster[0]._active_buffs.append(buff)

	var results: Array[CombatResult] = _resolver.GetStatusResolver().RemoveBuff(0, buff)

	assert_eq(_roster[0]._active_buffs.size(), 0, "Buff should be erased after RemoveBuff")
	assert_eq(results.size(), 1, "Removal should be reported")
	assert_eq(results[0].kind, CombatResult.Kind.Statuses_Removed)
	assert_eq(results[0].status_IDs, [buff.ID] as Array[int], "The removed buff's status ID should be reported")

func test_remove_buff_only_erases_target_buff() -> void:
	var buff_a: StatusEffects.Buff = _buff(Types.Buff_Type.Empower, 2)
	var buff_b: StatusEffects.Buff = _buff(Types.Buff_Type.Fortify, 3)
	_roster[0]._active_buffs.append(buff_a)
	_roster[0]._active_buffs.append(buff_b)

	_resolver.GetStatusResolver().RemoveBuff(0, buff_a)

	assert_eq(_roster[0]._active_buffs.size(), 1, "Only the targeted buff should be removed")
	assert_eq(_roster[0]._active_buffs[0].type, Types.Buff_Type.Fortify,
		"Remaining buff should be the one that was not removed")

# --- RemoveBuff health reclamp (reachable via ConsumeBuffs / StealBuff) ---

func test_remove_buff_reclamps_current_health_after_removing_a_max_health_buff() -> void:
	var unbuffed_max: int = _resolver.GetMaxHealth(0)
	var vigor: StatusEffects.Buff = _buff(Types.Buff_Type.Vigor, 2)
	vigor.value = 0.3
	_roster[0]._active_buffs.append(vigor)
	_roster[0]._current_health = _resolver.GetMaxHealth(0)
	assert_gt(_roster[0]._current_health, unbuffed_max, "Sanity check: Vigor should raise current max Health")

	_resolver.GetStatusResolver().RemoveBuff(0, vigor)

	assert_eq(_roster[0]._current_health, unbuffed_max,
		"Current Health should reclamp to the un-buffed max once Vigor is removed")

func test_steal_buff_reclamps_the_sources_current_health_when_stealing_a_max_health_buff() -> void:
	var unbuffed_max: int = _resolver.GetMaxHealth(0)
	var vigor: StatusEffects.Buff = _buff(Types.Buff_Type.Vigor, 2)
	vigor.value = 0.3
	_roster[0]._active_buffs.append(vigor)
	_roster[0]._current_health = _resolver.GetMaxHealth(0)

	_resolver.GetStatusResolver().StealBuff(0, 1)

	assert_eq(_roster[0]._current_health, unbuffed_max,
		"The source's current Health should reclamp once its Vigor is stolen away")
