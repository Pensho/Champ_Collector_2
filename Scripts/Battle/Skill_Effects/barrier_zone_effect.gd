class_name BarrierZoneEffect extends SkillEffect

## Grants the Architect's charge-scaled turn-bar Barrier (Raise the Frame). Reuses
## Skills.ApplyBarrierZone rather than the generic BarrierEffect so the Calibration
## trait's charge-investment bonus and its Zone_Used charge-grant hook stay intact.
## It reads zone_strength_multiplier — not a Barrier's own scaling, but the scalar a
## repeat resolution of the whole zone carries (ZoneResolver.ResolveZoneEffectEcho), which
## the Barrier owes the same as a damage zone owes its own. zone_damage_multiplier is
## DamageEffect-only, so a Barrier no longer inherits Sorcerer damage amplification.

func Resolve(p_context: SkillCastContext) -> void:
	for target_ID in p_context.TargetsFor(self):
		Skills.ApplyBarrierZone(p_context.resolver, p_context.caster_ID, p_context.zone_ID,
				p_context.caster_attributes.get(Types.Attribute.Knowledge, 0), target_ID,
				p_context.zone_strength_multiplier)
