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
var _avoidance_increment: float = 0.0

# Temporary icon borrowed from Hemoclarity until dedicated Jester art exists.
func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_avoidance_increment = AVOIDANCE_INCREMENT.get(p_rarity, 0.0)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Abilities/Double_The_Fun/Double_The_Fun.png")
	_title = "Double the fun!"
	_body = ("Chance to completely avoid incoming damage. The chance ramps up with each hit taken and resets on a "
			+ "successful avoidance.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Damage_Taken] = Callable(self, "OnDamageTaken")
	_execution_steps[Types.Combat_Event.On_Death] = Callable(self, "OnDeath")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_avoidance_stacks = 0

func OnDeath() -> void:
	_avoidance_stacks = 0

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_stacks: String = _body + "\nAvoidance chance: " \
	+ str(100.0 * (BASE_AVOID_CHANCE + (_avoidance_stacks * _avoidance_increment))) + "% / " \
	+ str(100.0 * (BASE_AVOID_CHANCE + (MAX_AVOIDANCE_STACKS * _avoidance_increment))) + "% (max)"
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_stacks, 0)
	p_character_repr.GetVisualEffects().SetSpriteEchoes(_avoidance_stacks)

func GetAvoidChance() -> float:
	return BASE_AVOID_CHANCE + _avoidance_increment * _avoidance_stacks

func OnDamageTaken(p_owner_ID: int, p_resolver: BattleResolver) -> float:
	var chance: float = GetAvoidChance()

	if(p_resolver.GetRandom().randf() < chance):
		_avoidance_stacks = 0
		p_resolver.EmitTraitText(p_owner_ID, "Avoided!")
		return 0.0

	_avoidance_stacks = min(_avoidance_stacks + 1, MAX_AVOIDANCE_STACKS)
	return 1.0

func GetTargetingDefenceMultiplier() -> float:
	return TARGETING_DEFENCE_MULTIPLIER
