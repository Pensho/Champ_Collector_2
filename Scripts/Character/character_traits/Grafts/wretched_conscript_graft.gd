class_name WretchedConscriptGraft extends GraftEffect

const DEFENCE_BONUS_PER_RARITY: Dictionary[Types.Rarity, float] = {
	Types.Rarity.Uncommon: 0.08,
	Types.Rarity.Rare: 0.10,
	Types.Rarity.Epic: 0.12,
	Types.Rarity.Legendary: 0.14,
}

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_title = "Wretched Conscript"
	_body = ("A soldier fused on and worn like a second hide. Gaining "
			+ str(roundi(DEFENCE_BONUS_PER_RARITY.get(p_rarity, 0.0) * 100)) + "% Defence.")

func _BonusForRarity(p_rarity: Types.Rarity) -> Dictionary[Types.Attribute, float]:
	return {Types.Attribute.Defence: DEFENCE_BONUS_PER_RARITY.get(p_rarity, 0.0)}
