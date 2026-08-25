class_name ApplyBuffEffect extends SkillEffect

## Applies a single buff type to the effect's target group, carrying its own duration
## (a buff_duration_overrides entry is now just a second ApplyBuffEffect for the same
## buff group with a different duration).

@export var buff_type: Types.Buff_Type = Types.Buff_Type.Invalid
@export var duration: int = 0

func Resolve(p_context: SkillCastContext) -> void:
	var status_resolver: StatusEffectResolver = p_context.resolver.GetStatusResolver()
	for target_ID in p_context.TargetsFor(self):
		var buff: StatusEffects.Buff = StatusEffects.Buff.new()
		buff.type = buff_type
		buff.duration = duration
		buff.name = Types.Buff_Type.keys()[buff_type]
		buff.source_ID = p_context.caster_ID
		buff.trait_riders = p_context.trait_result._trait_riders
		var caster: Character = p_context.resolver.GetCharacters()[p_context.caster_ID]
		var value_override: float = Skills.AppliedBuffValue(
				caster, p_context.caster_ID, target_ID, buff_type, p_context.resolver)
		if(value_override >= 0.0):
			buff.value = value_override
		if(p_context.is_zone_trigger):
			var data: StatusEffectData = StatusEffectRegistry.BuffData(buff_type)
			if(null != data):
				buff.value = data.magnitude * p_context.zone_magnitude
			var results: Array[CombatResult] = status_resolver.ApplyBuff(target_ID, buff)
			p_context.status_effect_attempted = true
			if(results.any(func(r: CombatResult) -> bool: return CombatResult.Kind.Status_Effect_Denied != r.kind)):
				p_context.status_effect_landed = true
		else:
			status_resolver.ApplyBuff(target_ID, buff)
