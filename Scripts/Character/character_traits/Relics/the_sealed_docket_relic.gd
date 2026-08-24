class_name TheSealedDocketRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Sealed_Docket/The_Sealed_Docket.png")
	_title = "The Sealed Docket"
	_magnitude_by_rarity = [0.35, 0.42, 0.50, 0.62, 0.80]
	_body = ("While the target carries four or more distinct debuff types, damaging " +
			"skills deal +" + str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Echoes produced by anyone on the wearer's team resolve at half strength.")
