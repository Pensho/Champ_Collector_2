extends GutTest

# A skill without its own presentation falls back on a shared archetype picked from its
# effects; echoes fall back on the skill's own look or the generic echo pulse.

var _archetypes: PresentationArchetypes

func before_each() -> void:
	_archetypes = PresentationArchetypes.new()
	_archetypes.physical_impact = PackedScene.new()
	_archetypes.arcane_impact = PackedScene.new()
	_archetypes.heal = PackedScene.new()
	_archetypes.barrier = PackedScene.new()
	_archetypes.buff = PackedScene.new()
	_archetypes.debuff = PackedScene.new()
	_archetypes.echo_pulse = PackedScene.new()

func _skill(p_effects: Array[SkillEffect]) -> Skill:
	var skill: Skill = Skill.new()
	skill.effects = p_effects
	return skill

func _damage(p_scaling: Dictionary[Types.Attribute, float]) -> DamageEffect:
	var effect: DamageEffect = DamageEffect.new()
	effect.damage_scaling = p_scaling
	return effect

func _heal() -> HealthChangeEffect:
	var effect: HealthChangeEffect = HealthChangeEffect.new()
	effect.fraction = 0.15
	return effect

func _archetype_for(p_effects: Array[SkillEffect]) -> PackedScene:
	var presentation: SkillPresentation = PresentationDefaults.ForSkill(_skill(p_effects), _archetypes)
	return presentation.archetype if null != presentation else null

func test_attack_scaled_damage_picks_the_physical_impact() -> void:
	assert_eq(_archetype_for([_damage({Types.Attribute.Attack: 1.0})]), _archetypes.physical_impact)

func test_mysticism_scaled_damage_picks_the_arcane_impact() -> void:
	assert_eq(_archetype_for([_damage({Types.Attribute.Mysticism: 1.2})]), _archetypes.arcane_impact)

func test_heal_barrier_buff_and_debuff_pick_their_categories() -> void:
	var barrier: BarrierEffect = BarrierEffect.new()
	assert_eq(_archetype_for([_heal()]), _archetypes.heal)
	assert_eq(_archetype_for([barrier]), _archetypes.barrier)
	assert_eq(_archetype_for([ApplyBuffEffect.new()]), _archetypes.buff)
	assert_eq(_archetype_for([ApplyDebuffEffect.new()]), _archetypes.debuff)

func test_damage_wins_over_an_earlier_debuff() -> void:
	assert_eq(_archetype_for([ApplyDebuffEffect.new(), _damage({Types.Attribute.Mysticism: 1.2})]),
			_archetypes.arcane_impact)

func test_without_damage_the_first_categorised_effect_wins() -> void:
	assert_eq(_archetype_for([ApplyBuffEffect.new(), _heal()]), _archetypes.buff)

func test_a_health_cost_is_not_a_heal() -> void:
	var cost: HealthChangeEffect = HealthChangeEffect.new()
	cost.fraction = -0.1
	assert_eq(_archetype_for([cost]), null)

func test_an_explicit_presentation_wins() -> void:
	var skill: Skill = _skill([_damage({Types.Attribute.Attack: 1.0})])
	skill.presentation = SkillPresentation.new()
	assert_eq(PresentationDefaults.ForSkill(skill, _archetypes), skill.presentation)

func test_an_unbuilt_archetype_means_no_presentation() -> void:
	_archetypes.heal = null
	assert_null(PresentationDefaults.ForSkill(_skill([_heal()]), _archetypes))

func test_a_skill_echo_replays_the_skills_own_look_unless_it_has_an_echo_archetype() -> void:
	var skill: Skill = _skill([])
	skill.presentation = SkillPresentation.new()
	skill.presentation.archetype = PackedScene.new()
	skill.presentation.variant = EffectVariant.new()
	assert_eq(PresentationDefaults.ForSkillEcho(skill, _archetypes).variant, skill.presentation.variant)

	skill.presentation.echo_archetype = PackedScene.new()
	assert_eq(PresentationDefaults.ForSkillEcho(skill, _archetypes).archetype, skill.presentation.echo_archetype)

func test_a_status_without_an_echo_archetype_plays_the_pulse_with_its_icon() -> void:
	var status: StatusEffectData = StatusEffectData.new()
	status.icon = PlaceholderTexture2D.new()
	var echo: SkillPresentation = PresentationDefaults.ForStatusEcho(status, _archetypes)
	assert_eq(echo.archetype, _archetypes.echo_pulse)
	assert_eq(echo.variant.texture, status.icon)
