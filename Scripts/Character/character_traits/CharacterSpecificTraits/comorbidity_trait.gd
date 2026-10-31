class_name ComorbidityTrait extends CharacterTrait

const TICK_GROWTH_SCALE: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 2.8,
	Types.Rarity.Rare: 3.2,
	Types.Rarity.Epic: 3.6,
	Types.Rarity.Legendary: 4.0,
}

var _tick_growth_scale: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_tick_growth_scale = TICK_GROWTH_SCALE.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/Comorbidity_Trait/comorbidity_trait.png")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_title = "Comorbidity"
	_body = ("This character's debuffs activate again for every distinct debuff type on the target. " +
			"Each activation makes later ones stronger: %d%% at first, less each time." %
				roundi(100.0 * _tick_growth_scale / (1.0 + StatusEffectResolver.TICK_GROWTH_HALF_COUNT)))

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	result._trait_riders[&"repeats_per_distinct_debuff"] = true
	result._trait_riders[StatusEffectResolver.TICK_GROWTH_SCALE_RIDER_KEY] = _tick_growth_scale
	return result
