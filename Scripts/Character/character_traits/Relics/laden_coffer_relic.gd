class_name LadenCofferRelic extends RelicEffect

const SPEED_DRAWBACK: float = 0.30

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Laden_Coffer/Laden_Coffer.png")
	_title = "Laden Coffer"
	_magnitude_by_rarity = [0.10, 0.15, 0.20, 0.25, 0.35]
	_body = ("Rewards from a battle the wearer fought in are increased by +" +
			str(roundi(Magnitude() * 100)) + "%. Only the largest bonus among the fielded " +
			"team applies.\n" +
			"The wearer's Speed is reduced by 30%.")

func GetRewardMultiplier() -> float:
	return 1.0 + Magnitude()

func GetAttributeDelta(p_attribute: Types.Attribute, p_base_value: int) -> int:
	if(Types.Attribute.Speed != p_attribute):
		return 0
	return -int(ceilf(p_base_value * SPEED_DRAWBACK))
