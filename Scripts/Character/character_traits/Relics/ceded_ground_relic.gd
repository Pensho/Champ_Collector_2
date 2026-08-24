class_name CededGroundRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Ceded_Ground/Ceded_Ground.png")
	_title = "Ceded Ground"
	_magnitude_by_rarity = [0.08, 0.10, 0.12, 0.14, 0.17]
	_body = ("When an ally lands a critical hit while holding a buff the wearer applied, " +
			"that ally heals for " + str(roundi(Magnitude() * 100)) + "% of the damage " +
			"dealt.\n" +
			"The healing is paid out of the wearer's own Health, and the wearer's " +
			"Mysticism is reduced by 50%.")
