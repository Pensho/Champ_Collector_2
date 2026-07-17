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
	heap_on_skill.skill_type = Types.Skill_Type.Heap_On
	heap_on_skill.target = Types.Skill_Target.Single_Enemy
	heap_on_skill.damage_scaling = {Types.Attribute.Health: 1.0}

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

func _first_damage_amount(p_results: Array[CombatResult]) -> int:
	var damage_results: Array[CombatResult] = _kinds(p_results, CombatResult.Kind.Damage)
	if(damage_results.is_empty()):
		return -1
	return damage_results[0].amount
