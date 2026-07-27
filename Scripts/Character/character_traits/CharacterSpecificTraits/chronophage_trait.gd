class_name ChronophageTrait extends CharacterTrait

const TITHE_FRACTION: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.25,
	Types.Rarity.Rare: 0.35,
	Types.Rarity.Epic: 0.45,
	Types.Rarity.Legendary: 0.55,
}

var _tithe_fraction: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_tithe_fraction = TITHE_FRACTION.get(p_rarity, 0.0)
	_title = "Time Tithe"
	_body = ("When the Chronophage reduces an enemy's turn bar, it absorbs a portion of " +
			"the stolen amount as its own turn-bar progress.")
	_execution_steps[Types.Combat_Event.Enemy_Turn_Bar_Reduced] = Callable(self, "OnEnemyTurnBarReduced")

func OnEnemyTurnBarReduced(
		p_owner_ID: int, p_reduction: float, p_resolver: BattleResolver) -> float:
	var turn_bump: float = p_reduction * _tithe_fraction
	if(0.0 != turn_bump):
		p_resolver.EmitTraitText(p_owner_ID, "Turn claimed")
	return turn_bump
