class_name TriggerDebuffTicksEffect extends SkillEffect

## Forces every one of the effect's target(s)' currently active self-ticking debuffs to
## deal their tick damage again immediately, without losing a turn of duration.

func Resolve(p_context: SkillCastContext) -> void:
	var status_resolver: StatusEffectResolver = p_context.resolver.GetStatusResolver()
	for target_ID in p_context.TargetsFor(self):
		status_resolver.ForceExtraDebuffTick(target_ID)
