extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Overflow (expiry-triggered AoE damage) and Wanderlust (a random
# primary attribute boosted each self-tick), Concept_Document.md 3.2.3.2.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	for id in _roster.keys():
		_roster[id]._skills.append(TestFactory.make_empty_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

func _damage_results(p_results: Array[CombatResult]) -> Array[CombatResult]:
	return p_results.filter(func(r): return r.kind == CombatResult.Kind.Damage)

func test_overflow_expiry_damages_every_living_enemy_and_no_ally() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Overflow
	buff.duration = 1
	_roster[0]._active_buffs.append(buff)
	_roster[0]._attributes[Types.Attribute.Mysticism] = 200

	var results: Array[CombatResult] = _resolver.ResolveSkill(0, [], 0)

	var damage: Array[CombatResult] = _damage_results(results)
	var damaged_targets: Array = damage.map(func(r): return r.target_ID)
	assert_true(3 in damaged_targets and 4 in damaged_targets and 5 in damaged_targets,
		"Overflow must damage every living enemy")
	assert_false(1 in damaged_targets or 2 in damaged_targets, "Overflow must not damage allies")
	assert_eq(_roster[0]._active_buffs.size(), 0, "Overflow should be gone after expiring")

func test_wanderlust_boosts_the_seeded_random_attribute_on_self_tick() -> void:
	# With the default seed (0), Wanderlust's first self-tick pick is Defence
	# (Scripts/Battle/reagent_resolver.gd's TINCTURE_ATTRIBUTES pool) — locked in
	# here rather than re-derived, matching this codebase's other seed-dependent tests.
	var chosen_attribute: Types.Attribute = Types.Attribute.Defence
	_roster[0]._skills[0] = TestFactory.make_strike_skill()
	_roster[0]._skills[0].damage_scaling = {chosen_attribute: 1.0}
	_roster[0]._attributes[chosen_attribute] = 500
	_roster[0]._attributes[Types.Attribute.CritChance] = 0
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Wanderlust
	buff.duration = 2
	_roster[0]._active_buffs.append(buff)

	var buffed_results: Array[CombatResult] = _resolver.ResolveSkill(0, [3], 0)
	var buffed_damage: int = _damage_results(buffed_results)[0].amount

	var baseline_roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	for id in baseline_roster.keys():
		baseline_roster[id]._skills.append(TestFactory.make_empty_skill())
	baseline_roster[0]._skills[0] = TestFactory.make_strike_skill()
	baseline_roster[0]._skills[0].damage_scaling = {chosen_attribute: 1.0}
	baseline_roster[0]._attributes[chosen_attribute] = 500
	baseline_roster[0]._attributes[Types.Attribute.CritChance] = 0
	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	baseline_resolver.GetRandom().randi_range(0, 8)  # realign with Wanderlust's own attribute-pick draw
	var baseline_results: Array[CombatResult] = baseline_resolver.ResolveSkill(0, [3], 0)
	var baseline_damage: int = _damage_results(baseline_results)[0].amount

	assert_gt(buffed_damage, baseline_damage,
		"Wanderlust's self-tick bonus should raise this turn's damage on the chosen attribute")

func test_wanderlust_does_not_persist_the_bonus_onto_the_character() -> void:
	var buff: StatusEffects.Buff = StatusEffects.Buff.new()
	buff.type = Types.Buff_Type.Wanderlust
	buff.duration = 2
	_roster[0]._active_buffs.append(buff)
	var attributes_before: Dictionary = _roster[0]._attributes.duplicate()

	_resolver.ResolveSkill(0, [], 0)

	assert_eq(_roster[0]._attributes, attributes_before,
		"The random attribute bonus must be transient, never written back to the character")
