class_name Skills
extends Node

## Stateless combat helpers: targeting, zone-target checks, status-effect rules, and
## attribute-snapshot modifiers. Everything stateful (Heap-On stacks, damage
## multipliers, status application, damage rolls) lives on BattleResolver.

const ZoneType = preload("uid://bdjrfif0s60v4")

static func ZoneMagnitude(p_base: float, p_owner_knowledge: int) -> float:
	return p_base * (1.0 + p_owner_knowledge * Game_Balance.ZONE_KNOWLEDGE_SCALING)

static func ActiveHooks(p_character: Character, p_event: Types.Combat_Event) -> Array[CharacterTrait]:
	var sources: Array[CharacterTrait] = []
	if(null == p_character):
		return sources
	for source: CharacterTrait in p_character.HookSources():
		if(source._execution_steps.has(p_event)):
			sources.append(source)
	return sources

static func OutgoingDamageBonus(
		p_character: Character, p_owner_ID: int, p_target_ID: int, p_resolver: BattleResolver) -> float:
	var total: float = 0.0
	if(null == p_character):
		return total
	for source: CharacterTrait in p_character.HookSources():
		total += source.GetOutgoingDamageBonus(p_owner_ID, p_target_ID, p_resolver)
	return total

static func OutgoingDefenceIgnoreFactor(
		p_character: Character, p_owner_ID: int, p_target_ID: int, p_resolver: BattleResolver) -> float:
	var factor: float = 1.0
	if(null == p_character):
		return factor
	for source: CharacterTrait in p_character.HookSources():
		factor *= source.GetOutgoingDefenceIgnoreFactor(p_owner_ID, p_target_ID, p_resolver)
	return factor

static func IncomingDebuffDurationBonus(p_character: Character, p_owner_ID: int) -> int:
	var total: int = 0
	if(null == p_character):
		return total
	for source: CharacterTrait in p_character.HookSources():
		total += source.GetIncomingDebuffDurationBonus(p_owner_ID)
	return total

static func OutgoingDebuffDurationBonus(p_character: Character, p_owner_ID: int) -> int:
	var total: int = 0
	if(null == p_character):
		return total
	for source: CharacterTrait in p_character.HookSources():
		total += source.GetOutgoingDebuffDurationBonus(p_owner_ID)
	return total

static func DamageTakenMultiplier(
		p_character: Character, p_owner_ID: int, p_attacker_ID: int, p_resolver: BattleResolver) -> float:
	var multiplier: float = 1.0
	if(null == p_character):
		return multiplier
	for source: CharacterTrait in p_character.HookSources():
		multiplier *= source.OnDamageTaken(p_owner_ID, p_attacker_ID, p_resolver)
	return multiplier

static func IncomingHealMultiplier(p_character: Character, p_owner_ID: int) -> float:
	var multiplier: float = 1.0
	if(null == p_character):
		return multiplier
	for source: CharacterTrait in p_character.HookSources():
		multiplier *= source.GetIncomingHealMultiplier(p_owner_ID)
	return multiplier

static func TargetingPriorityMultiplier(p_character: Character) -> float:
	var multiplier: float = 1.0
	if(null == p_character):
		return multiplier
	for source: CharacterTrait in p_character.HookSources():
		multiplier *= source.GetTargetingPriorityMultiplier()
	return multiplier

static func IncomingZoneEffectMultiplier(
		p_character: Character, p_owner_ID: int, p_zone_owner_ID: int, p_sides: CombatSides) -> float:
	var multiplier: float = 1.0
	if(null == p_character):
		return multiplier
	for source: CharacterTrait in p_character.HookSources():
		multiplier *= source.GetIncomingZoneEffectMultiplier(p_owner_ID, p_zone_owner_ID, p_sides)
	return multiplier

static func DebuffsCannotBeResisted(p_character: Character, p_owner_ID: int, p_target_ID: int) -> bool:
	if(null == p_character):
		return false
	for source: CharacterTrait in p_character.HookSources():
		if(source.DebuffsCannotBeResisted(p_owner_ID, p_target_ID)):
			return true
	return false

static func BlocksForwardTurnBarBump(p_character: Character, p_owner_ID: int) -> bool:
	if(null == p_character):
		return false
	for source: CharacterTrait in p_character.HookSources():
		if(source.BlocksForwardTurnBarBump(p_owner_ID)):
			return true
	return false

## First-opinion-wins: the first active hook source with a non-negative override for
## this debuff type sets its value; -1.0 (no opinion) if none do.
static func AppliedStatusValue(
		p_character: Character, p_owner_ID: int, p_target_ID: int,
		p_debuff_type: Types.Debuff_Type, p_resolver: BattleResolver) -> float:
	if(null == p_character):
		return -1.0
	for source: CharacterTrait in p_character.HookSources():
		var value: float = source.GetAppliedStatusValue(p_owner_ID, p_target_ID, p_debuff_type, p_resolver)
		if(value >= 0.0):
			return value
	return -1.0

static func AppliedBuffValue(
		p_character: Character, p_owner_ID: int, p_target_ID: int,
		p_buff_type: Types.Buff_Type, p_resolver: BattleResolver) -> float:
	if(null == p_character):
		return -1.0
	for source: CharacterTrait in p_character.HookSources():
		var value: float = source.GetAppliedBuffValue(p_owner_ID, p_target_ID, p_buff_type, p_resolver)
		if(value >= 0.0):
			return value
	return -1.0

## Merges every active Skill_Cast hook source's own TraitSkillResult into one: damage-
## multiplier deltas and turn-bar bumps add, trait riders union (a later source
## overwrites an earlier one's same key).
static func DispatchSkillCast(
		p_character: Character,
		p_owner_ID: int,
		p_target_IDs: Array[int],
		p_skill_name: String,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var merged: TraitSkillResult = TraitSkillResult.new()
	if(null == p_character):
		return merged
	for source: CharacterTrait in ActiveHooks(p_character, Types.Combat_Event.Skill_Cast):
		var result: TraitSkillResult = source.OnSkillCast(
				p_owner_ID, p_target_IDs, p_skill_name, p_caster_attributes, p_resolver)
		merged._damage_multiplier += result._damage_multiplier - 1.0
		merged._turn_bar_bump += result._turn_bar_bump
		for key: StringName in result._trait_riders:
			merged._trait_riders[key] = result._trait_riders[key]
	for cast_skill: Skill in p_character._skills:
		if(cast_skill.name == p_skill_name and 0 == cast_skill.cooldown):
			merged._damage_multiplier -= TeamCooldownlessDamagePenalty(
					p_resolver.GetSides(), p_resolver.GetCharacters(), p_owner_ID)
			break
	return merged

static func RewardMultiplier(p_fielded_team: Array[Character]) -> float:
	var largest_bonus: float = 0.0
	for character: Character in p_fielded_team:
		for source: CharacterTrait in character.HookSources():
			largest_bonus = maxf(largest_bonus, source.GetRewardMultiplier() - 1.0)
	return 1.0 + largest_bonus

## The character's cooldown-0 skill (Concept_Document.md 1.1.2's basic-skill baseline).
## Falls back to the first skill when the kit has no cooldown-0 entry.
static func BasicSkill(p_character: Character) -> Skill:
	for skill: Skill in p_character._skills:
		if(0 == skill.cooldown):
			return skill
	return p_character._skills[0] if not p_character._skills.is_empty() else null

## Additive attribute-scaled Barrier value, shared by the barrier zone and any future
## direct-cast Barrier skill (use GameBalance.BARRIER_DIRECT_BASE / _COEFF and the
## casting skill's own scaling attribute for the latter).
static func Barrier(p_base: float, p_coeff: float, p_attribute_value: int, p_bonus: float = 0.0) -> int:
	return int(ceil((p_base + p_coeff * p_attribute_value) * (1.0 + p_bonus)))

static func MakeBarrierZoneBuff(p_owner_knowledge: int, p_charge_bonus: float = 0.0) -> StatusEffects.Buff:
	var barrier: StatusEffects.Buff = StatusEffects.Buff.new()
	barrier.type = Types.Buff_Type.Barrier
	barrier.name = "Barrier"
	barrier.duration = 2
	barrier.value = Barrier(Game_Balance.BARRIER_ZONE_BASE, Game_Balance.BARRIER_ZONE_KNOWLEDGE_COEFF,
			p_owner_knowledge, p_charge_bonus)
	return barrier

static func TriggerZoneUsedHook(
		p_characters: Dictionary[int, Character],
		p_zone_owner_ID: int,
		p_user_ID: int,
		p_resolver: BattleResolver) -> void:
	var zone_owner: Character = p_characters.get(p_zone_owner_ID)
	if(null != zone_owner and zone_owner._current_health <= 0):
		return
	for active_trait: CharacterTrait in ActiveHooks(zone_owner, Types.Combat_Event.Zone_Used):
		active_trait.OnZoneUsed(p_zone_owner_ID, p_user_ID, p_resolver)

static func TriggerZoneConstructedHook(
		p_characters: Dictionary[int, Character],
		p_zone_owner_ID: int,
		p_zone_ID: int,
		p_resolver: BattleResolver) -> void:
	var zone_owner: Character = p_characters.get(p_zone_owner_ID)
	for active_trait: CharacterTrait in ActiveHooks(zone_owner, Types.Combat_Event.Zone_Constructed):
		active_trait.OnZoneConstructed(p_zone_owner_ID, p_zone_ID, p_resolver)

## Notifies every living member of the consumer's own team (the consumer included) that a
## reagent was consumed — the Alchemist's Fresh Batch team-wide factor hangs off this, not
## off the consumer-side Reagent_Consumed hook, since it must fire on any ally's
## consumption rather than only the Alchemist's own.
static func TriggerAllyReagentConsumedHook(
		p_sides: CombatSides,
		p_characters: Dictionary[int, Character],
		p_consumer_ID: int,
		p_reagent: ReagentData,
		p_resolver: BattleResolver) -> void:
	for ally_ID in p_sides.AlliesOf(p_consumer_ID).AliveMembers(p_characters):
		for ally_trait: CharacterTrait in ActiveHooks(p_characters[ally_ID], Types.Combat_Event.Ally_Reagent_Consumed):
			ally_trait.OnAllyReagentConsumed(ally_ID, p_consumer_ID, p_reagent, p_resolver)

static func CritChanceOverflowRate(
		p_sides: CombatSides,
		p_characters: Dictionary[int, Character],
		p_character_ID: int) -> float:
	var rate: float = 0.0
	var team: CombatTeam = p_sides.AlliesOf(p_character_ID)
	if(null == team):
		return rate
	for ally_ID in team.AliveMembers(p_characters):
		var ally: Character = p_characters[ally_ID]
		for source: CharacterTrait in ally.HookSources():
			rate += source.GetCritChanceOverflowRate()
	return rate

static func TeamCooldownlessDamagePenalty(
		p_sides: CombatSides, p_characters: Dictionary[int, Character], p_character_ID: int) -> float:
	var penalty: float = 0.0
	var team: CombatTeam = p_sides.AlliesOf(p_character_ID)
	if(null == team):
		return penalty
	for ally_ID in team.AliveMembers(p_characters):
		var ally: Character = p_characters[ally_ID]
		for source: CharacterTrait in ally.HookSources():
			penalty += source.GetTeamCooldownlessDamagePenalty()
	return penalty

static func AllyDeniesCriticalHits(
		p_sides: CombatSides, p_characters: Dictionary[int, Character], p_character_ID: int) -> bool:
	var team: CombatTeam = p_sides.AlliesOf(p_character_ID)
	if(null == team):
		return false
	for ally_ID in team.AliveMembers(p_characters):
		if(ally_ID == p_character_ID):
			continue
		for source: CharacterTrait in p_characters[ally_ID].HookSources():
			if(source.DeniesAlliesCriticalHits()):
				return true
	return false

static func TeamBarrierMultiplier(
		p_sides: CombatSides, p_characters: Dictionary[int, Character], p_target_ID: int) -> float:
	var multiplier: float = 1.0
	var team: CombatTeam = p_sides.AlliesOf(p_target_ID)
	if(null == team):
		return multiplier
	for ally_ID in team.AliveMembers(p_characters):
		for source: CharacterTrait in p_characters[ally_ID].HookSources():
			multiplier *= source.GetTeamBarrierMultiplier()
	return multiplier

static func ApplyBarrierZone(
		p_resolver: BattleResolver,
		p_zone_owner_ID: int,
		p_zone_ID: int,
		p_owner_knowledge: int,
		p_character_ID: int) -> void:
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var zone_owner: Character = characters.get(p_zone_owner_ID)
	var charge_bonus: float = 0.0
	if(null != zone_owner):
		for source: CharacterTrait in zone_owner.HookSources():
			charge_bonus += source.GetZoneChargeBonus(p_zone_ID)
	var barrier: StatusEffects.Buff = MakeBarrierZoneBuff(p_owner_knowledge, charge_bonus)
	barrier.value *= TeamBarrierMultiplier(p_resolver.GetSides(), characters, p_character_ID)
	p_resolver.GetStatusResolver().ApplyBuff(p_character_ID, barrier)
	TriggerZoneUsedHook(characters, p_zone_owner_ID, p_character_ID, p_resolver)

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
					p_random: RandomNumberGenerator = null,
					p_max_health: Callable = Callable()) -> Array[int]:
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
		Types.Skill_Target.Self:
			target_IDs.append(p_caster_ID)
		Types.Skill_Target.Most_Injured_Ally:
			target_IDs.append_array(p_sides.AlliesOf(p_caster_ID).members)
		Types.Skill_Target.Most_Injured_Enemy:
			return SingleTargetArray(
					MostInjured(p_sides.EnemiesOf(p_caster_ID).members, p_characters, p_max_health))
		Types.Skill_Target.Left_Most_Enemy:
			return SingleTargetArray(EdgeMostAlive(p_sides.EnemiesOf(p_caster_ID).AliveMembers(p_characters), true))
		Types.Skill_Target.Right_Most_Enemy:
			return SingleTargetArray(EdgeMostAlive(p_sides.EnemiesOf(p_caster_ID).AliveMembers(p_characters), false))
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

static func MostInjured(p_IDs: Array[int], p_characters: Dictionary[int, Character],
		p_max_health: Callable) -> int:
	var best_ID: int = -1
	var best_ratio: float = INF
	for id in p_IDs:
		if(not p_characters.has(id) or p_characters[id]._current_health <= 0):
			continue
		var max_health: int = p_max_health.call(id)
		var ratio: float = float(p_characters[id]._current_health) / float(max_health)
		if(ratio < best_ratio or (ratio == best_ratio and id < best_ID)):
			best_ratio = ratio
			best_ID = id
	return best_ID

static func MostBuffed(p_IDs: Array[int], p_characters: Dictionary[int, Character]) -> int:
	var most_buffs_character_ID: int = -1
	var most_buffs_count: int = -1
	for id in p_IDs:
		if(not p_characters.has(id) or p_characters[id]._current_health <= 0):
			continue
		var count: int = p_characters[id]._active_buffs.size()
		if(count > most_buffs_count):
			most_buffs_count = count
			most_buffs_character_ID = id
	return most_buffs_character_ID

## The left-most (p_want_left true) or right-most alive member of an already
## alive-filtered, left-to-right ordered ID list; -1 if the list is empty.
static func EdgeMostAlive(p_alive_IDs_left_to_right: Array[int], p_want_left: bool) -> int:
	if(p_alive_IDs_left_to_right.is_empty()):
		return -1
	return p_alive_IDs_left_to_right.front() if p_want_left else p_alive_IDs_left_to_right.back()

## The combined enemy-AI targeting-weight multiplier from all of a character's active
## buffs (e.g. Spotlight's 1.5x). 1.0 when none apply.
static func TargetingWeightMultiplier(p_character: Character) -> float:
	var multiplier: float = 1.0
	for buff in p_character._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data):
			multiplier *= data.targeting_weight_multiplier
	return multiplier

static func IsAttributeModifierKind(p_kind: StatusEffectData.MagnitudeKind) -> bool:
	return (StatusEffectData.MagnitudeKind.AttributePercent == p_kind
			or StatusEffectData.MagnitudeKind.AttributePercentagePointAdd == p_kind
			or StatusEffectData.MagnitudeKind.HighestBasePrimaryAttributePercent == p_kind)

static func IsAmplifiableKind(p_kind: StatusEffectData.MagnitudeKind) -> bool:
	return (IsAttributeModifierKind(p_kind)
			or StatusEffectData.MagnitudeKind.MaxHealthAttributePercent == p_kind)

static func _IsCritAttribute(p_attribute: Types.Attribute) -> bool:
	return (Types.Attribute.CritChance == p_attribute
			or Types.Attribute.CritDamage == p_attribute)

static func ApplyAttributeModifiers(
							p_data: StatusEffectData,
							p_value: float,
							p_attributes: Dictionary[Types.Attribute, int],
							p_trait_riders: Dictionary[StringName, Variant] = {}) -> void:
	# 0.0 means the instance never had its own value set (e.g. a debuff built directly by
	# a zone or a test) — fall back to the resource's static magnitude, same convention
	# ApplyBuff/ApplyDebuff already use when resolving a template's default value.
	var resolved_value: float = p_value if 0.0 != p_value else p_data.magnitude
	var amplification: float = p_trait_riders.get(&"attribute_amplification", 0.0)
	if(StatusEffectData.MagnitudeKind.HighestBasePrimaryAttributePercent == p_data.magnitude_kind):
		if(not p_trait_riders.has(&"attribute")):
			return
		var attribute: Types.Attribute = p_trait_riders[&"attribute"]
		var amplified_value: float = resolved_value + (0.0 if _IsCritAttribute(attribute) else amplification)
		p_attributes[attribute] += int(ceilf(p_attributes[attribute] * amplified_value))
		return
	for attribute in p_data.attribute_modifiers.keys():
		var modifier_sign: float = p_data.attribute_modifiers[attribute]
		if(StatusEffectData.MagnitudeKind.AttributePercentagePointAdd == p_data.magnitude_kind):
			p_attributes[attribute] += int(modifier_sign * resolved_value)
		else:
			var amplified_value: float = resolved_value + (0.0 if _IsCritAttribute(attribute) else amplification)
			p_attributes[attribute] += int(modifier_sign * ceilf(p_attributes[attribute] * amplified_value))

static func DisplayedAttributeModifierFraction(
							p_data: StatusEffectData,
							p_value: float,
							p_trait_riders: Dictionary[StringName, Variant]) -> float:
	var resolved_value: float = p_value if 0.0 != p_value else p_data.magnitude
	if(StatusEffectData.MagnitudeKind.DamageMultiplier == p_data.magnitude_kind):
		return resolved_value - 1.0
	if(not IsAmplifiableKind(p_data.magnitude_kind)
			or StatusEffectData.MagnitudeKind.AttributePercentagePointAdd == p_data.magnitude_kind):
		return resolved_value
	var amplification: float = p_trait_riders.get(&"attribute_amplification", 0.0)
	if(StatusEffectData.MagnitudeKind.MaxHealthAttributePercent == p_data.magnitude_kind):
		return resolved_value + amplification
	if(StatusEffectData.MagnitudeKind.HighestBasePrimaryAttributePercent == p_data.magnitude_kind):
		var attribute: Types.Attribute = p_trait_riders.get(&"attribute", Types.Attribute.Health)
		return resolved_value + (0.0 if _IsCritAttribute(attribute) else amplification)
	if(p_data.attribute_modifiers.keys().all(_IsCritAttribute)):
		return resolved_value
	return resolved_value + amplification

static func AppliedAttributeAmplification(
			p_source_ID: int,
			p_characters: Dictionary[int, Character],
			p_sides: CombatSides) -> float:
	if(p_source_ID < 0 or not p_characters.has(p_source_ID)):
		return 0.0
	var side: CombatTeam = p_sides.AlliesOf(p_source_ID)
	if(null == side):
		return 0.0
	var amplification: float = 0.0
	for member_ID in side.AliveMembers(p_characters):
		var character: Character = p_characters[member_ID]
		for source: CharacterTrait in character.HookSources():
			amplification += source.GetAppliedAttributeAmplification()
	return amplification

## Fraction (e.g. Time Tithe) p_source_ID gains for itself when its own effect
## reduced enemy p_target_ID's turn bar by p_fraction (0.0 = no tithe).
static func TurnBarTithe(
			p_source_ID: int, p_target_ID: int, p_fraction: float,
			p_characters: Dictionary[int, Character], p_sides: CombatSides, p_resolver: BattleResolver) -> float:
	if(p_fraction >= 0.0 or p_source_ID < 0 or p_source_ID == p_target_ID
			or not p_sides.AreEnemies(p_source_ID, p_target_ID)):
		return 0.0
	var source_character: Character = p_characters[p_source_ID]
	var tithe: float = 0.0
	for active_trait: CharacterTrait in ActiveHooks(source_character, Types.Combat_Event.Enemy_Turn_Bar_Reduced):
		tithe += active_trait.OnEnemyTurnBarReduced(p_source_ID, -p_fraction, p_resolver)
	return tithe

## Notifies p_source_ID's own trait when its effect moved ally p_target_ID forward on
## the turn bar by p_fraction (e.g. Time Tithe granting Borrowed Time). The ally
## counterpart to TurnBarTithe: positive fraction, and the two must be allies rather
## than enemies.
static func DispatchAllyTurnBarIncreased(
			p_source_ID: int, p_target_ID: int, p_fraction: float,
			p_characters: Dictionary[int, Character], p_sides: CombatSides, p_resolver: BattleResolver) -> void:
	if(p_fraction <= 0.0 or p_source_ID < 0 or p_source_ID == p_target_ID
			or p_sides.AreEnemies(p_source_ID, p_target_ID)):
		return
	var source_character: Character = p_characters.get(p_source_ID)
	if(null == source_character):
		return
	for active_trait: CharacterTrait in ActiveHooks(source_character, Types.Combat_Event.Ally_Turn_Bar_Increased):
		active_trait.OnAllyTurnBarIncreased(p_source_ID, p_target_ID, p_fraction, p_resolver)

## Fires an applier's Debuff_Applied trait hook when their debuff lands on someone
## else — the applier-side counterpart to _EmitBuffApplied's target-side dispatch.
static func DispatchDebuffApplied(
							p_debuff: StatusEffects.Debuff,
							p_target_ID: int,
							p_characters: Dictionary[int, Character],
							p_resolver: BattleResolver) -> void:
	if(p_debuff.source_ID < 0 or not p_characters.has(p_debuff.source_ID)):
		return
	var applier: Character = p_characters[p_debuff.source_ID]
	if(applier._current_health <= 0):
		return
	for active_trait: CharacterTrait in ActiveHooks(applier, Types.Combat_Event.Debuff_Applied):
		active_trait.OnDebuffApplied(p_debuff.source_ID, p_target_ID, p_debuff, p_resolver)

static func ApplyActiveAttributeModifiers(
							p_character: Character,
							p_attributes: Dictionary[Types.Attribute, int],
							p_include_debuffs: bool = true) -> void:
	for buff in p_character._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and IsAttributeModifierKind(data.magnitude_kind)):
			ApplyAttributeModifiers(data, buff.value, p_attributes, buff.trait_riders)
	if(not p_include_debuffs):
		return
	for debuff in p_character._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null != data and IsAttributeModifierKind(data.magnitude_kind)):
			ApplyAttributeModifiers(data, debuff.value, p_attributes, debuff.trait_riders)

static func RollsCritical(p_crit_chance: int, p_random: RandomNumberGenerator) -> bool:
	return p_random.randi_range(1, 100) <= p_crit_chance

static func HasMaxStatusEffects(p_character: Character) -> bool:
	if(GameBalance.MAX_STATUS_EFFECTS <= p_character._active_buffs.size() + p_character._active_debuffs.size()):
		print(p_character._name, " cannot have any more status effects right now.")
		return true
	return false

## Unrounded core of MitigatedDamage, shared with any caller (Scripts/Debug/blowout_calibration.gd,
## Scripts/Debug/burst_reachability.gd) that composes this result further before rounding, so
## a chain of ceil(int(...)) roundings never accumulates a quantization artifact the real
## single-roll formula does not have.
static func MitigatedDamageUnrounded(
		p_effective_defence: float,
		p_caster_scaled_attribute_aggregate: float,
		p_crit_multiplier: float,
		p_random_value: float) -> float:
	var defence_ratio: float = (
			p_effective_defence / (p_effective_defence + GameBalance.DEFENCE_SCALE_CONSTANT))
	var mitigation_factor: float = (
			1.0 - ((1.0 - GameBalance.MINIMUM_DMG_PERCENT) * defence_ratio))
	return mitigation_factor * p_caster_scaled_attribute_aggregate * p_crit_multiplier * p_random_value

## Mitigated damage from a single attack roll against `p_effective_defence`; shared by
## the direct hit and any Shield-Wall-style redirected share, which re-mitigates the
## same roll against the soaker's own Defence. `p_caster_scaled_attribute_aggregate` is
## expected to already carry the Combined_Modifier (Concept_Document.md 1.1.3-1.1.4).
static func MitigatedDamage(
		p_effective_defence: float,
		p_caster_scaled_attribute_aggregate: float,
		p_crit_multiplier: float,
		p_random_value: float) -> int:
	return int(ceil(MitigatedDamageUnrounded(
			p_effective_defence, p_caster_scaled_attribute_aggregate, p_crit_multiplier, p_random_value)))

static func FindDamageRedirect(
		p_resolver: BattleResolver, p_caster_ID: int, p_target_ID: int) -> Array:
	if(not p_resolver.GetSides().AreEnemies(p_caster_ID, p_target_ID)):
		return [-1, 0.0]
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var status_redirect: Array = _FindStatusDamageRedirect(characters, p_target_ID)
	if(-1 != status_redirect[0]):
		return status_redirect
	for ally_ID in p_resolver.GetSides().AlliesOf(p_target_ID).AliveMembers(characters):
		if(ally_ID == p_target_ID):
			continue
		var ally: Character = characters[ally_ID]
		for active_trait: CharacterTrait in ActiveHooks(ally, Types.Combat_Event.Ally_Damage_Taken):
			var fraction: float = active_trait.OnAllyDamageTaken(ally_ID, p_target_ID, p_resolver)
			if(fraction > 0.0):
				return [ally_ID, fraction]
	return [-1, 0.0]

static func _FindStatusDamageRedirect(
		p_characters: Dictionary[int, Character], p_target_ID: int) -> Array:
	var target: Character = p_characters.get(p_target_ID)
	if(null == target):
		return [-1, 0.0]
	for buff in target._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null == data or data.damage_redirect_to_applier_fraction <= 0.0):
			continue
		var applier: Character = p_characters.get(buff.source_ID)
		if(null == applier or applier._current_health <= 0):
			continue
		return [buff.source_ID, data.damage_redirect_to_applier_fraction]
	return [-1, 0.0]
