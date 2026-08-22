class_name BetweenThePlatesTrait extends CharacterTrait

const IGNORE_RATE: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.12,
	Types.Rarity.Rare: 0.16,
	Types.Rarity.Epic: 0.20,
	Types.Rarity.Legendary: 0.25,
}

var _ignore_rate: float = 0.0

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_ignore_rate = IGNORE_RATE.get(p_rarity, 0.0)
	_trait_texture = load(
			"res://Assets/Champ_Collector/Icons/Abilities/Passives/Between_The_Plates_Trait/between_the_plates_trait.png")
	_title = "Between the Plates"
	_body = ("Every attack ignores " + str(roundi(_ignore_rate * 100))
			+ "% of the target's Defence.")

func GetBaseDefenceIgnoreRate(_p_owner_ID: int) -> float:
	return _ignore_rate
