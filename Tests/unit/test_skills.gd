extends GutTest

# --- FindSkillTargets ---

func test_single_enemy_player_vs_monster() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(3, 0, Types.Skill_Target.Single_Enemy)
	assert_eq(targets.size(), 1, "Single Enemy should return exactly one target")
	assert_eq(targets[0], 3, "Target ID should be the chosen enemy")

func test_single_enemy_monster_vs_player() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(1, 3, Types.Skill_Target.Single_Enemy)
	assert_eq(targets.size(), 1, "Monster caster should hit the chosen player")
	assert_eq(targets[0], 1)

func test_single_enemy_rejects_friendly_target() -> void:
	# Player caster targeting another player — not a valid Single_Enemy target
	var targets: Array[int] = Skills.FindSkillTargets(1, 0, Types.Skill_Target.Single_Enemy)
	assert_eq(targets.size(), 0, "Single_Enemy must not target a friendly")

func test_all_enemies_player_caster() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(3, 0, Types.Skill_Target.All_Enemies)
	assert_eq(targets.size(), 3, "All_Enemies from a player should return all 3 monster IDs")
	for id in [3, 4, 5]:
		assert_true(targets.has(id), "Monster ID %d must be in All_Enemies targets" % id)

func test_all_enemies_monster_caster() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(0, 3, Types.Skill_Target.All_Enemies)
	assert_eq(targets.size(), 3, "All_Enemies from a monster should return all 3 player IDs")
	for id in [0, 1, 2]:
		assert_true(targets.has(id), "Player ID %d must be in All_Enemies targets" % id)

func test_single_ally_player_caster() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(1, 0, Types.Skill_Target.Single_Ally)
	assert_eq(targets.size(), 1)
	assert_eq(targets[0], 1, "Single_Ally should target the chosen ally")

func test_single_ally_rejects_enemy_target() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(3, 0, Types.Skill_Target.Single_Ally)
	assert_eq(targets.size(), 0, "Single_Ally must not target an enemy")

func test_all_allies_player_caster() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(1, 0, Types.Skill_Target.All_Allies)
	assert_eq(targets.size(), 3, "All_Allies from player should return all 3 player IDs")
	for id in [0, 1, 2]:
		assert_true(targets.has(id), "Player ID %d must be in All_Allies targets" % id)

func test_all_allies_returns_empty_when_target_is_enemy() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(3, 0, Types.Skill_Target.All_Allies)
	assert_eq(targets.size(), 0, "All_Allies should be empty when the target is an enemy")

func test_ally_not_self_excludes_caster() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(0, 0, Types.Skill_Target.Ally_Not_Self)
	assert_eq(targets.size(), 0, "Ally_Not_Self must not return the caster's own ID")

func test_ally_not_self_allows_other_ally() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(1, 0, Types.Skill_Target.Ally_Not_Self)
	assert_eq(targets.size(), 1)
	assert_eq(targets[0], 1)

func test_all_target() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(0, 0, Types.Skill_Target.All)
	assert_eq(targets.size(), 6, "All should return all 6 combatant IDs")

func test_all_other_allies_excludes_caster() -> void:
	var targets: Array[int] = Skills.FindSkillTargets(1, 0, Types.Skill_Target.All_Other_Allies)
	assert_false(targets.has(0), "All_Other_Allies should exclude the caster (ID 0)")
	assert_true(targets.has(1), "All_Other_Allies should include other ally IDs")
	assert_true(targets.has(2), "All_Other_Allies should include other ally IDs")

# --- CorrectZoneTarget ---

func test_zone_all_always_triggers() -> void:
	assert_true(Skills.CorrectZoneTarget(0, 3, Types.Skill_Target.ZoneAll),
		"ZoneAll should trigger for any combatant")
	assert_true(Skills.CorrectZoneTarget(3, 0, Types.Skill_Target.ZoneAll),
		"ZoneAll should trigger for any combatant")

func test_zone_ally_triggers_for_same_team() -> void:
	assert_true(Skills.CorrectZoneTarget(0, 1, Types.Skill_Target.ZoneAlly),
		"ZoneAlly: player zone owner, player trigger → true")
	assert_true(Skills.CorrectZoneTarget(3, 4, Types.Skill_Target.ZoneAlly),
		"ZoneAlly: monster zone owner, monster trigger → true")

func test_zone_ally_does_not_trigger_for_enemy() -> void:
	assert_false(Skills.CorrectZoneTarget(0, 3, Types.Skill_Target.ZoneAlly),
		"ZoneAlly: player zone, monster trigger → false")
	assert_false(Skills.CorrectZoneTarget(3, 0, Types.Skill_Target.ZoneAlly),
		"ZoneAlly: monster zone, player trigger → false")

func test_zone_enemy_triggers_for_opposing_team() -> void:
	assert_true(Skills.CorrectZoneTarget(0, 3, Types.Skill_Target.ZoneEnemy),
		"ZoneEnemy: player zone owner, monster trigger → true")
	assert_true(Skills.CorrectZoneTarget(3, 0, Types.Skill_Target.ZoneEnemy),
		"ZoneEnemy: monster zone owner, player trigger → true")

func test_zone_enemy_does_not_trigger_for_ally() -> void:
	assert_false(Skills.CorrectZoneTarget(0, 1, Types.Skill_Target.ZoneEnemy),
		"ZoneEnemy: player zone, player trigger → false")
	assert_false(Skills.CorrectZoneTarget(3, 4, Types.Skill_Target.ZoneEnemy),
		"ZoneEnemy: monster zone, monster trigger → false")
