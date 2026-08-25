class_name DamageEffect extends SkillEffect

## Deals damage_scaling-scaled damage to the effect's target group, contributing to the
## Combined_Modifier multiplicative channel (Concept_Document.md 1.1.3-1.1.4). bonus_per's
## Uses_This_Battle source ramps the pre-mitigation aggregate (a bucket of its own,
## improving Defence penetration as the skill grows); every other bonus_per source sums
## into one bucket keyed to this skill (or, in zone-trigger mode, to the triggering
## zone's source); bonus_per_debuff_on_target contributes one independent bucket per
## debuff type present on the target. See Technical Design Document 7.4.

@export var damage_scaling: Dictionary[Types.Attribute, float]
@export var defence_ignore_factor: float = 1.0
## A multiple of the caster's own base-referenced Defence-ignore rate (Between the Plates),
## never a rate of its own — 1.0 means "carry the passive's rate unmodified." A caster with
## no declared rate contributes no ignore regardless of this value. Independent of
## defence_ignore_factor above: this subtracts points from a debuff-free reference Defence, so
## a teammate's Defence debuff is never eaten by the caster's own bypass.
@export var defence_ignore_multiple: float = 1.0
@export var bonus_per: Dictionary[Types.Trait_Count_Source, float]
## Per-target bonus, one multiplying bucket per debuff type currently on the target —
## distinct from bonus_per because the source is a debuff type, not a Trait_Count_Source.
@export var bonus_per_debuff_on_target: Dictionary[Types.Debuff_Type, float]
@export var allow_critical: bool = true

func Resolve(p_context: SkillCastContext) -> void:
	var ramp_multiplier: float = _RampMultiplier(p_context)
	for target_ID in p_context.TargetsFor(self):
		var combined_damage_modifier: CombinedDamageModifier = CombinedDamageModifier.new()
		if(1.0 != ramp_multiplier):
			combined_damage_modifier.Contribute(_RampKey(p_context), ramp_multiplier - 1.0)
		if(1.0 != p_context.trait_result._damage_multiplier):
			combined_damage_modifier.Contribute(
					CombinedDamageModifier.TRAIT_RESOURCE_KEY, p_context.trait_result._damage_multiplier - 1.0)
		if(0.0 != p_context.repeat_bonus):
			combined_damage_modifier.Contribute(_RepeatKey(p_context), p_context.repeat_bonus)
		if(p_context.is_zone_trigger and 1.0 != p_context.zone_damage_multiplier):
			combined_damage_modifier.Contribute(_AmplifiedKey(p_context), p_context.zone_damage_multiplier - 1.0)
		if(p_context.is_zone_trigger and 1.0 != p_context.zone_strength_multiplier):
			combined_damage_modifier.Contribute(_StrengthKey(p_context), p_context.zone_strength_multiplier - 1.0)
		combined_damage_modifier.Contribute(_SkillKey(p_context), _SkillCountBonus(p_context, target_ID))
		_ContributeDebuffFactors(p_context, target_ID, combined_damage_modifier)
		p_context.resolver.ResolveEffectDamage(p_context.caster_ID, target_ID, p_context.caster_attributes,
				damage_scaling, defence_ignore_multiple, combined_damage_modifier, _AllowCritical(p_context),
				defence_ignore_factor)

func _AllowCritical(p_context: SkillCastContext) -> bool:
	if(not allow_critical or p_context.is_zone_trigger or null == p_context.skill):
		return allow_critical
	var caster: Character = p_context.resolver.GetCharacters().get(p_context.caster_ID)
	return not Skills.OwnCriticalHitSuppressed(caster, p_context.caster_ID, p_context.skill.name)

func _RampMultiplier(p_context: SkillCastContext) -> float:
	var per_use: float = bonus_per.get(Types.Trait_Count_Source.Uses_This_Battle, 0.0)
	if(0.0 == per_use):
		return 1.0
	return 1.0 + per_use * float(p_context.use_count)

## The skill (or, in zone-trigger mode where there is no cast Skill, the triggering
## zone's source) this effect belongs to — the mechanic identity its non-ramp bonus_per
## contributions share.
func _SkillKey(p_context: SkillCastContext) -> StringName:
	if(p_context.is_zone_trigger):
		if("" == p_context.zone_source_name):
			return &"Zone"
		return StringName("Zone: %s" % p_context.zone_source_name)
	return StringName(p_context.skill.name)

func _RampKey(p_context: SkillCastContext) -> StringName:
	return StringName("%s (ramp)" % _SkillKey(p_context))

func _RepeatKey(p_context: SkillCastContext) -> StringName:
	return StringName("%s (repeat)" % _SkillKey(p_context))

func _StrengthKey(p_context: SkillCastContext) -> StringName:
	return StringName("%s (strength)" % _SkillKey(p_context))

func _AmplifiedKey(p_context: SkillCastContext) -> StringName:
	return StringName("%s (amplified)" % _SkillKey(p_context))

func _SkillCountBonus(p_context: SkillCastContext, p_target_ID: int) -> float:
	var bonus: float = 0.0
	for source: Types.Trait_Count_Source in bonus_per.keys():
		if(Types.Trait_Count_Source.Uses_This_Battle == source):
			continue
		bonus += bonus_per[source] * _Count(p_context, p_target_ID, source)
	return bonus

func _ContributeDebuffFactors(
		p_context: SkillCastContext, p_target_ID: int, p_combined_damage_modifier: CombinedDamageModifier) -> void:
	for debuff_type: Types.Debuff_Type in bonus_per_debuff_on_target.keys():
		if(_TargetHasDebuff(p_context, p_target_ID, debuff_type)):
			p_combined_damage_modifier.Contribute(
					StringName(Types.Debuff_Type.keys()[debuff_type]), bonus_per_debuff_on_target[debuff_type])

func _TargetHasDebuff(p_context: SkillCastContext, p_target_ID: int, p_debuff_type: Types.Debuff_Type) -> bool:
	var target_character: Character = p_context.resolver.GetCharacters().get(p_target_ID)
	if(null == target_character):
		return false
	for debuff in target_character._active_debuffs:
		if(p_debuff_type == debuff.type):
			return true
	return false

func _Count(p_context: SkillCastContext, p_target_ID: int, p_source: Types.Trait_Count_Source) -> float:
	var count: float = 0.0
	match p_source:
		Types.Trait_Count_Source.Buffs_On_Caster:
			count = float(p_context.resolver.GetCharacters()[p_context.caster_ID]._active_buffs.size())
		Types.Trait_Count_Source.Buffs_Consumed:
			count = float(p_context.buffs_consumed)
		Types.Trait_Count_Source.Zones_On_Turn_Bar:
			count = float(p_context.resolver.GetZoneResolver().GetZones().size())
		Types.Trait_Count_Source.Trait_Condition, Types.Trait_Count_Source.Trait_Counter_On_Target, \
				Types.Trait_Count_Source.Trait_Counter_Raw_On_Target, \
				Types.Trait_Count_Source.Turn_Bar_Section_Span:
			count = _TraitCount(p_context, p_target_ID, p_source)
		Types.Trait_Count_Source.Target_Debuff_Count:
			count = float(_DistinctDebuffTypeCount(p_context, p_target_ID))
		Types.Trait_Count_Source.Wounded_Allies:
			count = float(_WoundedAllyCount(p_context))
	return count

func _DistinctDebuffTypeCount(p_context: SkillCastContext, p_target_ID: int) -> int:
	var target_character: Character = p_context.resolver.GetCharacters().get(p_target_ID)
	if(null == target_character):
		return 0
	var distinct_types: Dictionary[Types.Debuff_Type, bool] = {}
	for debuff in target_character._active_debuffs:
		distinct_types[debuff.type] = true
	return distinct_types.size()

## Living allies of the caster, caster excluded, currently below half their own max Health.
func _WoundedAllyCount(p_context: SkillCastContext) -> int:
	var resolver: BattleResolver = p_context.resolver
	var characters: Dictionary[int, Character] = resolver.GetCharacters()
	var count: int = 0
	for ally_ID in resolver.GetSides().AlliesOf(p_context.caster_ID).AliveMembers(characters):
		if(ally_ID == p_context.caster_ID):
			continue
		var max_health: int = resolver.GetMaxHealth(ally_ID)
		if(max_health <= 0):
			continue
		if(float(characters[ally_ID]._current_health) / float(max_health) < 0.5):
			count += 1
	return count

func _TraitCount(p_context: SkillCastContext, p_target_ID: int, p_source: Types.Trait_Count_Source) -> float:
	var caster: Character = p_context.resolver.GetCharacters()[p_context.caster_ID]
	var count: float = 0.0
	for source: CharacterTrait in caster.HookSources():
		count += source.GetConditionCount(p_context.caster_ID, p_target_ID, p_source, p_context.resolver)
	return count
