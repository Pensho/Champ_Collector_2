class_name ComorbidityTrait extends CharacterTrait

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/Comorbidity_Trait/comorbidity_trait.png")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_title = "Comorbidity"
	_body = "Debuffs placed by this skill tick again once for every distinct debuff type" \
			+ " on the target."

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	result._repeats_tick_per_distinct_debuff = true
	return result
