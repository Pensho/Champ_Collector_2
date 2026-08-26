class_name TriggerDebuffTicksEffect extends SkillEffect

## Forces every one of the effect's target(s)' currently active self-ticking debuffs to
## deal their tick damage again immediately, without losing a turn of duration.

func Resolve(p_context: SkillCastContext) -> void:
	var cascade: CascadeResolver = p_context.resolver.GetCascadeResolver()
	for target_ID in p_context.TargetsFor(self):
		var event: CascadeEvent = CascadeEvent.new(Types.Cascade_Trigger.Debuff_Tick_Forced)
		event.subject_ID = target_ID
		event.origin_ID = p_context.caster_ID
		cascade.Post(event)
