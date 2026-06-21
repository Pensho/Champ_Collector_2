class_name HemoclarityTrait extends CharacterTrait

const HEALTH_THRESHOLD: float = 0.5

const MYSTICISM_BONUS: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.25,
	Types.Rarity.Rare: 0.30,
	Types.Rarity.Epic: 0.35,
	Types.Rarity.Legendary: 0.40,
}

func Init() -> void:
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Hemoclarity/Hemoclarity.png")
	_title = "Hemoclarity"
	_body = "While below half health, gain increased Mysticism."
	_execution_steps[Types.Combat_Event.Skill_Cast] = Callable(self, "OnSkillCast")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

func OnSkillCast(
		p_owner_ID: int,
		_p_target_IDs: Array[int],
		p_characters: Dictionary[int, Character],
		_p_character_repr: Array[CharacterRepresentation],
		_p_skill_name: String,
		_p_battle_ui: BattleUI,
		p_caster_attributes: Dictionary[Types.Attribute, int]) -> TraitSkillResult:
	var result: TraitSkillResult = TraitSkillResult.new()
	var owner: Character = p_characters[p_owner_ID]

	var max_health: int = owner.GetBattleAttribute(Types.Attribute.Health) * Game_Balance.ATTRIBUTE_HEALTH_MULTIPLIER
	if max_health <= 0:
		return result
	var health_fraction: float = float(owner._currentHealth) / float(max_health)
	if health_fraction >= HEALTH_THRESHOLD:
		return result

	var bonus: float = MYSTICISM_BONUS.get(owner._rarity, 0.0)
	p_caster_attributes[Types.Attribute.Mysticism] += int(ceilf(p_caster_attributes[Types.Attribute.Mysticism] * bonus))
	return result
