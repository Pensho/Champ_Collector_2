class_name TheQuietMassRelic extends RelicEffect

var _targeting_weight_by_rarity: Array[float] = [0.45, 0.40, 0.35, 0.30, 0.25]

func TargetingWeightMultiplier() -> float:
	var index: int = int(_owner_rarity) - 1
	if(index < 0 or index >= _targeting_weight_by_rarity.size()):
		return 1.0
	return _targeting_weight_by_rarity[index]

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/The_Quiet_Mass/The_Quiet_Mass.png")
	_title = "The Quiet Mass"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.40, 0.50]
	_body = ("Gain +" + str(roundi(Magnitude() * 100)) + "% max Health.\n" +
			"Enemies target the wearer " + str(roundi((1.0 - TargetingWeightMultiplier()) * 100)) +
			"% less likely.")

func GetAttributeDelta(p_attribute: Types.Attribute, p_base_value: int) -> int:
	if(Types.Attribute.Health != p_attribute):
		return 0
	return int(ceilf(p_base_value * Magnitude()))

func GetTargetingPriorityMultiplier() -> float:
	return TargetingWeightMultiplier()
