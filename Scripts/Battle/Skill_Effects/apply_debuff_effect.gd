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
		status_resolver.CastDebuff(target_ID, debuff, p_context.caster_ID,
				p_context.trait_result._tick_bonus_per_debuff, true, true)
