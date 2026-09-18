class_name RarityColors

const UNKNOWN: Color = Color(0.0, 0.0, 0.0, 0.0)

# Backdrops and icon tints.
const FILL: Dictionary[Types.Rarity, Color] = {
	Types.Rarity.Common: Color8(98, 98, 98),
	Types.Rarity.Uncommon: Color8(0, 139, 80),
	Types.Rarity.Rare: Color8(0, 54, 226),
	Types.Rarity.Epic: Color8(105, 0, 123),
	Types.Rarity.Legendary: Color8(166, 97, 0),
}

# Brighter variants that stay readable as font colors on dark panels.
const TEXT: Dictionary[Types.Rarity, Color] = {
	Types.Rarity.Common: Color8(98, 98, 98),
	Types.Rarity.Uncommon: Color8(0, 186, 65),
	Types.Rarity.Rare: Color8(45, 131, 255),
	Types.Rarity.Epic: Color8(148, 35, 255),
	Types.Rarity.Legendary: Color8(238, 65, 0),
}

static func GetFill(p_rarity: int) -> Color:
	return FILL.get(p_rarity, UNKNOWN)
