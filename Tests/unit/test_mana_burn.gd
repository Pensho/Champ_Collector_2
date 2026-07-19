extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Mana Burn: deals damage scaling with the holder's own Mysticism
# whenever the holder casts a non-basic skill (Concept_Document.md 3.2.3.2).

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _apply_mana_burn(p_target_ID: int, p_source_ID: int) -> void:
	var template: StatusEffects.Debuff = StatusEffects.Debuff.new()
	template.type = Types.Debuff_Type.Mana_Burn
	template.duration = 2
	template.source_ID = p_source_ID
	_resolver.ApplyDebuff(p_target_ID, template)

func test_non_basic_cast_damages_the_holder_scaled_by_their_own_mysticism() -> void:
	_roster[0]._attributes[Types.Attribute.Mysticism] = 20  # 6 damage, less than the holder's 10 Health
	_apply_mana_burn(0, 3)
	var non_basic: Skill = TestFactory.make_empty_skill()
	non_basic.cooldown = 2
	_roster[0]._skills[0] = non_basic
	var health_before: int = _roster[0]._current_health

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)

	var expected: int = int(floor(20 * StatusEffectRegistry.DebuffData(Types.Debuff_Type.Mana_Burn).magnitude))
	assert_eq(_roster[0]._current_health, health_before - expected)
	var damage: Array = results.filter(func(r): return r.kind == CombatResult.Kind.Damage and r.target_ID == 0)
	assert_eq(damage.size(), 1)
	assert_eq(damage[0].amount, expected)
	assert_eq(damage[0].source_ID, 3)

func test_basic_skill_cast_does_not_trigger_mana_burn() -> void:
	_roster[0]._attributes[Types.Attribute.Mysticism] = 100
	_apply_mana_burn(0, 3)
	var health_before: int = _roster[0]._current_health

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._current_health, health_before, "A basic (no-cooldown) cast must not trigger Mana Burn")
