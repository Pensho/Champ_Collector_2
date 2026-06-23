class_name DoubleTheFunTrait extends CharacterTrait

const BASE_AVOID_CHANCE: float = 0.05
const MAX_AVOIDANCE_STACKS: int = 3

const AVOIDANCE_INCREMENT: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.03,
	Types.Rarity.Rare: 0.04,
	Types.Rarity.Epic: 0.05,
	Types.Rarity.Legendary: 0.06,
}

const TARGETING_DEFENCE_MULTIPLIER: float = 1.5

var _avoidance_stacks: int = 0

# Temporary icon borrowed from Hemoclarity until dedicated Jester art exists.
func Init() -> void:
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Hemoclarity/Hemoclarity.png")
	_title = "Double the fun!"
	_body = "Chance to completely avoid incoming damage. The chance ramps up with each hit taken and resets on a successful avoidance."
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Damage_Taken] = Callable(self, "OnDamageTaken")

func StartOfBattle(p_character_repr: CharacterRepresentation) -> void:
	_avoidance_stacks = 0
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, _body, 0)

func GetAvoidChance(p_rarity: Types.Rarity) -> float:
	return BASE_AVOID_CHANCE + AVOIDANCE_INCREMENT.get(p_rarity, 0.0) * _avoidance_stacks

func UpdateTooltip(p_character_repr: CharacterRepresentation, p_rarity: Types.Rarity) -> void:
	var body_with_stacks: String = _body + "\nAvoidance chance: " \
	+ str(100.0 * (BASE_AVOID_CHANCE + (_avoidance_stacks * AVOIDANCE_INCREMENT.get(p_rarity, 0.0)))) + "% / " \
	+ str(100.0 * (BASE_AVOID_CHANCE + (MAX_AVOIDANCE_STACKS * AVOIDANCE_INCREMENT.get(p_rarity, 0.0)))) + "% (max)"
	p_character_repr.SetTraitElementToolTip(_title, body_with_stacks, 0)

func OnDamageTaken(p_character_repr: CharacterRepresentation, p_rarity: Types.Rarity, p_battle_ui: BattleUI) -> float:
	var chance: float = GetAvoidChance(p_rarity)

	if randf() < chance:
		_avoidance_stacks = 0
		p_battle_ui.SpawnCombatText("Avoided!", p_character_repr.position + p_battle_ui.COMBAT_TEXT_SPAWN_POINT)
		UpdateTooltip(p_character_repr, p_rarity)
		return 0.0

	_avoidance_stacks = min(_avoidance_stacks + 1, MAX_AVOIDANCE_STACKS)
	UpdateTooltip(p_character_repr, p_rarity)
	return 1.0

func GetTargetingDefenceMultiplier() -> float:
	return TARGETING_DEFENCE_MULTIPLIER
