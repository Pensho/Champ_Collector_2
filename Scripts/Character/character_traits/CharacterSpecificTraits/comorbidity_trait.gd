class_name ComorbidityTrait extends CharacterTrait

const TICK_BONUS_PER_DEBUFF: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.05,
	Types.Rarity.Rare: 0.07,
	Types.Rarity.Epic: 0.09,
	Types.Rarity.Legendary: 0.11,
}

var _tick_bonus_per_debuff: float = 0.0

static func GetTickBonusPerDebuff(p_rarity: Types.Rarity) -> float:
	return TICK_BONUS_PER_DEBUFF.get(p_rarity, 0.0)

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_tick_bonus_per_debuff = GetTickBonusPerDebuff(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Status_Effects/Plague/Plague.png")
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

	_title = "Comorbidity"
	_body = "Debuffs placed by this skill deal increased damage over time, scaling with" \
			+ " the target's total active debuff count."

func OnSkillCast(
		_p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		_p_caster_attributes: Dictionary[Types.Attribute, int],
		_p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	result._tick_bonus_per_debuff = _tick_bonus_per_debuff
	return result
