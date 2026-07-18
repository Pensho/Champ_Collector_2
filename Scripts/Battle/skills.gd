class_name Skills
extends Node

## Stateless combat helpers: targeting, zone-target checks, status-effect rules, and
## attribute-snapshot modifiers. Everything stateful (Heap-On stacks, damage
## multipliers, status application, damage rolls) lives on BattleResolver.

const ZoneType = preload("uid://bdjrfif0s60v4")

static func AllyZoneMagnitude(p_base: float, p_owner_knowledge: int) -> float:
	return p_base * (1.0 + p_owner_knowledge * Game_Balance.ZONE_KNOWLEDGE_SCALING)

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
					p_sides: CombatSides,
					p_random: RandomNumberGenerator = null) -> Array[int]:
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
				return SingleTargetArray(p_sides.EnemiesOf(p_caster_ID).RandomAliveMember(p_characters, p_random))
		Types.Skill_Target.Single_Ally:
			if(p_sides.AreAllies(p_caster_ID, p_target_ID)):
				target_IDs.append(p_target_ID)
		Types.Skill_Target.All_Allies:
			if(p_sides.AreAllies(p_caster_ID, p_target_ID)):
				target_IDs.append_array(p_sides.AlliesOf(p_caster_ID).members)
		Types.Skill_Target.Random_Ally:
			if(p_sides.AreAllies(p_caster_ID, p_target_ID)):
				return SingleTargetArray(p_sides.AlliesOf(p_caster_ID).RandomAliveMember(p_characters, p_random))
		Types.Skill_Target.Ally_Not_Self:
			if(p_caster_ID != p_target_ID and p_sides.AreAllies(p_caster_ID, p_target_ID)):
				target_IDs.append(p_target_ID)
		Types.Skill_Target.Random_One:
			return SingleTargetArray(p_sides.RandomAliveMember(p_characters, p_random))
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

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the buff targets yet.
static func TriggerTargetBuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int]) -> void:
	for buff in p_target._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null == data or not data.applies_on_target_snapshot
				or StatusEffectData.MagnitudeKind.AttributePercent != data.magnitude_kind):
			continue
		p_target_attributes[data.affected_attribute] += int(
				ceilf(p_target_attributes[data.affected_attribute] * buff.value))

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the debuff targets yet.
static func TriggerTargetDebuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int]) -> void:
	for debuff in p_target._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null == data or not data.applies_on_target_snapshot
				or StatusEffectData.MagnitudeKind.AttributePercent != data.magnitude_kind):
			continue
		p_target_attributes[data.affected_attribute] -= int(
				ceilf(p_target_attributes[data.affected_attribute] * data.magnitude))

static func RollsCritical(p_crit_chance: int, p_random: RandomNumberGenerator) -> bool:
	return p_random.randi_range(1, 100) <= p_crit_chance

static func HasMaxStatusEffects(p_character: Character) -> bool:
	if(GameBalance.MAX_STATUS_EFFECTS <= p_character._active_buffs.size() + p_character._active_debuffs.size()):
		print(p_character._name, " cannot have any more status effects right now.")
		return true
	return false

static func DamageDealt(p_damage: float, p_bonus_percent: float) -> float:
	return p_damage * (1.0 + p_bonus_percent)
