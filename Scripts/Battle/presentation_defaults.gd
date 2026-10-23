class_name PresentationDefaults extends RefCounted

## Resolves the presentation a skill, a skill echo or a status echo plays. A skill's own
## presentation wins; otherwise one is derived from its effects. Null means release the
## results immediately.

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


## Returns a presentation carrying only the echo's archetype and variant.
static func ForSkillEcho(p_skill: Skill, p_archetypes: PresentationArchetypes) -> SkillPresentation:
	var skill_presentation: SkillPresentation = ForSkill(p_skill, p_archetypes)
	var echo: SkillPresentation = SkillPresentation.new()
	if(null != skill_presentation and null != skill_presentation.echo_archetype):
		echo.archetype = skill_presentation.echo_archetype
		echo.variant = skill_presentation.echo_variant
	elif(null != skill_presentation):
		echo.archetype = skill_presentation.archetype
		echo.variant = skill_presentation.variant
	else:
		echo.archetype = p_archetypes.echo_pulse
	return echo if null != echo.archetype else null


## Returns a presentation carrying only the echo's archetype and variant.
static func ForStatusEcho(
		p_status: StatusEffectData, p_archetypes: PresentationArchetypes) -> SkillPresentation:
	var echo: SkillPresentation = SkillPresentation.new()
	if(null != p_status and null != p_status.echo_archetype):
		echo.archetype = p_status.echo_archetype
		echo.variant = p_status.echo_variant
	else:
		echo.archetype = p_archetypes.echo_pulse
		echo.variant = EffectVariant.new()
		echo.variant.texture = p_status.icon if null != p_status else null
	return echo if null != echo.archetype else null


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
