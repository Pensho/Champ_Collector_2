extends GutTest

# Coverage for the Reanimating Statue (Boots) tempo kit: Wind the Mainspring is a
# cooldown-gated skill that hastes the statue and slows the whole player party, and
# Escapement Kick is the Speed-scaled basic it falls back to. Neither Haste nor Slow
# stacks, so each cast is a refresh rather than a ramp.

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")
const WIND_THE_MAINSPRING = preload(
		"res://Data/Character_Skill_Variants/Attack_Skills/Wind_the_Mainspring.tres")
const ESCAPEMENT_KICK = preload(
		"res://Data/Character_Skill_Variants/Attack_Skills/Escapement_Kick.tres")
const STATUE_BOOTS = preload("res://Data/Character_Enemy_Variants/Statue_Boots.tres")

var _characters: Dictionary[int, Character]
var _resolver: BattleResolver

func before_each() -> void:
	_characters = TestFactory.make_full_roster()
	# The statue is slot 3; slots 0-2 are the player party. Accuracy is raised well
	# above the party's Resistance so the Slow resist roll never masks the behavior
	# these tests are about.
	_characters[3]._attributes[Types.Attribute.Accuracy] = 200
	_resolver = TestFactory.make_resolver(_characters, TestFactory.make_full_sides())

func _give_statue_kit() -> void:
	_characters[3]._skills = [ESCAPEMENT_KICK.duplicate(true), WIND_THE_MAINSPRING.duplicate(true)]

func _count_buffs(p_character_ID: int, p_type: Types.Buff_Type) -> int:
	var count: int = 0
	for buff in _characters[p_character_ID]._active_buffs:
		if(p_type == buff.type):
			count += 1
	return count

func _count_debuffs(p_character_ID: int, p_type: Types.Debuff_Type) -> int:
	var count: int = 0
	for debuff in _characters[p_character_ID]._active_debuffs:
		if(p_type == debuff.type):
			count += 1
	return count

func test_wind_the_mainspring_hastes_the_caster() -> void:
	_give_statue_kit()
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	assert_eq(_count_buffs(3, Types.Buff_Type.Haste), 1, "The statue should gain one Haste instance")

func test_wind_the_mainspring_slows_the_whole_party() -> void:
	_give_statue_kit()
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	for player_ID in [0, 1, 2]:
		assert_eq(_count_debuffs(player_ID, Types.Debuff_Type.Slow), 1,
				"Player %d should be slowed" % player_ID)

func test_wind_the_mainspring_leaves_the_statues_allies_unslowed() -> void:
	_give_statue_kit()
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	for ally_ID in [4, 5]:
		assert_eq(_count_debuffs(ally_ID, Types.Debuff_Type.Slow), 0,
				"Monster %d is on the caster's own side and should not be slowed" % ally_ID)

func test_haste_raises_the_statues_effective_speed() -> void:
	_give_statue_kit()
	var before: int = _resolver.GetEffectiveAttributes(3)[Types.Attribute.Speed]
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	var after: int = _resolver.GetEffectiveAttributes(3)[Types.Attribute.Speed]
	assert_gt(after, before, "Haste should raise the Speed the turn bar reads")

func test_slow_lowers_a_party_members_effective_speed() -> void:
	_give_statue_kit()
	var before: int = _resolver.GetEffectiveAttributes(0)[Types.Attribute.Speed]
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	var after: int = _resolver.GetEffectiveAttributes(0)[Types.Attribute.Speed]
	assert_lt(after, before, "Slow should lower the Speed the turn bar reads")

func test_haste_does_not_stack_across_casts() -> void:
	_give_statue_kit()
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	assert_eq(_count_buffs(3, Types.Buff_Type.Haste), 1,
			"A second cast must not add a second Haste instance")

func test_slow_does_not_stack_across_casts() -> void:
	_give_statue_kit()
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	assert_eq(_count_debuffs(0, Types.Debuff_Type.Slow), 1,
			"A second cast must not add a second Slow instance")

func test_wind_the_mainspring_goes_on_cooldown() -> void:
	_give_statue_kit()
	_resolver.ResolveSkill(3, [0, 1, 2], 1)
	assert_eq(_characters[3]._skills[1].cooldown_left, 3,
			"Wind the Mainspring should be locked out for three turns")

# Resolves one Escapement Kick from a statue with the given Speed against a fresh
# party, returning the damage slot 0 took.
func _kick_damage_at_speed(p_speed: int) -> int:
	var characters: Dictionary[int, Character] = TestFactory.make_full_roster()
	characters[3]._attributes[Types.Attribute.Speed] = p_speed
	characters[3]._skills = [ESCAPEMENT_KICK.duplicate(true)]
	var resolver: BattleResolver = TestFactory.make_resolver(characters, TestFactory.make_full_sides())
	var before: int = characters[0]._current_health
	resolver.ResolveSkill(3, [0], 0)
	return before - characters[0]._current_health

func test_escapement_kick_scales_with_speed() -> void:
	assert_gt(_kick_damage_at_speed(20), _kick_damage_at_speed(5),
			"Escapement Kick's damage should rise with the caster's Speed")

# Battle.SelectEnemySkillID reverse-iterates the skill list for the first entry off
# cooldown and falls back to index 0, so the statue only alternates correctly while the
# cooldown-gated skill sits last and an uncooled basic sits first.
func test_variant_skill_order_drives_the_alternation() -> void:
	var skills: Array[Skill] = STATUE_BOOTS._skills
	assert_eq(skills.size(), 2, "The statue should carry exactly the basic and the tempo skill")
	assert_eq(skills[0].cooldown, 0, "Index 0 is the fallback and must never be on cooldown")
	assert_gt(skills[-1].cooldown, 0, "The cooldown-gated skill must sort last to be preferred")

func test_escapement_kick_has_no_cooldown() -> void:
	_give_statue_kit()
	_resolver.ResolveSkill(3, [0], 0)
	assert_eq(_characters[3]._skills[0].cooldown_left, 0,
			"The basic attack should stay available every turn")
