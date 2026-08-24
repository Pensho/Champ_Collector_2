class_name TheClosedWoundRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Closed_Wound/The_Closed_Wound.png")
	_title = "The Closed Wound"
	_magnitude_by_rarity = [0.25, 0.30, 0.35, 0.45, 0.60]
	_body = ("Damaging skills deal +" + str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"No one on the wearer's team can be healed, by any source.")
