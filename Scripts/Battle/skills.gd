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


static func IsAttributeModifierKind(p_kind: StatusEffectData.MagnitudeKind) -> bool:
	return (StatusEffectData.MagnitudeKind.AttributePercent == p_kind
			or StatusEffectData.MagnitudeKind.AttributePercentagePointAdd == p_kind)

static func ApplyAttributeModifiers(
							p_data: StatusEffectData,
							p_value: float,
							p_attributes: Dictionary[Types.Attribute, int]) -> void:
	# 0.0 means the instance never had its own value set (e.g. a debuff built directly by
	# a zone or a test) — fall back to the resource's static magnitude, same convention
	# ApplyBuff/ApplyDebuff already use when resolving a template's default value.
	var resolved_value: float = p_value if 0.0 != p_value else p_data.magnitude
	for attribute in p_data.attribute_modifiers.keys():
		var modifier_sign: float = p_data.attribute_modifiers[attribute]
		if(StatusEffectData.MagnitudeKind.AttributePercentagePointAdd == p_data.magnitude_kind):
			p_attributes[attribute] += int(modifier_sign * resolved_value)
		else:
			p_attributes[attribute] += int(modifier_sign * ceilf(p_attributes[attribute] * resolved_value))

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the buff targets yet.
static func TriggerTargetBuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int]) -> void:
	for buff in p_target._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null == data or not data.applies_on_target_snapshot or not IsAttributeModifierKind(data.magnitude_kind)):
			continue
		ApplyAttributeModifiers(data, buff.value, p_target_attributes)

# TODO: Right now the targeting only inherits the skill target and doesn't use
# the debuff targets yet.
static func TriggerTargetDebuffs(
							p_target: Character,
							p_target_attributes: Dictionary[Types.Attribute, int]) -> void:
	for debuff in p_target._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null == data or not data.applies_on_target_snapshot or not IsAttributeModifierKind(data.magnitude_kind)):
			continue
		ApplyAttributeModifiers(data, debuff.value, p_target_attributes)

static func RollsCritical(p_crit_chance: int, p_random: RandomNumberGenerator) -> bool:
	return p_random.randi_range(1, 100) <= p_crit_chance

static func HasMaxStatusEffects(p_character: Character) -> bool:
	if(GameBalance.MAX_STATUS_EFFECTS <= p_character._active_buffs.size() + p_character._active_debuffs.size()):
		print(p_character._name, " cannot have any more status effects right now.")
		return true
	return false

static func DamageDealt(p_damage: float, p_bonus_percent: float) -> float:
	return p_damage * (1.0 + p_bonus_percent)

## Mitigated damage from a single attack roll against `p_effective_defence`; shared by
## the direct hit and any Shield-Wall-style redirected share, which re-mitigates the
## same roll against the soaker's own Defence.
static func MitigatedDamage(
		p_effective_defence: float,
		p_caster_scaled_attribute_aggregate: float,
		p_crit_multiplier: float,
		p_random_value: float,
		p_damage_multiplier: float,
		p_damage_dealt_bonus: float,
		p_opportunist_multiplier: float) -> int:
	var damage_ratio: float = (
			p_caster_scaled_attribute_aggregate
			/ (p_effective_defence + p_caster_scaled_attribute_aggregate + 1.0))
	var mitigation_factor: float = (
			GameBalance.MINIMUM_DMG_PERCENT + ((1.0 - GameBalance.MINIMUM_DMG_PERCENT) * damage_ratio))
	return int(ceil(DamageDealt(mitigation_factor
			* (p_caster_scaled_attribute_aggregate * p_damage_multiplier)
			* p_crit_multiplier * p_random_value, p_damage_dealt_bonus)
			* p_opportunist_multiplier))

## The first living ally of `p_target_ID` whose trait redirects a share of incoming
## attack damage (e.g. Shield Wall); [-1, 0.0] when nobody redirects or the attacker
## is not an enemy of the target.
static func FindDamageRedirect(
		p_resolver: BattleResolver, p_caster_ID: int, p_target_ID: int) -> Array:
	if(not p_resolver.GetSides().AreEnemies(p_caster_ID, p_target_ID)):
		return [-1, 0.0]
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	for ally_ID in p_resolver.GetSides().AlliesOf(p_target_ID).AliveMembers(characters):
		if(ally_ID == p_target_ID):
			continue
		var ally: Character = characters[ally_ID]
		if(null == ally._trait or not ally._trait._execution_steps.has(Types.Combat_Event.Ally_Damage_Taken)):
			continue
		var fraction: float = ally._trait.OnAllyDamageTaken(ally_ID, p_target_ID, p_resolver)
		if(fraction > 0.0):
			return [ally_ID, fraction]
	return [-1, 0.0]
