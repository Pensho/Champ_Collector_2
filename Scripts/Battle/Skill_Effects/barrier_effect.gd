class_name BarrierEffect extends SkillEffect

## Grants a Barrier sized as a fraction of one source value: the Health the caster paid
## this cast (see health_paid), or the recipient's own max Health.

enum Source { Health_Paid, Target_Max_Health }

@export var source: Source = Source.Health_Paid
@export var fraction: float = 0.0
@export var duration: int = 0

func Resolve(p_context: SkillCastContext) -> void:
	var resolver: BattleResolver = p_context.resolver
	var status_resolver: StatusEffectResolver = resolver.GetStatusResolver()
	var caster_trait: CharacterTrait = resolver.GetCharacters()[p_context.caster_ID]._trait
	var restoration_multiplier: float = (caster_trait.GetOutgoingRestorationMultiplier(p_context.caster_ID, resolver)
			if null != caster_trait else 1.0)
	for target_ID in p_context.TargetsFor(self):
		var base: float = (float(p_context.health_paid) if Source.Health_Paid == source
				else float(resolver.GetMaxHealth(target_ID)))
		var value: float = base * fraction * restoration_multiplier
		if(value <= 0.0):
			# ApplyBuff treats an explicit value of 0.0 as "no value given" and falls back
			# to the registry's default magnitude; skip entirely rather than grant that.
			continue
		var barrier: StatusEffects.Buff = StatusEffects.Buff.new()
		barrier.type = Types.Buff_Type.Barrier
		barrier.name = "Barrier"
		barrier.duration = duration
		barrier.value = value
		status_resolver.ApplyBuff(target_ID, barrier)
