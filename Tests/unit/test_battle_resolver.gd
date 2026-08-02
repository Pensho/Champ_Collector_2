extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# The regression net for combat: a full scripted 3-versus-3 battle runs headlessly
# through BattleResolver with a fixed seed, so the winner and the produced results
# are reproducible. This is the foundation for the Run Multiplier auto-battle idea.

const BATTLE_SEED: int = 42
const TURN_LIMIT: int = 1000

func _make_roster() -> Dictionary[int, Character]:
	var roster: Dictionary[int, Character] = {}
	roster.assign(TestFactory.make_full_roster())
	for id in roster.keys():
		roster[id]._skills.append(TestFactory.make_strike_skill())
	return roster

## Plays the battle to its end with a simple round-robin script: each living
## character in slot order strikes the first living enemy. Returns every result.
func _run_battle(p_resolver: BattleResolver) -> Array[CombatResult]:
	var all_results: Array[CombatResult] = []
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	for turn in TURN_LIMIT:
		for caster_ID in characters.keys():
			if(characters[caster_ID]._current_health <= 0):
				continue
			var enemies: Array[int] = p_resolver.GetSides().EnemiesOf(caster_ID).AliveMembers(characters)
			if(enemies.is_empty()):
				break
			var target_IDs: Array[int] = p_resolver.FindSkillTargets(
					enemies[0], caster_ID, Types.Skill_Target.Single_Enemy)
			all_results.append_array(p_resolver.ResolveSkill(caster_ID, target_IDs, 0))
		if(BattleResolver.Winner.Ongoing != p_resolver.IsTheBattleOver()):
			return all_results
	fail_test("The scripted battle did not finish within the turn limit")
	return all_results

func _kinds(p_results: Array[CombatResult], p_kind: CombatResult.Kind) -> Array[CombatResult]:
	return p_results.filter(func(p_result): return p_result.kind == p_kind)

func test_full_battle_reaches_a_winner() -> void:
	var resolver: BattleResolver = TestFactory.make_resolver(
			_make_roster(), TestFactory.make_full_sides(), null, BATTLE_SEED)
	_run_battle(resolver)
	assert_ne(int(resolver.IsTheBattleOver()), int(BattleResolver.Winner.Ongoing),
		"A scripted battle between full rosters must end")

func test_players_win_when_acting_first_with_equal_stats() -> void:
	# Slot order gives players the first strike each round; with mirrored stats the
	# players must therefore win.
	var resolver: BattleResolver = TestFactory.make_resolver(
			_make_roster(), TestFactory.make_full_sides(), null, BATTLE_SEED)
	_run_battle(resolver)
	assert_eq(int(resolver.IsTheBattleOver()), int(BattleResolver.Winner.Player_Won))

func test_battle_reports_damage_and_all_enemy_deaths() -> void:
	var resolver: BattleResolver = TestFactory.make_resolver(
			_make_roster(), TestFactory.make_full_sides(), null, BATTLE_SEED)
	var results: Array[CombatResult] = _run_battle(resolver)

	assert_true(_kinds(results, CombatResult.Kind.Damage).size() > 0,
		"Strikes must be reported as Damage results")
	var dead_IDs: Array = _kinds(results, CombatResult.Kind.Death).map(
			func(p_result): return p_result.target_ID)
	for enemy_ID in [3, 4, 5]:
		assert_eq(dead_IDs.count(enemy_ID), 1, "Enemy %d should die exactly once" % enemy_ID)
	assert_eq(dead_IDs.size(), dead_IDs.filter(func(id): return dead_IDs.count(id) == 1).size(),
		"No combatant may die twice")

func test_same_seed_reproduces_the_same_battle() -> void:
	var first: Array[CombatResult] = _run_battle(TestFactory.make_resolver(
			_make_roster(), TestFactory.make_full_sides(), null, BATTLE_SEED))
	var second: Array[CombatResult] = _run_battle(TestFactory.make_resolver(
			_make_roster(), TestFactory.make_full_sides(), null, BATTLE_SEED))

	assert_eq(first.size(), second.size(), "The same seed must produce the same result count")
	for i in first.size():
		assert_eq(first[i].kind, second[i].kind, "Result kinds must match at index %d" % i)
		assert_eq(first[i].amount, second[i].amount, "Damage rolls must match at index %d" % i)
		assert_eq(first[i].target_ID, second[i].target_ID, "Targets must match at index %d" % i)

func test_different_seeds_can_differ() -> void:
	# A high crit chance makes the roll pattern sensitive to the seed even when the
	# small damage numbers would quantize identically.
	var roster_a: Dictionary[int, Character] = _make_roster()
	var roster_b: Dictionary[int, Character] = _make_roster()
	for roster in [roster_a, roster_b]:
		for id in roster.keys():
			roster[id]._attributes[Types.Attribute.CritChance] = 50
	var first: Array[CombatResult] = _run_battle(TestFactory.make_resolver(
			roster_a, TestFactory.make_full_sides(), null, 1))
	var second: Array[CombatResult] = _run_battle(TestFactory.make_resolver(
			roster_b, TestFactory.make_full_sides(), null, 2))

	var first_rolls: Array = []
	for result in _kinds(first, CombatResult.Kind.Damage):
		first_rolls.append([result.amount, result.critical])
	var second_rolls: Array = []
	for result in _kinds(second, CombatResult.Kind.Damage):
		second_rolls.append([result.amount, result.critical])
	assert_ne(first_rolls, second_rolls,
		"Two different seeds should produce different damage-roll sequences")

func test_heap_on_state_is_per_resolver_not_global() -> void:
	# Regression for the old `static var` state on Skills: two battles must not share
	# Heap-On stacks. The first cast of Heap On must behave identically in a fresh
	# resolver even after another resolver accumulated stacks.
	var heap_on_skill: Skill = Skill.new()
	heap_on_skill.name = "Heap On"
	heap_on_skill.target = Types.Skill_Target.Single_Enemy
	var heap_on_effect: DamageEffect = DamageEffect.new()
	heap_on_effect.damage_scaling = {Types.Attribute.Health: 1.0}
	heap_on_effect.bonus_per = {Types.Trait_Count_Source.Uses_This_Battle: 0.2}
	heap_on_skill.effects = [heap_on_effect]

	var roster_a: Dictionary[int, Character] = _make_roster()
	roster_a[0]._skills[0] = heap_on_skill
	var resolver_a: BattleResolver = TestFactory.make_resolver(
			roster_a, TestFactory.make_full_sides(), null, BATTLE_SEED)
	var first_cast_a: int = _first_damage_amount(resolver_a.ResolveSkill(0, [3], 0))
	resolver_a.ResolveSkill(0, [3], 0)
	resolver_a.ResolveSkill(0, [3], 0)

	var roster_b: Dictionary[int, Character] = _make_roster()
	roster_b[0]._skills[0] = heap_on_skill.duplicate()
	var resolver_b: BattleResolver = TestFactory.make_resolver(
			roster_b, TestFactory.make_full_sides(), null, BATTLE_SEED)
	var first_cast_b: int = _first_damage_amount(resolver_b.ResolveSkill(0, [3], 0))

	assert_eq(first_cast_a, first_cast_b,
		"A fresh resolver must start with clean Heap-On state (no static leakage)")

func test_ramp_per_use_grows_damage_and_is_permanent_for_the_battle() -> void:
	var ramping_skill: Skill = Skill.new()
	ramping_skill.name = "Breaching Charge"
	ramping_skill.target = Types.Skill_Target.Single_Enemy
	var ramping_effect: DamageEffect = DamageEffect.new()
	ramping_effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	ramping_effect.bonus_per = {Types.Trait_Count_Source.Uses_This_Battle: 0.15}
	ramping_skill.effects = [ramping_effect]

	var roster: Dictionary[int, Character] = _make_roster()
	roster[0]._skills[0] = ramping_skill
	# A high enough max Health that seven escalating hits cannot kill the target mid-test
	# — this test is about ramp growth, not about DamageEffect's alive-target filtering.
	roster[3]._attributes[Types.Attribute.Health] = 1000
	roster[3]._current_health = 1000 * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), null, BATTLE_SEED)

	# Each cast's random damage-variance roll (+/-5%) can occasionally outweigh a single
	# 15% ramp step, so compare across enough casts that the ramp's growth dominates the
	# per-cast noise rather than asserting strict cast-over-cast monotonicity.
	var first_cast: int = _first_damage_amount(resolver.ResolveSkill(0, [3], 0))
	var last_cast: int = first_cast
	for _i in range(6):
		last_cast = _first_damage_amount(resolver.ResolveSkill(0, [3], 0))

	assert_true(last_cast > first_cast,
		"A ramping skill must deal noticeably more damage after several casts than on its first")

func test_ramp_per_use_is_scoped_to_the_skill_not_the_caster() -> void:
	var ramping_skill: Skill = Skill.new()
	ramping_skill.name = "Breaching Charge"
	ramping_skill.target = Types.Skill_Target.Single_Enemy
	var ramping_effect: DamageEffect = DamageEffect.new()
	ramping_effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	ramping_effect.bonus_per = {Types.Trait_Count_Source.Uses_This_Battle: 0.15}
	ramping_skill.effects = [ramping_effect]

	var plain_skill: Skill = Skill.new()
	plain_skill.name = "Plain Strike"
	plain_skill.target = Types.Skill_Target.Single_Enemy
	var plain_effect: DamageEffect = DamageEffect.new()
	plain_effect.damage_scaling = {Types.Attribute.Attack: 1.0}
	plain_skill.effects = [plain_effect]

	var roster: Dictionary[int, Character] = _make_roster()
	roster[0]._skills[0] = ramping_skill
	roster[0]._skills.append(plain_skill)
	# A high enough max Health that a few ramping-skill hits cannot kill the target
	# mid-test — this test is about ramp scoping, not DamageEffect's alive-target filtering.
	roster[3]._attributes[Types.Attribute.Health] = 1000
	roster[3]._current_health = 1000 * GameBalance.ATTRIBUTE_HEALTH_MULTIPLIER
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), null, BATTLE_SEED)

	var first_plain_cast: int = _first_damage_amount(resolver.ResolveSkill(0, [3], 1))
	resolver.ResolveSkill(0, [3], 0)
	resolver.ResolveSkill(0, [3], 0)
	var second_plain_cast: int = _first_damage_amount(resolver.ResolveSkill(0, [3], 1))

	assert_eq(first_plain_cast, second_plain_cast,
		"A caster's other, non-ramping skill must be unaffected by a ramping skill's stacks")

func test_march_cadence_pushes_all_other_allies_turn_bar_and_not_the_caster() -> void:
	var march_cadence: Skill = Skill.new()
	march_cadence.name = "March Cadence"
	march_cadence.target = Types.Skill_Target.All_Other_Allies
	var turn_bar_effect: TurnBarEffect = TurnBarEffect.new()
	turn_bar_effect.fraction = 0.1
	march_cadence.effects = [turn_bar_effect]

	var roster: Dictionary[int, Character] = _make_roster()
	roster[0]._skills[0] = march_cadence
	var resolver: BattleResolver = TestFactory.make_resolver(
			roster, TestFactory.make_full_sides(), null, BATTLE_SEED)

	var target_IDs: Array[int] = resolver.FindSkillTargets(1, 0, Types.Skill_Target.All_Other_Allies)
	var results: Array[CombatResult] = resolver.ResolveSkill(0, target_IDs, 0)

	var bump_targets: Array = _kinds(results, CombatResult.Kind.Turn_Bar_Bump).map(
			func(p_result): return p_result.target_ID)
	assert_true(bump_targets.has(1) and bump_targets.has(2),
		"March Cadence must push the turn bar of every other ally")
	assert_false(bump_targets.has(0), "March Cadence must not push the caster's own turn bar")

func _first_damage_amount(p_results: Array[CombatResult]) -> int:
	var damage_results: Array[CombatResult] = _kinds(p_results, CombatResult.Kind.Damage)
	if(damage_results.is_empty()):
		return -1
	return damage_results[0].amount
