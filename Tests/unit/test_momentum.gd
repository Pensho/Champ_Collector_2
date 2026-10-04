extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const BREACHING_CHARGE: Skill = preload("res://Data/Character_Skill_Variants/Attack_Skills/Breaching_Charge.tres")
const CUT_PURSE: Skill = preload("res://Data/Character_Skill_Variants/Attack_Skills/Cut_Purse.tres")

# Coverage for Momentum: +15% damage dealt per stack, permanent, stacking in place up to 10
# times; a stolen permanent buff lasts 3 turns on the thief (Concept_Document.md 3.2.3.2, 3.2.4).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._attributes[Types.Attribute.CritChance] = 0
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _momentum(p_holder_ID: int) -> StatusEffects.Buff:
	for buff in _roster[p_holder_ID]._active_buffs:
		if(Types.Buff_Type.Momentum == buff.type):
			return buff
	return null

func _give_momentum(p_holder_ID: int, p_stacks: int) -> void:
	for i in p_stacks:
		var template: StatusEffects.Buff = StatusEffects.Buff.new()
		template.type = Types.Buff_Type.Momentum
		template.name = "Momentum"
		_resolver.GetStatusResolver().ApplyStackingBuff(p_holder_ID, template)

func _strike_damage(p_stacks: int) -> int:
	var roster: Dictionary[int, Character] = {}
	roster.assign(TestFactory.make_full_roster())
	roster[0]._skills.append(TestFactory.make_strike_skill())
	roster[0]._attributes[Types.Attribute.CritChance] = 0
	# Large enough that the final rounding can't mask a 15% step.
	roster[0]._attributes[Types.Attribute.Attack] = 1000
	var resolver: BattleResolver = TestFactory.make_resolver(roster, TestFactory.make_full_sides())
	for i in p_stacks:
		var template: StatusEffects.Buff = StatusEffects.Buff.new()
		template.type = Types.Buff_Type.Momentum
		resolver.GetStatusResolver().ApplyStackingBuff(0, template)
	var damage: Array = resolver.ResolveSkill(0, [3], 0).filter(
			func(result: CombatResult) -> bool: return CombatResult.Kind.Damage == result.kind)
	return damage[0].amount

func _pass_turn(p_character_ID: int) -> void:
	_resolver.BeginTurn(p_character_ID)
	_resolver.GetStatusResolver().TickStatusDurations(p_character_ID)

func test_each_breaching_charge_adds_a_stack() -> void:
	_roster[3]._skills.append(BREACHING_CHARGE)
	_resolver.ResolveSkill(3, [0], 0)
	assert_eq(_momentum(3).trait_riders.get(&"stacks"), 1)
	_resolver.ResolveSkill(3, [0], 0)
	assert_eq(_momentum(3).trait_riders.get(&"stacks"), 2, "A second Breaching Charge should stack in place")
	assert_almost_eq(_momentum(3).value, 0.30, 0.001)
	assert_eq(_roster[3]._active_buffs.size(), 1, "Stacks should live on a single instance")

func test_damage_rises_fifteen_percent_per_stack() -> void:
	var baseline: int = _strike_damage(0)
	assert_almost_eq(float(_strike_damage(1)) / float(baseline), 1.15, 0.02)
	assert_almost_eq(float(_strike_damage(2)) / float(baseline), 1.30, 0.02)

func test_stacks_cap_at_ten() -> void:
	_give_momentum(3, 12)
	assert_eq(_momentum(3).trait_riders.get(&"stacks"), 10)
	assert_almost_eq(_momentum(3).value, 1.5, 0.001)

func test_momentum_is_permanent_on_its_holder() -> void:
	_give_momentum(3, 1)
	for i in 5:
		_pass_turn(3)
	assert_not_null(_momentum(3), "Momentum should never expire on the character that built it")

func test_cut_purse_takes_the_whole_stack() -> void:
	_give_momentum(3, 4)
	_roster[0]._skills.append(CUT_PURSE)
	_resolver.ResolveSkill(0, [3], 0)
	assert_null(_momentum(3), "The stolen Momentum should leave its holder")
	var stolen: StatusEffects.Buff = _momentum(0)
	assert_not_null(stolen, "The Thief should hold the stolen Momentum")
	assert_eq(stolen.trait_riders.get(&"stacks"), 4, "The whole stack should transfer")
	assert_almost_eq(stolen.value, 0.60, 0.001)
	assert_eq(stolen.duration, 3, "A stolen permanent buff should last 3 turns")

func test_the_thief_deals_the_stolen_bonus() -> void:
	_give_momentum(3, 4)
	_roster[0]._skills.append(CUT_PURSE)
	_resolver.ResolveSkill(0, [3], 0)
	var factors: Dictionary[StringName, float] = _resolver.GetStatusResolver()._OutgoingDamagePercentFactors(0)
	assert_almost_eq(factors.get(&"Momentum", 0.0), 0.60, 0.001, "The Thief's hits should carry the stolen bonus")

func test_stolen_momentum_expires_after_three_turns() -> void:
	_give_momentum(3, 4)
	_roster[0]._skills.append(CUT_PURSE)
	_resolver.ResolveSkill(0, [3], 0)
	_pass_turn(0)
	_pass_turn(0)
	assert_not_null(_momentum(0), "Stolen Momentum should still be active after two turns")
	_pass_turn(0)
	assert_null(_momentum(0), "Stolen Momentum should expire on its third turn")
