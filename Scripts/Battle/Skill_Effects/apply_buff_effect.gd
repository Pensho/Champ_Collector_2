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
		status_resolver.ApplyBuff(target_ID, buff)
