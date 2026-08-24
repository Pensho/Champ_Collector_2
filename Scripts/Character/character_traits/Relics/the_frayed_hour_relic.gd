class_name TheFrayedHourRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Frayed_Hour/The_Frayed_Hour.png")
	_title = "The Frayed Hour"
	_magnitude_by_rarity = [200.0, 250.0, 275.0, 300.0, 350.0]
	_body = ("Temporal Leak applied by the wearer has +" + str(roundi(Magnitude())) +
			"% its effect.\n" +
			"Barriers on the wearer's team have 75% less effect.")
