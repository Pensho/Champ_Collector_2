class_name HealthTransferResolver extends RefCounted

## Resolves Skill.health_change (a signed max-Health-fraction transfer) and
## Skill.heal_scaling (attribute-scaled healing). Holds a back-reference to its owning
## BattleResolver for the shared batch/emit/snapshot services these steps need,
## mirroring ZoneResolver and StatusEffectResolver.

var _resolver: BattleResolver

func _init(p_resolver: BattleResolver) -> void:
	_resolver = p_resolver

func ResolveHealthCosts(p_caster_ID: int, p_target_IDs: Array[int], p_skill: Skill) -> int:
	var caster_paid: int = 0
	for target_type in p_skill.health_change.keys():
		var fraction: float = p_skill.health_change[target_type]
		if(fraction >= 0.0):
			continue
		var targets: Array[int] = SkillCastContext.ResolveStatusGroupTargets(
				_resolver, p_caster_ID, p_target_IDs, p_skill, target_type)
		for target_ID in targets:
			var requested: int = int(round(_resolver._MaxHealth(_resolver._characters[target_ID]) * -fraction))
			var paid: int = _resolver.ResolveHealthCost(target_ID, requested)
			if(target_ID == p_caster_ID):
				caster_paid = paid
	return caster_paid

func ResolveHealthGains(
		p_caster_ID: int,
		p_target_IDs: Array[int],
		p_skill: Skill,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> void:
	for target_type in p_skill.health_change.keys():
		var fraction: float = p_skill.health_change[target_type]
		if(fraction <= 0.0):
			continue
		var targets: Array[int] = SkillCastContext.ResolveStatusGroupTargets(
				_resolver, p_caster_ID, p_target_IDs, p_skill, target_type)
		for target_ID in targets:
			var requested: int = int(round(_resolver._MaxHealth(_resolver._characters[target_ID]) * fraction))
			_resolver.ResolveHealthGain(target_ID, requested)

	for target_type in p_skill.heal_scaling.keys():
		var scaling: Dictionary = p_skill.heal_scaling[target_type]
		var requested: int = 0
		for attribute: Types.Attribute in scaling.keys():
			requested += int(round(float(scaling[attribute]) * float(p_caster_attributes[attribute])))
		var heal_targets: Array[int] = SkillCastContext.ResolveStatusGroupTargets(
				_resolver, p_caster_ID, p_target_IDs, p_skill, target_type)
		for target_ID in heal_targets:
			_resolver.ResolveHealthGain(target_ID, requested)
