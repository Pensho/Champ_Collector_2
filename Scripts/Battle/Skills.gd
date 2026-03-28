class_name Skills
extends Node

const ZoneType = preload("uid://bdjrfif0s60v4")
const Statuses = preload("uid://bp3pvvar4437")

const PLAYER_IDS: Array[int] = [0,1,2]
const MONSTER_IDS: Array[int] = [3,4,5]

static var _heap_on_stacks: Array[int] = [0, 0, 0, 0, 0, 0]
static var _heap_on_value: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

static var _status_effect_textures: Dictionary[String, Texture]

static func ResolveZoneEffect(
					p_zone: Zone,
					p_character: Character,
					p_character_ID: int,
					p_battle_ui: BattleUI,
					p_character_repr: CharacterRepresentation) -> void:
	match p_zone._type:
		Types.Skill_Type.Flicker_Zone:
			if(CorrectZoneTarget(p_zone._owner_ID, p_character_ID, p_zone._target)):
				p_battle_ui._turn_bar.BumpCharacter(p_character_ID, 0.15)
		Types.Skill_Type.Lava_Zone:
			if(HasMaxStatusEffects(p_character)):
				return
			
			if(!OverwritableDebuff(Types.Debuff_Type.Burning)):
				var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
				new_debuff.type = Types.Debuff_Type.Burning # TODO: add a status effect container to the Zone class and use that instead
				new_debuff.duration = 2 # TODO: Replace with a defined number from the skill.
				new_debuff.ID = p_character_repr.AddStatusEffect(GetStatusEffectTexture(Statuses.DEBUFF_ICONS[Types.Debuff_Type.Burning]), new_debuff.duration)
				
				p_character._active_debuffs.append(new_debuff)

static func ResolveSkillEffect(
		p_caster_ID: int,
		p_caster_attr: Dictionary[Types.Attribute, int],
		p_skill: Skill) -> void:
	match p_skill.skill_type:
		Types.Skill_Type.Heap_On:
			if (0 == _heap_on_stacks[p_caster_ID]):
				_heap_on_value[p_caster_ID] = float(p_caster_attr[Types.Attribute.Health]) * Game_Balance.HEAP_ON_MULTIPLIER
			p_caster_attr[Types.Attribute.Health] += int(_heap_on_value[p_caster_ID] * float(_heap_on_stacks[p_caster_ID]))
			_heap_on_stacks[p_caster_ID] += 1

static func CorrectZoneTarget(p_zone_owner_ID: int, p_trigger_character_ID: int, p_zone_target: Types.Skill_Target) -> bool:
	match p_zone_target:
		Types.Skill_Target.ZoneAll:
			return true
		Types.Skill_Target.ZoneAlly:
			return (PLAYER_IDS.has(p_trigger_character_ID) and PLAYER_IDS.has(p_zone_owner_ID)) or (MONSTER_IDS.has(p_trigger_character_ID) and MONSTER_IDS.has(p_zone_owner_ID))
		Types.Skill_Target.ZoneEnemy:
			return (MONSTER_IDS.has(p_trigger_character_ID) and PLAYER_IDS.has(p_zone_owner_ID)) or (PLAYER_IDS.has(p_trigger_character_ID) and MONSTER_IDS.has(p_zone_owner_ID))
		_:
			print("Invalid target passed for zone target: ", p_zone_target)
	return false

static func FindSkillTargets(
					p_target_ID: int,
					p_attacker_ID: int,
					p_skill: Skill) -> Array[int]:
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
		Types.Skill_Target.ZoneAll, Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy:
			pass
		var INVALID_TYPE:
			print("Invalid argument for skill target enum passed: ", INVALID_TYPE)
	return target_IDs

static func TriggerExistingCasterDebuffs(
								p_caster: Character,
								p_caster_attributes: Dictionary[Types.Attribute, int],
								p_caster_repr: CharacterRepresentation) -> void:
	var debuff_IDs_to_be_removed: Array[int] = []
	for debuff in p_caster._active_debuffs:
		match debuff.type:
			Types.Debuff_Type.Burning:
				p_caster._currentHealth -= int(floor((p_caster_attributes[Types.Attribute.Health] * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))
			Types.Debuff_Type.Enfeeble:
				p_caster_attributes[Types.Attribute.Attack] -= int(ceilf(p_caster_attributes[Types.Attribute.Attack] * 0.3))
			Types.Debuff_Type.Expose_Weakness:
				p_caster_attributes[Types.Attribute.Defence] -= int(ceilf(p_caster_attributes[Types.Attribute.Defence] * 0.3))
		
		debuff.duration -= 1
		p_caster_repr.SetStatusEffectDuration(debuff.ID, debuff.duration)
		if (debuff.duration <= 0):
			debuff_IDs_to_be_removed.append(debuff.ID)
	
	p_caster._active_debuffs = p_caster._active_debuffs.filter(func(debuff): return debuff.duration > 0)
	p_caster_repr.RemoveStatusEffects(debuff_IDs_to_be_removed)

static func TriggerExistingCasterBuffs(
							p_caster: Character,
							p_caster_attributes: Dictionary[Types.Attribute, int],
							p_caster_repr: CharacterRepresentation) -> void:
	var buff_IDs_to_be_removed: Array[int] = []
	
	for buff in p_caster._active_buffs:
		match buff.type:
			Types.Buff_Type.Empower:
				p_caster_attributes[Types.Attribute.Attack] += int(ceilf(p_caster_attributes[Types.Attribute.Attack] * 0.3))
			Types.Buff_Type.Fortify:
				p_caster_attributes[Types.Attribute.Defence] += int(ceilf(p_caster_attributes[Types.Attribute.Defence] * 0.3))
			_:
				pass
		
		buff.duration -= 1
		p_caster_repr.SetStatusEffectDuration(buff.ID, buff.duration)
		if (buff.duration <= 0):
			buff_IDs_to_be_removed.append(buff.ID)
	
	p_caster._active_buffs = p_caster._active_buffs.filter(func(buff): return buff.duration > 0)
	p_caster_repr.RemoveStatusEffects(buff_IDs_to_be_removed)

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the buff targets yet.
static func TriggerTargetBuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int]) -> void:
	for buff in p_target._active_buffs:
		match buff.type:
			Types.Buff_Type.Empower:
				p_target_attributes[Types.Attribute.Attack] += int(ceilf(p_target_attributes[Types.Attribute.Attack] * 0.3))
			Types.Buff_Type.Fortify:
				p_target_attributes[Types.Attribute.Defence] += int(ceilf(p_target_attributes[Types.Attribute.Defence] * 0.3))
			_:
				pass

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the debuff targets yet.
static func TriggerTargetDebuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int]) -> void:
	for debuff in p_target._active_debuffs:
		match debuff.type:
			Types.Debuff_Type.Expose_Weakness:
				p_target_attributes[Types.Attribute.Defence] -= int(ceilf(p_target_attributes[Types.Attribute.Defence] * 0.5))
			_:
				pass

static func CastBuff(
				p_target: Character,
				p_skill: Skill,
				p_target_repr: CharacterRepresentation,
				p_battle_ui: BattleUI):
	if(HasMaxStatusEffects(p_target)):
		return
	
	for i in p_target._active_buffs.size():
		if(p_target._active_buffs[i].type == p_skill.buffs[p_skill.target]):
			if(OverwritableBuff(p_skill.buffs[p_skill.target])):
				p_target._active_buffs[i].duration = p_skill.duration
				p_target_repr.SetStatusEffectDuration(p_target._active_buffs[i].ID, p_skill.duration)
				return
	
	var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
	new_buff.type = p_skill.buffs[p_skill.target]
	new_buff.duration = p_skill.duration
	new_buff.ID = p_target_repr.AddStatusEffect(GetStatusEffectTexture(Statuses.BUFF_ICONS[new_buff.type]), new_buff.duration)
	p_target._active_buffs.append(new_buff)
	p_battle_ui.SpawnCombatText(Types.Buff_Type.keys()[new_buff.type], p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(0.335, 0.575, 0.838, 1.0))

static func CastDebuff(
					p_target: Character,
					p_target_attributes: Dictionary[Types.Attribute, int],
					p_caster_accuracy: int,
					p_skill: Skill,
					p_target_repr: CharacterRepresentation,
					p_battle_ui: BattleUI):
	if(HasMaxStatusEffects(p_target)):
		return
	
	var randomVal: float = randf_range(0.95, 1.0)
	var randomVal2: float = randf_range(0.95, 1.0)
	if(p_caster_accuracy * randomVal < p_target_attributes[Types.Attribute.Resistance] * randomVal2):
		print("Target character ", p_target._name, " resisted the debuff!")
		p_battle_ui.SpawnCombatText("Resisted debuff!", p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(0.801, 0.0, 0.0, 1.0))
		return
	
	for i in p_target._active_debuffs.size():
		if(p_target._active_debuffs[i].type == p_skill.debuffs[p_skill.target]):
			if(OverwritableDebuff(p_skill.debuffs[p_skill.target])):
				p_target._active_debuffs[i].duration = p_skill.duration
				p_target_repr.SetStatusEffectDuration(p_target._active_debuffs[i].ID, p_skill.duration)
				return
				
	var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	new_debuff.type = p_skill.debuffs[p_skill.target]
	new_debuff.duration = p_skill.duration
	new_debuff.ID = p_target_repr.AddStatusEffect(GetStatusEffectTexture(Statuses.DEBUFF_ICONS[new_debuff.type]), new_debuff.duration)
	p_target._active_debuffs.append(new_debuff)
	p_battle_ui.SpawnCombatText(Types.Debuff_Type.keys()[new_debuff.type], p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(0.681, 0.152, 0.31, 1.0))

static func DamageDealt(p_attacker_attr: Dictionary[Types.Attribute, int],
						p_defender_attr: Dictionary[Types.Attribute, int],
						p_skill: Skill,
						p_trait_multiplier: float,
						p_target_repr: CharacterRepresentation,
						p_battle_ui: BattleUI) -> int:
	var randomVal: float = randf_range(0.95, 1.05)
	var caster_scaled_attribute_aggregate: float = 0.0
	var crit_multiplier: float = 1.0
	var ignore_defense_factor: float = p_skill.defense_ignore_factor
	
	for key in p_skill.damage_scaling.keys():
		caster_scaled_attribute_aggregate += p_skill.damage_scaling[key] * float(p_attacker_attr[key]) * p_trait_multiplier
	# For example, some status skills deal no damage. So no need to continue.
	if(0.0 == caster_scaled_attribute_aggregate):
		return 0
		
	if(randi_range(0, 100) <= p_attacker_attr[Types.Attribute.CritChance]):
		crit_multiplier = float(p_attacker_attr[Types.Attribute.CritDamage]) * 0.01
		p_battle_ui.SpawnCombatText("Critical Strike!", p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(1.0, 0.729, 0.0, 1.0))
	
	var mitigation_factor: float = GameBalance.MINIMUM_DMG_PERCENT + ((1 - GameBalance.MINIMUM_DMG_PERCENT) * (caster_scaled_attribute_aggregate / ((p_defender_attr[Types.Attribute.Defence] * ignore_defense_factor) + caster_scaled_attribute_aggregate + 1)))
	var damage_dealt: float = mitigation_factor * caster_scaled_attribute_aggregate * crit_multiplier * randomVal
	return int(ceil(damage_dealt))

static func Reset() -> void:
	_heap_on_stacks = [0, 0, 0, 0, 0, 0]
	_heap_on_value = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0]

static func GetStatusEffectTexture(p_texture_path: String) -> Texture:
	if(not _status_effect_textures.has(p_texture_path)):
		_status_effect_textures[p_texture_path] = load(p_texture_path)
	
	return _status_effect_textures[p_texture_path]

static func HasMaxStatusEffects(p_character: Character) -> bool:
	if(GameBalance.MAX_STATUS_EFFECTS <= p_character._active_buffs.size() + p_character._active_debuffs.size()):
		print(p_character._name, " cannot have any more status effects right now.")
		return true
	return false

static func OverwritableBuff(p_buff_type: Types.Buff_Type) -> bool:
	match p_buff_type:
		Types.Buff_Type.Invalid, _:
			return true

static func OverwritableDebuff(p_debuff_type: Types.Debuff_Type) -> bool:
	match p_debuff_type:
		Types.Debuff_Type.Burning:
			return false
		Types.Buff_Type.Invalid, _:
			return true
