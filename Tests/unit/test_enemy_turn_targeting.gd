extends GutTest

# Regression coverage for the Statue_Shield / Statue_Weapon soft-lock: an enemy
# whose ally sorts ahead of the players in the targeting order must skip that
# ally and keep looking, instead of aborting the turn. This mirrors the
# targeting loop in Battle.HandleEnemyTurn()'s `_:` branch.

func _simulate_single_enemy_targeting(p_targeting_order: Array[int], p_caster_ID: int) -> Array[int]:
	for i in p_targeting_order:
		var target_IDs: Array[int] = Skills.FindSkillTargets(i, p_caster_ID, Types.Skill_Target.Single_Enemy)
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
