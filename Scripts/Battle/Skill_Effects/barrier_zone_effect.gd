class_name BarrierZoneEffect extends SkillEffect

## Grants the Architect's charge-scaled turn-bar Barrier (Raise the Frame). Reuses
## Skills.ApplyBarrierZone rather than the generic BarrierEffect so the Calibration
## trait's charge-investment bonus and its Zone_Used charge-grant hook stay intact.

func Resolve(p_context: SkillCastContext) -> void:
	for target_ID in p_context.TargetsFor(self):
		Skills.ApplyBarrierZone(p_context.resolver, p_context.caster_ID, p_context.zone_ID,
				p_context.caster_attributes.get(Types.Attribute.Knowledge, 0), target_ID)
