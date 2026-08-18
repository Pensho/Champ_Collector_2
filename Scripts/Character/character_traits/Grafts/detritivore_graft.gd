class_name DetritivoreGraft extends GraftEffect

const SCRAP_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.02,
	Types.Rarity.Rare: 0.03,
	Types.Rarity.Epic: 0.04,
	Types.Rarity.Legendary: 0.05,
}

const STARTING_RESISTANCE_PENALTY: float = -0.20
const SCAVENGE_HEAL_FRACTION: float = 0.02

var _stacks: int = 0
var _scrap_per_stack: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_scrap_per_stack = SCRAP_PER_RARITY.get(p_rarity, 0.0)
	_title = "Detritivore"
	_body = ("Whenever a reagent is consumed, a buff expires, or a zone dissipates anywhere in"
			+ " battle, heals " + str(roundi(SCAVENGE_HEAL_FRACTION * 100)) + "% of max Health and"
			+ " gains a permanent Scrap stack worth +" + str(roundi(_scrap_per_stack * 100))
			+ "% Resistance, uncapped. Starts each battle at "
			+ str(roundi(STARTING_RESISTANCE_PENALTY * 100)) + "% Resistance.")
	_execution_steps[Types.Combat_Event.Start_Combat] = Callable(self, "StartOfBattle")
	_execution_steps[Types.Combat_Event.Resource_Depleted] = Callable(self, "OnScavenge")

func StartOfBattle(_p_owner_ID: int, _p_resolver: BattleResolver) -> void:
	_stacks = 0
	_attribute_percent_delta[Types.Attribute.Resistance] = STARTING_RESISTANCE_PENALTY

func OnScavenge(p_owner_ID: int, p_resolver: BattleResolver) -> void:
	_stacks += 1
	_attribute_percent_delta[Types.Attribute.Resistance] = (
			STARTING_RESISTANCE_PENALTY + _scrap_per_stack * _stacks)
	p_resolver.ResolveTraitHeal([p_owner_ID], SCAVENGE_HEAL_FRACTION)

func RefreshVisuals(p_character_repr: CharacterRepresentation) -> void:
	var current_resistance_percent: int = roundi(
			_attribute_percent_delta.get(Types.Attribute.Resistance, 0.0) * 100)
	var body_with_modifier: String = (_body + "\nCurrent Resistance modifier: "
			+ str(current_resistance_percent) + "%")
	p_character_repr.SetTraitElement(_trait_texture, 0)
	p_character_repr.SetTraitElementToolTip(_title, body_with_modifier, 0)

func _Drawback() -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Resistance: STARTING_RESISTANCE_PENALTY}
