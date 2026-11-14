class_name AttributeImplicit extends ItemImplicit

## A flat bonus to one attribute: its Common value scaled by the rarity multiplier.

@export var _attribute: Types.Attribute
@export var _base_value: int = 0

func AttributeBonus(p_attribute: Types.Attribute, p_rarity: Types.Rarity) -> int:
	if(p_attribute != _attribute):
		return 0
	return Value(p_rarity)

func Text(p_rarity: Types.Rarity) -> String:
	return ItemText.AttributeLine(_attribute, Value(p_rarity))

func Value(p_rarity: Types.Rarity) -> int:
	return roundi(_base_value * RarityMultiplier(p_rarity))
