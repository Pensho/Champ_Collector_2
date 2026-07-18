class_name HemoclarityTrait extends CharacterTrait

const HEALTH_THRESHOLD: float = 0.5

const MYSTICISM_BONUS: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.25,
	Types.Rarity.Rare: 0.30,
	Types.Rarity.Epic: 0.35,
	Types.Rarity.Legendary: 0.40,
}

var _mysticism_bonus: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_mysticism_bonus = MYSTICISM_BONUS.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Hemoclarity/Hemoclarity.png")
	_title = "Hemoclarity"
	_body = "While below half health, gain increased Mysticism."
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle() -> void:
	pass

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		_p_skill_name: String,
		p_caster_attributes: Dictionary[Types.Attribute, int],
		p_resolver: BattleResolver) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	var owner: Character = p_resolver.GetCharacters()[p_owner_ID]

	var max_health: int = owner.GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	if max_health <= 0:
		return result
	var health_fraction: float = float(owner._current_health) / float(max_health)
	if health_fraction >= HEALTH_THRESHOLD:
		return result

	p_caster_attributes[Types.Attribute.Mysticism] += int(
			ceilf(p_caster_attributes[Types.Attribute.Mysticism] * _mysticism_bonus))
	return result
