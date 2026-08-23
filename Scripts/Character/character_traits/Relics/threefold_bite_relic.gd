class_name ThreefoldBiteRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/" +
			"Items/Relics/Threefold_Bite/Threefold_Bite.png")
	_title = "Threefold Bite"
	_magnitude_by_rarity = [0.60, 0.80, 1.00, 1.30, 1.70]
	_body = ("Every third cascade instance a single action produces deals +" +
			str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Drawback: damage that is not a cascade instance is reduced by 30%.")
