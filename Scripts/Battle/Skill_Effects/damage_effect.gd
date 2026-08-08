class_name DamageEffect extends SkillEffect

## Deals damage_scaling-scaled damage to the effect's target group, contributing to the
## Combined_Modifier multiplicative channel (Concept_Document.md 1.1.3-1.1.4). bonus_per's
## Uses_This_Battle source ramps the pre-mitigation aggregate (a bucket of its own,
## improving Defence penetration as the skill grows); every other bonus_per source sums
## into one bucket keyed to this skill (or, in zone-trigger mode, to the triggering
## zone's source); bonus_per_debuff_on_target contributes one independent bucket per
## debuff type present on the target. See Technical Design Document 7.4.

@export var damage_scaling: Dictionary[Types.Attribute, float]
@export var defense_ignore_factor: float = 1.0
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
		combined_damage_modifier.Contribute(_SkillKey(p_context), _SkillCountBonus(p_context, target_ID))
		_ContributeDebuffFactors(p_context, target_ID, combined_damage_modifier)
		p_context.resolver.ResolveEffectDamage(p_context.caster_ID, target_ID, p_context.caster_attributes,
				damage_scaling, defense_ignore_factor, combined_damage_modifier, allow_critical)

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
	match p_source:
		Types.Trait_Count_Source.Buffs_On_Caster:
			return float(p_context.resolver.GetCharacters()[p_context.caster_ID]._active_buffs.size())
		Types.Trait_Count_Source.Buffs_Consumed:
			return float(p_context.buffs_consumed)
		Types.Trait_Count_Source.Zones_On_Turn_Bar:
			return float(p_context.resolver.GetZoneResolver().GetZones().size())
		Types.Trait_Count_Source.Trait_Condition, Types.Trait_Count_Source.Trait_Counter_On_Target, \
				Types.Trait_Count_Source.Trait_Counter_Raw_On_Target:
			return _TraitCount(p_context, p_target_ID, p_source)
		Types.Trait_Count_Source.Target_Debuff_Count:
			return float(_DistinctDebuffTypeCount(p_context, p_target_ID))
		_:
			return 0.0

func _DistinctDebuffTypeCount(p_context: SkillCastContext, p_target_ID: int) -> int:
	var target_character: Character = p_context.resolver.GetCharacters().get(p_target_ID)
	if(null == target_character):
		return 0
	var distinct_types: Dictionary[Types.Debuff_Type, bool] = {}
	for debuff in target_character._active_debuffs:
		distinct_types[debuff.type] = true
	return distinct_types.size()

func _TraitCount(p_context: SkillCastContext, p_target_ID: int, p_source: Types.Trait_Count_Source) -> float:
	var caster_trait: CharacterTrait = p_context.resolver.GetCharacters()[p_context.caster_ID]._trait
	if(null == caster_trait):
		return 0.0
	return caster_trait.GetConditionCount(p_context.caster_ID, p_target_ID, p_source, p_context.resolver)
