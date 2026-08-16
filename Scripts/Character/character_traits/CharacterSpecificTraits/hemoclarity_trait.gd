class_name HemoclarityTrait extends CharacterTrait

## Rate applied per 1% of max Health the Bloodmage is missing, capped at MAX_MISSING_HEALTH.
const RATE_PER_PERCENT_MISSING: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.007,
	Types.Rarity.Rare: 0.008,
	Types.Rarity.Epic: 0.009,
	Types.Rarity.Legendary: 0.010,
}

const MAX_MISSING_HEALTH: float = 0.80

var _rate_per_percent_missing: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_rate_per_percent_missing = RATE_PER_PERCENT_MISSING.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Passives/Hemoclarity_Trait/Hemoclarity.png")
	_title = "Hemoclarity"
	_body = "For every 1% of max Health missing (capped at 80%), gain " \
			+ str(_rate_per_percent_missing * 100.0) + "% Mysticism, healing, and Barrier absorption."
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	var bonus: float = _MissingHealthBonus(p_owner_ID, p_resolver)
	if(0.0 == bonus):
		return result
	p_caster_attributes[Types.Attribute.Mysticism] += int(
			ceilf(p_caster_attributes[Types.Attribute.Mysticism] * bonus))
	return result

func GetOutgoingRestorationMultiplier(p_owner_ID: int, p_resolver: BattleResolver) -> float:
	return 1.0 + _MissingHealthBonus(p_owner_ID, p_resolver)

func _MissingHealthBonus(p_owner_ID: int, p_resolver: BattleResolver) -> float:
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]
	var max_health: int = p_resolver.GetMaxHealth(p_owner_ID)
	if(max_health <= 0):
		return 0.0
	var missing_fraction: float = clampf(1.0 - float(owner._current_health) / float(max_health), 0.0, MAX_MISSING_HEALTH)
	return _rate_per_percent_missing * missing_fraction * 100.0
