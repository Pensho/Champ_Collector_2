class_name Skills
extends Node

const Types = preload("res://Scripts/common_enums.gd")

const PLAYER_IDS: Array[int] = [0,1,2]
const MONSTER_IDS: Array[int] = [3,4,5]
const HEAP_ON_MULTIPLIER: float = 0.2

static var _heap_on_stacks: Array[int] = [0, 0, 0, 0, 0, 0]
static var _heap_on_value: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

static func ResolveSkillEffect(p_caster_ID: int, p_caster_attr: Dictionary[Types.Attribute, int], p_target_IDs: Array[int], p_skill: Skill, p_characterList: Dictionary[int, Character]) -> void:
	match p_skill.skill_type:
		Types.Skill_Type.Stab:
			pass
		Types.Skill_Type.Heap_On:
			if (0 == _heap_on_stacks[p_caster_ID]):
				_heap_on_value[p_caster_ID] = float(p_caster_attr[Types.Attribute.Health]) * HEAP_ON_MULTIPLIER
				print("Heap-on value: ", _heap_on_value[p_caster_ID])
			p_caster_attr[Types.Attribute.Health] += int(_heap_on_value[p_caster_ID] * float(_heap_on_stacks[p_caster_ID]))
			_heap_on_stacks[p_caster_ID] += 1

static func FindSkillTargets(p_target_ID: int, p_attacker_ID: int, p_characterList: Dictionary[int, Character], p_skill: Skill) -> Array[int]:
	var target_IDs: Array[int]
	if(p_characterList[p_target_ID]._currentHealth > 0):
		match p_skill.target:
			Types.Skill_Target.Single_Enemy:
				if(PLAYER_IDS.has(p_attacker_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
				elif(MONSTER_IDS.has(p_attacker_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
			Types.Skill_Target.All_Enemies:
				if(PLAYER_IDS.has(p_attacker_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append_array(MONSTER_IDS)
				elif(MONSTER_IDS.has(p_attacker_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append_array(PLAYER_IDS)
			Types.Skill_Target.Random_Enemy:
				if(PLAYER_IDS.has(p_attacker_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(3 + (randi() % 3))
				elif(MONSTER_IDS.has(p_attacker_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(randi() % 3)
			Types.Skill_Target.Single_Ally:
				if(PLAYER_IDS.has(p_attacker_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
				elif(MONSTER_IDS.has(p_attacker_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(p_target_ID)
			Types.Skill_Target.All_Allies:
				if(PLAYER_IDS.has(p_attacker_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append_array(PLAYER_IDS)
				elif(MONSTER_IDS.has(p_attacker_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append_array(MONSTER_IDS)
			Types.Skill_Target.Random_Ally:
				if(PLAYER_IDS.has(p_attacker_ID) and PLAYER_IDS.has(p_target_ID)):
					target_IDs.append(randi() % 3)
				elif(MONSTER_IDS.has(p_attacker_ID) and MONSTER_IDS.has(p_target_ID)):
					target_IDs.append(3 + (randi() % 3))
			Types.Skill_Target.Ally_Not_Self:
				if (p_attacker_ID != p_target_ID):
					if(PLAYER_IDS.has(p_attacker_ID) and PLAYER_IDS.has(p_target_ID)):
						target_IDs.append(p_target_ID)
					elif(MONSTER_IDS.has(p_attacker_ID) and MONSTER_IDS.has(p_target_ID)):
						target_IDs.append(p_target_ID)
			Types.Skill_Target.Random_One:
				target_IDs.append(randi() % 6)
			Types.Skill_Target.All:
				target_IDs.append_array(PLAYER_IDS)
				target_IDs.append_array(MONSTER_IDS)
			var INVALID_TYPE:
				print("Invalid argument for skill target enum passed: ", INVALID_TYPE)
	return target_IDs

static func ApplyStatusEffects(
	p_character_attr: Dictionary[Types.Attribute, int],
	p_character: Character) -> Dictionary[Types.Attribute, int]:
	var new_attributes: Dictionary[Types.Attribute, int] = p_character_attr
	
	return new_attributes

static func DamageDealt(p_attacker_attr: Dictionary[Types.Attribute, int],
						p_defender_attr: Dictionary[Types.Attribute, int],
						p_skill: Skill) -> int:
	var randomVal: float = randf_range(0.95, 1.05)
	var caster_scaled_attribute_aggregate: float = 0.0
	var crit_multiplier: float = 1.0
	
	for key in p_skill.damage_scaling.keys():
		caster_scaled_attribute_aggregate += p_skill.damage_scaling[key] * p_attacker_attr[key]
	if(randi_range(0, 100) <= p_attacker_attr[Types.Attribute.CritChance]):
		crit_multiplier = float(p_attacker_attr[Types.Attribute.CritDamage]) * 0.1
		print("The attacker did a critical strike!")
	var mitigation_factor: float = 0.5 + (0.5 * (caster_scaled_attribute_aggregate / (p_defender_attr[Types.Attribute.Defence] + caster_scaled_attribute_aggregate)))
	var damage_dealt: float = mitigation_factor * caster_scaled_attribute_aggregate * crit_multiplier * randomVal
	return int(ceil(damage_dealt))

static func Reset() -> void:
	_heap_on_stacks = [0, 0, 0, 0, 0, 0]
	_heap_on_value = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
