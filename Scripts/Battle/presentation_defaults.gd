class_name PresentationDefaults extends RefCounted

## Resolves the effect a skill or a status plays. A skill's own presentation wins; otherwise
## one is derived from its effects, and null means the skill shows no effect.

const PHYSICAL_ATTRIBUTES: Array[Types.Attribute] = [
	Types.Attribute.Attack,
	Types.Attribute.Speed,
	Types.Attribute.Accuracy,
]


static func ForSkill(p_skill: Skill, p_archetypes: PresentationArchetypes) -> SkillPresentation:
	if(null != p_skill.presentation):
		return p_skill.presentation
	var archetype: PackedScene = _DerivedArchetype(p_skill, p_archetypes)
	if(null == archetype):
		return null
	var presentation: SkillPresentation = SkillPresentation.new()
	presentation.archetype = archetype
	return presentation


## The status's own effect, or the default status effect.
static func StatusArchetype(p_status: StatusEffectData, p_archetypes: PresentationArchetypes) -> PackedScene:
	if(null != p_status and null != p_status.effect_archetype):
		return p_status.effect_archetype
	return p_archetypes.status_effect


## The status's own variant; on the default status effect, one showing the status's icon.
static func StatusVariant(p_status: StatusEffectData) -> EffectVariant:
	if(null == p_status):
		return null
	if(null != p_status.effect_archetype):
		return p_status.effect_variant
	var variant: EffectVariant = EffectVariant.new()
	variant.texture = p_status.icon
	return variant


static func _DerivedArchetype(p_skill: Skill, p_archetypes: PresentationArchetypes) -> PackedScene:
	for effect: SkillEffect in p_skill.effects:
		var damage: DamageEffect = _Unwrapped(effect) as DamageEffect
		if(null != damage):
			return p_archetypes.physical_impact if _IsPhysical(damage) else p_archetypes.arcane_impact
	for effect: SkillEffect in p_skill.effects:
		var unwrapped: SkillEffect = _Unwrapped(effect)
		if(unwrapped is HealthChangeEffect and (unwrapped as HealthChangeEffect).fraction >= 0.0):
			return p_archetypes.heal
		if(unwrapped is BarrierEffect or unwrapped is BarrierZoneEffect):
			return p_archetypes.barrier
		if(unwrapped is ApplyBuffEffect):
			return p_archetypes.buff
		if(unwrapped is ApplyDebuffEffect):
			return p_archetypes.debuff
	return null


## An AlternatingEffect is categorised by its first alternate.
static func _Unwrapped(p_effect: SkillEffect) -> SkillEffect:
	var alternating: AlternatingEffect = p_effect as AlternatingEffect
	if(null != alternating and not alternating.effects.is_empty()):
		return alternating.effects[0]
	return p_effect


static func _IsPhysical(p_damage: DamageEffect) -> bool:
	var physical_weight: float = 0.0
	var other_weight: float = 0.0
	for attribute: Types.Attribute in p_damage.damage_scaling:
		if(PHYSICAL_ATTRIBUTES.has(attribute)):
			physical_weight += p_damage.damage_scaling[attribute]
		else:
			other_weight += p_damage.damage_scaling[attribute]
	return physical_weight >= other_weight
