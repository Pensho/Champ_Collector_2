class_name Skills
extends Node

## Stateless combat helpers: targeting, zone-target checks, status-effect rules, and
## attribute-snapshot modifiers. Everything stateful (Heap-On stacks, damage
## multipliers, status application, damage rolls) lives on BattleResolver.

const ZoneType = preload("uid://bdjrfif0s60v4")

static func ZoneMagnitude(p_base: float, p_owner_knowledge: int) -> float:
	return p_base * (1.0 + p_owner_knowledge * Game_Balance.ZONE_KNOWLEDGE_SCALING)

static func ActiveHook(p_character: Character, p_event: Types.Combat_Event) -> CharacterTrait:
	if(null != p_character and null != p_character._trait
			and p_character._trait._execution_steps.has(p_event)):
		return p_character._trait
	return null

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
	var active_trait: CharacterTrait = ActiveHook(zone_owner, Types.Combat_Event.Zone_Used)
	if(null != active_trait):
		active_trait.OnZoneUsed(p_zone_owner_ID, p_user_ID, p_resolver)

static func TriggerZoneConstructedHook(
		p_characters: Dictionary[int, Character],
		p_zone_owner_ID: int,
		p_zone_ID: int,
		p_resolver: BattleResolver) -> void:
	var zone_owner: Character = p_characters.get(p_zone_owner_ID)
	var active_trait: CharacterTrait = ActiveHook(zone_owner, Types.Combat_Event.Zone_Constructed)
	if(null != active_trait):
		active_trait.OnZoneConstructed(p_zone_owner_ID, p_zone_ID, p_resolver)

static func ApplyBarrierZone(
		p_resolver: BattleResolver,
		p_zone_owner_ID: int,
		p_zone_ID: int,
		p_owner_knowledge: int,
		p_character_ID: int) -> void:
	var characters: Dictionary[int, Character] = p_resolver.GetCharacters()
	var zone_owner: Character = characters.get(p_zone_owner_ID)
	var charge_bonus: float = 0.0
	if(null != zone_owner and null != zone_owner._trait):
		charge_bonus = zone_owner._trait.GetZoneChargeBonus(p_zone_ID)
	p_resolver.GetStatusResolver().ApplyBuff(p_character_ID, MakeBarrierZoneBuff(p_owner_knowledge, charge_bonus))
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

## Applies a debuff's Field-of-Study weakness rider, if any, wherever the debuff's own
## attribute snapshot is taken — independent of the carrying debuff's own magnitude_kind.
static func ApplyWeaknessRider(
							p_debuff: StatusEffects.Debuff,
							p_attributes: Dictionary[Types.Attribute, int]) -> void:
	if(not p_debuff.has_weakness_rider):
		return
	var attribute: Types.Attribute = p_debuff.weakness_attribute
	p_attributes[attribute] -= int(ceilf(p_attributes[attribute] * p_debuff.weakness_reduction))

## Fraction (e.g. Chronophage's Time Tithe) p_source_ID gains for itself when its own
## effect reduced enemy p_target_ID's turn bar by p_fraction (0.0 = no tithe).
static func TurnBarTithe(
			p_source_ID: int, p_target_ID: int, p_fraction: float,
			p_characters: Dictionary[int, Character], p_sides: CombatSides, p_resolver: BattleResolver) -> float:
	if(p_fraction >= 0.0 or p_source_ID < 0 or p_source_ID == p_target_ID
			or not p_sides.AreEnemies(p_source_ID, p_target_ID)):
		return 0.0
	var source: Character = p_characters[p_source_ID]
	var active_trait: CharacterTrait = ActiveHook(source, Types.Combat_Event.Enemy_Turn_Bar_Reduced)
	if(null == active_trait):
		return 0.0
	return active_trait.OnEnemyTurnBarReduced(p_source_ID, -p_fraction, p_resolver)

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
	var active_trait: CharacterTrait = ActiveHook(applier, Types.Combat_Event.Debuff_Applied)
	if(null != active_trait):
		active_trait.OnDebuffApplied(p_debuff.source_ID, p_target_ID, p_debuff, p_resolver)

static func ApplyActiveAttributeModifiers(
							p_character: Character,
							p_attributes: Dictionary[Types.Attribute, int]) -> void:
	for buff in p_character._active_buffs:
		var data: StatusEffectData = StatusEffectRegistry.BuffData(buff.type)
		if(null != data and IsAttributeModifierKind(data.magnitude_kind)):
			ApplyAttributeModifiers(data, buff.value, p_attributes)
	for debuff in p_character._active_debuffs:
		var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff.type)
		if(null != data and IsAttributeModifierKind(data.magnitude_kind)):
			ApplyAttributeModifiers(data, debuff.value, p_attributes)
		ApplyWeaknessRider(debuff, p_attributes)

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
	var damage_ratio: float = (
			p_caster_scaled_attribute_aggregate
			/ (p_effective_defence + p_caster_scaled_attribute_aggregate + 1.0))
	var mitigation_factor: float = (
			GameBalance.MINIMUM_DMG_PERCENT + ((1.0 - GameBalance.MINIMUM_DMG_PERCENT) * damage_ratio))
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
		var active_trait: CharacterTrait = ActiveHook(ally, Types.Combat_Event.Ally_Damage_Taken)
		if(null == active_trait):
			continue
		var fraction: float = active_trait.OnAllyDamageTaken(ally_ID, p_target_ID, p_resolver)
		if(fraction > 0.0):
			return [ally_ID, fraction]
	return [-1, 0.0]
