class_name NoWastedMarginTrait extends CharacterTrait

## For every point of Critical Chance an ally has above 100, that ally's Critical Damage
## gains this many points instead of the excess being discarded.
const OVERFLOW_RATE: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 2.0,
	Types.Rarity.Rare: 3.0,
	Types.Rarity.Epic: 4.0,
	Types.Rarity.Legendary: 5.0,
}

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = load("res://Assets/Champ_Collector/Icons/Status_Effects/Keen_Edge/Keen_Edge.png")
	_title = "No Wasted Margin"
	_body = ("For every point of an ally's own Critical Chance above 100%%, that ally " +
			"gains %d Critical Damage per %% point instead.") % int(OVERFLOW_RATE.get(p_rarity, 0.0))

func GetCritChanceOverflowRate() -> float:
	return OVERFLOW_RATE.get(_owner_rarity, 0.0)
