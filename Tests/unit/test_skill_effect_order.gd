extends GutTest

# Effect order is authored data, not resolver structure (Technical Design Document 7.4):
# ResolveSkill just walks Skill.effects in array order. The canonical order — costs ->
# buff manipulation -> statuses -> damage -> heals — is a convention the .tres authoring
# must follow, not something the pipeline enforces, so this locks it in for the shipped
# skills that exercise more than one phase at once.

func test_tithe_of_vitality_orders_cost_before_status_before_damage() -> void:
	var skill: Skill = load("res://Data/Character_Skill_Variants/Attack_Skills/Tithe_of_Vitality.tres")
	var kinds: Array = skill.effects.map(func(e): return e.get_script())
	assert_eq(kinds, [HealthChangeEffect, ApplyDebuffEffect, DamageEffect] as Array[Script],
		"Tithe of Vitality should pay its cost, apply Hemorrhage, then deal damage, in that order")

func test_devour_blessing_orders_buff_manipulation_before_damage() -> void:
	var skill: Skill = load("res://Data/Character_Skill_Variants/Attack_Skills/Devour_Blessing.tres")
	var kinds: Array = skill.effects.map(func(e): return e.get_script())
	assert_eq(kinds, [ConsumeBuffsEffect, DamageEffect] as Array[Script],
		"Devour Blessing should consume buffs before dealing the buffs-consumed-scaled damage")
