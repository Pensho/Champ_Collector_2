extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for the retaliation-batch primitives: Damage_Taken now carries the attacker's
# ID (Glass Refraction, Undertow), a defender-side trait can redirect an incoming
# single-target skill to a random other character (Glamour), and AggregateDamageMultipliers is a
# public entry point onto the same battle-long bonus the Fractured Idol reagent writes.

var _roster: Dictionary[int, Character] = {}
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())

# --- P1: Damage_Taken carries the attacker ---

func test_damage_taken_hook_receives_the_attacker_ID() -> void:
	var recorder: TestFactory.FakeDamageTakenAttackerRecorder = TestFactory.FakeDamageTakenAttackerRecorder.new()
	_roster[0]._trait = recorder
	_roster[3]._skills.append(TestFactory.make_strike_skill())
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	_resolver.ResolveSkill(3, [0], 0)

	assert_eq(recorder.call_count, 1)
	assert_eq(recorder.last_owner_ID, 0)
	assert_eq(recorder.last_attacker_ID, 3, "The hook should receive the attacker's ID, not just the owner's")

# --- P2: defender-side single-target redirect ---

func test_redirect_at_full_chance_sends_a_single_enemy_skill_elsewhere() -> void:
	_roster[0]._trait = TestFactory.FakeRedirectChanceTrait.new(1.0)
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Single_Enemy)

	assert_eq(targets.size(), 1)
	assert_ne(targets[0], 0, "A chance-1.0 carrier should never remain the target")

func test_no_redirect_at_zero_chance() -> void:
	_roster[0]._trait = TestFactory.FakeRedirectChanceTrait.new(0.0)
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.Single_Enemy)

	assert_eq(targets, [0], "A chance-0 carrier should be untouched")

func test_redirect_never_applies_to_an_aoe_skill() -> void:
	_roster[0]._trait = TestFactory.FakeRedirectChanceTrait.new(1.0)
	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())

	var targets: Array[int] = _resolver.FindSkillTargets(0, 3, Types.Skill_Target.All_Enemies)

	assert_eq(targets, [0, 1, 2], "AoE targeting must never be redirected by the single-target hook")

# --- P3: public AggregateDamageMultipliers ---

func _strike_damage(p_resolver: BattleResolver) -> int:
	var results: Array[CombatResult] = p_resolver.ResolveSkill(3, [0], 0)
	for result in results:
		if(CombatResult.Kind.Damage == result.kind and 0 == result.target_ID):
			return result.amount
	return -1

func test_add_damage_dealt_bonus_raises_subsequent_damage() -> void:
	_roster[3]._skills.append(TestFactory.make_strike_skill())
	var baseline_roster: Dictionary[int, Character] = {}
	baseline_roster.assign(TestFactory.make_full_roster())
	baseline_roster[3]._skills.append(TestFactory.make_strike_skill())

	var baseline_resolver: BattleResolver = TestFactory.make_resolver(baseline_roster, TestFactory.make_full_sides())
	var baseline_damage: int = _strike_damage(baseline_resolver)

	_resolver = TestFactory.make_resolver(_roster, TestFactory.make_full_sides())
	_resolver.AggregateDamageMultipliers(3, 0.5)
	var boosted_damage: int = _strike_damage(_resolver)

	assert_gt(boosted_damage, baseline_damage, "AggregateDamageMultipliers must raise the caster's subsequent damage")
