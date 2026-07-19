extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Rush: batch-1-style attribute modifiers (all primary attributes except
# Health, matching Exhert's set) plus an unresistable 1-turn Stun on expiry, ordered
# after other expiries (Concept_Document.md 3.2.3.2).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _buff(p_type: Types.Buff_Type, p_duration: int = 2) -> StatusEffects.Buff:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = p_type
	buff.duration = p_duration
	return buff

func test_rush_touches_the_same_attributes_as_exhert() -> void:
	var rush_data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Rush)
	var exhert_data: StatusEffectData = StatusEffectRegistry.BuffData(Types.Buff_Type.Exhert)

	assert_eq(rush_data.attribute_modifiers, exhert_data.attribute_modifiers,
		"Rush should touch every primary attribute except Health, like Exhert")
	assert_almost_eq(rush_data.magnitude, 0.3, 0.0001)

func test_rush_expiry_applies_exactly_one_stun() -> void:
	_roster[0]._skills.append(TestFactory.make_empty_skill())
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Rush, 1))

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._active_buffs.size(), 0, "Rush should be removed on expiry")
	var stuns: Array = _roster[0]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Stun)
	assert_eq(stuns.size(), 1, "Rush's expiry should apply exactly one Stun")
	assert_eq(stuns[0].duration, 1, "The Stun from Rush lasts 1 turn")

func test_rush_expiry_stun_is_unresistable() -> void:
	_roster[0]._attributes[Types.Attribute.Resistance] = 1000000
	_roster[0]._skills.append(TestFactory.make_empty_skill())
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Rush, 1))

	_resolver.ResolveSkill(0, [], 0)

	var stuns: Array = _roster[0]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Stun)
	assert_eq(stuns.size(), 1, "Overwhelming Resistance must not prevent Rush's Stun from landing")

func test_rush_still_active_does_not_apply_stun() -> void:
	_roster[0]._skills.append(TestFactory.make_empty_skill())
	_roster[0]._active_buffs.append(_buff(Types.Buff_Type.Rush, 2))

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._active_buffs.size(), 1, "Rush should still be active after one tick of a 2-turn duration")
	var stuns: Array = _roster[0]._active_debuffs.filter(func(d): return d.type == Types.Debuff_Type.Stun)
	assert_eq(stuns.size(), 0, "No Stun should apply while Rush is still active")
