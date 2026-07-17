class_name Skills
extends Node

const ZoneType = preload("uid://bdjrfif0s60v4")
const Statuses = preload("uid://bp3pvvar4437")

# Per-combat state keyed by slot ID, sized by whatever roster the battle fields.
static var _heap_on_stacks: Dictionary[int, int] = {}
static var _heap_on_value: Dictionary[int, float] = {}
static var _damage_multiplier: Dictionary[int, float] = {}

static var _status_effect_textures: Dictionary[String, Texture]

static func AllyZoneMagnitude(p_base: float, p_owner_knowledge: int) -> float:
	return p_base * (1.0 + p_owner_knowledge * Game_Balance.ZONE_KNOWLEDGE_SCALING)

static func ResolveZoneEffect(
					p_zone: Zone,
					p_character: Character,
					p_character_ID: int,
					p_battle_ui: BattleUI,
					p_character_repr: CharacterRepresentation,
					p_sides: CombatSides) -> void:
	match p_zone._type:
		Types.Skill_Type.Flicker_Zone:
			if(CorrectZoneTarget(p_zone._owner_ID, p_character_ID, p_zone._target, p_sides)):
				p_battle_ui._turn_bar.BumpCharacter(
						p_character_ID,
						AllyZoneMagnitude(Game_Balance.FLICKER_ZONE_BASE_BUMP, p_zone._owner_knowledge))
		Types.Skill_Type.Lava_Zone:
			if(HasMaxStatusEffects(p_character)):
				return

			# Burning stacks by design (Concept_Document.md 3.2.3.2): every Lava-zone
			# trigger adds another independent Burning debuff, up to the status cap,
			# so a target left in the lava keeps accruing 4%-max-health ticks.
			var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
			# TODO: add a status effect container to the Zone class and use that instead.
			new_debuff.type = Types.Debuff_Type.Burning
			new_debuff.duration = 2 # TODO: Replace with a defined number from the skill.
			new_debuff.source_ID = p_zone._owner_ID
			new_debuff.ID = p_character_repr.AddStatusEffect(
					GetStatusEffectTexture(Statuses.DEBUFF_ICONS[Types.Debuff_Type.Burning]), new_debuff.duration)

			p_character._active_debuffs.append(new_debuff)

static func ResolveSkillEffect(
		p_caster_ID: int,
		p_caster_attr: Dictionary[Types.Attribute, int],
		p_skill: Skill) -> void:
	match p_skill.skill_type:
		Types.Skill_Type.Heap_On:
			if (0 == _heap_on_stacks.get(p_caster_ID, 0)):
				_heap_on_value[p_caster_ID] = float(p_caster_attr[Types.Attribute.Health]) * Game_Balance.HEAP_ON_MULTIPLIER
			p_caster_attr[Types.Attribute.Health] += int(
					_heap_on_value[p_caster_ID] * float(_heap_on_stacks.get(p_caster_ID, 0)))
			_heap_on_stacks[p_caster_ID] = _heap_on_stacks.get(p_caster_ID, 0) + 1

static func CorrectZoneTarget(
		p_zone_owner_ID: int,
		p_trigger_character_ID: int,
		p_zone_target: Types.Skill_Target,
		p_sides: CombatSides) -> bool:
	match p_zone_target:
		Types.Skill_Target.ZoneAll:
			return true
		Types.Skill_Target.ZoneAlly:
			return p_sides.AreAllies(p_trigger_character_ID, p_zone_owner_ID)
		Types.Skill_Target.ZoneEnemy:
			return p_sides.AreEnemies(p_trigger_character_ID, p_zone_owner_ID)
		_:
			print("Invalid target passed for zone target: ", p_zone_target)
	return false

static func FindSkillTargets(
					p_target_ID: int,
					p_caster_ID: int,
					p_target_type: Types.Skill_Target,
					p_characters: Dictionary[int, Character],
					p_sides: CombatSides) -> Array[int]:
	var target_IDs: Array[int]
	match p_target_type:
		Types.Skill_Target.Single_Enemy:
			if(p_sides.AreEnemies(p_caster_ID, p_target_ID)):
				target_IDs.append(p_target_ID)
		Types.Skill_Target.All_Enemies:
			if(p_sides.AreEnemies(p_caster_ID, p_target_ID)):
				target_IDs.append_array(p_sides.EnemiesOf(p_caster_ID).members)
		Types.Skill_Target.Random_Enemy:
			if(p_sides.AreEnemies(p_caster_ID, p_target_ID)):
				return SingleTargetArray(p_sides.EnemiesOf(p_caster_ID).RandomAliveMember(p_characters))
		Types.Skill_Target.Single_Ally:
			if(p_sides.AreAllies(p_caster_ID, p_target_ID)):
				target_IDs.append(p_target_ID)
		Types.Skill_Target.All_Allies:
			if(p_sides.AreAllies(p_caster_ID, p_target_ID)):
				target_IDs.append_array(p_sides.AlliesOf(p_caster_ID).members)
		Types.Skill_Target.Random_Ally:
			if(p_sides.AreAllies(p_caster_ID, p_target_ID)):
				return SingleTargetArray(p_sides.AlliesOf(p_caster_ID).RandomAliveMember(p_characters))
		Types.Skill_Target.Ally_Not_Self:
			if(p_caster_ID != p_target_ID and p_sides.AreAllies(p_caster_ID, p_target_ID)):
				target_IDs.append(p_target_ID)
		Types.Skill_Target.Random_One:
			return SingleTargetArray(p_sides.RandomAliveMember(p_characters))
		Types.Skill_Target.All:
			target_IDs.append_array(p_sides.AllMembers())
		Types.Skill_Target.ZoneAll, Types.Skill_Target.ZoneAlly, Types.Skill_Target.ZoneEnemy:
			pass
		Types.Skill_Target.All_Other_Allies:
			if(p_sides.AreAllies(p_caster_ID, p_target_ID)):
				target_IDs.append_array(p_sides.AlliesOf(p_caster_ID).members)
			target_IDs.erase(p_caster_ID)
		var INVALID_TYPE:
			print("Invalid argument for skill target enum passed: ", INVALID_TYPE)
	return FilterAliveTargets(target_IDs, p_characters)

# Keeps only the IDs that both exist in the battle and are still alive, so a skill
# never resolves against a corpse or an empty slot.
static func FilterAliveTargets(
					p_ids: Array[int],
					p_characters: Dictionary[int, Character]) -> Array[int]:
	var alive_IDs: Array[int] = []
	for id in p_ids:
		if(p_characters.has(id) and p_characters[id]._current_health > 0):
			alive_IDs.append(id)
	return alive_IDs

# Wraps a random pick as a target list: an empty array for the no-living-target
# sentinel (-1), a one-element array otherwise.
static func SingleTargetArray(p_target_ID: int) -> Array[int]:
	var target_IDs: Array[int] = []
	if(-1 != p_target_ID):
		target_IDs.append(p_target_ID)
	return target_IDs

# Ticks the caster's own debuffs at the start of their turn. Burning deals damage, so
# it shows combat text over the burning character and reports how much damage each
# source dealt (keyed by the applier's character ID) for post-battle damage totals.
static func TriggerExistingCasterDebuffs(
								p_caster: Character,
								p_caster_attributes: Dictionary[Types.Attribute, int],
								p_caster_repr: CharacterRepresentation,
								p_battle_ui: BattleUI) -> Dictionary[int, int]:
	var debuff_IDs_to_be_removed: Array[int] = []
	var burning_damage_by_source: Dictionary[int, int] = {}
	var burning_damage_total: int = 0
	for debuff in p_caster._active_debuffs:
		match debuff.type:
			Types.Debuff_Type.Burning:
				var tick_damage: int = int(floor(
						(p_caster_attributes[Types.Attribute.Health] * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER) * 0.04))
				p_caster._current_health -= tick_damage
				burning_damage_total += tick_damage
				if (not burning_damage_by_source.has(debuff.source_ID)):
					burning_damage_by_source[debuff.source_ID] = 0
				burning_damage_by_source[debuff.source_ID] += tick_damage
			Types.Debuff_Type.Enfeeble:
				p_caster_attributes[Types.Attribute.Attack] -= int(ceilf(p_caster_attributes[Types.Attribute.Attack] * 0.3))
			Types.Debuff_Type.Expose_Weakness:
				p_caster_attributes[Types.Attribute.Defence] -= int(ceilf(p_caster_attributes[Types.Attribute.Defence] * 0.3))

		debuff.duration -= 1
		p_caster_repr.SetStatusEffectDuration(debuff.ID, debuff.duration)
		if (debuff.duration <= 0):
			debuff_IDs_to_be_removed.append(debuff.ID)

	if (burning_damage_total > 0):
		p_battle_ui.SpawnCombatText(
				str(burning_damage_total),
				p_caster_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT,
				Color(1.0, 0.45, 0.1, 1.0))

	p_caster._active_debuffs = p_caster._active_debuffs.filter(func(debuff): return debuff.duration > 0)
	p_caster_repr.RemoveStatusEffects(debuff_IDs_to_be_removed)
	return burning_damage_by_source

static func TriggerExistingCasterBuffs(
							p_caster: Character,
							p_caster_attributes: Dictionary[Types.Attribute, int],
							p_caster_repr: CharacterRepresentation,
							p_caster_ID: int) -> void:
	var buff_IDs_to_be_removed: Array[int] = []
	
	for buff in p_caster._active_buffs:
		match buff.type:
			Types.Buff_Type.Empower:
				p_caster_attributes[Types.Attribute.Attack] += int(ceilf(p_caster_attributes[Types.Attribute.Attack] * 0.3))
			Types.Buff_Type.Fortify:
				p_caster_attributes[Types.Attribute.Defence] += int(ceilf(p_caster_attributes[Types.Attribute.Defence] * 0.3))
			Types.Buff_Type.Daunting_Strength:
				_damage_multiplier[p_caster_ID] = _damage_multiplier.get(p_caster_ID, 1.0) * 2.0
			Types.Buff_Type.Phalanx_Guard:
				pass
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
			Types.Buff_Type.Phalanx_Guard:
				p_target_attributes[Types.Attribute.Defence] += int(
						ceilf(p_target_attributes[Types.Attribute.Defence] * buff.value))
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
				p_target_attributes[Types.Attribute.Defence] -= int(ceilf(p_target_attributes[Types.Attribute.Defence] * 0.3))
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
				if(p_skill.duration > p_target._active_buffs[i].duration):
					p_target._active_buffs[i].duration = p_skill.duration
					p_target_repr.SetStatusEffectDuration(p_target._active_buffs[i].ID, p_skill.duration)
				return
	
	var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
	new_buff.type = p_skill.buffs[p_skill.target]
	new_buff.duration = p_skill.duration
	new_buff.ID = p_target_repr.AddStatusEffect(
			GetStatusEffectTexture(Statuses.BUFF_ICONS[new_buff.type]), new_buff.duration)
	p_target._active_buffs.append(new_buff)
	p_battle_ui.SpawnCombatText(
			Types.Buff_Type.keys()[new_buff.type],
			p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT,
			Color(0.335, 0.575, 0.838, 1.0))

static func ApplyBuff(
		p_target: Character,
		p_buff_template: StatusEffects.Buff,
		p_target_repr: CharacterRepresentation,
		p_battle_ui: BattleUI) -> void:
	if(HasMaxStatusEffects(p_target)):
		return
	
	for i in p_target._active_buffs.size():
		if(p_target._active_buffs[i].type == p_buff_template.type):
			if(OverwritableBuff(p_buff_template.type)):
				if(p_buff_template.duration > p_target._active_buffs[i].duration):
					p_target._active_buffs[i].duration = p_buff_template.duration
					p_target_repr.SetStatusEffectDuration(p_target._active_buffs[i].ID, p_buff_template.duration)
				return
	
	var new_buff: StatusEffects.Buff = StatusEffects.Buff.new()
	new_buff.type = p_buff_template.type
	new_buff.duration = p_buff_template.duration
	new_buff.name = p_buff_template.name
	new_buff.value = p_buff_template.value
	new_buff.ID = p_target_repr.AddStatusEffect(
			GetStatusEffectTexture(Statuses.BUFF_ICONS[new_buff.type]), new_buff.duration)
	p_target._active_buffs.append(new_buff)
	p_battle_ui.SpawnCombatText(
			new_buff.name, p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(0.335, 0.575, 0.838, 1.0))

static func RemoveBuff(
		p_target: Character,
		p_buff: StatusEffects.Buff,
		p_target_repr: CharacterRepresentation,
		_p_battle_ui: BattleUI) -> void:
	p_target._active_buffs.erase(p_buff)
	p_target_repr.RemoveStatusEffects([p_buff.ID])

static func ApplyDebuff(
		p_target: Character,
		p_debuff_template: StatusEffects.Debuff,
		p_target_repr: CharacterRepresentation,
		p_battle_ui: BattleUI) -> void:
	if(HasMaxStatusEffects(p_target)):
		return

	for i in p_target._active_debuffs.size():
		if(p_target._active_debuffs[i].type == p_debuff_template.type):
			if(OverwritableDebuff(p_debuff_template.type)):
				if(p_debuff_template.duration > p_target._active_debuffs[i].duration):
					p_target._active_debuffs[i].duration = p_debuff_template.duration
					p_target_repr.SetStatusEffectDuration(p_target._active_debuffs[i].ID, p_debuff_template.duration)
				return

	var new_debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
	new_debuff.type = p_debuff_template.type
	new_debuff.duration = p_debuff_template.duration
	new_debuff.name = p_debuff_template.name
	new_debuff.ID = p_target_repr.AddStatusEffect(
			GetStatusEffectTexture(Statuses.DEBUFF_ICONS[new_debuff.type]), new_debuff.duration)
	p_target._active_debuffs.append(new_debuff)
	p_battle_ui.SpawnCombatText(
			new_debuff.name, p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(0.681, 0.152, 0.31, 1.0))

static func CastDebuff(
					p_target: Character,
					p_target_attributes: Dictionary[Types.Attribute, int],
					p_caster_accuracy: int,
					p_skill: Skill,
					p_target_repr: CharacterRepresentation,
					p_battle_ui: BattleUI,
					p_caster_ID: int = -1):
	if(HasMaxStatusEffects(p_target)):
		return
	
	var random_value: float = randf_range(0.95, 1.0)
	var random_value_2: float = randf_range(0.95, 1.0)
	if(p_caster_accuracy * random_value < p_target_attributes[Types.Attribute.Resistance] * random_value_2):
		print("Target character ", p_target._name, " resisted the debuff!")
		p_battle_ui.SpawnCombatText(
				"Resisted debuff!", p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT, Color(0.801, 0.0, 0.0, 1.0))
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
	new_debuff.source_ID = p_caster_ID
	new_debuff.ID = p_target_repr.AddStatusEffect(
			GetStatusEffectTexture(Statuses.DEBUFF_ICONS[new_debuff.type]), new_debuff.duration)
	p_target._active_debuffs.append(new_debuff)
	p_battle_ui.SpawnCombatText(
			Types.Debuff_Type.keys()[new_debuff.type],
			p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT,
			Color(0.681, 0.152, 0.31, 1.0))

# Rolls a 1-100 die against the crit chance. The die starts at 1 (not 0) so a
# 0% crit chance can never crit and each chance point is worth exactly one percent.
static func RollsCritical(p_crit_chance: int) -> bool:
	return randi_range(1, 100) <= p_crit_chance

static func DamageDealt(p_attacker_attr: Dictionary[Types.Attribute, int],
						p_defender_attr: Dictionary[Types.Attribute, int],
						p_skill: Skill,
						p_trait_multiplier: float,
						p_target_repr: CharacterRepresentation,
						p_battle_ui: BattleUI,
						p_caster_ID: int) -> int:
	var random_value: float = randf_range(0.95, 1.05)
	var caster_scaled_attribute_aggregate: float = 0.0
	var crit_multiplier: float = 1.0
	
	for key in p_skill.damage_scaling.keys():
		caster_scaled_attribute_aggregate += p_skill.damage_scaling[key] * float(
				p_attacker_attr[key]) * p_trait_multiplier
	# For example, some status skills deal no damage. So no need to continue.
	if(0.0 == caster_scaled_attribute_aggregate):
		return 0
		
	if(RollsCritical(p_attacker_attr[Types.Attribute.CritChance])):
		crit_multiplier = max(
				Game_Balance.MINIMUM_CRIT_DAMAGE,
				float(p_attacker_attr[Types.Attribute.CritDamage] - (p_defender_attr[Types.Attribute.Knowledge] * 0.5))
				) * 0.01
		p_battle_ui.SpawnCombatText(
				"Critical Strike!",
				p_target_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT,
				Color(1.0, 0.729, 0.0, 1.0))
	
	var effective_defence: float = p_defender_attr[Types.Attribute.Defence] * p_skill.defense_ignore_factor
	var damage_ratio: float = (
			caster_scaled_attribute_aggregate / (effective_defence + caster_scaled_attribute_aggregate + 1))
	var mitigation_factor: float = (
			GameBalance.MINIMUM_DMG_PERCENT + ((1 - GameBalance.MINIMUM_DMG_PERCENT) * damage_ratio))
	var damage_dealt: float = (mitigation_factor *
			(caster_scaled_attribute_aggregate * _damage_multiplier.get(p_caster_ID, 1.0)) *
			crit_multiplier * random_value)
	_damage_multiplier.erase(p_caster_ID)
	return int(ceil(damage_dealt))

static func Reset() -> void:
	_heap_on_stacks.clear()
	_heap_on_value.clear()
	_damage_multiplier.clear()

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
