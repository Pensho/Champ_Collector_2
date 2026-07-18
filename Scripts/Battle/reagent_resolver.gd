class_name ReagentResolver extends Node

const TINCTURE_ATTRIBUTES: Array[Types.Attribute] = [
	Types.Attribute.Speed,
	Types.Attribute.Attack,
	Types.Attribute.Defence,
	Types.Attribute.Accuracy,
	Types.Attribute.Resistance,
	Types.Attribute.Mysticism,
	Types.Attribute.Knowledge,
	Types.Attribute.CritChance,
	Types.Attribute.CritDamage,
]


static func PercentFraction(p_magnitude: float, p_potency: float) -> float:
	return (p_magnitude / 100.0) * p_potency


static func AttributeIncreaseAmount(p_current_value: int, p_magnitude: float, p_potency: float) -> int:
	return int(ceil(p_current_value * PercentFraction(p_magnitude, p_potency)))


static func HealAmount(p_max_health: int, p_magnitude: float, p_potency: float) -> int:
	return int(ceil(p_max_health * PercentFraction(p_magnitude, p_potency)))


static func HealthCostAmount(p_max_health: int, p_magnitude: float, p_potency: float, p_current_health: int) -> int:
	var cost: int = int(ceil(p_max_health * PercentFraction(p_magnitude, p_potency)))
	return mini(cost, p_current_health - 1)


static func PotencyScaledCount(p_magnitude: float, p_potency: float) -> int:
	return int(floor(p_magnitude * p_potency))


static func RandomTinctureAttribute(p_random: RandomNumberGenerator) -> Types.Attribute:
	return TINCTURE_ATTRIBUTES[p_random.randi_range(0, TINCTURE_ATTRIBUTES.size() - 1)]
