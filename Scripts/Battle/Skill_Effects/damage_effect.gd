class_name DamageEffect extends SkillEffect

## Deals damage_scaling-scaled damage to the effect's target group. bonus_per sources a
## fraction × count damage bonus per Types.Damage_Bonus_Source; Uses_This_Battle scales
## the pre-mitigation damage aggregate (a ramp, improving Defence penetration as the
## skill grows), every other source adds to the final damage bonus alongside the
## battle-persistent damage-dealt bonus. See Technical Design Document 7.4.

@export var damage_scaling: Dictionary[Types.Attribute, float]
@export var defense_ignore_factor: float = 1.0
@export var bonus_per: Dictionary[Types.Damage_Bonus_Source, float]
@export var allow_critical: bool = true

func Resolve(p_context: SkillCastContext) -> void:
	var ramp_multiplier: float = _RampMultiplier(p_context)
	for target_ID in p_context.TargetsFor(self):
		var bonus: float = _AdditiveBonus(p_context, target_ID)
		p_context.resolver.ResolveEffectDamage(p_context.caster_ID, target_ID, p_context.caster_attributes,
				damage_scaling, defense_ignore_factor, p_context.trait_result._damage_multiplier,
				allow_critical, ramp_multiplier, bonus)

func _RampMultiplier(p_context: SkillCastContext) -> float:
	var per_use: float = bonus_per.get(Types.Damage_Bonus_Source.Uses_This_Battle, 0.0)
	if(0.0 == per_use):
		return 1.0
	return 1.0 + per_use * float(p_context.use_count)

func _AdditiveBonus(p_context: SkillCastContext, p_target_ID: int) -> float:
	var bonus: float = 0.0
	for source: Types.Damage_Bonus_Source in bonus_per.keys():
		if(Types.Damage_Bonus_Source.Uses_This_Battle == source):
			continue
		bonus += bonus_per[source] * _Count(p_context, p_target_ID, source)
	return bonus

func _Count(p_context: SkillCastContext, p_target_ID: int, p_source: Types.Damage_Bonus_Source) -> float:
	match p_source:
		Types.Damage_Bonus_Source.Buffs_On_Caster:
			return float(p_context.resolver.GetCharacters()[p_context.caster_ID]._active_buffs.size())
		Types.Damage_Bonus_Source.Buffs_Consumed:
			return float(p_context.buffs_consumed)
		Types.Damage_Bonus_Source.Trait_Condition, Types.Damage_Bonus_Source.Trait_Counter_On_Target:
			return _TraitCount(p_context, p_target_ID, p_source)
		_:
			return 0.0

func _TraitCount(p_context: SkillCastContext, p_target_ID: int, p_source: Types.Damage_Bonus_Source) -> float:
	var caster_trait: CharacterTrait = p_context.resolver.GetCharacters()[p_context.caster_ID]._trait
	if(null == caster_trait):
		return 0.0
	return caster_trait.GetConditionCount(p_context.caster_ID, p_target_ID, p_source, p_context.resolver)
