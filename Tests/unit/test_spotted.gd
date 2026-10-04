extends GutTest

const TestFactory = preload("res://Tests/unit/helpers/test_factory.gd")

# Coverage for Spotted: opposing single-target skills must target the holder, positional
# and area skills are unaffected, and a side holds one Spotted character at a time
# (Concept_Document.md 3.2.3.2). Landing is forced deterministic by making Accuracy or
# Resistance dominate.

var _roster: Dictionary[int, Character] = {}
var _sides: CombatSides = null
var _resolver: BattleResolver = null

func before_each() -> void:
	_roster.assign(TestFactory.make_full_roster())
	_sides = TestFactory.make_full_sides()
	for id in _roster.keys():
		_roster[id]._skills.append(_spotting_skill())
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1000
	_resolver = TestFactory.make_resolver(_roster, _sides)

func _spotting_skill() -> Skill:
	var skill: Skill = Skill.new()
	skill.name = "Spot"
	skill.target = Types.Skill_Target.Single_Enemy
	var effect: ApplyDebuffEffect = ApplyDebuffEffect.new()
	effect.target = Types.Skill_Target.Single_Enemy
	effect.debuff_type = Types.Debuff_Type.Spotted
	effect.duration = 2
	skill.effects = [effect]
	return skill

func _spot(p_holder_ID: int, p_duration: int = 2) -> void:
	var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	debuff.type = Types.Debuff_Type.Spotted
	debuff.duration = p_duration
	_roster[p_holder_ID]._active_debuffs.append(debuff)

func _is_spotted(p_ID: int) -> bool:
	return _roster[p_ID]._active_debuffs.any(
			func(debuff: StatusEffects.Debuff) -> bool: return Types.Debuff_Type.Spotted == debuff.type)

# Mirrors the targeting loop in Battle.HandleEnemyTurn.
func _enemy_turn_targets(p_order: Array[int], p_caster_ID: int, p_target_type: Types.Skill_Target) -> Array[int]:
	for id in Skills.EnemyTargetOrder(p_order, p_caster_ID, _roster, _sides):
		var target_IDs: Array[int] = _resolver.FindSkillTargets(id, p_caster_ID, p_target_type)
		if(not target_IDs.is_empty()):
			return target_IDs
	return []

func test_spotted_champion_heads_the_enemy_order_regardless_of_priority() -> void:
	_spot(2)
	var order: Array[int] = [0, 1, 3, 4, 5, 2]
	assert_eq(Skills.EnemyTargetOrder(order, 3, _roster, _sides), [2, 0, 1, 3, 4, 5] as Array[int])
	assert_eq(_enemy_turn_targets(order, 3, Types.Skill_Target.Single_Enemy), [2] as Array[int],
			"A single-target enemy skill should hit the Spotted champion even when it is last in priority")

func test_a_spotted_ally_of_the_caster_does_not_reorder() -> void:
	_spot(4)
	var order: Array[int] = [0, 1, 2, 3, 4, 5]
	assert_eq(Skills.EnemyTargetOrder(order, 3, _roster, _sides), order,
			"Only a Spotted opponent of the caster moves to the front")

func test_a_dead_spotted_champion_does_not_reorder() -> void:
	_spot(2)
	_roster[2]._current_health = 0
	var order: Array[int] = [0, 1, 2, 3, 4, 5]
	assert_eq(Skills.EnemyTargetOrder(order, 3, _roster, _sides), order)

func test_positional_and_area_skills_ignore_spotted() -> void:
	_spot(1)
	var order: Array[int] = [0, 1, 2, 3, 4, 5]
	assert_eq(_enemy_turn_targets(order, 3, Types.Skill_Target.Left_Most_Enemy), [0] as Array[int],
			"Left_Most_Enemy should stay on the left-most slot while another champion is Spotted")
	assert_eq(_enemy_turn_targets(order, 3, Types.Skill_Target.Right_Most_Enemy), [2] as Array[int],
			"Right_Most_Enemy should stay on the right-most slot while another champion is Spotted")
	assert_eq(_enemy_turn_targets(order, 3, Types.Skill_Target.All_Enemies), [0, 1, 2] as Array[int])

func test_a_second_landed_application_moves_the_mark() -> void:
	_resolver.ResolveSkill(3, [0], 0)
	assert_true(_is_spotted(0), "The first application should land")
	_resolver.ResolveSkill(3, [1], 0)
	assert_true(_is_spotted(1), "The second application should land on the new target")
	assert_false(_is_spotted(0), "The old holder should lose Spotted when it moves")

func test_a_resisted_application_leaves_the_old_holder_spotted() -> void:
	_resolver.ResolveSkill(3, [0], 0)
	_roster[3]._attributes[Types.Attribute.Accuracy] = 1
	_roster[1]._attributes[Types.Attribute.Resistance] = 1000
	_resolver.ResolveSkill(3, [1], 0)
	assert_false(_is_spotted(1), "The second application should be resisted")
	assert_true(_is_spotted(0), "A resisted application must not move the mark")

func test_a_mirrored_application_moves_the_mark_on_the_attackers_side() -> void:
	_spot(4)
	var mirror_coat: StatusEffects.Buff = StatusEffects.Buff.new()
	mirror_coat.type = Types.Buff_Type.Mirror_Coat
	mirror_coat.duration = 2
	_roster[0]._active_buffs.append(mirror_coat)
	_roster[0]._attributes[Types.Attribute.Accuracy] = 1000
	_roster[3]._attributes[Types.Attribute.Resistance] = 1
	_resolver.ResolveSkill(3, [0], 0)
	assert_true(_is_spotted(3), "Mirror Coat should copy Spotted onto the attacker")
	assert_false(_is_spotted(4), "The mirrored copy should move the mark off the attacker's ally")

func test_expiry_restores_the_normal_order() -> void:
	_spot(2, 1)
	var order: Array[int] = [0, 1, 2, 3, 4, 5]
	_resolver.BeginTurn(2)
	_resolver.GetStatusResolver().TickStatusDurations(2)
	assert_false(_is_spotted(2), "Spotted should expire")
	assert_eq(Skills.EnemyTargetOrder(order, 3, _roster, _sides), order)

func test_player_single_target_skill_may_only_target_the_spotted_enemy() -> void:
	_spot(4)
	assert_true(Skills.SpottedForbidsTarget(3, 0, Types.Skill_Target.Single_Enemy, _roster, _sides))
	assert_false(Skills.SpottedForbidsTarget(4, 0, Types.Skill_Target.Single_Enemy, _roster, _sides))
	assert_false(Skills.SpottedForbidsTarget(3, 0, Types.Skill_Target.All_Enemies, _roster, _sides))
	assert_false(Skills.SpottedForbidsTarget(1, 0, Types.Skill_Target.Single_Ally, _roster, _sides))

func test_targeting_help_highlights_only_the_spotted_enemy() -> void:
	_spot(4)
	var highlighted: Array[int] = TargetingHelp.HighlightedCharacters(
			Types.Skill_Target.Single_Enemy, 0, _roster, _sides, _resolver.GetMaxHealth)
	assert_eq(highlighted, [4] as Array[int])
	assert_eq(TargetingHelp.HighlightedCharacters(
			Types.Skill_Target.All_Enemies, 0, _roster, _sides, _resolver.GetMaxHealth).size(), 3)
