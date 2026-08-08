class_name ApplyDebuffEffect extends SkillEffect

## Applies a single debuff type to the effect's target group, carrying its own duration.

@export var debuff_type: Types.Debuff_Type = Types.Debuff_Type.Invalid
@export var duration: int = 0

func Resolve(p_context: SkillCastContext) -> void:
	var status_resolver: StatusEffectResolver = p_context.resolver.GetStatusResolver()
	for target_ID in p_context.TargetsFor(self):
		var debuff: StatusEffects.Debuff = StatusEffects.Debuff.new()
		debuff.type = debuff_type
		debuff.duration = duration
		var caster_trait: CharacterTrait = p_context.resolver.GetCharacters()[p_context.caster_ID]._trait
		if(null != caster_trait):
			var value_override: float = caster_trait.GetAppliedStatusValue(
					p_context.caster_ID, target_ID, debuff_type, p_context.resolver)
			if(value_override >= 0.0):
				debuff.value = value_override
		if(p_context.is_zone_trigger):
			debuff.source_ID = p_context.caster_ID
			if(0.0 == debuff.value):
				var data: StatusEffectData = StatusEffectRegistry.DebuffData(debuff_type)
				debuff.value = (status_resolver._SnapshotStatusValue(data, p_context.caster_ID, target_ID)
						* p_context.zone_magnitude)
			var results: Array[CombatResult] = status_resolver.ApplyDebuff(target_ID, debuff)
			p_context.status_effect_attempted = true
			if(results.any(func(r: CombatResult) -> bool: return CombatResult.Kind.Status_Effect_Denied != r.kind)):
				p_context.status_effect_landed = true
		else:
			status_resolver.CastDebuff(target_ID, debuff, p_context.caster_ID,
					p_context.trait_result._repeats_tick_per_distinct_debuff, true, true)
