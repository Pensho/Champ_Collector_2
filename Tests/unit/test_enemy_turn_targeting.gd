extends GutTest

# Regression coverage for the Statue_Shield / Statue_Weapon soft-lock: an enemy
# whose ally sorts ahead of the players in the targeting order must skip that
# ally and keep looking, instead of aborting the turn. This mirrors the
# targeting loop in Battle.HandleEnemyTurn()'s `_:` branch.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

func _simulate_single_enemy_targeting(p_targeting_order: Array[int], p_caster_ID: int) -> Array[int]:
	var roster: Dictionary = TestFactory.make_full_roster()
	var sides: CombatSides = TestFactory.make_full_sides()
	for i in p_targeting_order:
		var target_IDs: Array[int] = Skills.FindSkillTargets(
				i, p_caster_ID, Types.Skill_Target.Single_Enemy, roster, sides)
		if(target_IDs.is_empty()):
			continue
		return target_IDs
	return []

func test_targeting_loop_skips_ally_ahead_in_order() -> void:
	# Tankiest-first order: monster 4 (the caster's ally) sorts ahead of any
	# player, as happens with Statue_Shield / Statue_Weapon.
	var targeting_order: Array[int] = [4, 3, 0, 1, 2]
	var targets: Array[int] = _simulate_single_enemy_targeting(targeting_order, 3)
	assert_eq(targets.size(), 1, "Should skip the ally and find a player target")
	assert_eq(targets[0], 0, "Should land on the first player in the order")

func test_targeting_loop_skips_self_ahead_in_order() -> void:
	# Caster itself sorts first in the order (it is the tankiest character).
	var targeting_order: Array[int] = [3, 4, 0, 1, 2]
	var targets: Array[int] = _simulate_single_enemy_targeting(targeting_order, 3)
	assert_eq(targets.size(), 1, "Should skip self and find a player target")
	assert_eq(targets[0], 0)

# Battle.SelectEnemySkillID skips a skill with no living target the same way it skips
# one on cooldown, so an other-allies heal with every ally dead falls back to skill 0.
func test_other_allies_skill_has_no_target_once_allies_are_dead() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var sides: CombatSides = TestFactory.make_full_sides()
	roster[4]._current_health = 0
	roster[5]._current_health = 0
	assert_false(Skills.HasLivingTarget(3, Types.Skill_Target.All_Other_Allies, roster, sides),
			"With every other ally dead, an other-allies skill has no target")
	assert_false(Skills.HasLivingTarget(3, Types.Skill_Target.Ally_Not_Self, roster, sides),
			"With every other ally dead, an ally-not-self skill has no target")
	assert_true(Skills.HasLivingTarget(3, Types.Skill_Target.Single_Enemy, roster, sides),
			"Living players remain valid enemy targets")
	assert_true(Skills.HasLivingTarget(3, Types.Skill_Target.Self, roster, sides),
			"A living caster can always target itself")

func test_other_allies_skill_has_target_while_an_ally_lives() -> void:
	var roster: Dictionary[int, Character] = TestFactory.make_full_roster()
	var sides: CombatSides = TestFactory.make_full_sides()
	roster[4]._current_health = 0
	assert_true(Skills.HasLivingTarget(3, Types.Skill_Target.All_Other_Allies, roster, sides),
			"One living ally keeps an other-allies skill castable")
