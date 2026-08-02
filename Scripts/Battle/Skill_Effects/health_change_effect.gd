class_name HealthChangeEffect extends SkillEffect

## Signed max-Health-fraction transfer plus optional attribute-scaled healing. A
## negative fraction is a Health cost (authored early, in the costs phase, and written
## to context.health_paid for a following BarrierEffect); a non-negative fraction plus
## scaling is a heal (authored late, in the heals phase).

@export var fraction: float = 0.0
@export var scaling: Dictionary[Types.Attribute, float]

func Resolve(p_context: SkillCastContext) -> void:
	var resolver: BattleResolver = p_context.resolver
	for target_ID in p_context.TargetsFor(self):
		if(fraction < 0.0):
			var requested: int = int(round(resolver.GetMaxHealth(target_ID) * -fraction))
			var paid: int = resolver.ResolveHealthCost(target_ID, requested)
			if(target_ID == p_context.caster_ID):
				p_context.health_paid = paid
		else:
			var requested: int = int(round(resolver.GetMaxHealth(target_ID) * fraction))
			for attribute: Types.Attribute in scaling.keys():
				requested += int(round(float(scaling[attribute]) * float(p_context.caster_attributes[attribute])))
			if(requested > 0):
				resolver.ResolveHealthGain(target_ID, requested)
