class_name Skills
extends Node

const Types = preload("res://Scripts/common_enums.gd")
const Statuses = preload("res://Scripts/status_effects.gd")

const PLAYER_IDS: Array[int] = [0,1,2]
const MONSTER_IDS: Array[int] = [3,4,5]
const HEAP_ON_MULTIPLIER: float = 0.2

static var _heap_on_stacks: Array[int] = [0, 0, 0, 0, 0, 0]
static var _heap_on_value: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

static func ResolveSkillEffect(
		p_caster_ID: int,
		p_caster_attr: Dictionary[Types.Attribute, int],
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_characterList: Dictionary[int, Character]) -> void:
	match p_skill.skill_type:
		Types.Skill_Type.Heap_On:
			if (0 == _heap_on_stacks[p_caster_ID]):
				_heap_on_value[p_caster_ID] = float(p_caster_attr[Types.Attribute.Health]) * HEAP_ON_MULTIPLIER
			p_caster_attr[Types.Attribute.Health] += int(_heap_on_value[p_caster_ID] * float(_heap_on_stacks[p_caster_ID]))
			_heap_on_stacks[p_caster_ID] += 1
		Types.Skill_Type.Burning_Bolas:
			var randomVal: float = randf_range(0.95, 1.0)
			if(p_caster_attr[Types.Attribute.Accuracy] >= p_characterList[p_target_IDs[0]]._attributes[Types.Attribute.Resistance] * randomVal):
				pass

static func FindSkillTargets(p_target_ID: int, p_attacker_ID: int, p_skill: Skill) -> Array[int]:
	var target_IDs: Array[int]
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

static func TriggerExistingCasterDebuffs(
								p_caster: Character,
								p_caster_attributes: Dictionary[Types.Attribute, int],
								p_caster_repr: CharacterRepresentation) -> void:
	var debuff_IDs_to_be_removed: Array[int] = []
	for debuff in p_caster._active_debuffs:
		match debuff.effect:
			Types.Debuff_Type.Burning:
				p_caster._currentHealth -= int(floor((p_caster_attributes[Types.Attribute.Health] * Types.HEALTH_MULTIPLIER) * 0.05))
		
		debuff.duration -= 1
		if (debuff.duration <= 0):
			debuff_IDs_to_be_removed.append(debuff.ID)
	
	p_caster._active_debuffs.filter(func(debuff): return debuff.duration > 0)
	p_caster_repr.RemoveStatusEffects(debuff_IDs_to_be_removed)

static func TriggerCasterBuffs(
							p_caster: Character,
							p_caster_attributes: Dictionary[Types.Attribute, int],
							p_skill: Skill,
							p_target_self: bool,
							p_caster_repr: CharacterRepresentation) -> void:
	var buff_IDs_to_be_removed: Array[int] = []
	
	var receive_new_buff: bool
	for target in p_skill.buffs.keys():
		receive_new_buff = false
		match target:
			Types.Skill_Target.Single_Ally, Types.Skill_Target.Random_Ally, Types.Skill_Target.Random_One:
				if(p_target_self):
					receive_new_buff = true
			Types.Skill_Target.All_Allies, Types.Skill_Target.All:
				receive_new_buff = true
		
		if(receive_new_buff):
			var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
			new_buff.effect = p_skill.buffs[target]
			p_caster._active_buffs.append(new_buff)
			p_caster_repr.AddStatusEffect(Statuses.BUFF_ICONS[target])
	
	for buff in p_caster._active_buffs:
		match buff.effect:
			# TODO: Add buff handling
			_:
				pass
		
		buff.duration -= 1
		if (buff.duration <= 0):
			buff_IDs_to_be_removed.append(buff.ID)
	
	p_caster._active_buffs.filter(func(buff): return buff.duration > 0)
	p_caster_repr.RemoveStatusEffects(buff_IDs_to_be_removed)

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the buff targets yet.
static func TriggerTargetBuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int],
							p_skill: Skill,
							p_target_repr: CharacterRepresentation) -> void:
	
	for target in p_skill.buffs.keys():
		var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
		new_buff.effect = p_skill.buffs[target]
		p_target._active_buffs.append(new_buff)
		p_target_repr.AddStatusEffect(Statuses.BUFF_ICONS[target])
	
	for buff in p_target._active_buffs:
		match buff.effect:
			# TODO: Add buff handling
			_:
				pass

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the debuff targets yet.
static func TriggerTargetDebuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int],
							p_caster_accuracy: int,
							p_skill: Skill,
							p_target_repr: CharacterRepresentation) -> void:
	
	var randomVal: float = 0.0
	for target in p_skill.debuffs.keys():
		randomVal = randf_range(0.95, 1.05)
		if(p_caster_accuracy * randomVal > p_target_attributes[Types.Attribute.Resistance]):
			var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			new_debuff.effect = p_skill.debuffs[target]
			p_target._active_debuffs.append(new_debuff)
			p_target_repr.AddStatusEffect(Statuses.DEBUFF_ICONS[target])
		else:
			print("Target character ", p_target._name, " resisted the debuff!")
	
	for debuff in p_target._active_debuffs:
		match debuff.effect:
			# TODO: Add debuff handling
			_:
				pass

static func DamageDealt(p_attacker_attr: Dictionary[Types.Attribute, int],
						p_defender_attr: Dictionary[Types.Attribute, int],
						p_skill: Skill) -> int:
	var randomVal: float = randf_range(0.95, 1.05)
	var caster_scaled_attribute_aggregate: float = 0.0
	var crit_multiplier: float = 1.0
	var ignore_defense_factor: float = p_skill.defense_ignore_factor
	
	for key in p_skill.damage_scaling.keys():
		caster_scaled_attribute_aggregate += p_skill.damage_scaling[key] * p_attacker_attr[key]
		
	if(randi_range(0, 100) <= p_attacker_attr[Types.Attribute.CritChance]):
		crit_multiplier = float(p_attacker_attr[Types.Attribute.CritDamage]) * 0.1
		# TODO: Add a flair to highlight the occurance of a critical strike.
		print("The attacker did a critical strike!")
		
	var mitigation_factor: float = 0.5 + (0.5 * (caster_scaled_attribute_aggregate / ((p_defender_attr[Types.Attribute.Defence] * ignore_defense_factor) + caster_scaled_attribute_aggregate)))
	var damage_dealt: float = mitigation_factor * caster_scaled_attribute_aggregate * crit_multiplier * randomVal
	return int(ceil(damage_dealt))

static func Reset() -> void:
	_heap_on_stacks = [0, 0, 0, 0, 0, 0]
	_heap_on_value = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
