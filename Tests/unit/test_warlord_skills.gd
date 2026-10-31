extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const HOLD_THE_LINE = preload("res://Data/Character_Skill_Variants/Support_Skills/Hold_the_Line.tres")
const BRACE_FOR_IMPACT = preload("res://Data/Character_Skill_Variants/Support_Skills/Brace_for_Impact.tres")

const WARLORD_ID: int = 1

var _roster: Dictionary[int, Character] = {}
var _positions: TestFactory.FakeTurnPositions = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_roster[WARLORD_ID]._trait = ShieldWallTrait.new()
	_roster[WARLORD_ID]._trait.Init(Types.Rarity.Legendary)
	_roster[WARLORD_ID]._skills = [TestFactory.make_strike_skill(), HOLD_THE_LINE, BRACE_FOR_IMPACT]
	_roster[3]._attributes[Types.Attribute.Accuracy] = 9999
	_positions = TestFactory.FakeTurnPositions.new()
	_positions.proximity_IDs = [0]
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)

func _has_buff(p_character_ID: int, p_type: Types.Buff_Type) -> bool:
	return _resolver._HasBuff(p_character_ID, p_type)

func _debuff_on(p_character_ID: int, p_type: Types.Debuff_Type) -> StatusEffects.Debuff:
	for debuff in _roster[p_character_ID]._active_debuffs:
		if(p_type == debuff.type):
			return debuff
	return null

func _cast_debuff(p_target_ID: int, p_type: Types.Debuff_Type, p_duration: int, p_caster_ID: int = 3) -> void:
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = p_type
	template.duration = p_duration
	_resolver.GetStatusResolver().CastDebuff(p_target_ID, template, p_caster_ID)

func _attack(p_target_ID: int) -> Array[CombatResult]:
	return _resolver.ResolveTraitDamage(
			3, [p_target_ID], _resolver.GetEffectiveAttributes(3), {Types.Attribute.Attack: 1.0})

func _damage_to(p_results: Array[CombatResult], p_target_ID: int) -> int:
	var total: int = 0
	for result in p_results:
		if(CombatResult.Kind.Damage == result.kind and p_target_ID == result.target_ID):
			total += result.amount
	return total

# --- Hold the Line ---

func test_hold_the_line_ends_with_aegis_on_every_ally_and_keeps_the_warlords() -> void:
	_resolver.ResolveSkill(WARLORD_ID, [0, 1, 2], 1)
	assert_not_null(_debuff_on(WARLORD_ID, Types.Debuff_Type.Slow), "His own Slow lands")
	for id in [0, 1, 2]:
		assert_true(_has_buff(id, Types.Buff_Type.Aegis), "Every ally ends with Aegis")
		assert_true(_has_buff(id, Types.Buff_Type.Fortify), "Every ally gains Fortify")

# --- Brace for Impact ---

func test_brace_grants_rush_without_aegis() -> void:
	_resolver.ResolveSkill(WARLORD_ID, [WARLORD_ID], 2)
	assert_true(_has_buff(WARLORD_ID, Types.Buff_Type.Rush))
	assert_false(_has_buff(WARLORD_ID, Types.Buff_Type.Aegis))

func test_bracing_takes_every_attack_on_allies_at_any_distance() -> void:
	_positions.proximity_IDs = []
	_resolver.ResolveSkill(WARLORD_ID, [WARLORD_ID], 2)
	var results: Array[CombatResult] = _attack(0)
	assert_eq(_damage_to(results, 0), 0, "The ally takes nothing")
	assert_gt(_damage_to(results, WARLORD_ID), 0, "The Warlord takes the hit")

func test_bracing_halves_the_damage_the_warlord_takes() -> void:
	_roster[3]._attributes[Types.Attribute.Attack] = 5000
	_roster[WARLORD_ID]._current_health = 1000000
	_resolver.ResolveSkill(WARLORD_ID, [WARLORD_ID], 2)
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	var braced: int = _damage_to(_attack(WARLORD_ID), WARLORD_ID)
	# Rush raises his Defence too, so compare against the same Rush without the reduction.
	_roster[WARLORD_ID]._active_buffs[0].trait_riders.erase(StatusEffectResolver.DAMAGE_REDUCTION_RIDER_KEY)
	_roster[3]._active_debuffs.clear()
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides(), _positions)
	var rushed: int = _damage_to(_attack(WARLORD_ID), WARLORD_ID)
	assert_gt(rushed, 100, "Enough damage for the halving to read")
	assert_almost_eq(float(braced), rushed * 0.5, 1.0, "He takes 50% less damage")

func test_bracing_goes_ahead_of_sanguine_pact() -> void:
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.duration = 3
	pact.source_ID = 2
	_roster[0]._active_buffs.append(pact)
	_resolver.ResolveSkill(WARLORD_ID, [WARLORD_ID], 2)
	var results: Array[CombatResult] = _attack(0)
	assert_eq(_damage_to(results, 2), 0, "The Pact's applier takes nothing")
	assert_gt(_damage_to(results, WARLORD_ID), 0, "The Warlord takes the hit")

func test_sanguine_pact_still_goes_ahead_of_a_partial_shield_wall() -> void:
	var pact: StatusEffects.Buff = StatusEffects.Buff.new()
	pact.type = Types.Buff_Type.Sanguine_Pact
	pact.duration = 3
	pact.source_ID = 2
	_roster[0]._active_buffs.append(pact)
	var results: Array[CombatResult] = _attack(0)
	assert_gt(_damage_to(results, 2), 0)
	assert_eq(_damage_to(results, WARLORD_ID), 0)

# --- Shield Wall's debuff split ---

func test_a_two_turn_debuff_lasts_one_turn_on_each() -> void:
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 2)
	assert_eq(_debuff_on(0, Types.Debuff_Type.Enfeeble).duration, 1)
	assert_eq(_debuff_on(WARLORD_ID, Types.Debuff_Type.Enfeeble).duration, 1)

func test_a_three_turn_debuff_passes_only_one_turn() -> void:
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 3)
	assert_eq(_debuff_on(0, Types.Debuff_Type.Enfeeble).duration, 2)
	assert_eq(_debuff_on(WARLORD_ID, Types.Debuff_Type.Enfeeble).duration, 1)

func test_a_one_turn_debuff_passes_nothing() -> void:
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 1)
	assert_eq(_debuff_on(0, Types.Debuff_Type.Enfeeble).duration, 1)
	assert_null(_debuff_on(WARLORD_ID, Types.Debuff_Type.Enfeeble))

func test_out_of_range_passes_nothing() -> void:
	_positions.proximity_IDs = []
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 2)
	assert_eq(_debuff_on(0, Types.Debuff_Type.Enfeeble).duration, 2)
	assert_null(_debuff_on(WARLORD_ID, Types.Debuff_Type.Enfeeble))

func test_an_allys_own_debuff_passes_nothing() -> void:
	_roster[2]._attributes[Types.Attribute.Accuracy] = 9999
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 2, 2)
	assert_null(_debuff_on(WARLORD_ID, Types.Debuff_Type.Enfeeble))

func test_a_dead_warlord_takes_nothing() -> void:
	_roster[WARLORD_ID]._current_health = 0
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 2)
	assert_eq(_debuff_on(0, Types.Debuff_Type.Enfeeble).duration, 2)

func test_aegis_blocks_the_passed_turn_without_a_contest() -> void:
	var aegis: StatusEffects.Buff = StatusEffects.Buff.new()
	aegis.type = Types.Buff_Type.Aegis
	aegis.duration = 1
	_roster[WARLORD_ID]._active_buffs.append(aegis)
	_roster[WARLORD_ID]._attributes[Types.Attribute.Resistance] = 99999
	_roster[3]._attributes[Types.Attribute.Accuracy] = 9999
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 2)
	assert_null(_debuff_on(WARLORD_ID, Types.Debuff_Type.Enfeeble))
	assert_false(_has_buff(WARLORD_ID, Types.Buff_Type.Aegis), "Aegis is spent on the passed turn")

func test_the_passed_turn_ignores_the_warlords_resistance() -> void:
	_roster[WARLORD_ID]._attributes[Types.Attribute.Resistance] = 99999
	_cast_debuff(0, Types.Debuff_Type.Enfeeble, 2)
	assert_not_null(_debuff_on(WARLORD_ID, Types.Debuff_Type.Enfeeble))

func test_spotted_moves_to_the_warlord_outright() -> void:
	_cast_debuff(0, Types.Debuff_Type.Spotted, 2)
	assert_null(_debuff_on(0, Types.Debuff_Type.Spotted))
	assert_not_null(_debuff_on(WARLORD_ID, Types.Debuff_Type.Spotted))
