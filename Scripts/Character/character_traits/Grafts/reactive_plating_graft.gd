class_name ReactivePlatingGraft extends GraftEffect

const DEFENCE_BONUS_PER_STACK: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.02,
	Types.Rarity.Rare: 0.03,
	Types.Rarity.Epic: 0.04,
	Types.Rarity.Legendary: 0.05,
}

const MAX_STACKS: int = 9
const SPEED_DRAWBACK: float = -0.15

var _defence_bonus_per_stack: float = 0.0
var _stacks: int = 0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_defence_bonus_per_stack = DEFENCE_BONUS_PER_STACK.get(p_rarity, 0.0)
	_title = "Reactive Plating"
	_body = ("Gains a Hardened stack each time taking attack damage, raising Defense by "
			+ str(int(_defence_bonus_per_stack * 100)) + "% per stack, up to 9 stacks lasting the rest"
			+ " of the battle. Losing " + str(int(-SPEED_DRAWBACK * 100)) + "% Speed.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Damage_Taken] = Callable(self, "OnDamageTaken")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_stacks = 0
	_attribute_percent_delta[Types.Attribute.Defence] = 0.0

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var body_with_stacks: String = _body + "\nCurrent Hardened Stacks: " + str(_stacks)
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_stacks, 0)

func OnDamageTaken(_p_owner_ID: int, _p_attacker_ID: int, _p_resolver: BattleResolver) -> float:
	_stacks = min(_stacks + 1, MAX_STACKS)
	_attribute_percent_delta[Types.Attribute.Defence] = _defence_bonus_per_stack * _stacks
	return 1.0

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Speed: SPEED_DRAWBACK}
