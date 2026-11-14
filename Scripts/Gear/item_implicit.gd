class_name ItemImplicit extends Resource

## What a sub-type grants beyond its rolled attributes. Subclasses supply the kind of effect;
## its size is set by the item's rarity and never grows with upgrades. A kind whose magnitude
## does not scale smoothly may define its own rarity steps instead of RarityMultiplier.

func AttributeBonus(_p_attribute: Types.Attribute, _p_rarity: Types.Rarity) -> int:
	return 0

## The line shown apart from the rolled attributes.
func Text(_p_rarity: Types.Rarity) -> String:
	return ""

static func RarityMultiplier(p_rarity: Types.Rarity) -> float:
	var ladder: Array[float] = Game_Balance.ITEM_IMPLICIT_RARITY_MULTIPLIER
	return ladder[clampi(int(p_rarity) - 1, 0, ladder.size() - 1)]
