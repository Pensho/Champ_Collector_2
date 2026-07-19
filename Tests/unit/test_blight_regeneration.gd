extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the health-gain application point (_ApplyHeal): Regeneration heals 4%
# max Health at the start of the holder's own turn (self-tick, MaxHealthPercent read as
# a heal for buffs vs. Burning's damage for debuffs), and Blight halves any healing
# received by hooking that single application point, so both reagent heals and
# Regeneration ticks are reduced alike.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _set_max_health(p_character_ID: int, p_max_health: int) -> void:
	_roster[p_character_ID]._attributes[Types.Attribute.Health] = p_max_health
	_roster[p_character_ID]._current_health = 1

func _regeneration_buff() -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Regeneration
	buff.duration = 2
	return buff

func _blight_debuff() -> StatusEffects.Debuff:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Blight
	debuff.duration = 2
	return debuff

func test_regeneration_heals_4_percent_max_health_at_turn_start() -> void:
	_set_max_health(0, 100)
	_roster[0]._active_buffs.append(_regeneration_buff())
	var health_before: int = _roster[0]._current_health

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)

	var expected: int = int(floor((100 * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))
	assert_eq(_roster[0]._current_health, health_before + expected)
	var heals: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Heal)
	assert_eq(heals.size(), 1, "Regeneration should report one Heal result")
	assert_eq(heals[0].amount, expected)

func test_blight_halves_regeneration_healing() -> void:
	_set_max_health(0, 100)
	_roster[0]._active_buffs.append(_regeneration_buff())
	_roster[0]._active_debuffs.append(_blight_debuff())
	var health_before: int = _roster[0]._current_health

	_resolver.ResolveSkill(0, [], 0)

	var full_heal: int = int(floor((100 * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))
	var expected: int = int(floor(full_heal * 0.5))
	assert_eq(_roster[0]._current_health, health_before + expected,
		"Blight should halve the Regeneration tick like any other healing")

func test_blight_halves_reagent_healing() -> void:
	_set_max_health(0, 100)
	_roster[0]._active_debuffs.append(_blight_debuff())
	var health_before: int = _roster[0]._current_health
	# 15% of max Health (400), then halved by Blight.
	var unreduced: int = ReagentResolver.HealAmount(100 * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER, 15.0, 1.0)
	var expected: int = int(floor(unreduced * 0.5))

	var results: Array[CombatResult] = _resolver.ResolveReagent(0, "Restorative_Draught_Uncommon", 0)

	var heals: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Heal)
	assert_eq(heals.size(), 1)
	assert_eq(heals[0].amount, expected, "The reported Heal amount must be the Blight-reduced amount")
	assert_eq(_roster[0]._current_health, health_before + expected)
