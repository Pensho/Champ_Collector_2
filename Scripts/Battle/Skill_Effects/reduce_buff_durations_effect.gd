class_name ReduceBuffDurationsEffect extends SkillEffect

## Shaves amount turns off every buff already on the effect's target group.

@export var amount: int = 0

func Resolve(p_context: SkillCastContext) -> void:
	var status_resolver: StatusEffectResolver = p_context.resolver.GetStatusResolver()
	for target_ID in p_context.TargetsFor(self):
		status_resolver.ReduceBuffDurations(target_ID, amount, p_context.caster_ID)
