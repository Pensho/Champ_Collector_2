class_name ThePlantedHeelRelic extends RelicEffect

func Init(p_rarity: Types.Rarity) -> void:
	super.Init(p_rarity)
	_trait_texture = RelicEffect.LoadIcon("res://Assets/Champ_Collector/Icons/Items/" +
			"Relics/The_Planted_Heel/The_Planted_Heel.png")
	_title = "The Planted Heel"
	_magnitude_by_rarity = [0.30, 0.35, 0.40, 0.50, 0.65]
	_body = ("After the wearer takes a single hit exceeding 15% of their max Health, " +
			"their next damaging skill deals +" + str(roundi(Magnitude() * 100)) + "% damage.\n" +
			"Drawback: enemies target the wearer at 1.5x weight, permanently.")
